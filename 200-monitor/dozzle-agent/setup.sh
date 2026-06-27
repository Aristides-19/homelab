#!/bin/bash

mkdir -p /etc/containers/systemd/

LXC_HOSTNAME=$(hostname)

sed "s/\[AGENT_HOSTNAME\]/${LXC_HOSTNAME}/g" /opt/dozzle-agent/env.sample.yaml > /opt/dozzle-agent/env.${LXC_HOSTNAME}.yaml

cp /opt/dozzle-agent/pod.kube /etc/containers/systemd/dozzle-agent.kube
sed -i "s|ConfigMap=.*|ConfigMap=/opt/dozzle-agent/env.${LXC_HOSTNAME}.yaml|g" /etc/containers/systemd/dozzle-agent.kube
systemctl daemon-reload

echo "Dozzle Agent setup complete. Run \`systemctl start dozzle-agent\` to start the pod."