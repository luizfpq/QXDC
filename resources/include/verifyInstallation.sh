#!/bin/bash
verifyInstallation() {
  clear
  if [ -e "$1" ]
    then
      echo " O pacote $1 já está instalado"
    else
      return 0
    fi
}
