#!/bin/bash
source /opt/restic/.env

restic backup /targets/data/immich/library --no-scan --exclude "/targets/data/immich/library/thumbs" --exclude "/targets/data/immich/library/encoded-video" --tag immich && curl -s "$KUMA_IMMICH_URL"

restic backup /targets/personal/vaultwarden --no-scan \
--exclude "/targets/personal/vaultwarden/db.sqlite3" \
--exclude "/targets/personal/vaultwarden/db.sqlite3-shm" \
--exclude "/targets/personal/vaultwarden/db.sqlite3-wal" \
--exclude "/targets/personal/vaultwarden/icon_cache" \
--exclude "/targets/personal/vaultwarden/tmp" \
--exclude "/targets/personal/vaultwarden/sends" \
--tag vaultwarden && curl -s "$KUMA_VAULT_URL"

restic forget --keep-daily 7