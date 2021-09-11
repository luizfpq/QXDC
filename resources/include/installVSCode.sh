#!/usr/bin/env bash
# author:   Luiz Quirino
# since:    0.0.1
# version:  0.0.2
# created:  ____-__-__
# modified: 2021-09-11
# 
installVSCode() {
if [ -e "/usr/bin/code" ]
then
    clear && echo "VScode editor já instalado, pulando etapa"
else
  clear && echo instalando VScode editor...
  rm -rf ./vscode.deb
  wget --output-document=vscode.deb https://go.microsoft.com/fwlink/?LinkID=760868
  sudo apt-get install ./vscode.deb -y &>> /tmp/QXDCinstall.log
  rm -rf ./vscode.deb
fi
}
