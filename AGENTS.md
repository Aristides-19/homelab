# AGENTS.md

## Repository Structure
- Proxmox homelab configuration, services management.
- Host-level service definition, LXC container settings, networking.

## Proxmox Config
- Directory `proxmox/config/` holds LXC configurations `[id].conf`.
- Configuration files NOT symlinks.
- ALWAYS update manually running `update.sh` AFTER edit original Proxmox `/etc/pve/lxc/[id].conf` configuration.

## LXC Folders
- Folders named `[id]-[hostname]` (example: `100-gateway` matches `100.conf` hostname `gateway`).
- Service folders exist inside LXC folder.

## Service Folder Structure
- Containers run using Podman Quadlets.
- Files inside container service folder:
  - `pod.yaml`: Podman pod definition Kubernetes syntax.
  - `pod.kube`: Systemd Quadlet file.
  - `env.sample.yaml`: Template environment variables (if applicable).
  - `setup.sh`: Script copy `pod.kube` systemd directory `/etc/containers/systemd/` trigger systemd auto-start.
- Bare-metal services (no containers) use custom scripts, config files.
- ASK USER permission before read `env.yaml` files. Equivalent to `.env` secrets.

## Mountpoints
- Each service directory mounted from Proxmox host inside corresponding LXC.
- Enables Proxmox host modify configs, immediately reflected inside LXC, vice versa.
- ALWAYS run `proxmox/permissions.sh` Proxmox host after edit/add files. Restores ownership (`100000:100000`) for unprivileged LXCs.

## Internal Network & Gateway
- LXC `100-gateway` acts as subnet router.
- Gateway interfaces:
  - `eth0` on bridge `vmbr0` (external network, IP `192.168.0.3/24`, gateway `192.168.0.1`).
  - `eth1` on bridge `vmbr1` (internal network, IP `10.0.0.1/16`).
- Internal LXCs use `vmbr1` (subnet `10.0.0.0/16`), gateway IP set `10.0.0.1`.
- Gateway forwards traffic internal network external network using IP forwarding (`net.ipv4.ip_forward=1`), NAT masquerade (`iptables -t nat -A POSTROUTING -s 10.0.0.0/16 -o eth0 -j MASQUERADE`).
- Gateway hosts bare-metal services: Caddy (reverse proxy), Tailscale (VPN), Cloudflare Tunnel, AdGuardHome (ad-blocking DNS).

## Command Execution
- Run commands inside LXC from Proxmox host using `pct exec [id] -- [command]` (example: `pct exec 101 -- systemctl status karakeep`).

## Available Agent Skills
| Skill                                                              | Description                                                  |
| ------------------------------------------------------------------ | ------------------------------------------------------------ |
| [authoring-skills](.agents/skills/authoring-skills/SKILL.md)       | Guides the creation, formatting, and refinement of Skills.   |
| [caddy-route](.agents/skills/caddy-route/SKILL.md)                 | Manages Caddy reverse proxy routes in Gateway LXC.           |
| [caveman-compression](.agents/skills/caveman-compression/SKILL.md) | Aggressively removes stop words and grammatical scaffolding. |
| [debug-quadlet](.agents/skills/debug-quadlet/SKILL.md)             | Troubleshoots Podman Quadlet service failures inside LXCs.   |
| [deploy-quadlet](.agents/skills/deploy-quadlet/SKILL.md)           | Guides creation and deployment of Podman Quadlet services.   |
