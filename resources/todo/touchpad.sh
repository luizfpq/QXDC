#!/usr/bin/env bash
echo "Instalando touchpad..."
sudo apt-get install -qq -o=Dpkg::Use-Pty=0 xserver-xorg-input-synaptics -y &>> /tmp/QXDCinstall.log
