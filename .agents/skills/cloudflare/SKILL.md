---
name: cloudflare
description: Documents the OAuth scopes granted to the Cloudflare MCP server and the guardrails for using them via the execute tool. Use when reading or changing Cloudflare DNS, SSL/TLS certificates, zone settings, WAF, tunnels, cache, page rules, transform rules, or analytics for the homelab public zone.
license: MIT
metadata:
  audience: homelab
  standard: agentskills.io
  provider: cloudflare-mcp
---

# Cloudflare Access & Guardrails

Controls how the agent uses the Cloudflare MCP server. The grant is **scope-limited**: anything outside the list below fails with 403, and no tool can introspect the grant.

## Context

- One account, one active zone. Discover them at runtime with `GET /zones` and `GET /accounts`; do not hardcode ids in this skill.
- Auth: OAuth user grant (not an API token). `whoami` returns identity only, never scopes.
- Tools: `search` (OpenAPI spec), `execute` (API calls), `docs`, `whoami`, `submit_feedback`. Harness has no `skills/list`, so Cloudflare's official skills are not auto-loaded.

## Granted Scopes

| Scope | Level | Enables |
| --- | --- | --- |
| `dns.read` | read | List/get DNS records |
| `dns.write` | **write** | Create/update/delete DNS records |
| `zone.read` | read | List/get zones |
| `memberships.read` | read | List account memberships |
| `argotunnel.read` | read | List/get Cloudflare Tunnels (`cfd_tunnel`) |
| `argotunnel.write` | **write** | Create/update/delete tunnels, rotate secrets, manage configurations |
| `ssl-and-certificates.read` | read | Certificate packs, universal SSL, custom hostnames |
| `ssl-and-certificates.write` | **write** | Order/delete certificates, toggle SSL modes, certificate packs |
| `zone-settings.read` | read | Read zone settings (SSL mode, dev mode, cache level, security level) |
| `zone-settings.write` | **write** | Change zone settings |
| `zone-waf.read` | read | WAF rulesets, firewall custom rules, managed rules |
| `zone-waf.write` | **write** | Create/update WAF rules and rulesets |
| `http-ddos-managed-ruleset.read` | read | HTTP DDoS managed ruleset state |
| `analytics.read` | read | Zone analytics (dashboard, DNS, cache) |
| `account-analytics.read` | read | Account-level analytics |
| `logs.read` | read | Logpush jobs and log pulls |
| `cache.purge` | **write** | Purge cache (URL, tag, prefix, or purge-everything) |
| `zone-versioning.read` | read | Zone config versions (read only — no rollback) |
| `page-rules.read` | read | Page Rules (read only — legacy product) |
| `transform-rules.read` | read | Transform Rules (read only) |
| `zone-transform-rules.read` | read | Zone-level transform rules (read only) |
| `bot-management.read` | read | Bot Management configuration |

## Not Granted

Do not attempt these — they will 403, and retrying wastes turns:

- **Workers / Pages / R2 / D1 / KV / Queues / Hyperdrive** — no Workers or storage scopes.
- **Access (Zero Trust apps, policies, identity providers)** — no `access.*`.
- **WAF writes are granted, but `page-rules`, `transform-rules`, `zone-versioning` are read-only.** No rollback via versioning.
- **DNS write does not imply zone creation.** No `zone.create`, no account-level DNS.
- **No billing, no token issuance, no account member mutation.**
- **No R2 jurisdiction or Images scopes.**

## Guardrails

Read operations from Granted Scopes: execute freely.

**Confirm with the user before any write**, stating the exact endpoint and target. Writes that always require confirmation:

| Operation | Why |
| --- | --- |
| `DELETE` DNS record | Breaks routing; Typecaddy / gateway services depend on it |
| `dns.write` changing `A`/`AAAA`/`CNAME` on the apex or wildcard of the public zone | Breaks the Caddy reverse proxy on LXC 100 |
| `PUT/PATCH /zones/{id}/settings` for SSL mode or security level | Can take the public site offline |
| `DELETE /accounts/{id}/cfd_tunnel/{tunnel_id}` | Kills Cloudflare Tunnel connectivity |
| `argotunnel.write` rotating tunnel secret | Requires reconfiguring `cloudflared` inside the LXC |
| `purge_everything = true` | Flushes origin caches; origin load spike |
| `zone-waf.write` adding a block/challenge rule | Can lock out legitimate clients |
| `ssl-and-certificates.write` deleting cert packs | Certificate outage until reissue |

Never write to a zone other than the public homelab zone without explicit instruction — some scopes are account-wide, so a wrong zone id would succeed silently.

## Workflow

1. `search` — find the endpoint and its body schema before writing code.
2. `execute` — call with the explicit zone/account id (never rely on `accountId` alone for zone paths).
3. On 403 — read the error text; it names the missing permission. Do not retry.
4. On 429 — stop; do not catch and continue, the limit is shared.

## Related

- Caddy route changes that need matching DNS: see the `caddy-route` skill.
- Tunnel runs on LXC `100-gateway`.
- Cloudflare official skills: `github.com/cloudflare/skills` (not installed here).
