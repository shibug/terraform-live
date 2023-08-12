sudo apt list --upgradable
sudo apt update && sudo apt upgrade -y
sudo reboot
lsb_release -a

sudo do-release-upgrade -d
lsb_release -a
uname -mrs
cd /etc/apt/sources.list.d
#uncomment latest docker repository and delete the old one
sudo apt autoremove --purge