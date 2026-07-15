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

# Build the obscura image if it does not exist
if ! podman image exists localhost/obscura:stealth; then
    if [ ! -d "/opt/hermes/obscura" ]; then
        read -p "Obscura repository not found. Do you want to clone it from GitHub now? (y/n): " clone_repo
        if [[ "$clone_repo" =~ ^[Yy]$ ]]; then
            echo "Cloning Obscura repository..."
            git clone --depth 1 https://github.com/h4ckf0r0day/obscura.git /opt/hermes/obscura
        fi
    fi

    if [ -d "/opt/hermes/obscura" ]; then
        echo "Building Obscura image with stealth features..."
        podman build --network=host -t localhost/obscura:stealth -f /opt/hermes/Dockerfile.obscura /opt/hermes/obscura
          
        read -p "Do you want to delete the cloned Obscura repository? (y/n): " clean_repo
        if [[ "$clean_repo" =~ ^[Yy]$ ]]; then
            echo "Cleaning up local Obscura repository..."
            rm -rf /opt/hermes/obscura
        fi
    else
        echo "Error: localhost/obscura:stealth is missing and repository is not available to build it."
        exit 1
    fi
else
    echo "Image localhost/obscura:stealth already exists. Skipping build."
    # Clean up repository if it was left over
    if [ -d "/opt/hermes/obscura" ]; then
        read -p "Leftover Obscura repository found. Do you want to delete it? (y/n): " clean_leftover
        if [[ "$clean_leftover" =~ ^[Yy]$ ]]; then
            echo "Cleaning up leftover Obscura repository..."
            rm -rf /opt/hermes/obscura
        fi
    fi
fi

mkdir -p /etc/containers/systemd/

cp /opt/hermes/pod.kube /etc/containers/systemd/hermes.kube
systemctl daemon-reload


echo "Hermes setup complete. Run 'systemctl start hermes' to start the pod."
