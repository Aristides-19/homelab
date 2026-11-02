#!/bin/bash
# /data/opengym is a host bind mount used by the api container (runs as root, writes
# db.json, state-<uid>.json, secret, uploads/). It must stay owned by the LXC's mapped
# root (100000:100000) and world-readable/traversable: the unprivileged LXC maps
# container-root to 100000, and a directory owned by unmapped root (0:0, i.e. nobody
# from inside) rejects every write with EACCES even for container root.
DATA=/mnt/personal/opengym

# Only fix the owner when it is wrong, i.e. skip on every normal run. An unmapped
# owner shows up as 65534 in /proc, which is invisible from the host, so a plain
# `chown -R` is what self-heals a directory created on the host side by accident.
if [ "$(stat -c %u "$DATA")" != "100000" ]; then
  chown -R 100000:100000 "$DATA"
fi

# Traversable directories, no write for group/other, files readable but not executable.
find "$DATA" -type d -exec chmod 755 {} \;
find "$DATA" -type f -exec chmod u+rw,go+r {} \;
