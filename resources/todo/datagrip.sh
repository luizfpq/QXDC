#!/usr/bin/env bash

wget- c https://download-cf.jetbrains.com/datagrip/datagrip-2019.2.5.tar.gz
tar -zxvf datagrip-2019.2.5.tar.gz -C /opt/Datagrip
echo -e "
[Desktop Entry]\n
Version=1.1\n
Type=Application\n
Name=Datagrip\n
Comment=Database Management Tools\n
Icon=/opt/Datagrip/bin/datagrip.svg\n
Exec='/opt/Datagrip/bin/datagrip.sh' %f\n
Categories=Development;IDE;" >> /home/$USER/.local/share/applications/datagrip.desktop
