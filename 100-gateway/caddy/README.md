# Caddy Reverse Proxy

- Mounted at /etc/caddy
- Must set DNS rewrites in AdGuard for others LXCs
- Must build xcaddy with Caddy DNS Cloudflare module `xcaddy build --with github.com/caddy-dns/cloudflare` and move it to `/usr/bin`.
  - Run `apt-mark hold caddy` to avoid breaking it with updates
