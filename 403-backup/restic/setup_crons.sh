#!/bin/bash

echo "0 4 * * * root /bin/bash /opt/restic/backup.sh" | tee /etc/cron.d/restic-backup
chmod 644 /etc/cron.d/restic-backup

echo "0 6 14,28 * * root /bin/bash /opt/restic/prune.sh" | tee /etc/cron.d/restic-prune
chmod 644 /etc/cron.d/restic-prune