#!/bin/bash
#@todo criar um autoload
ROOTDIR=$(pwd)
source ./resources/include/purgeApplications.sh
source ./resources/include/installBaseApplications.sh
source ./resources/include/upgradePython.sh
source ./resources/include/installGoogleChrome.sh
source ./resources/include/installVSCode.sh
source ./resources/include/installThemes.sh
source ./resources/include/installPowerline.sh
#source ./resources/include/sourcesListChange.sh
source ./resources/include/configureUI.sh
#Alterando o sources list, pra remover o cd/dvd ou para inserir uma mais eficiente no brasil
#changeList
# Removendo aplicações indesejadas
# adicione o nome do novo pacote à lista para desinstalar
systemPurge
# Instalando aplicações básicas
# adicionando o nome de um novo pacote à lista para instalar automaticamente
installBaseApplications
#instalando atom-editor
#upgradePython
#instalando atom-editor
installVSCode
#instalando o Google Chrome
#installGoogleChrome
# Instalando tema GTK e ícones
installThemes
#installPowerline
cd $ROOTDIR
configureUI
