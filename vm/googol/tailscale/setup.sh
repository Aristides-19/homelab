#!/bin/bash

# ---- SETUP ----
# - Disable key expiry for this machine.
# - Approve exit node

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
  --accept-routes \
  --advertise-exit-node \
  --accept-dns