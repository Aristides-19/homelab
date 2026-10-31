#!/bin/bash
# Gateway container (100) runs bare-metal services as non-root users (caddy).
# They need read access to their configurations, so we set them to 755 for directories and 644 for files.
find /opt/homelab/100-gateway -type d -exec chmod 755 {} \;
find /opt/homelab/100-gateway -type f ! -name "*.sh" -exec chmod 644 {} \;
