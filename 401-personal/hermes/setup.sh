#!/bin/bash

# Create persistent configuration directory
mkdir -p /data/hermes/dev

# Set ownership to container user (UID 1993)
chown -R 1993:1993 /data/hermes/dev

# Chromium profile + CDP endpoint (second container in the pod)
mkdir -p /data/hermes/browser
chown -R 1993:1993 /data/hermes/browser

# Chromium watchdog: keeps labwc from streaming an empty desktop (and keeps the
# CDP endpoint on 9222 alive) when the window is closed. Installed after the
# container's first start has created /config/.config/labwc/.
if [ -d /data/hermes/browser/.config/labwc ]; then
  install -o 1993 -g 1993 -m 755 /opt/hermes/labwc/autostart \
    /data/hermes/browser/.config/labwc/autostart
fi

mkdir -p /etc/containers/systemd/

cp /opt/hermes/pod.kube /etc/containers/systemd/hermes.kube
systemctl daemon-reload

echo "Hermes setup complete. Run 'systemctl start hermes' to start the pod."
