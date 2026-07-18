---
name: deploy-quadlet
description: Guides creation and deployment of Podman Quadlet services in unprivileged LXCs. Use when adding or modifying containerized services.
---

## What I do

- Deploy containerized services using Podman Quadlets.
- Configure host mountpoints, sync configs, restore unprivileged LXC permissions.
- Setup Quadlet systemd service inside LXC.

## Directory Structure

Service directory `/opt/homelab/[id]-[hostname]/[service-name]/` MUST contain:
- `pod.yaml`: Podman pod definition using Kubernetes syntax.
- `pod.kube`: Systemd Quadlet config pointing `pod.yaml`.
- `env.sample.yaml`: Template environment variables (no secrets).
- `setup.sh`: Script copying `pod.kube` path `/etc/containers/systemd/` trigger systemd auto-start.

## Volumes & Mountpoints

- Important data/databases MUST store host `/mnt/[hostname]/` (example: `/mnt/data/`) and mount `/data/` inside LXC.
- Non-essential volumes (e.g., uptime-kuma) can stay inside LXC (no Proxmox host `/mnt/` mount needed).

## Workflow

1. **Create Directory**: Setup service folder, files (`pod.yaml`, `pod.kube`, `env.sample.yaml`, `setup.sh`).
2. **Mountpoint**: Edit `/etc/pve/lxc/[id].conf` Proxmox host. Map host service folder LXC path (e.g. `mp0: /opt/homelab/101-data/karakeep,mp=/opt/karakeep`).
3. **Sync Config**: Run `host/config/update.sh` on host to copy host configs repo.
4. **Permissions**: Run `host/permissions.sh` Proxmox host. Fixes unprivileged LXC ownership (`100000:100000`).
5. **Start Service**: Access LXC. Execute service `setup.sh`. Run `systemctl daemon-reload && systemctl start [service-name]`.

## References

- **Templates**: See [TEMPLATES.md](TEMPLATES.md)
- **Quality Checklist**: See [CHECKLIST.md](CHECKLIST.md)

