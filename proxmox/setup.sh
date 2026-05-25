#!/bin/bash

apt update && apt upgrade -y

printf "net.ipv4.ip_forward = 1\nnet.ipv6.conf.all.forwarding = 1\n" | tee /etc/sysctl.d/99-ip-forwarding.conf
sysctl -p /etc/sysctl.d/99-ip-forwarding.conf
