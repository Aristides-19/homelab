#!/bin/bash

# Create persistent configuration directory
mkdir -p /data/hermes/dev
# Set ownership to container user (UID 1993)
chown -R 1993:1993 /data/hermes/dev

# Build the antigravity-claude-proxy image if it does not exist
if ! podman image exists localhost/agy-proxy:latest; then
    echo "Building AGY Proxy image..."
    podman build --network=host -t localhost/agy-proxy:latest -f /opt/hermes/Dockerfile.proxy /opt/hermes
else
    echo "Image localhost/agy-proxy:latest already exists. Skipping build."
fi

mkdir -p /etc/containers/systemd/

cp /opt/hermes/pod.kube /etc/containers/systemd/hermes.kube
systemctl daemon-reload


echo "Hermes setup complete. Run 'systemctl start hermes' to start the pod."
