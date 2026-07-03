#!/bin/bash
mkdir -p /etc/containers/systemd/
cp /opt/ha/pod.kube /etc/containers/systemd/ha.kube
systemctl daemon-reload
echo "Setup complete. Run 'systemctl start ha' to start pod."
