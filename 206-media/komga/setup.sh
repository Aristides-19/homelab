#!/bin/bash

# Deploy Quadlet
mkdir -p /etc/containers/systemd/

cp /opt/komga/pod.kube /etc/containers/systemd/komga.kube
systemctl daemon-reload

echo "Komga setup complete. Run 'systemctl start komga' to start the pod."

