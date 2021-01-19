#!/bin/bash
#em processo de criação

installNextCloudClient() {
  sudo apt-get update
  sudo apt-get install -qq -o=Dpkg::Use-Pty=0 nextcloud-client
}

createSourcesListNxtCloudCli() {
 touch nextcloud-client.list
 echo deb http://ppa.launchpad.net/nextcloud-devs/client/ubuntu zesty main >> nextcloud-client.list
 echo deb-src http://ppa.launchpad.net/nextcloud-devs/client/ubuntu zesty main >> nextcloud-client.list
 sudo mv nextcloud-client.list /etc/apt/sources.list.d/nextcloud-client.list
 sudo apt-get install -qq -o=Dpkg::Use-Pty=0 dirmngr
 sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com AD3DD469
}

touch nextcloud-client.list
echo deb http://ppa.launchpad.net/nextcloud-devs/client/ubuntu bionic main >> nextcloud-client.list
echo deb-src http://ppa.launchpad.net/nextcloud-devs/client/ubuntu bionic main >> nextcloud-client.list
sudo mv nextcloud-client.list /etc/apt/sources.list.d/nextcloud-client.list
sudo apt-get install -qq -o=Dpkg::Use-Pty=0 dirmngr
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com AD3DD469
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1FCD77DD0DBEF5699AD2610160EE47FBAD3DD469
sudo apt-get update
axel -n 5 -a http://ftp.br.debian.org/debian/pool/main/libg/libgnome-keyring/libgnome-keyring-common_3.12.0-1_all.deb
sudo apt install ./libgnome-keyring-common_3.12.0-1_all.deb
axel -n 5 -a http://ftp.br.debian.org/debian/pool/main/libg/libgnome-keyring/libgnome-keyring0_3.12.0-1+b2_amd64.deb
sudo apt install ./libgnome-keyring0_3.12.0-1+b2_amd64.deb
sudo apt-get install -qq -o=Dpkg::Use-Pty=0 nextcloud-client
rm -rf *.deb
