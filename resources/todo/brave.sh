curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -

#source /etc/os-release

echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ buster main" | sudo tee /etc/apt/sources.list.d/brave-browser-release-buster.list

sudo apt-get update

sudo apt-get install brave-keyring brave-browser

#enabling namespaces
echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/00-local-userns.conf
service procps restart
