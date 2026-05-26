#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/immich/pod.kube /etc/containers/systemd/immich.kube
systemctl daemon-reload

echo "Immich setup complete. Run `systemctl start immich` to start the pod."