# Tailscale

- Just install, login, and run it by `tailscale up \
  --advertise-routes=10.0.0.0/24,192.168.0.0/24 \
  --advertise-exit-node \
  --accept-dns=false`
- It must be configured in tailscale admin panel
	- Disable expiry key
	- Allow auto-accept for exit node and subnet routing
	- Set tailnet DNS to this node
	- Enable ip forwarding with /etc/sysctl.d (in host and lxc levels)
