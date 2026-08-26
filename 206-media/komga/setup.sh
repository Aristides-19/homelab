#!/bin/bash

# Ensure Komf config directory exists and copy application.yml
mkdir -p /data/komga/komf
cp -f /opt/komga/application.yml /data/komga/komf/application.yml

# Deploy Quadlet
mkdir -p /etc/containers/systemd/

cp /opt/komga/pod.kube /etc/containers/systemd/komga.kube
systemctl daemon-reload

echo "Komga setup complete. Run 'systemctl start komga' to start the pod."
