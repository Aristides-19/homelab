# hermes

Hermes Agent gateway plus a Chromium sidecar in a single Podman pod (`hermes`).

## Containers

| Name | Image | Purpose |
| --- | --- | --- |
| `hermes-gateway` | `docker.io/nousresearch/hermes-agent:v0.23.4` | Agent gateway. Port `9119` (Webapp + session API). |
| `hermes-chromium` | `lscr.io/linuxserver/chromium:075b0b99-ls64` | Real desktop Chromium on a Wayland compositor. Port `3002` → `3000` (Selkies). |

Both containers share the pod network namespace, which is the whole point:

| Consumer | Endpoint | Notes |
| --- | --- | --- |
| You (human) | `https://browser.<DOMAIN>` | Selkies streams the desktop over WebRTC. Caddy route uses `only_admin`. |
| Hermes (agent) | `http://127.0.0.1:9222` | Chrome DevTools Protocol, loopback inside the pod. Never published. |

Hermes attaches via `browser.cdp_url` in `~/.hermes/config.yaml`. That setting takes
precedence over any cloud provider and over the local engine, so **Hermes never launches
its own browser** and never touches the profile. The `hermes-chromium` container is the
single owner of `/config/chrome-profile`.

## Webapp (v0.23.4 migration)

Before v0.23.4 the pod ran two Hermes processes: the gateway (`8642` API server) and a
separate `hermes dashboard` on `9119`. Chats opened in the dashboard ran in that second
process, not in the gateway.

Since v0.23.4 the gateway serves the **Webapp** at `9119` itself, so there is a single
Hermes process and every chat runs in the gateway. Configured in `config.yaml`:

```yaml
webapp:
  enabled: true
  host: 0.0.0.0   # required in a container; loopback is unreachable via hostPort
  port: 9119      # unchanged, so https://hermes.<DOMAIN> and its Caddy route still work
```

The **OpenAI-compatible API server (`8642`) was removed**: it was a separate platform
adapter with no clients. Its `hostPort`, its `API_SERVER_*` variables and the Caddy
`/gateway*` route are gone. The Desktop never used it — native clients (CLI, TUI,
Desktop) connect over the gateway's session listener on `9119`.

Sign-in is unchanged: `HERMES_DASHBOARD_BASIC_AUTH_*` still applies, because the Webapp
uses the dashboard's auth providers. A non-loopback `webapp.host` requires one and fails
closed without it.

`HERMES_DASHBOARD=1` was removed. The image's s6 `dashboard` slot stays declared but down,
so logout still shows `s6-supervise dashboard` — that is expected.

Rollback: `/data/hermes/backups/dev-pre-migration-*.tar.gz` holds the pre-migration home
(`config.yaml.bak-migration` sits beside it).

## Mounts

| Volume | Container path | Host path |
| --- | --- | --- |
| `home` | `/home/hermes/.hermes` | `/data/hermes/dev` (`/mnt/personal/hermes/dev`) |
| `browser` | `/config` | `/data/hermes/browser` (`/mnt/personal/hermes/browser`) |

The Chromium profile, cookies and logins live in `/data/hermes/browser/chrome-profile`, so
they survive container restarts, image updates and LXC reboots.

## Chromium watchdog

`labwc` autostarts Chromium; it is the compositor's only client. Closing the window used to
leave Selkies streaming an empty desktop (black screen) **and** kill the CDP endpoint on
`9222`, breaking the agent's browser with no visible cause.

`labwc/autostart` wraps it in a relaunch loop (2s backoff). It is installed into
`/data/hermes/browser/.config/labwc/autostart` by `setup.sh`. Consequence: the window cannot
stay closed — closing it reopens it. That is deliberate, because Hermes depends on it.

## Operations

Relaunch Chromium without disturbing the pod:

```bash
pct exec 401 -- podman restart hermes-chromium
```

Restart the whole pod:

```bash
pct exec 401 -- systemctl restart hermes
```

Verify CDP from the agent's side:

```bash
pct exec 401 -- podman exec hermes-gateway \
  curl -s http://127.0.0.1:9222/json/version
```

Redeploy after editing `pod.yaml`:

```bash
pct exec 401 -- bash /opt/hermes/setup.sh
pct exec 401 -- systemctl daemon-reload
pct exec 401 -- systemctl restart hermes
```

## Memory budget

Measured on this pod (LXC capped at 2560 MB, 1024 MB swap):

| State | Cgroup | LXC used |
| --- | --- | --- |
| Idle (blank tab) | ~310 MB | ~1.05 GB |
| One heavy page loaded | ~430 MB | ~1.3 GB |

Chromium's `CHROME_CLI` carries memory-reduction flags: `--process-per-site` and
`--renderer-process-limit=2` collapse the per-tab/per-site process model (worth ~55 MB and
two processes on a heavy page), plus `--js-flags=--max-old-space-size=256`,
`--disable-background-networking`, `--disable-component-update` and `--disable-extensions`.

Deliberately NOT set: `--single-process` (one crashed tab takes the whole browser, and it
interacts badly with Selkies) and `--disable-gpu` (forces software rasterisation, which
hurts the Selkies video path).

## Locale

The container runs `LANG=es_VE.UTF-8` with `TZ=America/Caracas`, and `CHROME_CLI` carries
`--lang=es-VE --accept-lang=es-VE,es`.

`LANG` alone is NOT enough: it changes the system locale but Chrome sends its own
`Accept-Language` from a separate preference. Verified over CDP against
`httpbin.org/headers` — with only `LANG` set, Chrome still reported
`en-US,en;q=0.9` and `navigator.language == "en-US"`; `--accept-lang` is what fixes it.

Do not add quality values (`;q=0.9`) to `--accept-lang`: `CHROME_CLI` is expanded unquoted
in the labwc autostart, so a semicolon would be parsed by bash as a command separator.
Chrome appends the `q` values itself.

The container `resources.limits` are ceilings, not reservations — lowering them frees
nothing and only removes headroom.

## Notes

- `browser.<DOMAIN>` resolves to the gateway and is restricted by Caddy's `only_admin`
  snippet, which filters on client IP (`IP_PC`, `IP_MOBILE`, `IP_TS_PC`, `IP_TS_MOBILE`,
  gateway, monitor). A laptop whose DHCP address changed gets the connection aborted —
  update `IP_PC` in `100-gateway/caddy/.env` and `systemctl restart caddy`.
- Selkies itself runs with access open; the only gate is Caddy.
- No GPU passthrough: capture is software (`Pixman`), fine for one Chromium at 1024x768.
- Do not set `browser.user_data_dir` in Hermes' config — a second Chromium on the same
  profile directory corrupts it.
- Log in to sites by hand through Selkies. Never put account credentials in `env.yaml`.
