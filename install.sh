#!/bin/bash
# Works for Debian 9.4
# wget --no-check-certificate -P /YOUR_DIRECTORY/DBTerminal/ https://raw.githubusercontent.com/DerbanTW/DBTerminal/master/install.sh && chmod +x /YOUR_DIRECTORY/DBTerminal/install.sh
# ./install.sh
# Actually you have to confirm with Yes/No
cd $(dirname "$(readlink -fn "$0")")

installPackages=ca-certificates,locales-all,curl,screen,tmux,htop,git,openjdk-7-jre,jq

doInstallPackages() {
	IFS=, read -a listPackages <<< "$installPackages"
	for varPackage in "${listPackages[@]}";do 
		isInstalled=$(dpkg-query -W -f='${Status}' $varPackage 2>/dev/null | grep -c "ok installed")
		if [[ $isInstalled == 0 ]];then
			echo "[INFO]: -> Starte Installation von  [$varPackage]..."
			apt-get install $varPackage
		fi
	done
}

echo Install Script started...

apt-get update
doInstallPackages
apt-get update

echo "Install packages finished!"

