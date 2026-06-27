#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/karakeep/pod.kube /etc/containers/systemd/karakeep.kube
systemctl daemon-reload

echo "Karakeep setup complete. Run \`systemctl start karakeep\` to start the pod."