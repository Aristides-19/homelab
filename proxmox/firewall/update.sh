#!/bin/bash
# Script to copy Proxmox firewall configs from the system to the repo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Copying Proxmox firewall configurations..."
cp /etc/pve/firewall/*.fw "$SCRIPT_DIR/"
cp /etc/pve/nodes/pc/host.fw "$SCRIPT_DIR/host.fw"

echo "Done."
