#!/bin/bash
#Works for Debian 9.4
#chmod +x ./install.sh
#You have to confirm with Yes/No

echo Install Script started...

apt-get update

apt install locales-all

apt-get install screen

apt-get install tmux

apt-get install htop

apt-get install default-jdk

apt-get install git

apt-get update

echo Install packages finished! Add cron-job for the init.sh @reboot...

crontab -l | { cat; echo "@reboot sleep 2 && /home/bashscripts/init.sh"; } | crontab -

echo Cronjob installed. Script finished!
