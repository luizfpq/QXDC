#!/bin/bash
#
# removemos os pacotes indesejados
PURGE="mutt hv3 imagemagick"

systemPurge() {
  clear
  sudo apt-get update > /dev/null
  for application in ${PURGE[@]}
    do
      echo -ne "Removendo $application  "
      sudo apt-get purge $application -y &>> /tmp/QXDCinstall.log && echo -e "\xE2\x9C\x94" || echo -e "\xE2\x9D\x8C"
    done
}
