#!/bin/bash

podman exec vaultwarden-server /vaultwarden backup && mv /data/vaultwarden/db_*_*.sqlite3 /data/vaultwarden/backups/

find /data/vaultwarden/backups -name "db_*_*.sqlite3" -mtime +3 -delete
