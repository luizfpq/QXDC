#!/usr/bin/env bash
echo "Alterando screen locker padrão"
sudo apt purge xfce4-screensaver
sudo apt purge gnome-screensaver
sudo mv /usr/bin/xflock4 /usr/bin/xflock4.old
sudo apt install i3lock i3lock-fancy
#altera as config do usuario
find ~/.config/xfce4/ -type f -exec sed -i "s/xflock4/i3lock-fancy/g" {} +
