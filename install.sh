#!/bin/bash
# Works for Debian 9.9 (minimal)
# wget --no-check-certificate -P /YOUR_DIRECTORY/DBTerminal/ https://raw.githubusercontent.com/DerbanTC/DBTerminal/master/install.sh && chmod +x /YOUR_DIRECTORY/DBTerminal/install.sh

# Install packages
doInstallPackages() {
	apt-get update
	installPackages=ca-certificates,locales-all,curl,screen,tmux,htop,git,jq,bc,fail2ban,ufw,default-jdk
	IFS=, read -a listPackages <<< "$installPackages"
	for varPackage in "${listPackages[@]}";do 
		isInstalled=$(dpkg-query -W -f='${Status}' $varPackage 2>/dev/null | grep -c "ok installed")
		if [[ $isInstalled == 0 ]];then
			echo "[INFO]: -> Starte Installation von  [$varPackage]..."
			apt-get install -y $varPackage
		fi
	done
}

# Support for äöü (todo: add entry in stdvariables and use inscript language to don't force other using german als std.).
setLocalesDE() {
	localesFile=/etc/default/locale
	germanLang="LC_ALL=de_DE.UTF-8"
	if [[ -z $(cat $localesFile | grep -o $germanLang) ]];then
		apt-get install locales-all
		apt-get update
		apt-get install -y locales
		locale-gen "de_DE.UTF-8"
		update-locale LC_ALL="de_DE.UTF-8"
	fi
}

# Actually all ports closed without ssh & ftp
setupFirewall() {
	ufw disable
	ufw default deny incoming
	ufw default allow outgoing
	ufw allow ssh
	ufw allow ftp
	ufw enable -y
}

# Add Mouse-Support (on/off with Alt-X/Y) 
installTMUXconf() {
	wget https://raw.githubusercontent.com/DerbanTC/DBTerminal/master/tmux.conf -O tmuxtmpfile
	cp tmuxtmpfile ~/.tmux.conf && rm tmuxtmpfile
}

# Standard Directory for DBT
createDBTDirectory() {
	actDir=${PWD##*/}
	if [[ $actDir == DBTerminal ]];then
		DBTDir="${PWD}/"
		copyfolder="$DBTDir/{copyfolder,data,log,tmp}"
	elif [[ -z $(ls -d */ 2>/dev/null) ]] || ! [[ $(ls -d */ | grep -c DBTerminal/) == 1 ]];then
		DBTDir="${PWD}/DBTerminal"
		copyfolder="$DBTDir/{copyfolder,data,log,tmp}"
		echo -e "[DONE]: -> Neuer Ordner <$DBTDir> wird erstellt..."
	else
		DBTDir="${PWD}/DBTerminal"
		copyfolder="$DBTDir/{copyfolder,data,log,tmp}"
	fi
	mkdir -p $DBTDir/{copyfolder,data,log,tmp}
}

# Download all Scripts in the DBT Directory
downloadDBTScripts() {
	if [[ -z $DBTDir ]];then
		echo -e "[Error]: -> [ERR_instsh_003] please report on: \n>> https://github.com/DerbanTC/DBTerminal/issues"
		exit 1
	fi
	cd $DBTDir
	DBTScripts=backup.sh,dataFunctions.sh,fixResources.sh,functions.sh,inject.sh,localCommands.sh,login.sh,mcfunctions.sh
	DBTScripts=$DBTScripts,netCommands.sh,printFunctions.sh,printHelp.sh,reboundloop.sh,stdvariables.sh,TerminalCMD.sh
	gitUrl=https://raw.githubusercontent.com/DerbanTC/DBTerminal/master/DBTerminal/
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
}

downloadMCStartShell() {
	mcStartShell=start.sh
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
	totalKB=$(free -m | awk '/^Mem:/{print $2}')
	totalGB=$(( totalKB / 1024 ))
	if [[ $totalGB -lt 9 ]];then
		mcMemory=$(( totalGB - 1 ))
	else
		mcMemory=$(( totalGB - 2 ))
	fi
	javaArg="java -Xms"$mcMemory"G -Xmx"$mcMemory"G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=60 -XX:G1MixedGCLiveThresholdPercent=35 -XX:+AlwaysPreTouch -XX:+ParallelRefProcEnabled -Dusing.aikars.flags=mcflags.emc.gs -jar minecraft_server.jar"
	javaArgLine=$(grep -o 'java[^"]*' $mcStartShell)
	sed -i "s/$javaArgLine/$javaArg/g" $mcStartShell
	echo -e "[INFO]: -> Minecraft-Server starten mit [$mcMemory/$totalGB] GB Ram ("$copyfolder"start.sh)"
	cd $DBTDir
}

# Create Standard Minecraft-Directory (change the entry "mcDir=/path_to_your_folder/" in the stdvariables.sh.
createMCDirectory() {
	stdvarFile=""$DBTDir"stdvariables.sh"
	if ! [[ -f $stdvarFile ]];then
		echo -e "[Error]: -> [ERR_instsh_004] please report on: \n>> https://github.com/DerbanTC/DBTerminal/issues"
		exit 1
	fi
	fullmcDir=$(grep -o 'mcDir=[^"]*' $stdvarFile)
	stdmcDir=${fullmcDir#*=}
	if ! [[ -d $stdmcDir ]];then
		mkdir -p ""$stdmcDir"YourServer/"
		echo -e "[DONE]: -> Neuer Ordner <$stdmcDir> erstellt."
	fi
}

echo Install Script started...

cd $(dirname "$(readlink -fn "$0")")
doInstallPackages
doInstallJava
setLocalesDE
setupFirewall
installTMUXconf
createDBTDirectory
downloadDBTScripts
downloadMCStartShell
createMCDirectory
./fixResources.sh

echo "Install packages finished! Please reboot..."

