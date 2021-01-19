
installGoogleChrome() {
if [ -e "/usr/bin/google-chrome-stable" ]
then
  clear && echo "Google Chrome já instalado, pulando etapa"
else
  clear && echo instalando google-chrome-stable
  # removendo instalador prévio caso esquecido
  cd /tmp && rm -rf atom-amd64.deb
  axel -n 5 https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -a
  sudo apt install ./google-chrome-stable_current_amd64.deb -y &>> /tmp/QXDCinstall.log
  # removendo instalador após instalar
  rm -rf google-chrome-stable_current_amd64.deb
fi
}
