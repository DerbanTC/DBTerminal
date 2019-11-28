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

echo Install Script finished
