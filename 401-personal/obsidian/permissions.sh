#!/bin/bash
# Obsidian configurations need read access for the bridge container user (deno 1993)
find /opt/homelab/401-personal/obsidian -type d -exec chmod 755 {} \;
find /opt/homelab/401-personal/obsidian -type f ! -name "*.sh" -exec chmod 644 {} \;
