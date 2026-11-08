#!/bin/bash

# Create persistent configuration directory
mkdir -p /data/hermes/dev

# Set ownership to container user (UID 1993)
chown -R 1993:1993 /data/hermes/dev

mkdir -p /etc/containers/systemd/

cp /opt/hermes/pod.kube /etc/containers/systemd/hermes.kube
systemctl daemon-reload

echo "Hermes setup complete. Run 'systemctl start hermes' to start the pod."
