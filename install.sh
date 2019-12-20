#!/bin/bash
# Works for Debian 9.9 (minimal)
# wget --no-check-certificate -P /YOUR_DIRECTORY/DBTerminal/ https://raw.githubusercontent.com/DerbanTW/DBTerminal/master/install.sh && chmod +x /YOUR_DIRECTORY/DBTerminal/install.sh
# ./install.sh


# Install packages
# Actually you have to confirm with Yes/No
doInstallPackages() {
	installPackages=ca-certificates,locales-all,curl,screen,tmux,htop,git,default-jdk,jq
	IFS=, read -a listPackages <<< "$installPackages"
	for varPackage in "${listPackages[@]}";do 
		isInstalled=$(dpkg-query -W -f='${Status}' $varPackage 2>/dev/null | grep -c "ok installed")
		if [[ $isInstalled == 0 ]];then
			echo "[INFO]: -> Starte Installation von  [$varPackage]..."
			apt-get install $varPackage
		fi
	done
}

# Support for äöü (todo: add entry in stdvariables and use inscript language to don't force other using german als std.).
setLocalesDE() {
	localesFile=/etc/default/locale
	germanLang="LANG=de_DE.UTF-8"
	isGerman=$(cat $localesFile | grep -o $germanLang)
	if [[ -z $isGerman ]];then
		apt-get install locales-all
		locale-gen de_DE.UTF-8
		update-locale LANG=de_DE.UTF-8
		echo -e "[DONE]: -> Lokale Sprache auf Deutsch gesetzt!"
	fi
}

# Some installations couldn't read the scripts; first solution.
fixBashrc() {
	fixPath="export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	bashrc="/root/.bashrc"
	tmpfile=instTempfile
	if [[ -f $bashrc ]];then
		while read -r line || [ -n "$line" ]; do 
			if [[ $line == $fixPath ]];then
				echo exportPathFound > instTempfile
			fi
		done < $bashrc
	fi

	if [[ -f $tmpfile ]];then
		if ! [[ -z $(grep -o 'exportPathFound' $tmpfile) ]];then
			rm $tmpfile
		fi
	else
		( echo "" ; echo "$fixPath" ; echo "" ) >> $bashrc
		echo -e "[Done/fixBashrc]: -> Linie [$fixPath] wurde der Datei <$bashrc> hinzugefuegt!"
	fi
}

# Add Mouse-Support (on/off with Alt-X/Y) 
installTMUXconf() {
	wget https://raw.githubusercontent.com/DerbanTW/bash/master/tmux.conf -O tmuxtmpfile
	cp tmuxtmpfile ~/.tmux.conf && rm tmuxtmpfile
}

# Standard Directory for DBT
createDBTDirectory() {
	actDir=${PWD##*/}
	if [[ $actDir == DBTerminal ]];then
		DBTDir="${PWD}/"
		copyfolder=""$DBTDir"copyfolder/"
	elif [[ -z $(ls -d */ 2>/dev/null) ]] || ! [[ $(ls -d */ | grep -c DBTerminal/) == 1 ]];then
		DBTDir="${PWD}/DBTerminal/"
		copyfolder=""$DBTDir"copyfolder/"
		mkdir -p $copyfolder
		echo -e "[DONE]: -> Neuer Ordner <$DBTDir> erstellt..."
	else
		DBTDir="${PWD}/DBTerminal/"
		copyfolder=""$DBTDir"copyfolder/"
	fi
	echo "0000 Copyfolder is [$copyfolder]"
}

# Download all Scripts in the DBT Directory
downloadDBTScripts() {
	if [[ -z $DBTDir ]];then
		echo -e "[Error]: -> [ERR_instsh_001] please report on: \n>> https://github.com/DerbanTW/DBTerminal/issues"
		exit 1
	fi
	cd $DBTDir
	DBTScripts=stdvariables.sh,functions.sh,mcfunctions.sh,cmdfunctions.sh,TerminalCMD.sh,reboundloop.sh,backup.sh
	mcStartShell=start.sh
	gitUrl=https://raw.githubusercontent.com/DerbanTW/DBTerminal/master/DBTerminal/
	IFS=, read -a DBTScriptsArray <<< "$DBTScripts"
	for varScript in "${DBTScriptsArray[@]}";do
		if [[ -f $varScript ]];then
			echo -e "[INFO]: -> Datei <$varScript> bereits vorhanden..."
		else
			echo -e "${yellow}>> Starte download von [$varScript]...${norm}"
			varUrl=$gitUrl$varScript
			wget $varUrl -qO $varScript
			chmod +x $varScript
		fi
	done
#todo: read max ram from system; adjust the start.sh (and move this in an own function)
	if ! [[ -d $copyfolder ]];then
		mkdir -p $copyfolder
	fi
	cd $copyfolder
	if [[ -f $mcStartShell ]];then
		echo -e "[INFO]: -> Datei <$mcStartShell> bereits vorhanden..."
	else
		echo -e "${yellow}>> Starte download von [$mcStartShell]...${norm}"
		cd $copyfolder
		varUrl=""$gitUrl"copyfolder/$mcStartShell"
		wget $varUrl -qO $mcStartShell
	fi
	cd $DBTDir
}

# Create Standard Minecraft-Directory (change the entry "mcDir=/path_to_your_folder/" in the stdvariables.sh.
createMCDirectory() {
	stdvarFile=""$DBTDir"stdvariables.sh"
	if ! [[ -f $stdvarFile ]];then
		echo -e "[Error]: -> [ERR_instsh_002] please report on: \n>> https://github.com/DerbanTW/DBTerminal/issues"
		exit 1
	fi
	fullmcDir=$(grep -o 'mcDir=[^"]*' $stdvarFile)
	stdmcDir=${fullmcDir#*=}
	if ! [[ -d $stdmcDir ]];then
		mkdir -p ""$stdmcDir"YourServer/"
		echo -e "[DONE]: -> Neuer Ordner <$stdmcDir> erstellt."
	fi
}

# Add a cronJob to start the DBTerminal by reboot
installCronJob() {
	CRON_FILE=/var/spool/cron/crontabs/root
	reboundShell="$(dirname "$(readlink -fn "$0")")/rebound.sh"
	cronJob="@reboot screen -dmS "ReboundLoop" bash -c ""$DBTDir"reboundloop.sh""
	cronExist=$(grep -o "$cronJob" $CRON_FILE 2>/dev/null)
	if [[ -z $cronExist  ]];then
		crontab -l 2>/dev/null | { cat; echo "$cronJob"; } | crontab -
		echo -e "[DONE]: -> Crontab bearbeitet. DBTerminal startet nun bei jedem Reboot!"
	fi
}


echo Install Script started...

cd $(dirname "$(readlink -fn "$0")")
apt-get update
doInstallPackages
apt-get update
setLocalesDE
fixBashrc
installTMUXconf
createDBTDirectory
downloadDBTScripts
createMCDirectory
installCronJob

echo "Install packages finished!"

