#!/bin/bash

# Exit on error
set -e

# Install Caddy if not already installed
if ! command -v caddy &> /dev/null; then
  echo "Caddy is not installed. Installing standard Caddy..."
  apt-get update
  apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
  chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  chmod o+r /etc/apt/sources.list.d/caddy-stable.list
  apt-get update
  apt-get install -y caddy
fi

# 2. Check if Caddy already has the Cloudflare DNS module installed
if command -v caddy &>/dev/null && caddy list-modules | grep -q "dns.providers.cloudflare"; then
  echo "Caddy is already installed with the Cloudflare DNS module. Skipping build."
else
  # Ensure Go is installed (needed to build xcaddy)
  if ! command -v go &> /dev/null; then
    echo "Go is not installed. Installing golang-go..."
    apt-get update
    apt-get install -y golang-go
  fi

  # Build custom Caddy with Cloudflare DNS module
  echo "Building Caddy with Cloudflare DNS module using xcaddy..."
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"
  go run github.com/caddyserver/xcaddy/cmd/xcaddy@latest build --with github.com/caddy-dns/cloudflare

  # Replace standard caddy binary with custom one
  echo "Stopping Caddy service..."
  systemctl stop caddy || true

  echo "Installing custom Caddy binary to /usr/bin..."
  mv caddy /usr/bin/caddy
  chmod +x /usr/bin/caddy

  # Prevent apt from overwriting our custom binary on updates
  echo "Marking caddy package as held..."
  apt-mark hold caddy

  # Clean up temp directory
  cd - > /dev/null
  rm -rf "$TMP_DIR"
fi

# Configure systemd override to load the environment file
echo "Configuring systemd override for Caddy environment variables..."
mkdir -p /etc/systemd/system/caddy.service.d
cat <<EOF > /etc/systemd/system/caddy.service.d/override.conf
[Service]
EnvironmentFile=/etc/caddy/.env
EOF

# Enable and restart Caddy service
echo "Starting Caddy service..."
systemctl daemon-reload
systemctl enable --now caddy
systemctl restart caddy

echo "Caddy setup complete!"
