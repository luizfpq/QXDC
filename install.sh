#!/usr/bin/env bash
# author:   Luiz Quirino
# since:    0.0.1
# version:  0.0.2
# created:  ____-__-__
# modified: 2022-07-28
# 

source ./resources/include/load.sh


#define variaveis do sistema
ROOTDIR=$(pwd)
DISTRO= load checkDistro


load logger


# Instalando aplicações básica
# adicione o nome do novo pacote à lista para instalar
load installBaseApplications
# Removendo aplicações indesejadas
# adicione o nome do novo pacote à lista para desinstalar
load systemPurge
#instalando editor
load installVSCode
#instalando o Google Chrome
load installGoogleChrome
# Instalando tema GTK e ícones
load installThemes
cd $ROOTDIR
load configureUI
