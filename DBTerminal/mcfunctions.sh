#!/bin/bash

getFunction() {
	source ""$SelfPath"functions.sh" $1 $2 $3 $4
}

grepExtern() {
	if ! [[ -z $1 ]];then
		mcName=$1 && SelfPath="$(dirname "$(readlink -fn "$0")")/"
		cd $SelfPath && source ./stdvariables.sh
		getFunction getSTDFiles
	fi
}

doMCPing() {
	tmpfile="$SelfPath"tmp/mcping
	varIP=$1 && varPort=$2
	if [[ -z $varIP ]] || [[ $varIP == $MCport ]] && ! [[ -z $varPort ]];then
		lastMsg="${lred}[ERROR/doMCPing]: ${norm}-> Keine IP als [varIP]! -> $varIP"
		return 1
	elif [[ -z $varPort ]];then
		varURL="$mcSrvCheckAPI$varIP"
	else
		varURL="$mcSrvCheckAPI$varIP:$varPort"
	fi
	echo -e "${yellow}>> Server wird gepingt... [$varURL]${norm}"
	fullping=$(curl --silent --request GET --url $varURL)
	if ! [[ -z $fullping ]];then
		echo $fullping > $tmpfile
		pingResponse=true
	else
		lastMsg="${lred}[ERROR/doMCPing]: ${norm}-> Keine Antwort erhalten!" && return 1
	fi
}

readMCPing() {
	unset pingAllowdString && unset onlinePlayersCount
	jsonfile="$SelfPath"tmp/mcping.json
	tmpfile="$SelfPath"tmp/mcping
	jq -s . $tmpfile > $jsonfile
	pingAllowdString=$(jq -r '.[].error' $jsonfile)
	if [[ $pingAllowdString != null ]];then
		lastMsg="[INFO/doMCPing]: -> Ping ist nicht erlaubt! Böse böse Admins..."
		return 1
	fi
	onlineString=$(jq -r '.[].online' $jsonfile)
	onlinePlayersCount=$(jq -r '.[].players.online' $jsonfile)
	maxPlayersCount=$(jq -r '.[].players.max' $jsonfile)
	versionString=$(jq -r '.[].version' $jsonfile)
	softwareString=$(jq -r '.[].software' $jsonfile)
	rm $jsonfile && rm $tmpfile
}

getOnlinePlayers() {
	if [[ -z $1 ]];then
		getFunction readProperties && doMCPing $MCip $MCport
	else
		doMCPing $1 $2
	fi
	if [[ $pingResponse == true ]];then
		getMCFunction readMCPing
	fi
}

startMCScreen() {
	grepExtern $1 && getFunction setMCBackupConf Autostart true
	varScreen=$(screen -ls | grep MCS_$mcName)
	if [[ -z $varScreen ]];then
		screen -dmS "MCS_$mcName" bash -c "$bash"
	fi
}

stopMC() {
	grepExtern $1 && getFunction setMCBackupConf Autostart false
	varScreen=$(screen -ls | grep MCS_$mcName)
	if ! [[ -z $varScreen ]];then
		screen -S "MCS_$mcName" -p 0 -X stuff "'\x0a'^M"
		screen -S "MCS_$mcName" -p 0 -X stuff "stop^M"
	else
		echo -e "[ERROR/stopMCScreen]: -> screen MCS_$mcName nicht gefunden!"
	fi
}

installMC() {
	grepExtern $1
	if ! [[ -f $eula ]];then
		echo -e "${yellow}> <eula.txt> wurde nicht gefunden. Erstelle Datei...${norm}" && echo "eula=true" > $eula
	fi
	if ! [[ -f $startShell ]];then
		echo -e "${yellow}> <$StartShellName> wurde nicht gefunden. Kopiere Datei...${norm}"
		cp $copyDir$StartShellName $mcDir$mcName/ && chmod +x $startShell
	elif ! [[ -x $startShell ]];then
		echo -e "${yellow}> <$StartShellName> hat keine Berechtigung! Ändere Berechtigung...${norm}" && chmod +x $startShell
	fi
	if ! [[ -f $bkupconfig ]];then
		echo -e "${yellow}> <$bkupconfName> wurde nicht gefunden! Erstelle Standard-Config...${norm}"
		echo -e "#Do not edit this file!\nbackup=false\nautorestart=true\nbackuptime=" > $bkupconfig
	fi
	if ! [[ -f $mcSrvProperties ]];then
		FirstMCSetup=true
	fi
	startMCScreen
	if [[ $FirstMCSetup == true ]];then
		echo -e "${yellow}> Erste Server-Installation..."
		echo -e "${yellow}> Warte bis die <server.properties> generiert wurde...${norm}"
		timer=0
		until [[ -f $mcSrvProperties ]];do
			sleep 1 && timer=$(( timer +1 ))
			if [[ $timer == 60 ]];then
				lastMsg="${lred}[ABBRUCH/StartMC]: ${yellow}-> <server.properties> wurde Seit 60 Sekunden nicht generiert${norm}!"
				return 1
			fi
		done
		echo -e "${yellow}> <server.properties> generiert. IP wird automatisch gesetzt..." 
		getFunction setProperties IP $internalIP && getFunction setProperties Port $stdMCPort
		lastMsg="${lgreen}[DONE/Start]: ${norm}-> Server-Installation wird ausgeführt. IP:$internalIP Port:$stdMCPort \n> Bitte schreibe ${yellow}Restart ${norm}sobald der Server erreichbar ist..."
	else
		lastMsg="${lgreen}[DONE/Start]: ${norm}-> Server [$mcName] wird gestartet!"
	fi
}

sendText() {
	if ! [[ -z $text ]];then
		if [[ -z $prefix ]];then prefix=Server;fi
		varText='tellraw @a ["",{"text":"'$prefix'", "color":"gold","bold":true},{"text":": '$text'","color":"white"}]^M'
		screen -S "MCS_$mcName" -p 0 -X stuff ''"$varText"'^M'
	else
		lastMsg="[ERROR/sendText]: -> Text vergessen?"
	fi
}

doTimedStop() {
	grepExtern $1 && reason=$2
	getFunction getSTDFiles && getFunction readMCBackupConf
	if [[ $doAutostart == false ]];then
		lastMsg="${lred}[ERROR/doTimedStop]: ${norm}-> Fehler Code doTimSt_001\n>> Autostart für [$mcName] ist [$doAutostart] statt true!"
		return 1
	fi
	timer=30 && unset cancel
	while [[ -z $cancel ]];do
		if [[ $timer == 30 ]] || [[ $timer == 10 ]];then
			text="Server-Shutdown in $timer Sekunden!"
			sendText
		elif [[ $timer == 3 ]] || [[ $timer == 2 ]] || [[ $timer == 1 ]];then
			text="Server-Shutdown in $timer..."
			sendText
		elif [[ $timer == 0 ]];then
			cancel=false
		fi
		clear
		echo -e "${yellow}>> Manueller Stop! $onlinePlayersCount Spieler online"
		echo -e "[$timer] Sekunden bis zum Stop des Server..."
		echo -e "${lred}Drücke ${lblue}ENTER ${lred}um den Stop abzubrechen!${norm}"
		read -t 1 answer
		if [[ $? -eq 0 ]];then
			cancel=true
		fi
		timer=$(( timer - 1 ))
	done	
	if [[ $cancel == false ]];then
		stopMC
	fi
	if ! [[ -z $1 ]];then
		if [[ $cancel == false ]];then
			local a="${lgreen}[DONE/$reason]: ${norm}-> Server [$mcName] wurde gestoppt..."
			lastMsg="$a\n> $onlinePlayersCount Spieler waren online!"
		else
			text="Shutdown abgebrochen..." && sendText
			lastMsg="${lred}[ABGEBROCHEN/$reason]: ${norm}-> ${reason} Abgrebrochen! Der Server wird ${lred}nicht ${norm}gestoppt!"
		fi
	
	fi
	export $cancel
}

doEnsureMCStop() {
	getOnlinePlayers
	if [[ $onlinePlayersCount == 0 ]] || [[ $onlinePlayersCount == null ]] || [[ -z $onlinePlayersCount ]];then
		stopMC
	else
		sendText && doTimedStop $mcName
	fi
}

downloadMCcheck() {
	source ./stdvariables.sh
	local mcName=$1
	cd "$mcDir"$mcName/
	echo -e "$(ls -f | grep -c "minecraft_server.jar.*")"
}

downloadMCjar() {
	createDir() {
		newMCDir=""$mcDir"$1"
		if [[ -d $newMCDir ]];then
			cd $newMCDir
			if [[ -f "minecraft_server.jar" ]];then
				count=$(ls -f | grep -c "minecraft_server.jar_OLD.*")
				if [[ $count -gt 0 ]];then
					count=$(( count + 1 ))
					cp minecraft_server.jar "minecraft_server.jar_OLD$count"
				else
					cp minecraft_server.jar minecraft_server.jar_OLD
				fi
				rm minecraft_server.jar
			fi
		else
			mkdir $newMCDir && cd $newMCDir
		fi
	}
	downloadJar() {
		local ServerVersion=$1
		local ServerType=$2
		case $ServerType in
			Paper)
				local paperURL="https://papermc.io/api/v1/paper/$ServerVersion/latest/download"
				wget -q --content-disposition $paperURL -O minecraft_server.jar
			;;
			Waterfall)
				local paperURL="https://papermc.io/api/v1/waterfall/$ServerVersion/latest/download"
				wget -q --content-disposition $paperURL -O minecraft_server.jar
			;;
		esac
		cd $SelfPath
	}
	if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]];then return 1;fi
	grepExtern $4
	createDir $1
	downloadJar $2 $3
}

$1 $2 $3 $4 $5
