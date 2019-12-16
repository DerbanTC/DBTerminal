#!/bin/bash

ExecuteCommand=$1
Argument2=$2
Argument3=$3

getFunction() {
	source ""$SelfPath"functions.sh" $1 $2 $3
}

doMCPing() {
	tmpfile="$SelfPath"tmpfile
	varIP=$1
	varPort=$2
	if [[ -z $varIP ]] || [[ $varIP == $MCport ]] && ! [[ -z $varPort ]];then
		echo  -e "${lred}[ERROR/doMCPing]: ${norm}-> Keine IP als [varIP]! -> $varIP"
		return 1
	elif [[ -z $varPort ]];then
		varURL="$mcSrvCheckAPI$varIP"
	else
		varURL="$mcSrvCheckAPI$varIP:$varPort"
	fi
	echo do ping [$varURL]...
	fullping=$(curl --request GET --url $varURL)
	if ! [[ -z $fullping ]];then
		echo $fullping > $tmpfile
		pingResponse=true
	else
		pingResponse=false
	fi
}

readMCPing() {
	unset pingAllowdString && unset onlinePlayersCount
	jsonfile="$SelfPath"tmpfile.json
	tmpfile="$SelfPath"tmpfile
	jq -s . tmpfile >tmpfile.json
	pingAllowdString=$(jq -r '.[].error' $jsonfile)
	if [[ $pingAllowdString != null ]];then
		echo Error found
		return 1
	else
		pingAllowdString=true
	fi
	onlineString=$(jq -r '.[].online' $jsonfile)
	onlinePlayersCount=$(jq -r '.[].players.online' $jsonfile)
	maxPlayersCount=$(jq -r '.[].players.max' $jsonfile)
	versionString=$(jq -r '.[].version.name' $jsonfile)
	rm $jsonfile && rm $tmpfile
}

getOnlinePlayers() {
	getFunction readProperties
	doMCPing $MCip $MCport
	if [[ $pingResponse == true ]];then
		getMCFunction readMCPing
	fi
}

MCStop() {
	if $(screen -ls | grep -q MCS_$mcServer);then
		screen -S "MCS_$mcServer" -p 0 -X stuff "stop^M"
	fi
}

MCStart() {
	if ! $(screen -ls | grep -q MCS_$mcServer);then
		screen -dmS "MCS_$mcServer" bash -c "$bash"
		getFunction detachMCScreen
		getFunction attachMCScreen
	fi

}

installMC() {
	if ! [[ -f $eula ]];then
		echo -e "${yellow}> <eula.txt> wurde nicht gefunden. Erstelle Datei...${norm}"
		echo "eula=true" > $eula
	fi
	if ! [[ -f $startShell ]];then
		echo -e "${yellow}> <$StartShellName> wurde nicht gefunden. Kopiere Datei...${norm}"
		cp $copyDir$StartShellName $mcDir$mcServer/
		chmod +x $startShell
	fi
	if ! [[ -x $startShell ]];then
		echo -e "${yellow}> <$StartShellName> hat keine Berechtigung! Ändere Berechtigung...${norm}"
		chmod +x $startShell
	fi
	if ! [[ -f $bkupconfig ]];then
		echo -e "${yellow}> <$bkupconfName> wurde nicht gefunden! Erstelle Standard-Config...${norm}"
		getFunction createStdBkupConfig
	fi
	if ! [[ -f $mcSrvProperties ]];then
		FirstMCSetup=true
	fi
	if ! [[ -f $mcSrvProperties ]];then
		FirstMCSetup=true
	fi
	getFunction setBackupConf Autostart true
	getFunction checkConditions
	if [[ $StartIsEnabled == firstRun ]] && ! $(screen -ls | grep -q MCS_$mcServer);then
		echo -e "${yellow}> Starte Screen"
		getFunction startMCScreen
	fi
	getFunction detachMCScreen
	getFunction attachMCScreen

	if [[ $FirstMCSetup == true ]];then
		echo -e "${lred}[WARNUNG/StartMC]: ${yellow}-> <server.properties> wurde nicht gefunden!"
		echo -e "${yellow} > Erste Server-Installation..."
		echo -e "${yellow} > Warte bis die <server.properties> generiert wurde...${norm}"
		timer=0
		until [[ -f $mcSrvProperties ]];do
			sleep 1s
			timer=$(( timer +1 ))
			if [[ $timer == 60 ]];then
				echo -e "${lred}[ABBRUCH/StartMC]: ${yellow}-> <server.properties> wurde Seit 60 Sekunden nicht generiert${norm}!"
				return 1
			fi
		done
		echo -e "${yellow}> <server.properties> generiert. Der Server wird nach 75 Sekunden automatisch gestoppt und neu gestartet!"
		sleep 1
		headerText="${yellow}>> Aktive MCServer-Installation! \nWarte bis der Server gestartet wurde.${norm}"
		timerText="${yellow}bis der Server gestoppt wird...${norm}"
#change to 120 or more if you run on a hdd
		getFunction showTimer 74
		if ! [[ -z $cancel ]];then
			cancelReason="${lred}[ABBRUCH/Start]: ${norm}-> Der Stop wurde manuell unterbrochen!\n>> Installation ${lred}nicht ${norm}vollendet. Nutze ${yellow}Stop ${norm}um den Server zu stoppen!"
			return 1
		fi
		MCStop
		clear
		timerText="${yellow}bis der Server gestartet wird...${norm}"
		getFunction showTimer 5
		if ! [[ -z $cancel ]];then
			cancelReason="${lred}[ABBRUCH/Start]: ${norm}-> Der Start wurde manuell unterbrochen!\n>> Installation vollendet. Nutze ${yellow}Start ${norm}um den Server zu starten!"
			return 1
		fi
		getFunction readProperties
		getFunction setProperties IP $internalIP
		getFunction setProperties Port $stdMCPort
		getFunction setBackupConf Autostart true
		clear
	fi

}

sendText() {
	if ! [[ -z $text ]];then
		varText='tellraw @a ["",{"text":"'$prefix'", "color":"gold","bold":true},{"text":": '$text'","color":"white"}]^M'
		screen -S "MCS_$Server" -p 0 -X stuff ''"$varText"'^M'
	else
		echo "[ERROR/sendText]: -> Text vergessen?"
	fi
}

doTimedStop() {
	tmpfile=./showTimerTmpfile
	text="Server-Shutdown in 30 Sekunden!"
	sendText
	sleep 20
	if [[ -f $tmpfile ]];then
		if ! [[ -z $(grep -o 'isCancelled' $tmpfile) ]];then
			rm $tmpfile && return 1
		fi
	fi
	text="Server-Shutdown in 10 Sekunden!"
	sendText
	sleep 7
	if [[ -f $tmpfile ]];then
		if ! [[ -z $(grep -o 'isCancelled' $tmpfile) ]];then
			rm $tmpfile && return 1
		fi
	fi
	text="Server-Shutdown in 3..."
	sendText
	sleep 1
	if [[ -f $tmpfile ]];then
		if ! [[ -z $(grep -o 'isCancelled' $tmpfile) ]];then
			rm $tmpfile && return 1
		fi
	fi
	text="Restart in 2..."
	sendText
	sleep 1
	if [[ -f $tmpfile ]];then
		if ! [[ -z $(grep -o 'isCancelled' $tmpfile) ]];then
			rm $tmpfile && return 1
		fi
	fi
	text="Restart in 1..."
	sendText
	if [[ -f $tmpfile ]];then
		if ! [[ -z $(grep -o 'isCancelled' $tmpfile) ]];then
			rm $tmpfile && return 1
		fi
	fi
	sleep 1
	getFunction setBackupConf Autostart false
	MCStop
	unset prefix
}

doEnsureMCStop() {
	getOnlinePlayers
	if [[ $onlinePlayersCount == 0 ]];then
		MCStop
	else
		sendText
		doTimedStop
	fi
}

$ExecuteCommand $Argument2 $Argument3

