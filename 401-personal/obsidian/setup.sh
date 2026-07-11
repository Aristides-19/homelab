#!/bin/bash

# Build the livesync-bridge image if it does not exist
if ! podman image exists localhost/livesync-bridge:latest; then
    if [ ! -d "/opt/obsidian/livesync-bridge" ]; then
        read -p "livesync-bridge repository not found. Do you want to clone it from GitHub now? (y/n): " clone_repo
        if [[ "$clone_repo" =~ ^[Yy]$ ]]; then
            echo "Cloning livesync-bridge repository (with submodules)..."
            git clone --recursive --depth 1 https://github.com/vrtmrz/livesync-bridge.git /opt/obsidian/livesync-bridge
        fi
    fi

    if [ -d "/opt/obsidian/livesync-bridge" ]; then
        echo "Building livesync-bridge image..."
        podman build --network=host -t localhost/livesync-bridge:latest /opt/obsidian/livesync-bridge
          
        read -p "Do you want to delete the cloned livesync-bridge repository? (y/n): " clean_repo
        if [[ "$clean_repo" =~ ^[Yy]$ ]]; then
            echo "Cleaning up local livesync-bridge repository..."
            rm -rf /opt/obsidian/livesync-bridge
        fi
    else
        echo "Error: localhost/livesync-bridge:latest is missing and repository is not available to build it."
        exit 1
    fi
else
    echo "Image localhost/livesync-bridge:latest already exists. Skipping build."
    # Clean up repository if it was left over
    if [ -d "/opt/obsidian/livesync-bridge" ]; then
        read -p "Leftover livesync-bridge repository found. Do you want to delete it? (y/n): " clean_leftover
        if [[ "$clean_leftover" =~ ^[Yy]$ ]]; then
            echo "Cleaning up leftover livesync-bridge repository..."
            rm -rf /opt/obsidian/livesync-bridge
        fi
    fi
fi

mkdir -p /etc/containers/systemd/

# CouchDB and Vaults Settings
mkdir -p /data/obsidian/db/data
mkdir -p /data/obsidian/db/config
chown -R 5984:5984 /data/obsidian/db

mkdir -p /data/obsidian/vaults/dev
mkdir -p /data/obsidian/vaults/doc
chown -R 1993:1993 /data/obsidian/vaults

cp /opt/obsidian/pod.kube /etc/containers/systemd/obsidian.kube
systemctl daemon-reload

echo "Obsidian setup complete. Run 'systemctl start obsidian' to start the pod."
