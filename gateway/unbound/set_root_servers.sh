#!/bin/bash

sudo mkdir -p /var/lib/unbound
sudo curl -o /var/lib/unbound/root.key https://data.iana.org/root-anchors/root-anchors.xml
sudo curl -o /etc/unbound/root.hints https://internic.net
sudo chown -R unbound:unbound /var/lib/unbound/root.key /etc/unbound/root.hints

