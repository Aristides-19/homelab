---
name: caddy-route
description: Manages Caddy reverse proxy routes in Gateway LXC. Use when adding or modifying website routes or domain mappings.
---

## What I do

- Add, update, or remove Caddy reverse proxy routes in the homelab Gateway.
- Format Caddyfile layout.
- Validate Caddy configuration syntax.
- Reload Caddy service safely without downtime.

## Configuration File

- Host path: `/opt/homelab/100-gateway/caddy/Caddyfile`
- LXC path: `/etc/caddy/Caddyfile` (inside Gateway LXC 100)

## Workflow

1. **Edit Caddyfile**: Modify `/opt/homelab/100-gateway/caddy/Caddyfile` on the Proxmox host.
2. **Format Caddyfile**: Format the file layout. Run Proxmox host:
   `pct exec 100 -- caddy fmt --overwrite /etc/caddy/Caddyfile`
3. **Validate Configuration**: Verify configuration correctness before reload. Run Proxmox host:
   `pct exec 100 -- caddy validate --config /etc/caddy/Caddyfile`
4. **Reload Caddy**: Reload configuration without stopping the proxy. Run Proxmox host:
   `pct exec 100 -- systemctl reload caddy`
   (Alternative: `pct exec 100 -- caddy reload --config /etc/caddy/Caddyfile`)

## References

- **Templates**: See [TEMPLATES.md](TEMPLATES.md)
- **Quality Checklist**: See [CHECKLIST.md](CHECKLIST.md)
