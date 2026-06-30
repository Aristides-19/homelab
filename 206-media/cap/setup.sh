#!/bin/bash

# Build the media-server image if it does not exist
if ! podman image exists localhost/cap-media-server:latest; then
    if [ ! -d "/opt/cap/Cap" ]; then
        read -p "Cap repository not found. Do you want to clone it from GitHub now? (y/n): " clone_repo
        if [[ "$clone_repo" =~ ^[Yy]$ ]]; then
            echo "Cloning Cap repository..."
            git clone --depth 1 https://github.com/CapSoftware/Cap.git /opt/cap/Cap
        fi
    fi

    if [ -d "/opt/cap/Cap" ]; then
        echo "Building media-server image..."
        podman build --network=host -t localhost/cap-media-server:latest \
          -f /opt/cap/Cap/apps/media-server/Dockerfile.standalone \
          /opt/cap/Cap/apps/media-server
          
        read -p "Do you want to delete the cloned Cap repository? (y/n): " clean_repo
        if [[ "$clean_repo" =~ ^[Yy]$ ]]; then
            echo "Cleaning up local Cap repository..."
            rm -rf /opt/cap/Cap
        fi
    else
        echo "Error: localhost/cap-media-server:latest is missing and repository is not available to build it."
        exit 1
    fi
else
    echo "Image localhost/cap-media-server:latest already exists. Skipping build."
    # Clean up repository if it was left over
    if [ -d "/opt/cap/Cap" ]; then
        read -p "Leftover Cap repository found. Do you want to delete it? (y/n): " clean_leftover
        if [[ "$clean_leftover" =~ ^[Yy]$ ]]; then
            echo "Cleaning up leftover Cap repository..."
            rm -rf /opt/cap/Cap
        fi
    fi
fi

# Deploy Quadlet
mkdir -p /etc/containers/systemd/

cp /opt/cap/pod.kube /etc/containers/systemd/cap.kube
systemctl daemon-reload

echo "Cap setup complete. Run 'systemctl start cap' to start the pod."