---
name: create-lxc
description: Creates and configures a new unprivileged LXC container on the Proxmox host, wired into the internal network, DNS, SSH and reverse proxy. Use when adding a new container or service host to the homelab.
---

## Naming

| Thing | Rule | Example |
| --- | --- | --- |
| Container id | Next free in the block (`1xx` infra, `2xx` media/monitor, `4xx` personal) | `102` |
| Hostname | From the user | `dev` |
| Repo folder | `<id>-<hostname>` | `102-dev` |
| DNS | `<hostname>.lxc` | `dev.lxc` |
| SSH | `<hostname>-lxc` | `dev-lxc` |
| Public route | Service subdomain | `sc.<DOMAIN>` |

Name containers after their hostname, **never after a service they host**.
`102-dev` runs `sc`: DNS is `dev.lxc`, not `sc.lxc`.

## Steps

1. **Free id and IP.** `pct list`, then `grep -h "^net0" host/config/*.conf`.

   The address derives from the container id: `10.0.<id / 100>.<id % 100>`. `206` → `10.0.2.6`, `418` → `10.0.4.18`. The `4xx` block pins the third octet to `4` so it does not collide with `1xx` (`401` → `10.0.4.1`, not `10.0.1.1`). Verify the result is unused before creating.

2. **Create.**

```bash
pct create <id> local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst \
  --hostname <hostname> --ostype debian --arch amd64 \
  --cores 2 --memory 2048 --swap 2048 --rootfs local:8 \
  --unprivileged 1 --features nesting=1 --onboot 1 \
  --net0 name=eth0,bridge=vmbr1,gw=10.0.0.1,ip=10.0.<id / 100>.<id % 100>/16 \
  --startup order=8,up=15 --tags <tag>
```

`local:8` = 8G. Startup orders: `1` gateway, `2` home, `3` data, `4` media, `5` personal, `6` backup, `7` monitor, `8` dev. Only the gateway uses `up=0`.

Add only when needed: `dev0: /dev/dri` (transcode), `firewall=1` (external iface), `cgroup2.devices.allow` + `/dev/net/tun` (Tailscale).

3. **Mounts.** `mp0: /mnt/<hostname>`→`/data`, `mp1: /opt/homelab/<id>-<hostname>/<service>`→`/opt/<service>`, `dozzle-agent`→`/opt/dozzle-agent`. Gaps in `mpN` are harmless.

4. **Start + base setup. Answer `y` to the Podman prompt if necessary.**

```bash
pct start <id>
pct exec <id> -- bash < host/lxc_setup.sh
```

5. **Ownership, then reboot.** The reboot is required after adding mounts.

```bash
./host/permissions.sh
pct reboot <id>
pct exec <id> -- findmnt -no SOURCE,FSTYPE /data
```

6. **Sync config.** `./host/config/update.sh`. Never edit `host/config/` by hand.

7. **DNS.** The variable is the hostname uppercased, prefixed `IP_`: hostname `dev` → `IP_DEV` (`data` → `IP_DATA`, `media` → `IP_MEDIA`). Write `IP_DEV=<ip>` in `100-gateway/caddy/.env` and `.env.sample` — `setup.sh` reads them from `/etc/caddy/.env`, not `adguard/.env`. Then `add_rewrite "dev.lxc" "${IP_DEV}"` in `100-gateway/adguard/setup.sh`, and **run it**:

```bash
pct exec 100 -- bash /opt/adguard/setup.sh
pct exec <id> -- getent hosts <hostname>.lxc
```

8. **SSH.** Append to `ssh/config`:

```
Host <hostname>-lxc
    HostName <hostname>.lxc
    User root
    Port 22
    ProxyJump gateway-lxc
    IdentityFile ~/.ssh/<Hostname>.pub
    IdentitiesOnly yes
```

9. **Ask the user for the key.** It lives in their Bitwarden vault; the agent cannot create it:

> Add an SSH key in Bitwarden named `<Hostname>`, unlock the agent, run `./ssh/export_bw_keys.sh`.

Verify: `ssh <hostname>-lxc 'hostname'`

10. **Route, only if the container is publicly proxied.** Skip for containers that are not (e.g. backup). The `IP_*` variable from step 7 is already in `100-gateway/caddy/.env`; add the route with the `caddy-route` skill.

   `systemctl reload caddy` does not re-read `EnvironmentFile`. After any `.env` change, restart it:

```bash
pct exec 100 -- systemctl restart caddy
```

11. **Document.** One English line in `README.md` → **Active Services**:

```
- **<id>-<hostname>:** <Purpose> (`<subdomain>.<DOMAIN>`).
```

Track progress with [CHECKLIST.md](CHECKLIST.md). The service itself is `deploy-quadlet`.

## Pitfalls

| Symptom | Cause |
| --- | --- |
| Mount empty / stub dir | Container not rebooted after adding it |
| Files unreadable in container | `permissions.sh` not run |
| `<hostname>.lxc` unresolved | `setup.sh` edited but not executed |
| `ssh` works by IP only | `ssh/config` block missing |
| Wrong DNS name | Container named after its service |

## References

- **Templates**: See [TEMPLATES.md](TEMPLATES.md)
- **Quality Checklist**: See [CHECKLIST.md](CHECKLIST.md)
