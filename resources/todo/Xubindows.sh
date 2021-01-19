#!/usr/bin/env bash

wget -c https://dllb2.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjE0ODU3Njc1OTEiLCJ1IjpudWxsLCJsdCI6ImRvd25sb2FkIiwicyI6ImZmNWI4YmUyOTE1OGRlZjNhNjM5N2I5NjFjYzEyMDY0NGRhZTI4ODdhNDNjNDhjZTBjNzY1NjU2OTU0ZjJjZmRlN2FkYWVlNTMxYmViZmE2ZDRjMTAwZmYyNDNlZjYwY2MyMDFkMDQzMjkzMjlhNmIxOThjNTBjOGM5YTk1NDE3IiwidCI6MTU5NDA3NTQwNiwic3RmcCI6ImMxOTgwMGQxODQ1MjQ0YzJjYjNmMmE2ZTY1NzNkZDk2Iiwic3RpcCI6IjEzOC4xODYuMzkuMjIzIn0.QIv4_IkZqY6WQDc9AWrf1zx89oagKLRWELKy_DTMRL0/windows10-icons_1.2_all.deb

sudo apt install ./windows10-icons_1.2_all.deb

sudo rm -rf windows10-icons_1.2_all.deb

echo "Configurando icones..."
#xfconf-query -c xsettings -p /Net/ThemeName -s "Mint-Y-Dark-Purple"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Windows10"

mkdir ~/.icons

wget -c https://i.ya-webdesign.com/images/png-to-icon-windows-10-4.png -O ~/.icons/startup_icon.png

wget -c https://ist.ifsp.edu.br/images/IF-ICON-White.png -O ~/.icons/logo_icon.png
