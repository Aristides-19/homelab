# Caddy Route Templates

## Standard Reverse Proxy Route
```caddy
	# <Service-Name> (<LXC-Hostname> LXC)
	@<subdomain> host <subdomain>.{$DOMAIN}
	handle @<subdomain> {
		reverse_proxy <lxc-hostname>.lxc:<port>
	}
```

## Admin-Only Restricted Route
```caddy
	# <Service-Name> Admin Area
	@<subdomain> host <subdomain>.{$DOMAIN}
	handle @<subdomain> {
		import only_admin
		reverse_proxy <lxc-hostname>.lxc:<port>
	}
```

## Route with Body Limit / Stream Optimization
Use for file uploads (e.g. Immich, Paperless):
```caddy
	# <Service-Name> Upload API
	@<subdomain> host <subdomain>.{$DOMAIN}
	handle @<subdomain> {
		reverse_proxy <lxc-hostname>.lxc:<port> {
			flush_interval -1
		}
		request_body {
			max_size 512MB
		}
	}
```
