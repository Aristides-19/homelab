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

## Variables: sample vs live `env.yaml`

The live `env.yaml` is gitignored; `env.sample.yaml` is committed. They are two different audiences.

- **`env.sample.yaml` NEVER contains real infrastructure values.** No real domain, hostname, IP, mailbox or account id. Use the `example.com` / `change.me` / `192.168.1.20` style placeholders — the repo is public and a sample is a template, not this deployment's exported config. Copy the sample to `env.yaml`, then substitute the real values ONLY there.
- **Never put the real domain in a sample "just to save a step".** It leaks the host, and it silently becomes the default for anyone reusing the file. Put it in `env.yaml`.
- **Anything that is configuration belongs in `env.yaml` only.** Do NOT restate `PORT`, `DATA_DIR`, `BACKEND`, URL/origin, limits, etc. in `pod.yaml`'s `env:` block when the pod already uses `envFrom: configMapRef`. An explicit `env:` entry WINS over the ConfigMap, so the `env.yaml` value becomes dead and edits to it do nothing — two sources of truth that diverge silently. Keep `pod.yaml` for structure only (image, ports, mounts, resources) and let one ConfigMap be the single source.
- Contact/identity fields (`VAPID_SUBJECT`, mail from-addresses, admin e-mails) are **either real or absent — never invented**. Never derive one from the domain (`admin@<domain>`) on the assumption it exists: check for an MX record first (`dig +short MX <domain>`), and if there is none, that mailbox reaches nobody. A made-up address is worse than an unset variable, because it looks configured.
- **Prefer omitting an optional variable over guessing.** Read the app's fallback in code before filling it in. Example: `VAPID_SUBJECT` unset makes the API use its `ORIGIN`, which is valid for the protocol and an honest identifier for the instance; a `mailto:` is only worth setting for a mailbox that exists.
- When a bulk `sed` rewrites a real domain into a file, re-read neighbouring values afterwards: placeholders sitting next to the substituted one get overwritten or silently turned into claims about infrastructure.

## Unprivileged LXC: host-created directories are unreachable

A subdirectory created **on the Proxmox host** under a parent owned by `100000:100000` (e.g. `/mnt/personal/<svc>`) is born `root:root 755`. Inside the unprivileged LXC it appears as `65534:nogroup` (unmapped uid), so **even container root gets `EACCES`** when writing — the app starts and then fails on its first write. Creating the same directory from *inside* the LXC works, which is the tell.

- Create data dirs either from inside the LXC, or run `host/permissions.sh` / the service's own `permissions.sh` after creating them from the host.
- Fix the owner only when it is wrong (`[ "$(stat -c %u "$DATA")" != "100000" ]`), so a normal run does not recursively chown live databases.
- Verify from inside: `pct exec [id] -- bash -c 'touch /data/<svc>/probe && rm /data/<svc>/probe'`.

The same mapping means a file created on the host with mode `600` is unreadable from the LXC, while one created at `644`+ is readable but never writable. If the service needs to write, its directory must exist with correct ownership **before** first start.

## Podman `kube play`: healthcheck and probe traps

- `healthcheck: test: ["NONE"]` in a kube YAML is **ignored** by `podman kube play`. An image `HEALTHCHECK` (often `CMD-SHELL curl ...`) cannot be cleared this way, and images frequently ship no `curl` → permanently `unhealthy`.
- A failing `readinessProbe` marks the container unhealthy and then podman's kube path **stops and recreates the container on every probe interval** (observed: every ~4 min, each a SIGKILL after the 10 s SIGTERM timeout when the app ignores SIGTERM). A `livenessProbe` alone does not restart anything from an unhealthy state.
- Therefore: **declare no probes** for such images and check health from outside (`pct exec [id] -- curl -s http://127.0.0.1:<hostPort>/...`), relying on systemd `Restart=on-failure` for real exits. Document the check command in `pod.yaml`.
- A probe using `host: localhost`/`127.0.0.1` targets the **pod's infra container**, not the app container, so it cannot work when each container binds its own loopback. Omit `host` (or use the pod address) if probes are ever reinstated.

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

