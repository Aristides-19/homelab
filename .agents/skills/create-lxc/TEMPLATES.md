# create-lxc Templates

`<id>` container id · `<hostname>` container name · `<Hostname>` capitalised hostname (`dev` → `Dev`) · `<ip>` `10.0.<id / 100>.<id % 100>` (`206` → `10.0.2.6`) · `<tag>` purpose tag

## `pct create`

```bash
pct create <id> local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst \
  --hostname <hostname> --ostype debian --arch amd64 \
  --cores 2 --memory 2048 --swap 2048 --rootfs local:8 \
  --unprivileged 1 --features nesting=1 --onboot 1 \
  --net0 name=eth0,bridge=vmbr1,gw=10.0.0.1,ip=<ip>/16 \
  --startup order=8,up=15 --tags <tag>
```

## `host/config/<id>.conf`

Produced by `pct create`, synced into the repo by `./host/config/update.sh`.

```ini
arch: amd64
cores: 2
features: nesting=1
hostname: <hostname>
memory: 2048
mp0: /mnt/<hostname>,mp=/data
mp1: /opt/homelab/<id>-<hostname>/<service>,mp=/opt/<service>
mp2: /opt/homelab/200-monitor/dozzle-agent,mp=/opt/dozzle-agent
net0: name=eth0,bridge=vmbr1,gw=10.0.0.1,hwaddr=<assigned>,ip=<ip>/16,type=veth
onboot: 1
ostype: debian
rootfs: local:<id>/vm-<id>-disk-0.raw,size=8G
startup: order=8,up=15
swap: 2048
tags: <tag>
unprivileged: 1
```

## AdGuard rewrite

`IP_<HOSTNAME>` is the hostname uppercased: `dev` → `IP_DEV`.

In `100-gateway/adguard/setup.sh`, with the other LXC rewrites:

```bash
add_rewrite "<hostname>.lxc" "${IP_<HOSTNAME>}"
```

Its IP comes from `100-gateway/caddy/.env`, which `setup.sh` imports at runtime:

```bash
IP_<HOSTNAME>=<ip>
```

## `ssh/config`

```ini
Host <hostname>-lxc
    HostName <hostname>.lxc
    User root
    Port 22
    ProxyJump gateway-lxc
    IdentityFile ~/.ssh/<Hostname>.pub
    IdentitiesOnly yes
```

Omit `ProxyJump` for the gateway container only.

## `README.md` entry

```markdown
- **<id>-<hostname>:** <Purpose> (`<subdomain>.<DOMAIN>`).
```
