#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/vaultwarden/pod.kube /etc/containers/systemd/vaultwarden.kube
systemctl daemon-reload

echo "Vaultwarden setup complete. Run \`systemctl start vaultwarden\` to start the pod."