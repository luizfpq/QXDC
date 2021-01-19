#!/usr/bin/env bash

curl -L https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb && sudo apt install ./deb-multimedia-keyring_2016.8.1_all.deb
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 4B4E7A9523ACD201
wget -q -O - http://download.opensuse.org/repositories/home:/ivaradi/Debian_9.0/Release.key | sudo apt-key add -
sudo apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 3766223989993A70
sudo apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys E58A9D36647CAE7F
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 1F3045A5DF7587C3
sudo apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A87FF9DF48BF1C90
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F24AEA9FB05498B7
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4773BD5E130D1D45
wget -O - https://download.teamviewer.com/download/linux/signature/TeamViewer2017.asc | sudo apt-key add -
