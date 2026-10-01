#!/bin/bash

apt update && apt upgrade -y

printf "net.ipv4.ip_forward = 1\nnet.ipv6.conf.all.forwarding = 1\n" | tee /etc/sysctl.d/99-ip-forwarding.conf
sysctl -p /etc/sysctl.d/99-ip-forwarding.conf

# Setup Tailscale route via Gateway LXC (100) on vmbr0
cat << 'EOF' > /etc/network/if-up.d/tailscale-route
#!/bin/sh
if [ "$IFACE" = "vmbr0" ]; then
    ip route replace 100.64.0.0/10 via 192.168.0.3
fi
EOF
chmod +x /etc/network/if-up.d/tailscale-route
IFACE=vmbr0 /etc/network/if-up.d/tailscale-route

# Run permissions script
/bin/bash "$(dirname "$0")/permissions.sh"