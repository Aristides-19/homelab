#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/uptime-kuma/pod.kube /etc/containers/systemd/uptime-kuma.kube
systemctl daemon-reload

echo "Uptime-Kuma setup complete. Run \`systemctl start uptime-kuma\` to start the pod."