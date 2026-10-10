#!/bin/bash
mkdir -p /etc/containers/systemd/
cp /opt/tududi/pod.kube /etc/containers/systemd/tududi.kube
systemctl daemon-reload
echo "Setup complete. Run 'systemctl start tududi' to start pod."

