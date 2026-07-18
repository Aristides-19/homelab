#!/bin/bash

apt-get install python3-requests

echo "0 8 * * * root /bin/python3 /opt/homelab/vm/googol/cron/daily_report.py" | tee /etc/cron.d/daily-report
chmod 644 /etc/cron.d/daily-report
