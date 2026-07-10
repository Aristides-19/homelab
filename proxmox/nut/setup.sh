#!/bin/bash
# Script to apply NUT configurations from repo to /etc/nut

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root." >&2
  exit 1
fi

# Ensure /etc/nut directory exists
if [ ! -d "/etc/nut" ]; then
  echo "NUT does not seem to be installed. Installing nut package..."
  apt update && apt install -y nut nut-client nut-server
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Copying NUT configurations to /etc/nut/..."
cp "$SCRIPT_DIR/ups.conf" /etc/nut/ups.conf
cp "$SCRIPT_DIR/nut.conf" /etc/nut/nut.conf
cp "$SCRIPT_DIR/upsd.conf" /etc/nut/upsd.conf

# Handle credentials and monitor configuration (preserve existing or generate new)
if [ -f "/etc/nut/upsd.users" ] && grep -q "\[upsmon_user\]" /etc/nut/upsd.users; then
  PASSWORD=$(grep -A 2 "\[upsmon_user\]" /etc/nut/upsd.users | grep "password" | awk -F '=' '{print $2}' | xargs)
  echo "Preserving existing password for upsmon_user."
else
  PASSWORD=$(openssl rand -hex 16)
  echo "Generating new secure password for upsmon_user."
fi

sed "s/REPLACE_WITH_SECURE_PASSWORD/$PASSWORD/g" "$SCRIPT_DIR/upsd.users" > /etc/nut/upsd.users
sed "s/REPLACE_WITH_SECURE_PASSWORD/$PASSWORD/g" "$SCRIPT_DIR/upsmon.conf" > /etc/nut/upsmon.conf

# Set correct ownership and permissions
chown root:nut /etc/nut/ups.conf /etc/nut/nut.conf /etc/nut/upsd.conf /etc/nut/upsd.users /etc/nut/upsmon.conf
chmod 640 /etc/nut/ups.conf /etc/nut/nut.conf /etc/nut/upsd.conf /etc/nut/upsd.users /etc/nut/upsmon.conf

echo "Restarting services..."
systemctl restart nut-server
systemctl restart nut-monitor
systemctl enable nut-monitor

echo "Verification:"
if upsc cdp_ups >/dev/null 2>&1; then
  echo "SUCCESS: NUT is communicating with cdp_ups!"
  upsc cdp_ups | grep -E "battery.charge|ups.status|input.voltage"
else
  echo "WARNING: Could not connect to cdp_ups. Check physical connections or logs."
fi

echo "Status of services:"
systemctl status nut-server nut-monitor --no-pager

