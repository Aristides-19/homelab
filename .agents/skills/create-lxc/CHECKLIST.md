# New LXC Checklist

Tick every line before reporting done.

## Container

- [ ] Id and IP unused (`pct list`, `grep -h "^net0" host/config/*.conf`)
- [ ] Created `unprivileged`, `nesting=1`, `onboot=1`, on `vmbr1`, gw `10.0.0.1`
- [ ] `--startup order=8,up=15` (sandbox) or justified otherwise
- [ ] `lxc_setup.sh` run, **`y`** answered to the Podman prompt
- [ ] `hostname` inside returns the expected name

## Mounts

- [ ] `mp0` → `/mnt/<hostname>` at `/data`
- [ ] Service dir at `/opt/<service>`
- [ ] `dozzle-agent` mounted
- [ ] `./host/permissions.sh` run
- [ ] `pct reboot <id>` done **after** adding mounts
- [ ] `findmnt -no SOURCE,FSTYPE /data` shows the bind

## Repo

- [ ] `./host/config/update.sh` run
- [ ] `host/config/<id>.conf` present and matching live config
- [ ] Folder `<id>-<hostname>/` created

## DNS

- [ ] `IP_<HOSTNAME>` (hostname uppercased) in `100-gateway/caddy/.env`
- [ ] `IP_<HOSTNAME>` in `100-gateway/caddy/.env.sample`
- [ ] `add_rewrite "<hostname>.lxc"` in `100-gateway/adguard/setup.sh`
- [ ] `setup.sh` **executed**, not only edited
- [ ] `getent hosts <hostname>.lxc` resolves

## SSH

- [ ] `Host <hostname>-lxc` block in `ssh/config`, with `ProxyJump gateway-lxc`
- [ ] Key named `<Hostname>` agreed with the user
- [ ] User ran `./ssh/export_bw_keys.sh`
- [ ] `ssh <hostname>-lxc 'hostname'` works

## Route

- [ ] Caddy route added via `caddy-route`
- [ ] Caddy **restarted** (not reloaded) after any `.env` change
- [ ] Reaches the service over HTTPS
