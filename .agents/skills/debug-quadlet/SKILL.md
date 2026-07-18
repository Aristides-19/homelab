---
name: debug-quadlet
description: Troubleshoots Podman Quadlet service failures inside unprivileged LXCs. Use when a containerized service fails to start, crash loops, or has network/permission issues.
---

## What I do

- Diagnose systemd unit startup failures.
- Check Podman pod and container run status.
- Troubleshoot volume permission denied issues.
- Inspect internal container port binding and network connectivity.

## Troubleshooting Workflow

### 1. Systemd Service Failure
If systemd service fails to start:
- Check service status:
  `pct exec [id] -- systemctl status [service-name]`
- View systemd journal logs:
  `pct exec [id] -- journalctl -u [service-name] -n 100 --no-pager`

### 2. Podman Container Failure
If systemd starts but containers crash or restart:
- List running/stopped pods:
  `pct exec [id] -- podman pod ps`
- List all container instances:
  `pct exec [id] -- podman ps -a`
- View container stdout/stderr logs:
  `pct exec [id] -- podman logs [container-name-or-id]`
- Check container resource usage:
  `pct exec [id] -- podman stats --no-stream`

### 3. Permission Denied / Mountpoint Issues
If container logs show database lock, write errors, or "Permission Denied":
- Check directory owners inside LXC:
  `pct exec [id] -- ls -la /opt/[service-name]` or `/data`
- Correct ownership from Proxmox host:
  Run `host/permissions.sh` on host to restore `100000:100000` ownership.

### 4. Network & Port Conflicts
If service is running but inaccessible:
- Check listening ports inside LXC:
  `pct exec [id] -- ss -tulpn`
- Verify container ports mapped in `pod.yaml` hostPort matches host LXC port.
- Test internal response:
  `pct exec [id] -- curl -I http://localhost:[port]`

## References

- **Checklist**: See [CHECKLIST.md](CHECKLIST.md)
