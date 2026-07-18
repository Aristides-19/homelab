# Homelab

## Hardware
- PC: HP ProDesk 400 G4 Mini
  - CPU: i5-8500T (6 Cores / 6 Threads)
  - RAM: 16GB DDR4
  - SSD: 256GB NVMe SSD
- UPS: CDP R-Smart 751

## Architecture
- **Hypervisor:** Proxmox VE
- **Virtualization Style:** Unprivileged LXC containers running Podman Quadlets (`pod.kube`) integrated into systemd.
- **Networking:** 
  - `100-gateway` acts as a subnet router (NAT) bridging external network (`vmbr0`, `192.168.0.0/24`) and internal subnet (`vmbr1`, `10.0.0.0/16`).
  - Proxmox Host has `10.0.0.2` assigned to `vmbr1` for private host services (e.g. NUT server).


## Active Services
- **100-gateway:** Caddy (Reverse Proxy), Tailscale (VPN), Cloudflare Tunnel, AdGuard Home (DNS).
- **101-data:** Immich, Karakeep, Paperless.
- **200-monitor:** Uptime Kuma, Dozzle (agents in each LXC).
- **206-media:** Cap.so.
- **401-personal:** Vaultwarden, IT Tools, Obsidian Live Sync.
- **403-backup:** Restic (cronjobs + Backblaze S3).
- **418-home:** Home Assistant.

## Hardware & Host Configuration
- **UPS Monitoring:** Configured on host using Network UPS Tools (NUT). See `host/nut/README.md`.

