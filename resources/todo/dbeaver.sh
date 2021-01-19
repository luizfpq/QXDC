echo "Adicionando chave e repositórios"
echo "Entre com a senha sudo: "
wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo apt-key add -
sudo sh -c 'echo "deb https://dbeaver.io/debs/dbeaver-ce /" > /etc/apt/sources.list.d/dbeaver.list'
#echo "deb https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
echo "Atualizando repositórios"
sudo apt-get update > /dev/null
echo "Instalando dbeaver..."
sudo apt-get install -qq -o=Dpkg::Use-Pty=0 dbeaver-ce -y &>> /tmp/QXDCinstall.log
