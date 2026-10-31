#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/openbot/pod.kube /etc/containers/systemd/openbot.kube
systemctl daemon-reload

echo "OpenBot setup complete. Run \`systemctl start openbot\` to start the pod."
echo "Then sign in with: pct exec 401 -- podman exec openbot-openbot openbot login"
