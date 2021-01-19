#!/usr/bin/env bash

VERSION=$(xfce4-about --version | grep 4.1)
if [[ $VERSION == *"4.14"* ]]; then
  echo 'Instalando definições para Xfce 4.14'
elif [[ $VERSION == *"4.12"* ]]; then
  echo 'Instalando definições para Xfce 4.12'
else
  echo 'Versão não encontrada, usando definições para o Xfce 4.12'
  #@todo criar confirmação para prosseguir
fi
