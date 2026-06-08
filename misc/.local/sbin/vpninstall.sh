#!/bin/sh

vpnctl_src="$HOME/.local/sbin/vpnctl"
vpnrun_src="$HOME/.local/sbin/vpnrun"

chmod 755 "$vpnctl_src"
chmod 755 "$vpnrun_src"
sudo ln -s "$vpnctl_src" "/usr/local/sbin/vpnctl"
sudo ln -s "$vpnrun_src" "/usr/local/sbin/vpnrun"

sudo tee /etc/systemd/system/vpnctl-login@.service >/dev/null <<'EOF'
[Unit]
Description=Start vpnctl %i when user logs in
After=network-online.target user@1000.service
Wants=network-online.target
PartOf=user@1000.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/vpnctl up %i
ExecStop=/usr/local/sbin/vpnctl down %i

[Install]
WantedBy=user@1000.service
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now vpnctl-login@wg-CH-1038.service

