#!/bin/bash

ExecuteCommand=$1
Argument2=$2
Argument3=$3

getFunction() {
	source ""$SelfPath"functions.sh" $1 $2 $3
}

getMCFunction() {
	source ""$SelfPath"mcfunctions.sh" $1 $2 $3
}

doMCStart() {
	if [[ -z $mcServer ]];then
		echo -e "${lred}[ERROR/Start]: ${norm}-> Kein Server ausgewählt! Command nicht möglich."
	else
		getFunction checkConditions
		if [[ $StartIsEnabled == missingJar ]];then
			echo -e "${lred}[ERROR/Start]: ${norm}-> Keine <$jarName> gefunden!"
		elif [[ $StartIsEnabled == isRunning ]];then
			echo -e "${lgreen}[INFO/Start]: ${norm}-> Server ${lblue}[$mcServer] ${norm}läuft bereits."
		elif [[ $StartIsEnabled == doNewInstall ]];then
			echo -e "${lgreen}[INFO/Start]: ${norm}-> Installiere Server..."
			getMCFunction installMC
			clear
			if [[ -z $cancel ]];then
				echo -e "${lgreen}[DONE/Start]: ${norm}-> Neue Server-Installation vollendet!"
				echo -e ">> IP [$internalIP] Port [$stdMCPort]"
			else
				echo -e "$cancelReason"
			fi
		elif [[ $StartIsEnabled == noStart ]];then
			getFunction setBackupConf Autostart true
			getFunction startMCScreen
			getFunction detachMCScreen
			getFunction attachMCScreen
			clear
			echo -e "${lgreen}[DONE/Start]: ${norm}-> Server ${lblue}[$mcServer] ${norm}wurde gestartet!"
		else
			echo -e "${lred}[ERROR/Start]: ${norm}-> Fehler [$StartIsEnabled]"
		fi
		
	fi
}

doMCRestart() {
	if [ -z $mcServer ];then
		echo -e "${lred}[ERROR/Restart]: ${norm}-> Kein Server ausgewählt! Command nicht möglich. Nutze ${yellow}ServerWahl${norm}..."
	else
		if $(screen -ls | grep -q MCS_$mcServer);then
			getFunction detachMCScreen
			getFunction attachMCScreen
			getFunction getSTDFiles
			getFunction readBackupConf
			if [[ $doAutostart == true ]];then
				getMCFunction getOnlinePlayers
				if [[ $onlinePlayersCount == 0 ]];then
					echo -e "${yellow}> Keine Spieler online. Stoppe Server..."
					echo -e "${lgreen}[DONE/Restart]: ${norm}-> Server [$mcServer] wird neu gestartet..."
					getMCFunction MCStop
				else
					prefix=[Terminal]
					text="Manueller Restart!"
					getMCFunction sendText
					headerText="${yellow}>> Manueller Restart!"
					timerText="bis zum Restart des Servers..."
					getMCFunction doTimedStop &
					getFunction showTimer 30
					if [[ $cancel == cancelled ]];then
						clear
						text="Shutdown abgebrochen..."
						sendText
						echo -e "${lred}[ABGEBROCHEN/Restart]: ${norm}-> Restart Abgrebrochen! Der Server wird ${lred}nicht ${norm}gestoppt!"
						return 1
					fi
					sleep 2 && getFunction setBackupConf Autostart true &
					clear
					echo -e "${lgreen}[DONE/Restart]: ${norm}-> Server [$mcServer] wird neu gestartet..."
					echo -e "> $onlinePlayersCount Spieler waren online"
				fi
			else
				echo -e "${lred}[ERROR/Restart]: ${norm}-> Server ist gestoppt! Nutze ${yellow}Start ${norm}!"
			fi
		else
			echo -e "${lred}[ERROR/Restart]: ${norm}-> Screen ist nicht aktiv! Nutze ${yellow}Start ${norm}!"
		fi		
	fi
}

doMCStop() {
	if [ -z $mcServer ];then
		echo -e "${lred}[ERROR/Stop]${norm}: -> Kein Server ausgewählt! Command nicht möglich. Nutze ${yellow}ServerWahl${norm}..."
	else
		if $(screen -ls | grep -q MCS_$mcServer);then
			getFunction detachMCScreen
			getFunction attachMCScreen
			getFunction getSTDFiles
			getFunction readBackupConf
			if [[ $doAutostart == true ]];then
				getMCFunction getOnlinePlayers
				if [[ $onlinePlayersCount == 0 ]];then
					getMCFunction MCStop
					getFunction setBackupConf Autostart false
					clear
					echo -e "${lgreen}[DONE/Restart]: ${norm}-> Server [$mcServer] wurde gestoppt! (0 Spieler online)"
				else
					prefix=[Terminal]
					text="Manueller Shutdown!"
					getMCFunction sendText
					headerText="${yellow}>> Manueller Stop! $onlinePlayersCount Spieler online"
					timerText="bis zum Stop des Servers..."
					getMCFunction doTimedStop &
					getFunction showTimer 30
					if [[ $cancel == cancelled ]];then
						clear
						text="Shutdown abgebrochen..."
						sendText
						echo -e "${lred}[ABGEBROCHEN/Stop]: ${norm}-> Stop Abgrebrochen! Der Server wird ${lred}nicht ${norm}gestoppt!"
						return 1
					fi
					clear
					echo -e "${lgreen}[DONE/Stop]: ${norm}-> Server [$mcServer] wurde gestoppt..."
					echo -e "> $onlinePlayersCount Spieler waren online"
				fi
			else
				echo -e "${lred}[ERROR/Stop]${norm} -> Server [$mcServer] ist bereits gestoppt!"
			fi
		else
			echo -e "${lred}[ERROR/Stop]${norm} -> Server [$mcServer] ist nicht aktiv!"
		fi
	fi
}

doServerCheck() {
	if [ -z $mcServer ];then
		echo -e "${lred}[ERROR/ServerCheck]${norm}: -> Kein Server ausgewählt! Command nicht möglich.${norm}"
		return 1
	elif [[ -z $(screen -ls | grep MCS_$mcServer ) ]];then
		echo -e "${lgreen}[INFO/ServerCheck]${norm}: -> Server wurde nicht gestartet...(kein Terminal)${norm}"
		return 1
	else
		getFunction readBackupConf
	fi
	if [[ $doAutostart == false ]];then
		echo -e "${lgreen}[INFO/ServerCheck]${norm}: -> Server wurde gestoppt... (autorestart=false)${norm}"
	else
		getFunction getSTDFiles
		getFunction readProperties
		if ! [[ -z $MCip ]] && ! [[ -z $MCport ]];then
			echo -e "${yellow}> Starte API-Abfrage..."
			getMCFunction doMCPing $MCip $MCport
			if [[ $pingResponse == true ]];then
				getFunction readMCPing
				clear
				echo -e "${lgreen}[DONE/ServerCheck]: ${norm}-> Server ${lblue}[$mcServer]${norm} wurde geprüft..."
				echo -e "${yellow}-----------------------------------------------------------------------------------"
				echo -e "${lgreen}[$mcServer]: online"	
				echo -e "${lgreen}[Spieler]: $onlinePlayersCount / $maxPlayersCount"
				echo -e "${lgreen}[Version]: $versionString"
			else
				echo -e "${lred}[ERROR/ServerCheck]${norm}: -> Server ist offline...${norm}"
			fi
		else
			echo -e "${lred}[ERROR/ServerCheck]${norm}: -> Kein Server ausgewählt! Command nicht möglich.${norm}"
		fi
	fi
}

doPingOther() {
	if [[ -z $varIP ]];then
		echo -e "${lred}[ERROR/pingOther]${norm}: -> Keine IP! Command nicht möglich.${norm}"
		return 1
	elif [[ -z $varPort ]];then
		getMCFunction doMCPing $varIP
	else
		getMCFunction doMCPing $varIP $varPort
	fi
	if [[ $pingResponse == true ]];then
		getFunction readMCPing
		clear
		echo -e "${lgreen}[DONE/pingOther]: ${norm}-> Server ${lblue}[$varIP]${norm} wurde geprüft..."
		echo -e "${yellow}-----------------------------------------------------------------------------------"
		echo -e "${lgreen}[$varIP]: online"	
		echo -e "${lgreen}[Spieler]: $onlinePlayersCount / $maxPlayersCount"
		echo -e "${lgreen}[Version]: $versionString"
		unset varIP && unset varPort
	fi
}

InputBoolean() {
	echo -e "${yellow}[Terminal/SetConfig] Warte auf Eingabe...${norm}"
	echo -e "${yellow}-> true, false${norm}"
	read INPUT_STRING
	case $INPUT_STRING in
		true)
			Boolean=true
		;;
		false)
			Boolean=false
		;;
		*)
			clear
			unset Boolean
			echo -e "${lred}[ERROR/InputBoolean]: ${norm}-> <$INPUT_STRING> ist falsch! (true/false)"
		;;
	esac
}

sendText() {
	getFunction getBackupConfig
	getFunction readBackupConf
	if [[ $doAutostart == false ]];then
		echo -e "${lred}[ERROR/sendText]${norm} -> Server <$mcServer> ist gestoppt!"
	else
		echo -e "${yellow}Gib den Text ein:${norm}"
		read text
		if ! [[ -z $text ]];then
			clear
			echo -e "[Text]: $text"
			echo -e "${yellow}Text an Server [$mcServer] senden? (y/n)${norm}"
			read inputBoolean
			case $inputBoolean in
# type y, or yes or yjhdlfhjdghl
				y*)
					prefix=[Terminal]
					getMCFunction sendText
					clear
					echo -e "${lgreen}[DONE/SendText]: ${norm}-> Text wurde gesendet!"
				;;
				*)
					echo -e "Abgebrochen"
				;;
			esac
		else
			clear
		fi
	fi
}

readConfig() {
	echo -e "${lblue}-------------------------------------${norm}"
	echo -e "${lblue}-${norm}${lined}${bold}BackupConfig.txt${norm} [$mcServer]"
	n=0
	cat $bkupconfig | while read line; do
		n=$((n+1))
		echo -e "${lblue}-${norm}[Zeile$n] $line"
	done
	echo -e "${lblue}-------------------------------------${norm}"
}

checkConfig() {
	if [ -z $mcServer ];then
		echo -e "${lred}[ERROR]${norm}: -> Kein Server ausgewählt! Command nicht möglich."
	else
		getFunction getBackupConfig
		if [[ -f $bkupconfig ]];then
			readConfig
		else
			echo -e "${lred}[ERROR/CheckConfig]: ${norm}-> Datei <backup.config> wurde nicht gefunden!"
		fi
	fi
}

setConfig() {
	if [ -z $mcServer ];then
		echo -e "${lred}[ERROR]${norm}: -> Kein Server ausgewählt! Command nicht möglich."
	else
		getFunction getBackupConfig
		if [[ -z $bkupconfig ]];then
			echo -e "${lred}[ERROR/SetConfig]: ${norm}-> Datei <backup.config> wurde nicht gefunden!"
		else
			echo -e "Server ausgewählt: ${lblue}[$mcServer]${norm}"
			echo -e "${yellow}[Terminal/SetConfig] Warte auf Eingabe...${norm}"
			echo -e "${yellow}-> autostart, backup${norm}"
			read INPUT_STRING
			case $INPUT_STRING in
				autostart)
					InputBoolean
					if ! [[ -z $Boolean ]];then
						clear
						getFunction setBackupConf Autostart $Boolean
						echo -e "${lgreen}[INFO/SetConfig]: ${norm}-> Autostart ist nun <$Boolean>..."
					fi
				;;
				backup)
					InputBoolean
					if ! [[ -z $Boolean ]];then
						clear
						getFunction setBackupConf Backup $Boolean
						echo -e "${lgreen}[INFO/SetConfig]: ${norm}-> Backup ist nun <$Boolean>..."
					fi
				;;
				*)
					echo -e "${lred}[ERROR/SetConfig]: ${norm}-> <$INPUT_STRING> ist falsch!"
				;;
			esac
		fi
	fi
}

getMCPort() {
	if [ -z $mcServer ];then
		echo -e "${lred}[ERROR]${norm}: -> Kein Server ausgewählt! Command nicht möglich."
	else
		getFunction getProperties
		if [[ -f $mcSrvProperties ]];then
			getFunction readProperties
			if [[ $MCport == empty ]];then
				echo -e "${lred}[INFO/GetPort]: ${norm}-> Der Eintrag für den Port von ${lblue}[$mcServer] ${norm}ist leer! Nutze ${yellow}SetPort${norm}..."
			else
				echo -e "${lgreen}[INFO/GetPort]: ${norm}-> Der aktuelle Port von ${lblue}[$mcServer] ${norm}ist ${lgreen}[$MCport]${norm}"
			fi
		else
			echo -e "${lred}[ERROR/GetPort]${norm}: -> Datei <server.properties> nicht vorhanden!"
		fi
	fi
}

ServerList() {
	echo "Server-Liste:"
	count=0
	countSlashes=$(echo $mcDir | grep -o "/" | wc -l)
	lastSlash=$(( countSlashes +1 ))
	for mcServer in $(ls -d "$mcDir"*/ | cut -f$lastSlash -d'/');do
		getFunction getBackupConfig
		count=$(( n+1))
		MCS="MCS_$mcServer"
		if [[ -f $bkupconfig ]];then
			getFunction readBackupConf
			if [[ $doAutostart == true ]];then
				isRunning="${green}Server aktiv!"
			else
				isRunning="${lred}Server gestoppt!"
			fi
			if $(screen -ls | grep -q $MCS);then
				activTerminal="${green}Terminal aktiv!"
			else
				activTerminal="${lred}Terminal inaktiv!"
			fi
			echo -e "Server$count: ${lblue}[$mcServer]  $isRunning $activTerminal ${norm}"
		else
			echo -e "Server$count: ${lblue}[$mcServer] ${red}keine Config! ${norm}"
		fi
		unset doAutostart
	done
}

ServerWahl() {
	ServerList
	echo -e "${yellow}-----------------------------------------------------------------------------------"
	echo -e "${yellow}[Terminal:ServerWahl] Warte auf Eingabe...${norm}"
	read INPUT_STRING
	if [ -z $INPUT_STRING ];then
		clear
	elif [ -d $mcDir$INPUT_STRING/ ];then
		mcServer=$INPUT_STRING
		clear
		getFunction attachMCScreen
		echo -e "${lgreen}[INFO]: ${norm}-> Server ${lblue}[$INPUT_STRING] ${norm}wurde ausgewählt!"
	else
		clear
		echo -e "${lred}[ERROR] Falsche Eingabe!${norm} -> $INPUT_STRING"
	fi
}

stdPrintText() {
	echo -e "${yellow}-----------------------------------------------------------------------------------"
	if [ -z $mcServer ];then
		echo -e "${lred}[WARNUNG]${norm}: -> Du hast keinen Server ausgewählt!"
	else
		echo -e "Server ausgewählt: ${lblue}[$mcServer]${norm}"
	fi
	echo -e "${yellow}[Terminal] Warte auf Eingabe..."
	echo -e "-> ServerList, ServerWahl, ServerCheck, pingOther, GetScreen, doBackup"
	echo -e "-> Start, Stop, Restart, SendText, CheckConfig, SetConfig, GetPort, cpu${norm}"
}

htop() {
	if [[ $(pgrep -c htop) == 0 ]];then
		tmux send-key -t Terminal:0.2 "htop" C-m
	else
		tmux send-key -t Terminal:0.2 "q"
	fi
}

$ExecuteCommand $Argument2 $Argument3

