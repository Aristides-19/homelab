#!/bin/bash

# Configuration
CONFIG_DIR="/opt/homelab/host/config"
MONITOR_LXC_ID="200"

echo "=== Restarting Dozzle and Dozzle Agents ==="

# 1. Restart dozzle-agent in all LXCs using it
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
      echo "  LXC $lxc_id is running. Restarting dozzle-agent..."
      if pct exec "$lxc_id" -- systemctl restart dozzle-agent; then
        echo "  [OK] dozzle-agent restarted in LXC $lxc_id"
      else
        echo "  [ERROR] Failed to restart dozzle-agent in LXC $lxc_id"
      fi
    else
      echo "  [SKIP] LXC $lxc_id is not running (status: ${status:-offline})"
    fi
  fi
done

# 2. Restart dozzle in the monitor LXC
echo "Restarting dozzle in monitor LXC ($MONITOR_LXC_ID)..."
status=$(pct status "$MONITOR_LXC_ID" 2>/dev/null)
if [[ "$status" == *"status: running"* ]]; then
  if pct exec "$MONITOR_LXC_ID" -- systemctl restart dozzle; then
    echo "  [OK] dozzle restarted in LXC $MONITOR_LXC_ID"
  else
    echo "  [ERROR] Failed to restart dozzle in LXC $MONITOR_LXC_ID"
  fi
else
  echo "  [SKIP] Monitor LXC $MONITOR_LXC_ID is not running (status: ${status:-offline})"
fi

echo "=== Done ==="
