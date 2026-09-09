#!/bin/bash

# Configuration
CONFIG_DIR="/opt/homelab/host/config"
MONITOR_LXC_ID="200"
IMAGE_NAME="ghcr.io/amir20/dozzle:v10"

echo "=== Updating & Restarting Dozzle and Dozzle Agents ==="

# 1. Update and restart dozzle-agent in all LXCs using it
echo "Searching for LXCs using dozzle-agent..."

for conf_file in "$CONFIG_DIR"/*.conf; do
  # Extract the LXC ID from the filename (e.g. 101.conf -> 101)
  filename=$(basename "$conf_file")
  lxc_id="${filename%.conf}"
  
  # Skip non-numeric filenames if any
  [[ ! "$lxc_id" =~ ^[0-9]+$ ]] && continue
  
  # Check if the config references dozzle-agent
  if grep -q "dozzle-agent" "$conf_file"; then
    echo "Found dozzle-agent mount in LXC $lxc_id"
    
    # Check if the LXC is running
    status=$(pct status "$lxc_id" 2>/dev/null)
    if [[ "$status" == *"status: running"* ]]; then
      echo "  LXC $lxc_id is running. Pulling latest image..."
      pct exec "$lxc_id" -- podman pull "$IMAGE_NAME"
      echo "  Restarting dozzle-agent..."
      if pct exec "$lxc_id" -- systemctl restart dozzle-agent; then
        echo "  [OK] dozzle-agent updated and restarted in LXC $lxc_id"
      else
        echo "  [ERROR] Failed to restart dozzle-agent in LXC $lxc_id"
      fi
    else
      echo "  [SKIP] LXC $lxc_id is not running (status: ${status:-offline})"
    fi
  fi
done

# 2. Update and restart dozzle in the monitor LXC
echo "Updating and restarting dozzle in monitor LXC ($MONITOR_LXC_ID)..."
status=$(pct status "$MONITOR_LXC_ID" 2>/dev/null)
if [[ "$status" == *"status: running"* ]]; then
  echo "  Pulling latest image in monitor LXC $MONITOR_LXC_ID..."
  pct exec "$MONITOR_LXC_ID" -- podman pull "$IMAGE_NAME"
  echo "  Restarting dozzle..."
  if pct exec "$MONITOR_LXC_ID" -- systemctl restart dozzle; then
    echo "  [OK] dozzle updated and restarted in LXC $MONITOR_LXC_ID"
  else
    echo "  [ERROR] Failed to restart dozzle in LXC $MONITOR_LXC_ID"
  fi
else
  echo "  [SKIP] Monitor LXC $MONITOR_LXC_ID is not running (status: ${status:-offline})"
fi

echo "=== Done ==="
