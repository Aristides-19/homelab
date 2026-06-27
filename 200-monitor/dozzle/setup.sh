#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/dozzle/pod.kube /etc/containers/systemd/dozzle.kube
systemctl daemon-reload

echo "Dozzle setup complete. Run \`systemctl start dozzle\` to start the pod."