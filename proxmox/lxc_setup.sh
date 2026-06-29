#!/bin/bash

apt update && apt upgrade -y && apt install -y xclip micro && apt remove -y nano && apt autoremove -y

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

export EDITOR=micro
source ~/.bashrc

echo "LXC setup complete."