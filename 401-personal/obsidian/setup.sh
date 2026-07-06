#!/bin/bash
mkdir -p /etc/containers/systemd/

# CouchDB Settings
mkdir -p /data/obsidian/db/data
mkdir -p /data/obsidian/db/config
chown -R 5984:5984 /data/obsidian/db

cp /opt/obsidian/pod.kube /etc/containers/systemd/obsidian.kube
systemctl daemon-reload

echo "CouchDB setup complete. Run 'systemctl start obsidian' to start the pod."
