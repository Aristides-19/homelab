#!/bin/bash

apt update && apt upgrade -y && apt install -y xclip micro curl && apt remove -y nano && apt autoremove -y

# Optional Podman installation
read -p "Do you want to install Podman? (y/n): " install_podman
if [[ "$install_podman" =~ ^[Yy]$ ]]; then
    apt install -y podman
    systemctl enable --now podman.socket
    echo "Podman installed with socket enabled."
fi

mkdir -p ~/.config/micro
cat <<EOF > ~/.config/micro/settings.json
{
    "clipboard": "terminal",
    "tabsize": 2
}
EOF

if ! grep -q "export EDITOR=micro" ~/.bashrc; then
    echo "export EDITOR=micro" | tee -a ~/.bashrc
    echo "Added micro as the default editor in ~/.bashrc"
fi

timedatectl set-timezone America/Caracas
loginctl enable-linger 0

# SSH is publickey-only. /run/sshd is absent in these containers (no tmpfiles
# rule ships for it), so sshd refuses to start; /run is tmpfs, so recreate the
# dir on every boot too.
printf 'd /run/sshd 0755 root root -\n' > /etc/tmpfiles.d/sshd.conf
systemd-tmpfiles --create /etc/tmpfiles.d/sshd.conf
cat << 'EOF' > /etc/ssh/sshd_config.d/99-harden.conf
# Disable password auth: access is publickey-only.
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
EOF
sshd -t && systemctl restart ssh

# Limit journald disk usage to 200M
mkdir -p /etc/systemd/journald.conf.d
cat <<EOF > /etc/systemd/journald.conf.d/00-journal-limit.conf
[Journal]
SystemMaxUse=200M
EOF
systemctl restart systemd-journald

export EDITOR=micro
source ~/.bashrc

echo "LXC setup complete."