#!/bin/bash

mkdir -p /etc/containers/systemd/

cp /opt/paperless/pod.kube /etc/containers/systemd/paperless.kube
systemctl daemon-reload

echo "Paperless setup complete. Run `systemctl start paperless` to start the pod."