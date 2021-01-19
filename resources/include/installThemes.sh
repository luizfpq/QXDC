#!/bin/bash

installThemes() {
clear
  verifyIcons
  verifyTheme
}

verifyTheme() {
  if [ -e "/usr/share/themes/Mint-Y" ]
    then
      echo " Tema já está instalado..."
    else
      echo " Instalando o tema..."
      axel -n 5 -a http://packages.linuxmint.com/pool/main/m/mint-themes/mint-themes_1.8.6_all.deb
      sudo apt-get install ./mint-themes_1.8.6_all.deb -qq -o=Dpkg::Use-Pty=0  -y &>> /tmp/QXDCinstall.log
      rm -rf mint-themes_1.8.6_all.deb
    fi
}

verifyIcons() {
  if [ -e "/usr/share/icons/Mint-Y/" ]
    then
      echo " Os ícones já estão instalados..."
    else
      echo " Instalando os ícones..."
      axel -n 5 -a http://packages.linuxmint.com/pool/main/m/mint-x-icons/mint-x-icons_1.5.5_all.deb
      sudo apt-get install ./mint-x-icons_1.5.5_all.deb -qq -o=Dpkg::Use-Pty=0  -y &>> /tmp/QXDCinstall.log
      rm -rf mint-x-icons_1.5.5_all.deb
      axel -n 5 -a http://packages.linuxmint.com/pool/main/m/mint-y-icons/mint-y-icons_1.4.3_all.deb
      sudo apt-get install ./mint-y-icons_1.4.3_all.deb -qq -o=Dpkg::Use-Pty=0  -y &>> /tmp/QXDCinstall.log
      rm -rf mint-y-icons_1.4.3_all.deb

    fi
}
