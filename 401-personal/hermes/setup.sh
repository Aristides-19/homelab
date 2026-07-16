#!/bin/bash

# Create persistent configuration directory
mkdir -p /data/hermes/dev
# Set ownership to container user (UID 1993)
chown -R 1993:1993 /data/hermes/dev

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
