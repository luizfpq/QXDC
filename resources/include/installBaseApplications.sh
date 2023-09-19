#!/usr/bin/env bash
# author:   Luiz Quirino
# since:    0.0.1
# version:  0.0.2
# created:  ____-__-__
# modified: 2021-09-11
# 
# adicionando o nome do pacote ao fim da linha, seu pacote será instalado
# mantenha atenção ao conjunto de pacotes da sua distribuição

PKG_MANAGER=$(load packageManager)


APPLICATIONS="autoconf gvfs gvfs-bin gvfs-common gvfs-daemons gvfs-libs\
 libmtp-dev gvfs-backends apt-transport-https htop gnome-disk-utility apparmor asciinema \
 axel curl fonts-lyx galculator gimp inkscape\
 keepassxc lightning locate lsb-release menulibre neofetch net-tools software-properties-common\
  thunderbird thunderbird-l10n-pt-br transmission-gtk unrar unzip "

verifyXFCE() {
  sudo dpkg -s task-xfce-desktop &> /dev/null

if [ $? -eq 0 ]; then
    echo "Iniciando a instalação das aplicações básicas do desktop..."
else
    echo "Pacote task-xfce-desktop não está instalado,\n deseja instalar?"
    read -p "Tecle S para instalar o pacote e reiniciar seu computador, você deve reiniciar esta instalação após a reinicialização do sistema. " -n 1 -r


    case "$REPLY" in
      s|S )
        echo "Aguarde a instalação, esta etapa pode demorar alguns minutos... faça um café e aguarde o reboot automático da máquina"
        $PKG_MANAGER task-xfce-desktop &>> /tmp/QXDCinstall.log && echo -e "\xE2\x9C\x94" && sudo reboot|| echo -e "\xE2\x9D\x8C"
      ;;
    esac
fi
}

installBaseApplications() {
  clear

  verifyXFCE

  echo "Atualizando os repositórios..."
  echo
  echo
  sudo apt-get update > /dev/null
  for application in ${APPLICATIONS[@]}
    do
      echo -ne "Instalando $application  "
      $PKG_MANAGER $application &>> /tmp/QXDCinstall.log && echo -e "\xE2\x9C\x94" || echo -e "\xE2\x9D\x8C"

    done
}
