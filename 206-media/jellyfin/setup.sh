#!/bin/bash

# Deploy Quadlet
mkdir -p /etc/containers/systemd/

cp /opt/jellyfin/pod.kube /etc/containers/systemd/jellyfin.kube
systemctl daemon-reload

echo "Jellyfin setup complete. Run 'systemctl start jellyfin' to start the pod."