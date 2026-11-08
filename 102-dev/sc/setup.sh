#!/bin/bash
# Idempotent: safe to re-run any time pod.yaml, pod.kube or env.yaml change.
mkdir -p /etc/containers/systemd/
cp /opt/sc/pod.kube /etc/containers/systemd/sc.kube
systemctl daemon-reload
echo "Setup complete. Run 'systemctl restart sc' to apply pod.yaml/env.yaml changes."
