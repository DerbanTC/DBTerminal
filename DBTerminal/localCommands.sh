#!/bin/bash

grepExtern() {
	if ! [[ -z $1 ]];then
		mcName=$1
		varPath="$(dirname "$(readlink -fn "$0")")/"
		cd $varPath
		source ./stdvariables.sh
		source ./inject.sh
	fi
}

### STD COMMANDS
ServerList() {
	dataFunction readDBTData && dataFunction setLocalData
	n=0 && while IFS= read -a line; do
		n=$(( n + 1 ))
		dataFunction readLocalData $n
		if [[ -z $notedIP ]];then
			lastListMsg="${lblue}[$n] ${norm}>> ${lblue}[$mcName] ${red}nicht installiert${norm}"
		elif [[ $isRunning == false ]];then
			lastListMsg="${lblue}[$n] ${norm}>> ${lblue}[$mcName] ${lred}inaktiv${norm}\n$(addSpace 5)>> [$notedIP:$notedPort] [Autobackup=$doBackup]"
		else
			lastListMsg="${lblue}[$n] ${norm}>> ${lblue}[$mcName] ${lgreen}aktiv\n$(addSpace 5)>> ${norm}[$notedIP:$notedPort] [Autobackup=$doBackup]"
		fi
		declare -g "magic_variable_$n=$(echo -e "$lastListMsg")"
	done < "$localData"
	unset lastListMsg && listMsgHeader="${yellow}Server-Liste:${norm}"
}

ServerWahl() {
	unset answer
	while [[ -z $answer ]];do
		ServerList && getFunction printLastMSG
		maxEntries=$(grep -c "$internalIP," $localData)
		echo -e "${yellow}[Terminal/ServerWahl]: -> Warte auf Eingabe... (1-$maxEntries)${norm}"
		read INPUT_STRING
		pattern="^[1-9]$|^[1-9][0-9]$"
		if [[ -z $INPUT_STRING ]];then
			clear && answer=null && unset mcName
		elif [[ $INPUT_STRING =~ $pattern ]] && ! [[ $INPUT_STRING -gt $maxEntries ]];then
			dataFunction readLocalData $INPUT_STRING
			dataFunction setDBTData MCServer $INPUT_STRING
			getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName
			answer=$INPUT_STRING && clear
			lastMsg="${lgreen}[DONE]: ${norm}-> Server ${lblue}[$INPUT_STRING] [$mcName] ${norm}wurde ausgewählt!"
		else 
			lastMsg="${lred}[ERROR]: ${norm}-> [$INPUT_STRING] Falsche Eingabe (1-$maxEntries)!" && printSTD
		fi
	done
}

### MC COMMANDS
doMCStart() {
	if [[ -z $mcName ]];then
		lastMsg="${lred}[ERROR/Start]: ${norm}-> Kein Server ausgewählt! Command nicht möglich." && return 1
	fi
	getFunction checkConditions
	if [[ $StartIsEnabled =~ missingJar ]];then
		lastMsg="${lred}[ERROR/Start]: ${norm}-> Keine <$jarName> gefunden!"
	elif [[ $StartIsEnabled =~ isRunning ]];then
		lastMsg="${lgreen}[INFO/Start]: ${norm}-> Server ${lblue}[$mcName] ${norm}läuft bereits."
		getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName	
	elif [[ $StartIsEnabled == noStart ]];then
		getMCFunction startMCScreen
		getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName	
		lastMsg="${lgreen}[DONE/Start]: ${norm}-> Server ${lblue}[$mcName] ${norm}wird gestartet!"
	elif [[ $StartIsEnabled =~ doNewInstall ]];then
		echo -e "${lgreen}[INFO/Start]: ${norm}-> Installiere Server..." && printSTD
		getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName	
		getFunction waitUntilScreen "MCS_$mcName" &
		getMCFunction installMC
	else
		lastMsg="> ERROR unknown state Code [doMCStrt_001]"
	fi

}

doMCStop() {
	if [[ -z $mcName ]];then
		lastMsg="${lred}[ERROR/Start]: ${norm}-> Kein Server ausgewählt! Command nicht möglich."
	else 
		getFunction getSTDFiles && getFunction readMCBackupConf
		getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName
		if ! $(screen -ls | grep -q MCS_$mcName);then
			lastMsg="${lred}[ERROR/Stop]${norm} -> Server [$mcName] ist bereits gestoppt!"
		else
			getMCFunction getOnlinePlayers
			if [[ $onlinePlayersCount == 0 ]] || [[ $onlinePlayersCount == null ]];then
				getMCFunction stopMC && clear
				lastMsg="${lgreen}[DONE/Stop]: ${norm}-> Server [$mcName] wurde gestoppt! (0 Spieler online)"
			else
				getMCFunction doTimedStop && clear
				if [[ $cancel == true ]];then
					text="Shutdown abgebrochen..." && getMCFunction sendText
					lastMsg="${lred}[ABGEBROCHEN/Stop]: ${norm}-> Stop Abgrebrochen! Der Server wird ${lred}nicht ${norm}gestoppt!"
				else
					lastMsg="${lgreen}[DONE/Stop]: ${norm}-> Server [$mcName] wurde gestoppt...\n> $onlinePlayersCount Spieler waren online!"
				fi
			fi
		fi
	fi
}

doMCRestart() {
	if [[ -z $mcName ]];then
		lastMsg="${lred}[ERROR/Restart]: ${norm}-> Kein Server ausgewählt! Command nicht möglich."
	else
		getFunction checkConditions
		getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName
		if ! $(screen -ls | grep -q MCS_$mcName) || [[ $doAutostart == false ]];then
			lastMsg="${lred}[ERROR/Restart]${norm} -> Server [$mcName] ist bereits gestoppt!"
		else
			getMCFunction getOnlinePlayers
			if [[ $onlinePlayersCount == 0 ]];then
				getMCFunction stopMC && setMCBackupConf Autostart true && clear
				echo -e "${lgreen}[DONE/Restart]: ${norm}-> Server [$mcName] wurde gestoppt! (0 Spieler online)"
			else
				getMCFunction doTimedStop && setMCBackupConf Autostart true && clear
				if [[ $cancel == true ]];then
					text="Shutdown abgebrochen..."
					getMCFunction sendText
					lastMsg="${lred}[ABGEBROCHEN/Stop]: ${norm}-> Stop Abgrebrochen! Der Server wird ${lred}nicht ${norm}gestoppt!"
				else
					lastMsg="${lgreen}[DONE/Stop]: ${norm}-> Server [$mcName] wurde gestoppt...\n> $onlinePlayersCount Spieler waren online!"
				fi
			fi
		fi
	fi
}

sendText() {
	grepExtern $1 && getFunction readMCBackupConf
	if [[ -z $mcName ]];then
		lastMsg="${lred}[ERROR/Restart]${norm}: -> Kein Server ausgewählt! Command nicht möglich.${norm}"
	elif ! $(screen -ls | grep -q MCS_$mcName) || [[ $doAutostart == false ]];then
		lastMsg="${lred}[ERROR/Restart]${norm} -> Server [$mcName] ist bereits gestoppt!"
	else
		if [[ -z $1 ]];then
			getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName
		fi
		echo -e "${yellow}Gib den Text ein:${norm}"
		read text
		if [[ -z $text ]];then
			lastMsg="[SendText]: -> ${lred}abgebrochen..." && clear
		else
			echo -e "${yellow}> [Text]: $text\n> Text an Server [$mcName] senden? (y/n)${norm}"
			read inputBoolean
			case $inputBoolean in
				y*)
					prefix=[Terminal] && getMCFunction sendText
					lastMsg="${lgreen}[DONE/SendText]: ${norm}-> Text wurde gesendet!\n> $text" && clear
				;;
				*)
					lastMsg="${yellow}[SendText]: -> ${lred}abgebrochen..." && clear
				;;
			esac
		fi
	fi
	if ! [[ -z $1 ]];then
		local file="$SelfPath"tmp/lastSendText@$mcName
		echo -e "$lastMsg" > $file
	fi
}

doServerCheck() {
	if [[ -z $mcName ]] || [[ -z $selectedMCSrv ]];then
		lastMsg="${lred}[ERROR/ServerCheck]: ${norm}-> Kein Server ausgewählt! Command nicht möglich.${norm}"
		return 1
	elif [[ -z $isRunning ]];then
		lastMsg="${lgreen}[INFO/ServerCheck]: ${norm}-> Server [$mcName] ist ${red}nicht installiert!${norm}"
		return 1
	elif [[ $isRunning == false ]];then
		lastMsg="${lgreen}[INFO/ServerCheck]: ${norm}-> Server [$mcName] ist ${lred}gestoppt!${norm}"
		return 1
	elif [[ -z $notedIP ]] && [[ -z $notedPort ]] || [[ -z $notedIP ]];then
		lastMsg="${lred}[ERROR/ServerCheck]: ${norm}-> Keine IP [$notedIP] oder Port [$notedPort] notiert!${norm}"
		return 1
	fi
	echo -e "${yellow}> Starte API-Abfrage..."
	getMCFunction doMCPing $notedIP $notedPort
	if [[ $pingResponse == true ]];then
		getFunction readMCPing && clear
		lastMsg="${lgreen}[DONE/pingOther]: ${norm}-> Server ${lblue}[$varIP]${norm} wurde geprüft..."
		varText="${lgreen}[$varIP]: online\n[Spieler]: $onlinePlayersCount / $maxPlayersCount\n[Version]: $versionString $softwareString"
		declare -g "magic_variable_1=$(echo -e "$varText")"
		unset varIP && unset varPort
	else
		lastMsg="${lred}[ERROR/ServerCheck]${norm}: -> Server ist offline...${norm}"
	fi
}

doPingOther() {
	varIP=$1 && varPort==$2
	if [[ -z $varIP ]];then
		lastMsg="${lred}[ERROR/pingOther]${norm}: -> Keine IP! Command nicht möglich.${norm}" && return 1
	elif [[ -z $varPort ]];then
		getMCFunction doMCPing $varIP
	else
		getMCFunction doMCPing $varIP $varPort
	fi
	if [[ $pingResponse == true ]];then
		getFunction readMCPing && clear
		lastMsg="${lgreen}[DONE/pingOther]: ${norm}-> Server ${lblue}[$varIP]${norm} wurde geprüft..."
		varText="${lgreen}[$varIP]: online\n[Spieler]: $onlinePlayersCount / $maxPlayersCount\n[Version]: $versionString $softwareString"
		declare -g "magic_variable_1=$(echo -e "$varText")"
		unset varIP && unset varPort
	fi
}

mcConfig() {
	grepExtern $1
	if [[ -z $mcName ]];then
		lastMsg="${lred}[ERROR/mcConfig]: ${norm}-> Kein Server ausgewählt! Command nicht möglich."
	else
		while true;do
			askMCConfHeader() {
				 printFunction printHeader && printSTD && getFunction printMCConfig && printLastMessage && getFunction readMCBackupConf
			}
			mcConfigSetBackup() {
				clear && dataFunction readLocalConf
				askMCConfHeader
				askQuestion2 true false "${yellow}[Terminal/backup]: -> Bitte gib einen neuen Wert für Backup an! ${norm}(aktuell $doBackup)" backup
				if [[ -z $askedAnswer ]];then
					return 1
				elif [[ $askedAnswer == true ]] && ! [[ $doBackup == true ]];then
					getFunction setMCBackupConf Backup $askedAnswer
					lastMsg="${lgreen}[DONE/backup]: ${norm}-> [backup] von [$mcName] wurde auf [$askedAnswer] gesetzt!"
				elif [[ $askedAnswer == false ]] && ! [[ $doBackup == false ]];then
					getFunction setMCBackupConf Backup $askedAnswer
					lastMsg="${lgreen}[DONE/backup]: ${norm}-> [backup] von [$mcName] wurde auf [$askedAnswer] gesetzt!"
				else
					lastMsg="${lred}[ERROR/backup]: ${norm}-> [backup] von [$mcName] ist bereits [${lred}$askedAnswer${norm}]!"	
				fi && unset askedAnswer
			}
			mcConfigSetAutostart() {
				askMCConfHeader
				askQuestion2 true false "${yellow}[Terminal/autorestart]: -> Bitte gib einen neuen Wert für Autorestart an! ${norm}(aktuell $doAutostart)" autorestart
				if [[ -z $askedAnswer ]];then
					return 1
				elif [[ $askedAnswer == true ]] && ! [[ $doAutostart == true ]];then
					getFunction setMCBackupConf Autostart $askedAnswer
					lastMsg="${lgreen}[DONE/autorestart]: ${norm}-> [autorestart] von [$mcName] wurde auf [$askedAnswer] gesetzt!"
				elif [[ $askedAnswer == false ]] && ! [[ $doAutostart == false ]];then
					getFunction setMCBackupConf Autostart $askedAnswer
					lastMsg="${lgreen}[DONE/autorestart]: ${norm}-> [autorestart] von [$mcName] wurde auf [$askedAnswer] gesetzt!"
				else
					lastMsg="${lred}[ERROR/autorestart]: ${norm}-> [autorestart] von [$mcName] ist bereits [${lred}$askedAnswer${norm}]!"	
				fi && unset askedAnswer
			}
			mcConfigBackupTime() {
				dataFunction readLocalConf
				askMCConfHeader
				if [[ $localBackupMode == sync ]];then
					local a="> ${lred}WARNUNG ${yellow}-> Synchroner Modus! "
					askQuestionWarning="$a\n> Eine Änderung setzt den Modus automatisch auf Asynchron..."
				fi
				askQuestionTime "${yellow}[Terminal/backuptime]: -> Bitte gib eine neue Zeit für das Backup an! ${norm}(aktuell $BackupTime)" backup
				if [[ -z $askedAnswerTime ]];then
					return 1
				elif ! [[ $askedAnswerTime == $BackupTime ]];then
					getFunction setMCBackupConf BackupTime $askedAnswerTime
					lastMsg="${lgreen}[DONE/backuptime]: ${norm}-> [backuptime] von [$mcName] wurde auf [$askedAnswerTime] gesetzt!"
				else
					lastMsg="${lred}[ERROR/backuptime]: ${norm}-> [backuptime] von [$mcName] ist bereits [${lred}$askedAnswerTime${norm}]!"	
				fi && unset askedAnswerTime
			}

			getBackupFunction updateCronJob &
			askMCConfHeader
			echo -e "${yellow}[Terminal/mcConfig] Warte auf Eingabe...\n-> backup, autorestart, backuptime${norm}"
			read USER_INPUT
			case $USER_INPUT in
				backup)
					mcConfigSetBackup
				;;
				autorestart)
					mcConfigSetAutostart
				;;
				backuptime)
					mcConfigBackupTime
				;;
				*)
					if [[ -z $USER_INPUT ]];then 
						clear && return 1
					fi
					clear && lastMsg="${lred}[ERROR/mcConfig]: ${norm}-> [${lred}$USER_INPUT${norm}] ist falsch!"
				;;
			esac

		done
	fi
}

downloadMC() {
	askServerVersion() {
		unset ServerVersion && while [[ -z $ServerVersion ]] && [[ -z $stopFunction ]];do
			clear && printFunction printHeader && printFunction printSTD && printFunction printAvaibleVersions $ServerType && printLastMSG
			if ! [[ -z $askQuestionWarning ]];then echo -e "$askQuestionWarning" && printSTD;fi
			echo -e "${yellow}[Terminal/downloadMC]: Wähle die Server-Version" && printSTD
			echo -e "${yellow}[Terminal/downloadMC]: Warte auf Eingabe...${norm}"
			read newServerVersion
			if [[ -z $newServerVersion ]];then stopFunction=true && unset askQuestionWarning && return 1;fi
			if [[ -z $(grep -o "\"$newServerVersion\"" $jsonFile) ]];then
				lastMsg="> Server version not avaible!"
			else
				ServerVersion=$newServerVersion
			fi
		done
	}
	askServerType() {
		unset ServerType && while [[ -z $ServerType ]] && [[ -z $stopFunction ]];do
			clear && printFunction printHeader && printFunction printSTD && printFunction printLastMSG 
			if ! [[ -z $askQuestionWarning ]];then echo -e "$askQuestionWarning" && printFunction printSTD;fi
			echo -e "${yellow}[Terminal/downloadMC]: Wähle den Server-Typ" && printFunction printSTD
			echo -e "${yellow}[Terminal/downloadMC]: Warte auf Eingabe..."
			echo -e "${yellow}-> Paper, Waterfall (bungee from paper)${norm}"
			read newServerType
			case $newServerType in
				Paper)
					ServerType=Paper
				;;
				Waterfall)
					ServerType=Waterfall
				;;
				*)
					if [[ -z $newServerType ]];then stopFunction=true && unset askQuestionWarning && return 1;fi
					lastMsg="> Sorry, coming soon... actually only paper avaible"
				;;
			esac
		done
	}
	askServerName() {
		unset newMCDir && while [[ -z $newMCDir ]] && [[ -z $stopFunction ]];do
			clear && printFunction printHeader && printFunction printSTD && printFunction printLastMSG
			echo -e "${yellow}[Terminal/downloadMC]: Wähle einen Namen für den MC-Server (YourServer, Bungee, etc.)" && printFunction printSTD
			echo -e "${yellow}[Terminal/$internCommand]: Warte auf Eingabe...${norm}"
			read newMCName
			if [[ -z $newMCName ]];then stopFunction=true && return 1;fi
			if [[ $str == *['!'@#\$%^\&*()_+]* ]];then
				clear && lastMsg="${lred}[ERROR/mcConfig]: ${norm}-> Keine Spezial-Zeichen!"
			else
				newMCName=$newMCName
				newMCDir="$mcDir"$newMCName
			fi
		done
	}
	unset stopFunction && while [[ -z $stopFunction ]];do
		askServerName
		local jarFile=""$newMCDir"/minecraft_server.jar"
		if [[ -f $jarFile ]];then
			askQuestionWarning="${lred}> Warnung! ${norm}-> Datei [$jarFile] bereits vorhanden!"
			askQuestion2 yes no "Weiterfahren?"
			if ! [[ $askedAnswer == yes ]];then stopFunction=true && return 1;fi
		fi
		askServerType
		askServerVersion
		if ! [[ -z $stopFunction ]];then return 1;fi
		getMCFunction downloadMCjar "$newMCName" "$ServerVersion" "$ServerType"
		local file="$newMCDir/minecraft_server.jar"
		if [[ -f $file ]];then
			lastMsg="${lgreen}[DONE/downloadMC]: ${norm}-> Download für [$newMCName] erfolgreich!\n> Nutze ${lblue}ServerWahl${norm} um den Server auszuwählen..."
		else
			lastMsg="${lred}[ERROR/downloadMC]: ${norm}-> Download fehlgeschlagen!${norm}"
		fi
		unset askQuestionWarning && return 1
	done
}

### DBT COMMANDS
GetScreen() {
	if [[ -z $mcName ]] || [[ -z $selectedMCSrv ]];then
		lastMsg="${lred}[ERROR/GetScreen]: ${norm}-> Kein Server ausgewählt! Command nicht möglich.${norm}"
	elif [[ -z $(screen -ls | grep "MCS_$mcName") ]];then
		lastMsg="${lred}[ERROR/GetScreen]: ${norm}-> Screen [MCS_$mcName] nicht gefunden!"
	elif ! [[ -z $(ps aux | grep ssh | grep "MCS_$mcName") ]];then
		screen -d "MCS_$mcName" && getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName	
		lastMsg="${lgreen}[DONE/GetScreen]: ${norm}-> Screen [MCS_$mcName] wird recordet!${norm}\n> ${lred}WARNUNG: ${norm}-> Externe Verbindung wurde beendet!"
	elif ! [[ -z $(screen -ls | grep "MCS_$mcName" | grep Attached) ]] && ! [[ $selectedTMUX02 == "screen,intern,MCS_$mcName	" ]];then
		screen -d "MCS_$mcName" && getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName	
		lastMsg="${lgreen}[DONE/GetScreen]: ${norm}-> Screen [MCS_$mcName] wird recordet!${norm}\n> ${lred}WARNUNG: ${norm}-> Internes Screen-Recording (screen -r) wurde beendet!"
	elif ! [[ -z $(screen -ls | grep "MCS_$mcName" | grep Detached) ]];then
		lastMsg="${lgreen}[DONE/GetScreen]: ${norm}-> Screen [MCS_$mcName] wird recordet!${norm}"
		getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName &
	fi
}

htop() {
	readDBTData && newDBTEntry=htop,intern
	if ! [[ -z $(tmux capture-pane -pt "Terminal:0.2" -S -1 | grep -oF "SHR S CPU% MEM%") ]];then
		lastMsg="${lgreen}[DONE/CPU]: ${norm}-> CPU-Anzeige geschlossen!"
		newDBTEntry=
	else
		lastMsg="${lgreen}[DONE/CPU]: ${norm}-> CPU wird angezeigt!"
	fi
	getFunction changeTerminal TMUX02 $newDBTEntry &
}

### BACKUP COMMANDS
BackupCommands() {
	askLocalConfHeader() {
		printHeader && printSTD && printLocalBackupConf && 
		getFunction printLastMSG && dataFunction readLocalConf
	}
	askMCConfHeader() {
		printFunction printHeader && printFunction printSTD && getFunction printMCConfigALL && 
		getFunction printLastMSG && getFunction readMCBackupConf
	}
	
	setMCDailyBackup() {
		(
			clear && readLocalData $selectedMCSrv
			if [[ $doBackup == true ]];then
				askQuestion2 yes no "${yellow}[Terminal/backup]: -> Tägliche Backups für [$mcName] ${lred}deaktivieren${yellow}?" DailyBackup
			elif [[ $doBackup == false ]];then
				askQuestion2 yes no "${yellow}[Terminal/backup]: -> Tägliche Backups für [$mcName] ${lgreen}aktivieren${yellow}?" DailyBackup
			elif [[ -z $doBackup ]];then
				lastMsg="${lred}[ERROR/DailyBackup]: ${norm}-> Server [$mcName] wurde nie oder nicht korrekt gestartet!"
			fi
			
			if [[ $askedAnswer == yes ]] && [[ $doBackup == true ]];then
				setMCBackupConf Backup false
				setLocalData
				lastMsg="${lgreen}[DONE/backup]: ${norm}-> [backup] von [$mcName] wurde auf [$askedAnswer] gesetzt!"
			elif [[ $askedAnswer == yes ]] && [[ $doBackup == false ]];then
				setMCBackupConf Backup true
				setLocalData
				lastMsg="${lgreen}[DONE/backup]: ${norm}-> [backup] von [$mcName] wurde auf [$askedAnswer] gesetzt!"
			fi && unset askedAnswer
		)
	}
	setMCBackupTime() {
		dataFunction readLocalData $selectedMCSrv
		askQuestionTime "${yellow}[Terminal/setTime]: -> Bitte gib eine neue Zeit an! ${norm}(aktuell $doBackupTime)" setTime
		if [[ -z $askQuestionTime ]];then
			return 1
		elif ! [[ $askedAnswerTime == $doBackupTime ]];then
			setMCBackupConf BackupTime $askedAnswerTime
			setLocalData
			lastMsg="${lgreen}[DONE/syncTime]: ${norm}-> [syncTime] wurde auf [$askedAnswerTime] gesetzt!"
		elif [[ $askedAnswerTime == $doBackupTime ]];then
			lastMsg="${lred}[ERROR/syncTime]: ${norm}-> [syncTime] ist bereits [${lred}$askedAnswerTime${norm}]!"	
		fi && unset askedAnswerTime
		command=printMCConf
	}
	BackupSetConf() {
		while true;do
			printHeader && printSTD && printLastMSG
			echo -e "${yellow}Warte auf Eingabe..."
			echo -e "-> DailyMax, WeeklyMax, DayOfWeek, DayOfMonth${norm}"
			read INPUT_STRING && clear
			case $INPUT_STRING in
				DailyMax)
					askQuestionNumberRange 1 31 "Maximale tägliche Backups aktuell: ${green}$DailyBackupMax" DailyMax
					if ! [[ -z $askedAnswerRange ]];then
						setBackupConf DailyMax $askedAnswerRange
						lastMsg="${lgreen}[DONE/DailyMax]: ${norm}-> Maximale Anzahl von täglichen Backups auf [$askedAnswerRange] gesetzt!"
					else
						return 1
					fi
				;;
				WeeklyMax)
					askQuestionNumberRange 1 52 "Maximale Wöchentliche Backups aktuell: ${green}$WeeklyBackupMax" WeeklyMax
					if ! [[ -z $askedAnswerRange ]];then
						setBackupConf WeeklyMax $askedAnswerRange
						lastMsg="${lgreen}[DONE/WeeklyMax]: ${norm}-> Maximale Anzahl von täglichen Backups auf [$askedAnswerRange] gesetzt!"
					else
						return 1
					fi
				;;
				
				DayOfWeek)
					askQuestionNumberRange 1 7 "Day of Month aktuell: ${green}$WeeklyDay" DayOfWeek
					if ! [[ -z $askedAnswerRange ]];then
						setBackupConf WeeklyDay $askedAnswerRange
						lastMsg="${lgreen}[DONE/DayOfWeek]: ${norm}-> Wöchentliche Kopie wird am [$askedAnswerRange.] Tag der Woche erstellt!"
					else
						return 1
					fi
				;;
				
				DayOfMonth)
					askQuestionNumberRange 1 28 "Day of Month aktuell: ${green}$MonthlyDay" DayOfMonth
					if ! [[ -z $askedAnswerRange ]];then
						setBackupConf MonthlyDay $askedAnswerRange
						lastMsg="${lgreen}[DONE/DayOfMonth]: ${norm}-> Monatliche Kopie wird am [$askedAnswerRange.] Tag des Monat erstellt!"
					else
						return 1
					fi
				;;
				*)
					if [[ -z $INPUT_STRING ]];then
						clear && return 1
					else
						lastMsg="${lred}[ERROR/mcConfig]: ${norm}-> [${lred}$INPUT_STRING${norm}] ist falsch!"
					fi
				;;
			esac
		done
	}
	BackupCMDdoLocalBackup() {
		if [[ -z $mcName ]];then
			lastMsg="${lred}[ERROR/Start]: ${norm}-> Kein Server ausgewählt! Command nicht möglich." && return 1
		else
			local ManuallyBackupDir="$backupDir"local/minecraft/$mcName/manually/
			local varQuestion="${yellow}> Manuelles Backup von [$mcName] erstellen?"
			local varQuestion="$varQuestion\n> Speicher-Ort: ${norm}[$ManuallyBackupDir]${yellow}"
			askQuestion2 yes no "$varQuestion" doBackup
			if [[ $askedAnswer == yes ]];then
				clear && printFunction printHeader && printFunction printSTD && echo -e "${yellow}> Starte Backup von [$mcName]..."
				getBackupFunction cmdBackupManually $mcName && cd $SelfPath
				local varFile="${yellow}> Datei: ${norm}[$varTarFile.gz]"
				local varPath="${yellow}> Pfad: ${norm} [$ManuallyBackupDir]"
				if [[ -f "$varBackupFile" ]];then
					lastMsg="${lgreen}[DONE/doBackup]: ${norm}-> Manuelles Backup von [$mcName] erstellt!\n$varPath\n$varFile${norm}"
				else
					lastMsg="${lred}[ERROR/doBackup]: ${norm}-> Manuelles Backup fehlgeschlagen!${norm}"
				fi
			fi && unset askedAnswer && clear
		fi
	}
	dataFunction updateLocalConf
	local command=printLocalConf
	while true;do
		getBackupFunction updateCronJob &
		if [[ $command = printLocalConf ]];then
			askLocalConfHeader
		else
			askMCConfHeader && local command=printLocalConf
		fi
		echo -e "${yellow}[Terminal/Backup] Warte auf Eingabe...\n-> info, mcCheck, backupConf, doBackup, setBackup, setTime${norm}"
		read INPUT_STRING && clear
		case $INPUT_STRING in
			info)
				clear && getFunction printHelp cmdBackupInfo &
			;;
			mcCheck)
				clear && local command=mcCheck
			;;
			backupConf)
				BackupSetConf
			;;
			doBackup)
				clear && BackupCMDdoLocalBackup
			;;
			setBackup) #done
				clear && setMCDailyBackup $1
				local command=printMCConf
			;;
			setTime) #done
				setMCBackupTime
			;;
			*)
				if [[ -z $INPUT_STRING ]];then clear && return 1;fi
				clear && lastMsg="${lred}[ERROR/mcConfig]: ${norm}-> [${lred}$INPUT_STRING${norm}] ist falsch!"
			;;
		esac
		getBackupFunction updateCronJob &
	done
}

$1 $2 $3 $4 $5
