# debug-quadlet Checklist

Use this checklist step-by-step to isolate and fix service failures.

## Step 1: Systemd Diagnostics
- [ ] Run `pct exec [id] -- systemctl status [service-name]`.
- [ ] If status is inactive/failed, inspect logs: `pct exec [id] -- journalctl -u [service-name] -e --no-pager`.
- [ ] Check if Quadlet file exists: `pct exec [id] -- ls -l /etc/containers/systemd/[service-name].kube`.
- [ ] Run `pct exec [id] -- systemctl daemon-reload` to make sure changes are loaded.

## Step 2: Podman Diagnostics
- [ ] Run `pct exec [id] -- podman pod ps`. Check pod status (should be `Running`).
- [ ] Run `pct exec [id] -- podman ps -a`. Inspect container exit codes.
- [ ] Retrieve logs: `pct exec [id] -- podman logs [container-name]`.
- [ ] Look for stack traces, missing environment variables, or config schema errors.

## Step 3: Permission Checks
- [ ] Inspect permissions of mounted directories: `pct exec [id] -- ls -la /opt/[service-name]`.
- [ ] If permissions are not `100000:100000` (or `root:root` where required), run `host/permissions.sh` on the Proxmox host.
- [ ] Verify that directories required by `pod.yaml` volumes exist on the host (e.g. `/data/<service-name>`).

## Step 4: Network Verification
- [ ] Run `pct exec [id] -- ss -tulpn`. Identify if target port is bound.
- [ ] Verify no port conflicts exist on the LXC host.
- [ ] Run `pct exec [id] -- curl -sSL http://localhost:[port]` to test local response.
- [ ] Check if Caddy reverse proxy matches the target LXC port.
