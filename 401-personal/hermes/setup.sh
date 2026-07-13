#!/bin/bash

# Create persistent configuration directory
mkdir -p /data/hermes/dev
# Set ownership to container user (UID 1000)
chown -R 1000:1000 /data/hermes/dev

# Install acl package if not present (needed for sharing vault permissions)
if ! command -v setfacl &>/dev/null; then
  echo "Installing acl package..."
  apt update && apt install -y acl
fi

# Apply ACLs to Obsidian vault so both container users (UID 1000 and UID 1993) can read/write notes
if [ -d "/data/obsidian/vaults/dev" ]; then
  echo "Applying ACL permissions to Obsidian dev vault..."
  setfacl -R -m u:1000:rwx,u:1993:rwx /data/obsidian/vaults/dev
  setfacl -R -d -m u:1000:rwx,u:1993:rwx /data/obsidian/vaults/dev
else
  echo "Warning: Obsidian dev vault directory not found at /data/obsidian/vaults/dev"
fi

mkdir -p /etc/containers/systemd/

cp /opt/hermes/pod.kube /etc/containers/systemd/hermes.kube
systemctl daemon-reload


echo "Hermes setup complete. Run 'systemctl start hermes' to start the pod."
