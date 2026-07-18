# deploy-quadlet Checklist

## Before Deploying
- [ ] Service folder created: `/opt/homelab/[id]-[hostname]/[service-name]/`.
- [ ] Files exist: `pod.yaml`, `pod.kube`, `env.sample.yaml`, `setup.sh`.
- [ ] Secrets/sensitive data NOT in template. Put secrets ONLY in gitignored `env.yaml`.
- [ ] Proxmox host `/etc/pve/lxc/[id].conf` has mountpoint mapping host directory `/opt/[service-name]`.
- [ ] For important data/dbs: verify mountpoint `mp[N]` map host `/mnt/[hostname]` to `/data` in LXC.
- [ ] Config copy synced: run `host/config/update.sh` on Proxmox host.
- [ ] Permissions fixed: run `host/permissions.sh` Proxmox host. Checks ownership (`100000:100000`).

## During Deployment
- [ ] Run commands inside LXC using Proxmox host `pct exec [id] -- [command]`.
- [ ] Create `env.yaml` inside `/opt/[service-name]/` using `env.sample.yaml` schema. Fill actual secrets.
- [ ] Run `setup.sh` inside LXC.
- [ ] Run `systemctl start [service-name]`.

## Post Deployment
- [ ] Check systemd status: `systemctl status [service-name]`. Verify active (running).
- [ ] Check Podman pods: `podman pod ps` and `podman ps`. Verify all container instances running.
- [ ] Test connectivity service port from within private network.
