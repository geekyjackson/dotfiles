#!/usr/bin/env bash
set -Eeuo pipefail

NETNS="${NETNS:-vpn}"
WG_DIR="${WG_DIR:-/etc/wireguard}"

VRF_TABLE_BASE="${VRF_TABLE_BASE:-1000}"
STATE_DIR="${STATE_DIR:-/var/lib/vpn-netns/$NETNS}"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root." >&2
    exit 1
  fi
}

require_cmds() {
  for cmd in ip wg wg-quick awk sort sed grep tr; do
    command -v "$cmd" >/dev/null 2>&1 || {
      echo "Missing required command: $cmd" >&2
      exit 1
    }
  done
}

conf_value_lines() {
  local key="$1"
  local file="$2"

  awk -v wanted="$key" '
    BEGIN { section = "" }

    /^[[:space:]]*($|#|;)/ { next }

    /^\[/ {
      section = tolower($0)
      next
    }

    section == "[interface]" {
      line = $0
      sub(/[[:space:]]*[#;].*$/, "", line)

      split(line, parts, "=")
      k = parts[1]
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)

      if (tolower(k) == tolower(wanted)) {
        sub(/^[^=]*=/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        print line
      }
    }
  ' "$file"
}

comma_values() {
  sed 's/,/\n/g' |
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' |
    sed '/^$/d'
}

valid_ifname() {
  local name="$1"

  [[ ${#name} -le 15 ]] || return 1
  [[ "$name" =~ ^[A-Za-z0-9_.-]+$ ]] || return 1
}

vrf_name_for_index() {
  local index="$1"
  printf 'vrf%d\n' "$index"
}

delete_existing_link() {
  local ifname="$1"
  local vrfname="$2"

  if ip link show "$ifname" >/dev/null 2>&1; then
    ip link delete "$ifname"
  fi

  if ip -n "$NETNS" link show "$ifname" >/dev/null 2>&1; then
    ip -n "$NETNS" link delete "$ifname"
  fi

  if ip -n "$NETNS" link show "$vrfname" >/dev/null 2>&1; then
    ip -n "$NETNS" link delete "$vrfname"
  fi
}

is_ipv6() {
  [[ "$1" == *:* ]]
}

add_addr_to_iface() {
  local ifname="$1"
  local addr="$2"

  if is_ipv6 "$addr"; then
    ip -n "$NETNS" -6 address add "$addr" dev "$ifname"
  else
    ip -n "$NETNS" -4 address add "$addr" dev "$ifname"
  fi
}

add_route_for_cidr() {
  local table="$1"
  local ifname="$2"
  local cidr="$3"
  local metric="$4"

  [[ "$cidr" == "(none)" ]] && return 0

  if is_ipv6 "$cidr"; then
    ip -n "$NETNS" -6 route replace table "$table" "$cidr" dev "$ifname" metric "$metric"
  else
    ip -n "$NETNS" -4 route replace table "$table" "$cidr" dev "$ifname" metric "$metric"
  fi
}

add_dns_host_route() {
  local table="$1"
  local ifname="$2"
  local dns="$3"

  # Ignore search domains here. Only numeric DNS servers need routes.
  if [[ "$dns" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ip -n "$NETNS" -4 route replace table "$table" "$dns/32" dev "$ifname"
  elif [[ "$dns" == *:* ]]; then
    ip -n "$NETNS" -6 route replace table "$table" "$dns/128" dev "$ifname"
  fi
}

require_root
require_cmds

shopt -s nullglob
confs=("$WG_DIR"/*.conf)

if (( ${#confs[@]} == 0 )); then
  echo "No .conf files found in $WG_DIR" >&2
  exit 1
fi

if ! ip netns list | awk '{print $1}' | grep -qx "$NETNS"; then
  ip netns add "$NETNS"
fi

ip -n "$NETNS" link set lo up

# Allow VRF-bound processes to use local services if needed.
# These are harmless if unsupported on an older kernel.
ip netns exec "$NETNS" sysctl -qw net.ipv4.tcp_l3mdev_accept=1 || true
ip netns exec "$NETNS" sysctl -qw net.ipv4.udp_l3mdev_accept=1 || true
ip netns exec "$NETNS" sysctl -qw net.ipv4.raw_l3mdev_accept=1 || true

dns_nameservers="$(mktemp)"
dns_search="$(mktemp)"
vrf_map="$(mktemp)"
trap 'rm -f "$dns_nameservers" "$dns_search" "$vrf_map"' EXIT

index=1

for conf in "${confs[@]}"; do
  ifname="$(basename "$conf" .conf)"
  vrfname="$(vrf_name_for_index "$index")"
  table=$((VRF_TABLE_BASE + index))

  if ! valid_ifname "$ifname"; then
    echo "Invalid interface name derived from $conf: $ifname" >&2
    echo "Interface names must be <=15 chars and contain only A-Z, a-z, 0-9, _, ., or -" >&2
    exit 1
  fi

  echo "Configuring $ifname from $conf in namespace $NETNS using $vrfname table $table"

  delete_existing_link "$ifname" "$vrfname"

  ip -n "$NETNS" link add "$vrfname" type vrf table "$table"
  ip -n "$NETNS" link set "$vrfname" up

  # Create WireGuard in the host namespace first.
  # This keeps the WireGuard UDP socket in the host namespace after the link
  # is moved, so endpoint traffic still uses the host network path.
  ip link add "$ifname" type wireguard
  wg setconf "$ifname" <(wg-quick strip "$conf")
  ip link set "$ifname" netns "$NETNS"

  # Put this WireGuard link into its own VRF.
  ip -n "$NETNS" link set "$ifname" master "$vrfname"

  # Now duplicate provider addresses are safe because each interface is in a
  # different VRF/routing table inside the same namespace.
  while IFS= read -r addr; do
    add_addr_to_iface "$ifname" "$addr"
  done < <(conf_value_lines Address "$conf" | comma_values)

  mtu="$(conf_value_lines MTU "$conf" | comma_values | head -n1 || true)"
  if [[ -n "${mtu:-}" ]]; then
    ip -n "$NETNS" link set dev "$ifname" mtu "$mtu"
  fi

  ip -n "$NETNS" link set "$ifname" up

  # Add AllowedIPs routes into this interface's VRF table.
  while read -r _peer allowed_ips; do
    for cidr in $allowed_ips; do
      add_route_for_cidr "$table" "$ifname" "$cidr" 100
    done
  done < <(ip netns exec "$NETNS" wg show "$ifname" allowed-ips)

  # Collect DNS and also add host routes for same-IP provider DNS inside
  # this interface's own VRF table.
  while IFS= read -r dns; do
    if [[ "$dns" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$dns" == *:* ]]; then
      echo "$dns" >> "$dns_nameservers"
      add_dns_host_route "$table" "$ifname" "$dns"
    else
      echo "$dns" >> "$dns_search"
    fi
  done < <(conf_value_lines DNS "$conf" | comma_values)

  printf '%s %s %s\n' "$ifname" "$vrfname" "$table" >> "$vrf_map"

  index=$((index + 1))
done

mkdir -p "/etc/netns/$NETNS"

if [[ -s "$dns_nameservers" || -s "$dns_search" ]]; then
  {
    echo "# Generated from $WG_DIR/*.conf for netns $NETNS"
    echo "# DNS is resolved inside whichever VRF the process is bound to."

    if [[ -s "$dns_nameservers" ]]; then
      sort -u "$dns_nameservers" | sed 's/^/nameserver /'
    fi

    if [[ -s "$dns_search" ]]; then
      printf "search "
      sort -u "$dns_search" | paste -sd ' ' -
      printf "\n"
    fi
  } > "/etc/netns/$NETNS/resolv.conf"
fi

install -d "$STATE_DIR"
cp "$vrf_map" "$STATE_DIR/vrf-map"

echo
echo "Done."
echo
echo "VRF map:"
cat "$STATE_DIR/vrf-map"

echo
echo "Check interfaces:"
echo "  sudo ip netns exec $NETNS ip -br addr"
echo
echo "Check VRFs:"
echo "  sudo ip netns exec $NETNS ip -d link show type vrf"
echo
echo "Check routes for one VRF table:"
echo "  sudo ip netns exec $NETNS ip route show table 1001"
echo
echo "Run through a specific VPN interface/VRF:"
echo "  sudo ip netns exec $NETNS ip vrf exec vrf1 curl https://ifconfig.me"
