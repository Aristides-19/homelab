#!/bin/bash

# Adjust owners and permissions for security and compatibility with unprivileged LXC
chown -R 100000:100000 /opt/homelab

# Root folder to root:root (755)
chown root:root /opt/homelab
chmod 755 /opt/homelab

# Proxmox control folder to root:root (700)
chown -R root:root /opt/homelab/proxmox
chmod 700 /opt/homelab/proxmox
chmod 700 /opt/homelab/proxmox/*.sh

# Remove "other" permissions for all configurations
chmod -R o-rwx /opt/homelab/*

# Note that exec implies entering for folders
# Ensure 770 (read/write/exec) permissions for service directories and 660 (read/write, no exec) for files (excluding scripts)
find /opt/homelab -type d ! -path "/opt/homelab" ! -path "/opt/homelab/proxmox" ! -path "/opt/homelab/proxmox/*" -exec chmod 770 {} \;
find /opt/homelab -type f ! -path "/opt/homelab/proxmox/*" ! -name "*.sh" -exec chmod 660 {} \;

# Find and execute local permission scripts in service directories
find /opt/homelab -maxdepth 3 -name "permissions.sh" ! -path "/opt/homelab/proxmox/*" -exec bash {} \;


# Adjust permissions for top-level mount points in /mnt (non-recursive to protect database ownerships)
chown 100000:100000 /mnt/*
chmod 770 /mnt/*
