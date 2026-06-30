# caddy-route Checklist

## Before Reload
- [ ] Added new route to `/opt/homelab/100-gateway/caddy/Caddyfile`.
- [ ] Pointed `reverse_proxy` target to correct internal `<lxc-hostname>.lxc:<port>` or `localhost:<port>`.
- [ ] If service requires upload capabilities, configured body max_size limit.
- [ ] If service restricted, imported `only_admin` snippet.

## Command Verification Order
- [ ] **First (Format)**: Run Caddy format command on Proxmox host:
  `pct exec 100 -- caddy fmt --overwrite /etc/caddy/Caddyfile`
- [ ] **Second (Validate)**: Validate syntax command on Proxmox host:
  `pct exec 100 -- caddy validate --config /etc/caddy/Caddyfile`
- [ ] **Third (Reload)**: Reload configuration on Proxmox host:
  `pct exec 100 -- systemctl reload caddy`

## Post Reload
- [ ] Verify Caddy service active status.
- [ ] Curl service subdomain: `curl -I https://<subdomain>.<your-domain>` or test in browser.
- [ ] Check Caddy logs if reload fails: `pct exec 100 -- journalctl -u caddy -n 50 --no-pager`.
