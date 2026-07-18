#!/bin/bash

# ---- SETUP ----
# - Disable key expiry for this machine and VM.
# - Set corresponding IPs for caddy
# - Approve/Auto-accept the exit node and subnet routes.
# - Set the Tailnet DNS to point to this node.

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
  echo "Tailscale is not installed. Installing..."
  curl -fsSL https://tailscale.com/install.sh | sh
else
  echo "Tailscale is already installed."
fi

# Enable and start the tailscaled daemon
echo "Enabling and starting tailscaled daemon..."
systemctl enable --now tailscaled

# Bring Tailscale up with specified routes and settings
echo "Configuring Tailscale..."
tailscale up \
  --advertise-routes=10.0.0.0/16,192.168.0.0/24 \
  --advertise-exit-node \
  --accept-dns=false
