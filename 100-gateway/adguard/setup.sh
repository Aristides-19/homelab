#!/bin/bash

# Exit on error
set -e

# Change directory to the script's directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Load environment variables
if [ ! -f .env ]; then
  echo "Error: .env file not found!"
  echo "Please copy .env.sample to .env and configure ADGUARD_USER and ADGUARD_PASSWORD."
  exit 1
fi

# Load variables
export $(grep -v '^#' .env | xargs)

if [ -z "$ADGUARD_USER" ] || [ -z "$ADGUARD_PASSWORD" ]; then
  echo "Error: ADGUARD_USER or ADGUARD_PASSWORD is not set in .env."
  exit 1
fi

# Install AdGuard Home if not installed
if ! command -v AdGuardHome &> /dev/null && [ ! -f /opt/AdGuardHome/AdGuardHome ]; then
  echo "AdGuard Home is not installed. Installing..."
  curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh
else
  echo "AdGuard Home is already installed."
fi

# Ensure service is enabled and started
echo "Ensuring AdGuardHome service is running..."
systemctl enable --now AdGuardHome

# Wait for AdGuard Home to start listening
echo "Waiting for AdGuard Home to start..."
sleep 3

# Complete the initial installation wizard if needed
# By default, the wizard listens on port 3000
if curl -s --connect-timeout 2 http://127.0.0.1:3000/ > /dev/null; then
  echo "AdGuard Home initial wizard detected on port 3000. Automating configuration..."
  
  JSON_PAYLOAD=$(cat <<EOF
{
  "web": {
    "ip": "0.0.0.0",
    "port": 8080
  },
  "dns": {
    "ip": "0.0.0.0",
    "port": 53
  },
  "username": "$ADGUARD_USER",
  "password": "$ADGUARD_PASSWORD"
}
EOF
)

  curl -s -X POST "http://127.0.0.1:3000/control/install/configure" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD"
  
  echo "Initial configuration submitted. Waiting for AdGuard Home to restart on port 8080..."
  sleep 5
else
  echo "AdGuard Home initial wizard not running on port 3000 (likely already configured)."
fi

# Apply settings via the API on port 8080
echo "Applying post-install settings (Upstream DNS, Rate Limit Whitelist & Cache Configuration)..."
DNS_PAYLOAD='{"upstream_dns":["https://cloudflare-dns.com/dns-query"],"ratelimit_whitelist":["10.0.2.0","10.0.0.1","127.0.0.1"],"cache_size":4194304,"cache_ttl_min":3600,"cache_ttl_max":0,"cache_enabled":true,"cache_optimistic":true}'

STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -u "$ADGUARD_USER:$ADGUARD_PASSWORD" \
  -X POST "http://127.0.0.1:8080/control/dns_config" \
  -H "Content-Type: application/json" \
  -d "$DNS_PAYLOAD")

if [ "$STATUS_CODE" -eq 200 ]; then
  echo "DNS settings (Upstream, Whitelist, and Cache) successfully applied."
else
  echo "Warning: Failed to set upstream DNS (HTTP Status: $STATUS_CODE)."
fi

# Helper function to add DNS rewrite
add_rewrite() {
  local domain=$1
  local ip=$2
  if [ -n "$domain" ] && [ -n "$ip" ]; then
    # Check if the rewrite already exists in the pre-fetched list
    if echo "$EXISTING_REWRITES" | grep -F -q "\"domain\":\"$domain\""; then
      echo "  DNS Rewrite for $domain already exists. Skipping."
      return 0
    fi

    echo "Adding DNS Rewrite: $domain -> $ip"
    local payload="{\"domain\":\"$domain\",\"answer\":\"$ip\"}"
    local status=$(curl -s -o /dev/null -w "%{http_code}" -u "$ADGUARD_USER:$ADGUARD_PASSWORD" \
      -X POST "http://127.0.0.1:8080/control/rewrite/add" \
      -H "Content-Type: application/json" \
      -d "$payload")
    if [ "$status" -eq 200 ]; then
      echo "  DNS Rewrite successfully added."
    else
      echo "  Warning: Failed to set DNS Rewrite (HTTP Status: $status)."
    fi
  fi
}

# Configure DNS Rewrites from Caddy and Tailscale configuration
echo "Configuring DNS Rewrites..."
# Pre-fetch existing rewrites to avoid duplicate API calls
EXISTING_REWRITES=$(curl -s -u "$ADGUARD_USER:$ADGUARD_PASSWORD" http://127.0.0.1:8080/control/rewrite/list || echo "[]")

CADDY_ENV="/etc/caddy/.env"
if [ -f "$CADDY_ENV" ]; then
  # Import all variables from Caddy's .env file
  export $(grep -v '^#' "$CADDY_ENV" | xargs)
  
  if [ -n "$DOMAIN" ] && [ -n "$IP_GATEWAY" ]; then
    # Wildcard Domain Rewrite
    add_rewrite "*.${DOMAIN}" "${IP_GATEWAY}"
    
    # Proxmox Host Rewrite
    add_rewrite "proxmox.host" "${IP_HOST}"
    
    # LXC Subdomains
    add_rewrite "gateway.lxc" "${IP_GATEWAY}"
    add_rewrite "data.lxc" "${IP_DATA}"
    add_rewrite "monitor.lxc" "${IP_MONITOR}"
    add_rewrite "media.lxc" "${IP_MEDIA}"
    add_rewrite "backup.lxc" "${IP_BACKUP}"
    add_rewrite "personal.lxc" "${IP_PERSONAL}"
    add_rewrite "home.lxc" "${IP_HOME}"
    
    # Tailscale googol rewrite
    add_rewrite "googol.ts" "${IP_GOOGOL}"
  else
    echo "Warning: DOMAIN or IP_GATEWAY not found in $CADDY_ENV."
  fi
else
  echo "Warning: Caddy .env not found at $CADDY_ENV."
fi

echo "AdGuard Home setup complete!"
