#!/bin/bash
# Works for Debian 9.4
# wget --no-check-certificate -P /YOUR_DIRECTORY/DBTerminal/ https://raw.githubusercontent.com/DerbanTW/DBTerminal/master/install.sh && chmod +x /YOUR_DIRECTORY/DBTerminal/install.sh
# ./install.sh
# Actually you have to confirm with Yes/No
cd $(dirname "$(readlink -fn "$0")")

echo Install Script started...

apt-get update
apt install locales-all
apt-get install curl
apt-get install jq
apt-get install screen
apt-get install tmux
apt-get install htop
apt-get install openjdk-7-jre
apt-get install git
apt-get update

echo "Install packages finished!"

echo Cronjob installed. Script finished!
