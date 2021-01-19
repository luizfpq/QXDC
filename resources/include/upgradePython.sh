#!/usr/bin/env

upgradePython() {
  sudo apt-get purge -qq -o=Dpkg::Use-Pty=0 python2* -y &>> /tmp/QXDCinstall.log

  sudo apt-get install -qq -o=Dpkg::Use-Pty=0 python3-pip python3-setuptools -y &>> /tmp/QXDCinstall.log

  sudo ln -s /usr/bin/python3 /usr/bin/python
}
