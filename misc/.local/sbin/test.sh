#!/usr/bin/env bash
set -Eeuo pipefail

NETNS="${NETNS:-vpn}"
WG_DIR="${WG_DIR:-/etc/wireguard}"
ROUTE_METRIC_BASE="${ROUTE_METRIC_BASE:-100}"

# Assign unique non-routed display addresses to wg interfaces so GUI/programs
# that only list interfaces with addresses can see them.
WG_INTERFACE_ALIASES="${WG_INTERFACE_ALIASES:-1}"
WG_ALIAS_PREFIX_A="${WG_ALIAS_PREFIX_A:-198}"
WG_ALIAS_PREFIX_B="${WG_ALIAS_PREFIX_B:-18}"

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

delete_existing_link() {
  local ifname="$1"

  if ip link show "$ifname" >/dev/null 2>&1; then
    ip link delete "$ifname"
  fi

  if ip -n "$NETNS" link show "$ifname" >/dev/null 2>&1; then
    ip -n "$NETNS" link delete "$ifname"
  fi
}

addr_ip() {
  local addr="$1"

  addr="${addr%%/*}"
  addr="${addr%%%*}"
  printf '%s\n' "$addr"
}

is_ipv6_addr() {
  [[ "$1" == *:* ]]
}

host_prefix_addr() {
  local ip_addr
  ip_addr="$(addr_ip "$1")"

  if is_ipv6_addr "$ip_addr"; then
    printf '%s/128\n' "$ip_addr"
  else
    printf '%s/32\n' "$ip_addr"
  fi
}

ensure_loopback_addr() {
  local addr="$1"
  local host_addr

  host_addr="$(host_prefix_addr "$addr")"

  # Real provider tunnel addresses live on lo once per namespace.
  ip -n "$NETNS" address replace "$host_addr" dev lo
}

assign_interface_alias() {
  local ifname="$1"
  local index="$2"

  (( WG_INTERFACE_ALIASES )) || return 0

  # 198.18.0.0/15 is reserved for benchmarking and is not publicly routed.
  # These are only visibility aliases. They are not used as VPN source addresses.
  local third fourth alias
  third=$(( (index - 1) / 250 ))
  fourth=$(( ((index - 1) % 250) + 1 ))

  alias="${WG_ALIAS_PREFIX_A}.${WG_ALIAS_PREFIX_B}.${third}.${fourth}/32"

  ip -n "$NETNS" address replace "$alias" dev "$ifname"
}

get_conf_sources() {
  local file="$1"
  local src4=""
  local src6=""
  local addr ip_addr

  while IFS= read -r addr; do
    ip_addr="$(addr_ip "$addr")"

    if is_ipv6_addr "$ip_addr"; then
      [[ -z "$src6" ]] && src6="$ip_addr"
    else
      [[ -z "$src4" ]] && src4="$ip_addr"
    fi
  done < <(conf_value_lines Address "$file" | comma_values)

  printf '%s\t%s\n' "$src4" "$src6"
}

add_route_for_cidr() {
  local ifname="$1"
  local cidr="$2"
  local metric="$3"
  local src4="$4"
  local src6="$5"

  [[ "$cidr" == "(none)" ]] && return 0

  if [[ "$cidr" == *:* ]]; then
    if [[ -n "$src6" ]]; then
      ip -n "$NETNS" -6 route replace "$cidr" dev "$ifname" src "$src6" metric "$metric"
    else
      ip -n "$NETNS" -6 route replace "$cidr" dev "$ifname" metric "$metric"
    fi
  else
    if [[ -n "$src4" ]]; then
      ip -n "$NETNS" route replace "$cidr" dev "$ifname" src "$src4" metric "$metric"
    else
      ip -n "$NETNS" route replace "$cidr" dev "$ifname" metric "$metric"
    fi
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

dns_nameservers="$(mktemp)"
dns_search="$(mktemp)"
trap 'rm -f "$dns_nameservers" "$dns_search"' EXIT

metric="$ROUTE_METRIC_BASE"
index=1

for conf in "${confs[@]}"; do
  ifname="$(basename "$conf" .conf)"

  if ! valid_ifname "$ifname"; then
    echo "Invalid interface name derived from $conf: $ifname" >&2
    echo "Interface names must be <=15 chars and contain only A-Z, a-z, 0-9, _, ., or -" >&2
    exit 1
  fi

  echo "Configuring $ifname from $conf in namespace $NETNS"

  delete_existing_link "$ifname"

  # Create WireGuard in the host namespace first.
  # After the link is moved, WireGuard keeps its UDP socket in the original
  # namespace, so encrypted endpoint traffic still uses the host network.
  ip link add "$ifname" type wireguard

  # Apply only WireGuard-native config.
  wg setconf "$ifname" <(wg-quick strip "$conf")

  # Move the link into the vpn namespace.
  ip link set "$ifname" netns "$NETNS"

  # Put each unique real provider tunnel address on lo.
  # This avoids duplicating 10.2.0.2/32 on every wg interface.
  while IFS= read -r addr; do
    ensure_loopback_addr "$addr"
  done < <(conf_value_lines Address "$conf" | comma_values)

  IFS=$'\t' read -r src4 src6 < <(get_conf_sources "$conf")

  mtu="$(conf_value_lines MTU "$conf" | comma_values | head -n1 || true)"
  if [[ -n "${mtu:-}" ]]; then
    ip -n "$NETNS" link set dev "$ifname" mtu "$mtu"
  fi

  ip -n "$NETNS" link set "$ifname" up

  # Add a unique synthetic address directly to the WireGuard interface.
  # This is for interface visibility in programs that ignore addressless links.
  assign_interface_alias "$ifname" "$index"

  # Recreate wg-quick-style AllowedIPs routes inside the namespace.
  # The real provider tunnel address is still used as the route source.
  while read -r _peer allowed_ips; do
    for cidr in $allowed_ips; do
      add_route_for_cidr "$ifname" "$cidr" "$metric" "$src4" "$src6"
    done
  done < <(ip netns exec "$NETNS" wg show "$ifname" allowed-ips)

  # Collect DNS entries for /etc/netns/$NETNS/resolv.conf.
  while IFS= read -r dns; do
    if [[ "$dns" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || "$dns" == *:* ]]; then
      echo "$dns" >> "$dns_nameservers"
    else
      echo "$dns" >> "$dns_search"
    fi
  done < <(conf_value_lines DNS "$conf" | comma_values)

  metric=$((metric + 100))
  index=$((index + 1))
done

if [[ -s "$dns_nameservers" || -s "$dns_search" ]]; then
  mkdir -p "/etc/netns/$NETNS"

  {
    echo "# Generated from $WG_DIR/*.conf for netns $NETNS"

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

echo
echo "Done."
echo
echo "Check addresses:"
echo "  ip netns exec $NETNS ip -br addr"
echo
echo "Check routes:"
echo "  ip -n $NETNS route"
echo "  ip -n $NETNS -6 route"
echo
echo "Check WireGuard:"
echo "  ip netns exec $NETNS wg show"
echo
echo "Run commands inside the namespace:"
echo "  ip netns exec $NETNS <command>"
