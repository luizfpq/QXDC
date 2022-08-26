#!/usr/bin/env bash
# author:   Luiz Quirino
# since:    0.0.1
# version:  0.0.2
# created:  ____-__-__
# modified: 2021-09-11
# 
# reference: https://forum.xfce.org/viewtopic.php?id=8619

PKG_MANAGER=$(load packageManager)

configurePanel() {

  #
  # Creating panel 1
  #
  xfconf-query -n -c xfce4-panel -p "/panels/panel-1/plugin-ids" -a \
            -t int -s 1  -t int -s 2  -t int -s 3  -t int -s 4  -t int -s 5  \
            -t int -s 6  -t int -s 7  -t int -s 8  -t int -s 9  -t int -s 10 \
            -t int -s 11 -t int -s 12 -t int -s 13 -t int -s 14

  #
  # addin plugins
  #

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-1" -t string -s 'whiskermenu'
  
  xfconf-query -c xfce4-panel -pn "/plugins/plugin-2" -t string -s 'tasklist'
  #plugin specific settings
    xfconf-query -c xfce4-panel -p /plugins/plugin-2/grouping -t uint -s "0" -a --create

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-3" -t string -s 'separator'
    xfconf-query -c xfce4-panel -p /plugins/plugin-3/expand -t bool -s "true" -a --create
    xfconf-query -c xfce4-panel -p /plugins/plugin-3/style -t uint -s "0" -a --create
    
  xfconf-query -c xfce4-panel -pn "/plugins/plugin-4" -t string -s 'pager'

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-5" -t string -s 'separator'
    xfconf-query -c xfce4-panel -p /plugins/plugin-3/style -t uint -s "0" -a --create

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-6" -t string -s 'systray'

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-7" -t string -s 'pulseaudio'

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-8" -t string -s 'power-manager-plugin'

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-9" -t string -s 'notification-plugin'

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-10" -t string -s 'separator'
    xfconf-query -c xfce4-panel -p /plugins/plugin-3/style -t uint -s "0" -a --create

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-11" -t string -s 'clock'

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-12" -t string -s 'separator'
    xfconf-query -c xfce4-panel -p /plugins/plugin-12/grouping -t uint -s "0" -a --create

  xfconf-query -c xfce4-panel -pn "/plugins/plugin-13" -t string -s 'actions'


  #
  # Creating panel 2
  #
  xfconf-query -n -c xfce4-panel -p "/panels/panel-2/plugin-ids" -a \
            -t int -s 15  -t int -s 16  -t int -s 17  -t int -s 18  -t int -s 19  \
            -t int -s 20  -t int -s 21  -t int -s 22  -t int -s 23  -t int -s 24 \
            -t int -s 25 -t int -s 26 -t int -s 27
  # so 14 is our plugin count, lets add

  # addin plugins
  xfconf-query -c xfce4-panel -pn "/plugins/plugin-15" -t string -s 'showdesktop'
  xfconf-query -c xfce4-panel -pn "/plugins/plugin-16" -t string -s 'separator'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-17" -t string -s 'separator'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-18" -t string -s 'pager'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-19" -t string -s 'separator'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-20" -t string -s 'systray'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-21" -t string -s 'tasklist'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-22" -t string -s 'pulseaudio'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-23" -t string -s 'power-manager-plugin'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-24" -t string -s 'notification-plugin'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-25" -t string -s 'separator'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-26" -t string -s 'clock'
  # xfconf-query -c xfce4-panel -pn "/plugins/plugin-27" -t string -s 'separator'
  


# restart panels for taking effect
xfce4-panel --restart
}


nord-xfce-terminal() {
  # need to implement better practices
  echo "Installing nord-xfce4-terminal, thanks to Arctic Ice Studio..."
  git clone https://github.com/arcticicestudio/nord-xfce-terminal.git
  cd nord-xfce-terminal 
  ./install

}

installIcons() {
  $PKG_MANAGER papirus-icon-theme &>> /tmp/QXDCinstall.log && echo -e "\xE2\x9C\x94" && sudo reboot|| echo -e "\xE2\x9D\x8C"
  # customize papiris
  #https://github.com/PapirusDevelopmentTeam/papirus-folders
  sudo wget -qO- https://git.io/papirus-folders-install | sh
  sudo papirus-folders -C nordic --theme Papirus-Dark

}

configureUI() {
  clear
  read -p "Tecle S para aplicar as configurações de ambiente para o usuario atual ou qualquer outra tecla para não aplicar para nenhum... " -n 1 -r


  case "$REPLY" in
    s|S )
          echo "Configurando XFCE para o usuario atual..."

          mkdir $(xdg-user-dir PICTURES)/Wallpapers
          mkdir $(xdg-user-dir PICTURES)/Screenshots

        # @todo create menu to select wallpaper
        # download wallpaper from google, set as wallpaper and set as background          
          wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=110nhzi77Xzc3amO81HHGQATe4_Mf3bSl' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=110nhzi77Xzc3amO81HHGQATe4_Mf3bSl" -O $(xdg-user-dir PICTURES)/Wallpapers/main.jpg && rm -rf /tmp/cookies.txt

          #axel -n 5 -a https://qxdc.herokuapp.com/Wallpapers/main.jpg -o $(xdg-user-dir PICTURES)/Wallpapers/main.jpg


          #install icons
          installIcons


          xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark"
          xfconf-query -c xsettings -p /Net/IconThemeName -s "Arc"
          xfconf-query -c xfwm4 -p /general/theme -s "Arc-Dark"
          xfconf-query -c xfce4-desktop \
            -p /backdrop/screen0/monitor0/workspace0/last-image \
            -s  $(xdg-user-dir PICTURES)/Wallpapers/main.jpg
          xfce4-panel --quit
          pkill xfconfd
          
          
          VERSION=$(xfce4-about --version | grep 4.1)
          if [[ $VERSION == *"4.16"* ]]; then
            rm -rf ~/.config/xfce4/*
            cp -Rfv ./resources/dotfiles/* ~/
          else
            echo 'Versão não encontrada, usando definições para o Xfce 4.16'
            rm -rf ~/.config/xfce4/*
            cp -Rfv ./resources/dotfiles/* ~/
            # @todo criar confirmação para prosseguir
          fi

          xfce4-panel &
     ;;
      * ) echo "Ignorando etapa..."   ;;
  esac


}


