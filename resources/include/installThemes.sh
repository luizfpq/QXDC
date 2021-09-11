#!/usr/bin/env bash
# author:   Luiz Quirino
# since:    0.0.1
# version:  0.0.2
# created:  ____-__-__
# modified: 2021-09-11
# 

installThemes() {
clear
  verifyIcons
  verifyTheme
}

verifyTheme() {
  if [ -e "/usr/share/themes/Arc-Dark" ]
    then
      echo " Tema já está instalado..."
    else
      echo " Instalando o tema..."
      sudo apt install arc-theme
    fi
}

verifyIcons() {
  if [ -e "/usr/share/icons/Arc/" ]
    then
      echo " Os ícones já estão instalados..."
    else
      echo " Instalando os ícones..."
      cd /tmp
      git clone https://github.com/horst3180/arc-icon-theme --depth 1 && cd arc-icon-theme
      ./autogen.sh --prefix=/usr
      sudo make install
    fi
}
