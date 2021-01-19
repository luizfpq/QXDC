# 1. Add the Spotify repository signing keys to be able to verify downloaded packages
wget -qO - https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -

# 2. Add the Spotify repository
sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'

# 3. Update list of available packages
sudo apt-get update > /dev/null

# 4. Install Atom
echo "Instalando Atom..."
sudo apt-get install -qq -o=Dpkg::Use-Pty=0 atom -y &>> /tmp/QXDCinstall.log
