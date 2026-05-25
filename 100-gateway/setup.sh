#!/bin/bash

echo "Setting up NAT..."
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

echo "Saving iptables rules..."
apt update && apt upgrade -y && apt install -y iptables-persistent && netfilter-persistent save

echo "Configuring IP forwarding..."
printf "net.ipv4.ip_forward = 1\nnet.ipv6.conf.all.forwarding = 1\n" | tee /etc/sysctl.d/99-ip-forwarding.conf
sysctl -p /etc/sysctl.d/99-ip-forwarding.conf

echo "Gateway setup complete."
