#!/usr/bin/env bash
# author:   Luiz Quirino
# since:    0.0.1
# version:  0.0.2
# created:  ____-__-__
# modified: 2021-09-11
# 

PKG_MANAGER=$(load packageManager)
LOGFILE='/tmp/qxdc/installThemes.log'

THEMES="arc-theme arc-icon-theme moka-icon-theme"

installThemes() {
clear

  echo "Instalando temas e ícones..."
  echo
  echo
  sudo apt-get update > /dev/null
  for package in ${THEMES[@]}
    do
      echo -ne "Instalando $package  "
      $PKG_MANAGER $package &>> $LOGFILE && echo -e "\xE2\x9C\x94" || echo -e "\xE2\x9D\x8C"

    done
}
