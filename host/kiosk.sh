#!/bin/bash

useradd -m -s /bin/bash kiosk

echo "exec btop" | tee /home/kiosk/.bashrc

cat << 'EOF' > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin kiosk --noclear %I $TERM
EOF

systemctl daemon-reload

systemctl restart getty@tty1.service
