#!/bin/bash

apt update && apt upgrade -y && apt install -y xclip micro && apt remove -y nano && apt autoremove -y

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

export EDITOR=micro
source ~/.bashrc

echo "LXC setup complete."