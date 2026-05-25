#!/bin/bash

echo "WARNING: Ensure TARGET_TAILNET_IP and KUMA_URL are configured in uptime/check.sh"

chmod +x /opt/tailscale/uptime/check.sh

cp tailscale-uptime.service /etc/systemd/system/
cp tailscale-uptime.timer /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now tailscale-uptime.timer

echo "Setup complete. Check /opt/tailscale/uptime/check.sh configuration."