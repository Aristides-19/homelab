#!/bin/bash

TARGET_TAILNET_IP="0.0.0.0"
KUMA_URL="https://uptime.change.me/api/push/UPTIME_TAILSCALE"

PING_MS=$(ping -c 3 -W 2 "$TARGET_TAILNET_IP" | grep 'time=' | tail -n 1 | awk -F'time=' '{print $2}' | cut -d' ' -f1)

if [ -n "$PING_MS" ]; then
    curl -s "${KUMA_URL}?status=up&msg=OK&ping=${PING_MS}" > /dev/null
else
    curl -s "${KUMA_URL}?status=down&msg=Unreachable" > /dev/null
fi
