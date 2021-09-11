#!/usr/bin/env bash
# author:   Luiz Quirino
# since:    0.0.1
# version:  0.0.2
# created:  ____-__-__
# modified: 2021-09-11
# 
ROOTDIR=$(pwd)
source ./resources/include/load.sh

# Removendo aplicações indesejadas
# adicione o nome do novo pacote à lista para desinstalar
load systemPurge
# Instalando aplicações básica
# adicione o nome do novo pacote à lista para instalar
load installBaseApplications
#instalando editor
#load installVSCode
#instalando o Google Chrome
#load installGoogleChrome
# Instalando tema GTK e ícones
load installThemes
cd $ROOTDIR
load configureUI
