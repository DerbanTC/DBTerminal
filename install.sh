#!/bin/bash
#Works for Debian 9.4
#wget -P /home/bashscripts/ https://raw.githubusercontent.com/DerbanTW/bash/master/install.sh && chmod +x /home/bashscripts/install.sh
#./install.sh
#You have to confirm with Yes/No

echo Install Script started...

apt-get update

apt install locales-all

apt-get install curl

apt-get install jq

apt-get install screen

apt-get install tmux

apt-get install htop

apt-get install openjdk-7-jre-headless

apt-get install git

apt-get update

echo "Install packages finished! Add cron-job for the rebound.sh @reboot..."

crontab -l | { cat; echo "@reboot sleep 2 && screen -dmS "ReboundLoop" bash -c /home/bashscripts/reboundloop.sh"; } | crontab -

echo Cronjob installed. Script finished!
