#!/bin/bash

iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

apt update && apt upgrade -y && apt install -y iptables-persistent && netfilter-persistent save
