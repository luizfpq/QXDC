#!/usr/bin/env bash
# author:   Luiz Quirino <luizfpq@gmail.com>
# since:    v0.0.1
# version:  v0.0.1  
# created:  2021-09-11
# modified: 2022-07-28

checkDistro() {
    OS=$(lsb_release -i)
    OS="${OS:16}"
    ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
    VERSION=$(lsb_release -c)
    VERSION="${VERSION:9}"
    echo $OS
}