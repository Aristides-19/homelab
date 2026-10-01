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

# Copy Caddyfile to Caddy config directory
cp -f "$(dirname "$0")/Caddyfile" /etc/caddy/Caddyfile

# Copy .env file if it exists
if [ -f "$(dirname "$0")/.env" ]; then
  cp -f "$(dirname "$0")/.env" /etc/caddy/.env
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
