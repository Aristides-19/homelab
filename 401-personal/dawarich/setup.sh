#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/dawarich/pod.kube /etc/containers/systemd/dawarich.kube
systemctl daemon-reload

echo "Dawarich setup complete. Run \`systemctl start dawarich\` to start the pod."