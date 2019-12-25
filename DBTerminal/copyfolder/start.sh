#!/bin/bash

#################################################
# start-shell for minecraft server
################################################

mcServer=${PWD##*/}
Selfpath=$(dirname "$(readlink -fn "$0")")
Config=$Selfpath/BackupConfig.txt
bkupconfig=$Selfpath/BackupConfig.txt
mcSrvProperties=$Selfpath/server.properties

norm=$(tput sgr0)
yellow='\033[1;33m'
lblue='\033[1;34m'
lred='\033[1;31m'
black='\033[0;30m'

bgreen=$(tput setab 2)
byellow=$(tput setab 3)
bblue=$(tput setab 4)
n=0

readBackupConf() {
	if [[ -f $bkupconfig ]];then
		AutostartLine=$(grep -o 'autorestart[^"]*' $bkupconfig)
		doAutostart=${AutostartLine#*=}
		BackupLine=$(grep -o 'backup[^"]*' $bkupconfig)
		doBackup=${BackupLine#*=}
	fi
}

readProperties() {
	if [[ -f $mcSrvProperties ]];then
		MCportfull=$(grep -o 'server-port[^"]*' $mcSrvProperties)
		MCport=${MCportfull#*=}
	fi
}

errorFunc() {
	if [[ -z $foundError ]];then
		if [[ -f $bkupconfig ]];then
			echo -e "${lred}[ERROR/start.sh]: ${norm}-> <autorestart> ist nicht true/false!"
			sed -i "s/$AutostartLine/autorestart=false/g" $bkupconfig
			echo -e "${yellow}>> Fehlerhafte Linie ersetzt! <autorestart> ist nun false..."
		else
			foundError=true
			echo -e "${lred}[ERROR/start.sh]: ${norm}-> Datei <$bkupconfig> nicht gefunden!"
			echo -e ">> Code [ERRstsh001] Do you know what you are doing man?"
		fi
	fi
}

openPort() {
	if ! [[ -z $1 ]];then
		countOpened=$(ufw status | grep $1 | grep -c ALLOW)
		if [[ $countOpened == 0 ]];then
			ufw allow $1/tcp 1>/dev/null
			echo -e "${bgreen}>> Port [$1/tcp] wurde geöffnet!${norm}"
		fi
	fi
}

closePort() {
	if ! [[ -z $1 ]];then
		varPort=$(ufw status | grep $1 | grep ALLOW | grep v6 | cut -d ' ' -f1)
		if ! [[ -z $varPort ]];then
			ufw delete allow $varPort 1>/dev/null
			echo -e "${black}${byellow}>> Port [$varPort] wurde geschlossen!${norm}"
		fi
	fi
}

cd "$Selfpath"
echo -e "${yellow}[INFO/start.sh]: -> Script wurde gestartet..."
echo -e "[INFO/start.sh]: -> Prüfe <$bkupconfig>...${norm}"

readBackupConf

echo -e "${bblue}>> $bkupconfig <<"
echo -e "> AutoBackup = $doBackup "
echo -e "> AutoRestart = $doAutostart "
echo -e "------------------------------------------------${norm}"

while true; do
	readBackupConf
	readProperties
	if [[ $doAutostart == true ]];then
		echo -e "${bgreen}[INFO/start.sh]: -> Server [$mcServer] wird gestartet!${norm}"
		openPort $MCport
		sleep 1
		java -Xms3G -Xmx3G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=60 -XX:G1MixedGCLiveThresholdPercent=35 -XX:+AlwaysPreTouch -XX:+ParallelRefProcEnabled -Dusing.aikars.flags=mcflags.emc.gs -jar minecraft_server.jar
		echo -e ""
		echo -e "${black}${byellow}[INFO/start.sh]: -> Server [$mcServer] wurde gestoppt...${norm}"
		n=0
	elif [[ $doAutostart == false ]];then
		if [[ $n = 0 ]];then
			echo -e "${black}${byellow}[INFO/start.sh]: -> Start von [$mcServer] wurde unterbrochen! (autorestart ist false)${norm}"
			closePort $MCport
			echo -e "${black}${byellow}>> 10-Sekunden Timer wurde gestartet. Warte auf Änderung der Config...${norm}"
			n=1
		fi
	else
		errorFunc
	fi
	sleep 10
done
