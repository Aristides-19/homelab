#!/bin/bash

echo "0 2 * * * root /bin/bash /opt/vaultwarden/crons/backup.sh" | tee /etc/cron.d/vaultwarden-backup
chmod 644 /etc/cron.d/vaultwarden-backup