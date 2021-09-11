#!/usr/bin/env bash
# author:   Luiz Quirino
# since:    0.0.1
# version:  0.0.2
# created:  ____-__-__
# modified: 2021-09-11
# 
# Add here pack managers 

OS=$(load checkDistro)

packageManager() {
    case $OS in
        Debian)
            PKG_MANAGER="sudo apt-get install -qq -o=Dpkg::Use-Pty=0 -y"
            ;;
        Arch)
            PKG_MANAGER="sudo yay -Sy "
            ;;
        *)
            # leave ARCH as-is
            ;;
esac

echo $PKG_MANAGER
}