#!/usr/bin/env bash

installPowerline() {
  cd /tmp &&
  git clone https://github.com/b-ryan/powerline-shell &&
  cd powerline-shell &&
  sudo python setup.py install
  sudo apt-get install -qq -o=Dpkg::Use-Pty=0 fonts-powerline powerline-gitstatus -y &>> /tmp/QXDCinstall.log
}
