#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/it-tools/pod.kube /etc/containers/systemd/it-tools.kube
systemctl daemon-reload

echo "IT-Tools setup complete. Run 'systemctl start it-tools' to start the pod."
