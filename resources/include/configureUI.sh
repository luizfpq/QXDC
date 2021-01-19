#!/bin/bash
configureUI() {
  clear
  read -p "Tecle S para aplicar as configurações de ambiente para o usuario atual ou qualquer outra tecla para não aplicar para nenhum... " -n 1 -r


  case "$REPLY" in
    s|S )
          echo "Configurando XFCE para o usuario atual..."
          xfconf-query -c xsettings -p /Net/ThemeName -s "Mint-Y-Dark-Purple"
          xfconf-query -c xsettings -p /Net/IconThemeName -s "Mint-Y-Dark-Purple"
          xfconf-query -c xfwm4 -p /general/theme -s "Mint-Y-Dark-Purple"
          xfconf-query -c xfce4-desktop \
            -p /backdrop/screen0/monitor0/workspace0/last-image \
            -s  ~/Imagens/Wallpapers/main.jpg
          xfce4-panel --quit
          pkill xfconfd
          tar -zxvf ./resources/dotfiles.tar.gz -C ~
          VERSION=$(xfce4-about --version | grep 4.1)
          if [[ $VERSION == *"4.14"* ]]; then
              rm -rf ~/.config/xfce4/*
              cp -Rfv ./resources/xfce4.14.dot/* ~/.config/xfce4/
          elif [[ $VERSION == *"4.12"* ]]; then
            rm -rf ~/.config/xfce4/*
            cp -Rfv ./resources/xfce4.12.dot/* ~/.config/xfce4/
          else
            echo 'Versão não encontrada, usando definições para o Xfce 4.12'
            m -rf ~/.config/xfce4/*
            cp -Rfv ./resources/xfce4.12.dot/* ~/.config/xfce4/
            #@todo criar confirmação para prosseguir
          fi

          #configurando username atual
          #@deprecated   rpl -R BASE_USERNAME $USER ~/.config
          find ~/.config -type f -exec sed -i "s/BASE_USERNAME/$USER/g" {} +

          xfce4-panel &
     ;;
      * ) echo "Ignorando etapa..."   ;;
  esac


}
