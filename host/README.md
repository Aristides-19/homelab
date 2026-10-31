# Host Scripts

Scripts run **on the Proxmox host** as `root`, unless noted otherwise.

## Setup
| Script | Purpose |
| --- | --- |
| `setup.sh` | First-time host bootstrap: `apt upgrade`, IP forwarding sysctl, Tailscale route via gateway, then `permissions.sh`. |
| `lxc_setup.sh` | Creates/base-configures an LXC container. |
| `permissions.sh` | Restores ownership (`100000:100000`) and modes for unprivileged LXCs. Run after editing/adding files. |

## Maintenance
| Script | Purpose |
| --- | --- |
| `update_all.sh` | Updates packages across host and containers. Follow it with `cleanup_host.sh` to drop the kernels and cache the upgrade left behind. |
| `update_images.sh` | On-demand refresh of service container images. Removes the previous image once the unit is back active, so a failed restart stays rollback-able. |
| `prune_images.sh` | Removes **dangling** Podman images (`<none>:<none>`) inside LXCs. Tagged and in-use images are never touched. Supports `-n` and an LXC id list. |
| `cleanup_host.sh` | Reclaims host disk from unbounded growth: apt cache, orphaned kernels, systemd journal. Supports `-n` and per-step selection. |

Both cleanup scripts accept `-n` / `--dry-run` to report without changing anything — run that first if unsure.

```bash
./prune_images.sh -n          # report dangling images in every running LXC
./prune_images.sh 200 401     # only these LXCs

./cleanup_host.sh -n          # report everything
./cleanup_host.sh --journal   # only vacuum the journal
```

### Disk growth the host does not cap by default
- **Podman images**: each pull leaves the previous tag behind. `prune_images.sh` handles dangling ones; superseded *tagged* images (e.g. an old `dozzle:v10` after moving to `v11`) must be removed manually with `podman rmi`.
- **systemd journal**: without `SystemMaxUse` journald may consume 10% of the disk. This host caps it in `/etc/systemd/journald.conf.d/99-limits.conf` (`SystemMaxUse=500M`, `MaxRetentionSec=1month`). `cleanup_host.sh --journal` enforces it on demand.
- **apt cache and old kernels**: `cleanup_host.sh` clears the cache and removes kernels left behind by upgrades, always keeping the running kernel.

## Misc
| Script | Purpose |
| --- | --- |
| `kiosk.sh` | Launches the kiosk session (user `kiosk`). |
| `caddy` | Wrapper that delegates `caddy` calls to the gateway LXC (100), for local config formatting. |
