#!/bin/bash

# ==========================================
# OBSIDIAN CLIENT SETUP CONFIGURATION
# ==========================================
# Replace these values with actual CouchDB credentials and encryption keys
export hostname="https://obsidian-sync.change.me"
export database="obsidian-dev" # Client User
export username="CHANGE_ME" # COUCHDB_USER
export password="CHANGE_ME" # COUCHDB_PASSWORD
export passphrase="CHANGE_ME"  # End-to-End Encryption (E2EE) passphrase

echo "Generating Setup URI for Obsidian..."

# Check if Deno is installed locally on the system
if command -v deno &> /dev/null; then
    echo "Deno detected locally. Running script..."
    deno run -A https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/flyio/generate_setupuri.ts
else
    echo "Deno is not installed locally. Running via temporary Podman container..."
    podman run --rm -it \
        -e hostname="$hostname" \
        -e database="$database" \
        -e username="$username" \
        -e password="$password" \
        -e passphrase="$passphrase" \
        docker.io/denoland/deno:alpine run -A https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/flyio/generate_setupuri.ts
fi
