#!/bin/bash
mkdir -p /etc/containers/systemd/
cp /opt/opengym/pod.kube /etc/containers/systemd/opengym.kube
systemctl daemon-reload
echo "Setup complete. Run 'systemctl start opengym' to start pod."
