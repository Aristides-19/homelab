# NUT Configuration

Monitoring setup for **CDP R-Smart 751** on Proxmox VE.

## Install
```bash
apt install nut nut-client nut-server
```

## Apply Configuration

Run the setup script as root to copy configurations and restart services:
```bash
bash setup.sh
```

*(This copies [ups.conf](ups.conf), [nut.conf](nut.conf), and [upsd.conf](upsd.conf) to `/etc/nut/`, sets permissions, and restarts `nut-server`).*


## Automatic Shutdown (`upsmon`)

The `setup.sh` script automatically configures the monitoring daemon (`nut-monitor`) and handles credentials:

* **First run:** Generates a secure random password and configures both `/etc/nut/upsd.users` and `/etc/nut/upsmon.conf`.
* **Subsequent runs:** Preserves your existing password if `upsmon_user` is already configured.

### Tracked Config Templates:
* [upsd.users](upsd.users): Template for the monitor user.
* [upsmon.conf](upsmon.conf): Active configuration settings for the monitor daemon.

