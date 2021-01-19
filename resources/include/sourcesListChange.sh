#!/bin/bash
changeList() {
  clear

  OS=$(grep ID= /etc/os-release | sed 's/ID=//g' | tr -d '="')

  if [ $OS  ]; then

  read -p "Deseja criar uma nova sources list? (S/N)? " -n 1 -r

  case "$REPLY" in
    s|S )
          echo "Realizando backup da sources list original..."
          sudo cp -Rfv /etc/apt/sources.list /etc/apt/sources.list.old
          echo "Copiando nova sources list..."
          sudo cp -Rfv ./resources/sources.list /etc/apt/sources.list
     ;;
    n|N ) echo "Sua sources list não será alterada...\n continuando"
     ;;
      * ) echo "Invalido, tente novamente"
          changeList
      ;;
  esac
fi
}
