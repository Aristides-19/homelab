#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root."
  exit 1
fi

echo "=========================================="
echo "Starting system updates..."
echo "=========================================="

# Update Proxmox Host
echo ">>> [Host] Updating Proxmox Host..."
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade

# Update all running LXC containers
echo ""
echo ">>> [LXC] Identifying running LXC containers..."
running_containers=$(pct list | awk 'NR>1 && $2=="running" {print $1}')

if [ -z "$running_containers" ]; then
  echo "No running LXC containers found."
else
  for vmid in $running_containers; do
    name=$(pct list | awk -v id="$vmid" '$1==id {print $4}')
    echo "------------------------------------------"
    echo ">>> [LXC $vmid - $name] Updating container..."
    echo "------------------------------------------"
    
    # Run apt update & upgrade inside the container non-interactively
    pct exec "$vmid" -- sh -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade"
    
    if [ $? -eq 0 ]; then
      echo ">>> [LXC $vmid - $name] Update successful!"
    else
      echo ">>> [LXC $vmid - $name] WARNING: Update failed or returned errors."
    fi
  done
fi

echo ""
echo "=========================================="
echo "System updates finished!"
echo "=========================================="
