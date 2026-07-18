#!/bin/bash

echo "Setting up Minecraft NAT..."
iptables -t nat -A PREROUTING -i ens4 -p tcp --dport 25565 -j DNAT --to-destination 10.0.4.4:25565
iptables -t nat -A POSTROUTING -o tailscale0 -p tcp -d 10.0.4.4 --dport 25565 -j MASQUERADE
iptables -A FORWARD -p tcp -d 10.0.4.4 --dport 25565 -j ACCEPT

echo "Saving iptables rules..."
apt update && apt upgrade -y && apt install -y iptables-persistent && netfilter-persistent save

echo "Configuring IP forwarding..."
printf "net.ipv4.ip_forward = 1\nnet.ipv6.conf.all.forwarding = 1\n" | tee /etc/sysctl.d/99-ip-forwarding.conf
sysctl -p /etc/sysctl.d/99-ip-forwarding.conf

echo "Minecraft TCP 25565 forwarding setup complete."
