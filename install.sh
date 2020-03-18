#!/bin/bash
# Works for Debian 9.9 (minimal)
# wget --no-check-certificate -P /YOUR_DIRECTORY/DBTerminal/ https://raw.githubusercontent.com/DerbanTC/DBTerminal/master/install.sh && chmod +x /YOUR_DIRECTORY/DBTerminal/install.sh

gitUrl=https://raw.githubusercontent.com/DerbanTC/DBTerminal/master/DBTerminal/

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
		DBTDir="${PWD}"
	elif [[ -z $(ls -d */ 2>/dev/null) ]] || ! [[ $(ls -d */ | grep -c DBTerminal/) == 1 ]];then
		DBTDir="${PWD}/DBTerminal"
		echo -e "[DONE]: -> Neuer Ordner <$DBTDir> wird erstellt..."
	else
		DBTDir="${PWD}/DBTerminal"
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
	DBTScripts=$DBTScripts,netCommands.sh,printFunctions.sh,printHelp.sh,reboundloop.sh,sshfunctions.sh,stdvariables.sh,TerminalCMD.sh
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
	local copyfolder="$DBTDir/copyfolder"
	local mcStartShell="$copyfolder/start.sh"
	if [[ -f $mcStartShell ]];then
		echo -e "[INFO]: -> Datei <$mcStartShell> bereits vorhanden..."
	else
		echo -e "${yellow}>> Starte download von [$mcStartShell]...${norm}"
		local varUrl=""$gitUrl"copyfolder/start.sh"
		wget $varUrl -qO $mcStartShell
	fi
	local totalKB=$(free -m | awk '/^Mem:/{print $2}')
	local totalGB=$(( totalKB / 1024 ))
	if [[ $totalGB -lt 9 ]];then
		local mcMemory=$(( totalGB - 1 ))
	else
		local mcMemory=$(( totalGB - 2 ))
	fi
	local javaArg="java -Xms"$mcMemory"G -Xmx"$mcMemory"G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=60 -XX:G1MixedGCLiveThresholdPercent=35 -XX:+AlwaysPreTouch -XX:+ParallelRefProcEnabled -Dusing.aikars.flags=mcflags.emc.gs -jar minecraft_server.jar"
	local javaArgLine=$(grep -o 'java[^"]*' $mcStartShell)
	sed -i "s/$javaArgLine/$javaArg/g" $mcStartShell
	echo -e "[INFO]: -> Minecraft-Server starten mit [$mcMemory/$totalGB] GB Ram ($mcStartShell)"
}

# Create Standard Minecraft-Directory (change the entry "mcDir=/path_to_your_folder/" in the stdvariables.sh.
createMCDirectory() {
	local stdvarFile="$DBTDir/stdvariables.sh"
	if ! [[ -f $stdvarFile ]];then
		echo -e "[Error]: -> [ERR_instsh_004] please report on: \n>> https://github.com/DerbanTC/DBTerminal/issues"
		exit 1
	fi
	local fullmcDir=$(grep -o 'mcDir=[^"]*' $stdvarFile)
	local stdmcDir=${fullmcDir#*=}
	mkdir -p "$stdmcDir"YourServer/
	if ! [[ -d $stdmcDir ]];then
		mkdir -p "$stdmcDir"YourServer/
		echo -e "[DONE]: -> Neuer Ordner <$stdmcDir> erstellt."
	fi
}

echo Install Script started...

cd $(dirname "$(readlink -fn "$0")")
doInstallPackages
setLocalesDE
setupFirewall
installTMUXconf
createDBTDirectory
downloadDBTScripts
downloadMCStartShell
createMCDirectory
./fixResources.sh
if [[ -z $(screen -ls | grep ReboundLoop) ]];then
	screen -dmS "ReboundLoop" bash -c "$DBTDir/reboundloop.sh"
fi
echo "Install packages finished! Please open a new Terminal..."
