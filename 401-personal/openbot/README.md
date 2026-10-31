# OpenBot

Self-hosted OpenBot server in LXC 401 (personal), per
<https://github.com/nightly-labs/openbot/blob/main/docs/docker.md>.

## Why there is an `openbot.conf`

OpenBot needs three settings that a Quadlet `.kube` unit cannot express, because
`podman kube play` has no flag for them and Kubernetes has no field for them:

| Setting | Value | Why |
| --- | --- | --- |
| `seccomp_profile` | `seccomp.json` | The Electron sandbox makes user namespaces. The default profile refuses them. |
| `shm_size` | `1g` | Chromium uses shared memory. The default of 64 MB is too small. |
| `stop_timeout` | `60` | OpenBot stops its agents and closes its database before it exits. |

`stop_timeout` is a libpod engine setting, so it goes in `[engine]`; the other two
go in `[containers]`. The module is loaded with `ContainersConfModule=` in
`pod.kube`, so it applies to this pod only and not to vaultwarden, tududi,
it-tools or obsidian.

Verified, not assumed:

- `podman inspect` shows `ShmSize: 1000000000` and `StopTimeout: 60`.
- The custom seccomp profile is active: `vmsplice` (allowed by `seccomp.json`,
  denied by the Podman default profile) is `ALLOWED` in the container and
  `DENIED` with the default profile on the same image.

An `emptyDir medium: Memory` mounted on `/dev/shm` does **not** set the size:
Podman mounts its own tmpfs there. A pod that declares one still reports the
default. Do not use it for this.

## Limits

`resources.limits.memory: 2Gi` makes OpenBot read the real ceiling: `openbot
status` reports `Memory: ... of 2048 MiB` and `Turns at the same time: at most 2`.
Idle use is about 350 MB. Do not raise the limit without raising the LXC memory:
the turn count follows the ceiling, and more turns than the LXC can hold end in
an OOM kill that also takes vaultwarden.

## Network

The pod uses the default podman bridge and opens no port. OpenBot only connects
out: to the account server, the providers, and Signal and TURN. The desktop app,
the phone app and `openbot.run/app` reach it through WebRTC. This is not an HTTP
service, so Caddy has no route for it.

The LXC has no LAN-reachable address: `192.168.0.0/24` does not route to
`10.0.0.0/16`, and the gateway NATs it. A device in the tailnet reaches the host
directly. A device on the plain LAN falls back to the coturn relay or to NAT
hairpin. Enabling `privateNetwork` would remove the relay and leave those devices
with no path, so leave it off.

## Sign in

```sh
pct exec 401 -- podman exec openbot-openbot openbot login
pct exec 401 -- podman exec openbot-openbot openbot mobile-connect   # phone app
```
