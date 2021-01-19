#!/bin/bash
#adicionando ao fim da linha, seu pacote será instalado
APPLICATIONS="mugshot gvfs gvfs-bin gvfs-common gvfs-daemons gvfs-libs\
 libmtp-dev gvfs-backends apt-transport-https htop gnome-disk-utility apparmor asciinema \
 axel curl debian-keyring fonts-lyx galculator gimp inkscape\
 keepassxc lightning locate menulibre neofetch net-tools software-properties-common\
  thunderbird thunderbird-l10n-pt-br transmission-gtk unrar unzip xfce4-goodies fonts-powerline"

verifyXFCE() {
  sudo dpkg -s task-xfce-desktop &> /dev/null

if [ $? -eq 0 ]; then
    echo "Iniciando a instalação!"
else
    echo "Pacote task-xfce-desktop não está instalado,\n deseja instalar?"
    read -p "Tecle S para instalar o pacote e reiniciar seu computador, você deve reiniciar esta instalação após a reinicialização do sistema. " -n 1 -r


    case "$REPLY" in
      s|S )
        sudo apt-get install -qq -o=Dpkg::Use-Pty=0 task-xfce-desktop -y &>> /tmp/QXDCinstall.log && echo -e "\xE2\x9C\x94" && sudo reboot|| echo -e "\xE2\x9D\x8C"
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
      sudo apt-get install -qq -o=Dpkg::Use-Pty=0 $application -y &>> /tmp/QXDCinstall.log && echo -e "\xE2\x9C\x94" || echo -e "\xE2\x9D\x8C"

    done
}
