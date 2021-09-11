#!/usr/bin/env bash
# author:   Luiz Quirino
# since:    0.0.1
# version:  0.0.2
# created:  ____-__-__
# modified: 2021-09-11
# 
verifyInstallation() {
  clear
  if [ -e "$1" ]
    then
      echo " O pacote $1 já está instalado"
    else
      return 0
    fi
}
