#!/bin/bash
# Idempotent: safe to re-run any time pod.yaml, pod.kube or env.yaml change.
#
# What needs what:
#   pod.yaml  - read by `podman kube play` on every start, so a restart is enough.
#   env.yaml  - passed as --configmap, also re-read on every start. A restart
#               applies it; `systemctl reload` would not, and nothing is cached.
#   pod.kube  - copied to /etc/containers/systemd/, which systemd turns into the
#               unit at daemon-reload. THIS is the only file that needs setup.sh:
#               editing it alone changes nothing until the copy is refreshed.
# Re-running always is cheap and removes the question.
mkdir -p /etc/containers/systemd/
cp /opt/opengym/pod.kube /etc/containers/systemd/opengym.kube
systemctl daemon-reload
echo "Setup complete. Run 'systemctl restart opengym' to apply pod.yaml/env.yaml changes."
