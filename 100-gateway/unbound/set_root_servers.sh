#!/bin/bash

mkdir -p /var/lib/unbound
wget https://www.internic.net/domain/named.root -qO- | tee /var/lib/unbound/root.hints >/dev/null
chown -R unbound:unbound /var/lib/unbound

echo "0 0 1 */6 * root wget https://www.internic.net/domain/named.root -qO- | tee /var/lib/unbound/root.hints >/dev/null 2>&1" | tee /etc/cron.d/unbound-hints
chmod 644 /etc/cron.d/unbound-hints
