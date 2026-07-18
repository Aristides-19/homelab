#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/minecraft/pod.kube /etc/containers/systemd/minecraft.kube
systemctl daemon-reload

echo "Minecraft setup complete. Run 'systemctl start minecraft' to start the pod."
