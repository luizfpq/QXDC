#!/usr/bin/env bash
# author:     Luiz Quirino
# since:       v0.0.1
# created:   --/--/----
# modified: --/--/----
#em processo de criação
sudo rm -Rf /opt/trello*
sudo rm -Rf /usr/bin/trello
sudo rm -Rf /usr/share/applications/trello.desktop
#uname -m

axel -n 5 -a https://github.com/danielchatfield/trello-desktop/releases/download/v0.1.9/Trello-linux-0.1.9.zip

sudo mkdir /opt/trello
sudo unzip Trello-linux-0.1.9.zip -d /opt/trello/
sudo ln -sf /opt/trello/Trello /usr/bin/trello
echo -e '[Desktop Entry]\n Version=1.0\n Name=trello\n Exec=/opt/trello/Trello\n Icon=/opt/trello/resources/app/static/Icon.png\n Type=Application\n Categories=Office' | sudo tee /usr/share/applications/trello.desktop
sudo chmod +x /usr/share/applications/trello.desktop
