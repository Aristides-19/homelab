#!/bin/bash

# Deploy Quadlet
mkdir -p /etc/containers/systemd/

cp /opt/qbittorrent/pod.kube /etc/containers/systemd/qbittorrent.kube
systemctl daemon-reload

echo "qBittorrent setup complete. Run 'systemctl start qbittorrent' to start the pod."
