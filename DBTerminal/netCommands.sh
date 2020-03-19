#!/bin/bash

ExecuteCommand=$1
Argument2=$2
Argument3=$3

### STD COMMANDS
ServerList() {
	local tmpNet="$tmpDir"tmpnet && local x=0
	dataFunction readDBTData
	if [[ $countOfExternServer -gt 0 ]] && [[ -z $1 ]];then
		clear && echo -e "${yellow}[Terminal]: -> Prüfe Netwerk...${norm}"
		dataFunction setNetData
	fi
	echo -e "Nr.@Name@Status@IP:Port@Backup@Location" > $tmpNet
	while IFS= read -a line;do
		local x=$(( x + 1 ))
		dataFunction readNetData $x
		local header="${lblue}[$x] ${norm}>> ${lblue}[$mcName]"
		if [[ -z $notedIP ]];then
			local status="${red}n. installiert${norm}" && local ip="..." && local doBackup="..."
		elif [[ $isRunning == false ]];then
			local status="inaktiv"
			local ip="$notedIP:$notedPort"
		else
			local status="aktiv"
			local ip="$notedIP:$notedPort"
		fi
		echo -e "[$x]@$mcName@$(chColor "$status")@"$ip"@$(chColor "$doBackup")@"$location"" >> $tmpNet
	done < "$netData"
	listMsgHeader="${yellow}Server-Liste:${norm}"
	local n=1 && lastListMsg=$(cat $tmpNet | column -s @ -t) && declare -g "magic_variable_$n=$(echo -e "$lastListMsg")"
}

ServerWahl() {
	unset answer && local y=0 && ServerList
	while [[ -z $answer ]];do
		if [[ $y -gt 0 ]];then clear && ServerList noUpdate;fi
		getFunction printLastMSG && local y=$(( y + 1 ))
		maxEntries=$(grep -Ec "[^-]*,*" $netData)
		echo -e "${yellow}[Terminal/ServerWahl]: -> Warte auf Eingabe... (1-$maxEntries)${norm}"
		read INPUT_STRING
		pattern="^[1-9]$|^[1-9][0-9]$"
		if [[ -z $INPUT_STRING ]];then
			clear && answer=null && unset mcName
		elif [[ $INPUT_STRING =~ $pattern ]] && ! [[ $INPUT_STRING -gt $maxEntries ]];then
			dataFunction readNetData $INPUT_STRING
			dataFunction setDBTData MCServer $INPUT_STRING
			if [[ $location == intern ]];then
				getFunction changeTerminal TMUX00 screen,intern,MCS_$mcName
			else
				getFunction changeTerminal TMUX00 screen,$physisIP,MCS_$mcName
			fi
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
		lastMsg="${lred}[ERROR/Start]: ${norm}-> Kein Server ausgewählt! Command nicht möglich."
	elif [[ $location == intern ]];then
		localCommand doMCStart
	else
		dataFunction updateVarNetData
		dataFunction readNetData $selectedMCSrv
		if [[ $isRunning == true ]];then
			getFunction changeTerminal TMUX00 screen,$physisIP,MCS_$mcName &
			lastMsg="${lgreen}[INFO/Start]: ${norm}-> Server ${lblue}[$mcName] ${norm}läuft bereits."
		elif [[ $isRunning == false ]];then
			waitUntilExternScreen "MCS_$mcName" &
			runExternScript $physisIP mcfunctions.sh startMCScreen $mcName
			dataFunction updateVarNetData
			lastMsg="${lgreen}[DONE/Start]: ${norm}-> Server ${lblue}[$mcName] ${norm}wird gestartet!"
		else
			waitUntilExternScreen "MCS_$mcName" &
			echo -e "${lgreen}[INFO/Start]: ${norm}-> Installiere Server..."
			runExternScript $physisIP mcfunctions.sh installMC $mcName
			dataFunction updateVarNetData
			local a="${lgreen}[DONE/Start]: ${norm}-> Server ${lblue}[$mcName] ${norm}wird installiert..."
			lastMsg="$a\n> Bitte Starte den Server neu (Restart)!"
		fi
	fi
}

doMCStop() {
	if [[ -z $mcName ]];then
		lastMsg="${lred}[ERROR/Stop]: ${norm}-> Kein Server ausgewählt! Command nicht möglich."
	elif [[ $location == intern ]];then
		localCommand doMCStop
	elif [[ $location == extern ]];then
		dataFunction updateVarNetData
		dataFunction readNetData $selectedMCSrv
		getFunction changeTerminal TMUX00 screen,$physisIP,MCS_$mcName
		if [[ $isRunning == false ]];then
			lastMsg="${lred}[ERROR/Stop]${norm} -> Server [$mcName] ist bereits gestoppt!"
		elif [[ $isRunning == true ]];then
			getMCFunction getOnlinePlayers $notedIP $notedPort
			if [[ $onlinePlayersCount == 0 ]] || [[ $onlinePlayersCount == null ]] || [[ -z $onlinePlayersCount ]];then
				lastMsg="${lgreen}[DONE/Stop]: ${norm}-> Server [$mcName] wurde gestoppt! (0 Spieler online)"
				runExternScript $physisIP mcfunctions.sh stopMC $mcName
				dataFunction updateVarNetData
			else
				lastMsg="${lgreen}[DONE/Stop]: ${norm}-> Server [$mcName] wurde gestoppt! ($onlinePlayersCount Spieler online)"
				runExternScript $physisIP mcfunctions.sh doTimedStop $mcName Stop
				dataFunction updateVarNetData
			fi
		else
			lastMsg=">> ERROR no state of isRunning ($isRunning)"
		fi
	fi
}

doMCRestart() {
	if [[ -z $mcName ]];then
		lastMsg="${lred}[ERROR/Restart]: ${norm}-> Kein Server ausgewählt! Command nicht möglich."
	elif [[ $location == intern ]];then
		localCommand doMCRestart
	elif [[ $location == extern ]];then
		dataFunction updateVarNetData
		dataFunction readNetData $selectedMCSrv
		getFunction changeTerminal TMUX00 screen,$physisIP,MCS_$mcName
		if [[ $isRunning == false ]];then
			echo -e "${lred}[ERROR/Restart]${norm} -> Server [$mcName] ist bereits gestoppt!"
		elif [[ $isRunning == true ]];then
			getMCFunction getOnlinePlayers $notedIP $notedPort
			if [[ $onlinePlayersCount == 0 ]] || [[ $onlinePlayersCount == null ]] || [[ -z $onlinePlayersCount ]];then
				runExternScript "$physisIP" mcfunctions.sh stopMC "$mcName"
				runExternScript "$physisIP" functions.sh setMCBackupConf Autostart true "$mcName"
				dataFunction updateVarNetData
				lastMsg="${lgreen}[DONE/Restart]: ${norm}-> Server [$mcName] wurde gestoppt! (0 Spieler online)\n> Server startet in wenigen Sekunden neu..."
			else
				runExternScript "$physisIP" mcfunctions.sh doTimedStop "$mcName" Restart
				runExternScript "$physisIP" functions.sh setMCBackupConf Autostart true "$mcName"
				dataFunction updateVarNetData
				local a="${lgreen}[DONE/Restart]: ${norm}-> Server [$mcName] wurde gestoppt! ($onlinePlayersCount Spieler online)"
				lastMsg="$a\n> Server startet in wenigen Sekunden neu..."
			fi
		else
			lastMsg=">> ERROR unknown state of isRunning ($isRunning)"
		fi
	fi
}

sendText() {
	if [[ -z $mcName ]];then
		lastMsg="${lred}[ERROR/Restart]${norm}: -> Kein Server ausgewählt! Command nicht möglich.${norm}"
	elif [[ $location == intern ]];then
		localCommand sendText
	elif [[ $location == extern ]];then
		getFunction changeTerminal TMUX00 screen,$physisIP,MCS_$mcName
		runExternScript $physisIP localCommands.sh sendText $mcName
		local file="\$DBTDIR"/tmp/lastSendText@$mcName
		lastMsg=$(ssh -q -tt -i $dbtKeyFile -p $stdSSHport root@$physisIP "if [[ -f $file ]];then cat $file && rm $file;fi")
	fi
}

mcConfig() {
	if [[ -z $mcName ]];then
		lastMsg="${lred}[ERROR/mcConfig]: ${norm}-> Kein Server ausgewählt! Command nicht möglich."
	else
		while true;do
			askMCConfHeader() {
				 printHeader && printSTD && printMCConfig && printLastMessage && readNetData $selectedMCSrv
			}
			mcConfigSetBackup() {
				askQuestion2 true false "${yellow}[Terminal/backup]: -> Bitte gib einen neuen Wert für Backup an! ${norm}(aktuell $doBackup)" backup
				if [[ -z $askedAnswer ]];then
					return 1
				elif [[ $askedAnswer == $doBackup ]];then
					lastMsg="${lred}[ERROR/backup]: ${norm}-> [backup] von [$mcName] ist bereits [${lred}$askedAnswer${norm}]!"	
				else
					if [[ $location == intern ]];then
						getFunction setMCBackupConf Backup $askedAnswer
						updateLocalToNetData
					else
						runExternScript $physisIP functions.sh setMCBackupConf Backup $askedAnswer $mcName
						updateVarNetData
					fi
					lastMsg="${lgreen}[DONE/backup]: ${norm}-> [backup] von [$mcName] wurde auf [$askedAnswer] gesetzt!"	
				fi && unset askedAnswer
			}
			mcConfigSetAutostart() {
				askQuestion2 true false "${yellow}[Terminal/autorestart]: -> Bitte gib einen neuen Wert für Autorestart an! ${norm}(aktuell $doAutostart)" autorestart
				if [[ -z $askedAnswer ]];then
					return 1
				elif [[ $askedAnswer == $doAutostart ]];then
					lastMsg="${lred}[ERROR/autorestart]: ${norm}-> [autorestart] von [$mcName] ist bereits [${lred}$askedAnswer${norm}]!"	
				else
					if [[ $location == intern ]];then
						getFunction setMCBackupConf Autostart $askedAnswer
						updateLocalToNetData
					else
						runExternScript $physisIP functions.sh setMCBackupConf Autostart $askedAnswer $mcName
						updateVarNetData
					fi
					lastMsg="${lgreen}[DONE/autorestart]: ${norm}-> [autorestart] von [$mcName] wurde auf [$askedAnswer] gesetzt!"
				fi && unset askedAnswer
			}
			mcConfigBackupTime() {
				askQuestionTime "${yellow}[Terminal/backuptime]: -> Bitte gib eine neue Zeit für das Backup an! ${norm}(aktuell $BackupTime)" backup
				if [[ -z $askedAnswerTime ]];then
					return 1
				elif [[ $askedAnswerTime == $doBackupTime ]];then
					lastMsg="${lred}[ERROR/backuptime]: ${norm}-> [backuptime] von [$mcName] ist bereits [${lred}$askedAnswerTime${norm}]!"	
				else
					if [[ $location == intern ]];then
						getFunction setMCBackupConf BackupTime $askedAnswerTime
						updateLocalToNetData
					else
						runExternScript $physisIP functions.sh setMCBackupConf BackupTime $askedAnswerTime $mcName
						updateVarNetData
					fi
					lastMsg="${lgreen}[DONE/backuptime]: ${norm}-> [backuptime] von [$mcName] wurde auf [$askedAnswerTime] gesetzt!"	
				fi && unset askedAnswerTime
			}
			if [[ $location == extern ]];then
				runExternScript $physisIP backup.sh updateCronJob &
			else
				getBackupFunction updateCronJob &
			fi
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
	askLocation() {
		listIP=$(grep -E "^MCServer[0-9]+=" $dataFile | cut -f 2 -d '=' | tr -s "\n" " ")
		unset stopFunction && while true;do
			clear && printHeader && printSTD && printLastMSG
			echo -e "${yellow}[Terminal/downloadMC]: Wähle den Standort..." && printSTD
			echo -e "${yellow}[Terminal/downloadMC]: Warte auf Eingabe...${norm}"
			echo -e "-> intern $listIP"
			read newDownloadLocation
			if [[ -z $newDownloadLocation ]];then stopFunction=true && return 1;fi
			if [[ $newDownloadLocation == intern ]];then
				newLocation=intern && return 1
			elif [[ -z $(grep -oE "^MCServer[0-9]+=$newDownloadLocation" $dataFile) ]];then
				lastMsg="> Falscher Standort!"
			else
				newLocation=$newDownloadLocation && return 1
			fi
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
				newMCDir="$mcDir"$newMCName
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
	
	unset stopFunction && while [[ -z $stopFunction ]];do
		askLocation
		askServerName
		if [[ $newLocation == intern ]];then
			local jarFile=""$newMCDir"/minecraft_server.jar"
			if [[ -f $jarFile ]];then
				askQuestionWarning="${lred}> Warnung! ${norm}-> Datei [$jarFile] bereits vorhanden!"
				askQuestion2 yes no "Weiterfahren?"
				if ! [[ $askedAnswer == yes ]];then stopFunction=true && return 1;fi
			fi
		else
			if ! [[ -z $(grep "$newLocation" $netData | grep "$newMCName") ]];then
				askQuestionWarning="${lred}> Warnung! ${norm}-> Datei [minecraft_server.jar] bereits vorhanden!"
				askQuestion2 yes no "Weiterfahren?"
				if ! [[ $askedAnswer == yes ]];then stopFunction=true && return 1;fi
			fi
		fi
		askServerType
		askServerVersion
		if ! [[ -z $stopFunction ]];then return 1;fi
		if [[ $newLocation == intern ]];then
			getMCFunction downloadMCjar "$newMCName" "$ServerVersion" "$ServerType"
			local file="$newMCDir/minecraft_server.jar"
			if [[ -f $file ]];then
				lastMsg="${lgreen}[DONE/downloadMC]: ${norm}-> Download für [$newMCName] erfolgreich!\n> Nutze ${lblue}ServerWahl${norm} um den Server auszuwählen..."
			else
				lastMsg="${lred}[ERROR/downloadMC]: ${norm}-> Download fehlgeschlagen!${norm}"
			fi
		else
			lastJar=$(getSSHFunction runExternScript "$newLocation" mcfunctions.sh downloadMCcheck "$newMCName")
			echo -e "${yellow}Starte download..."
			getSSHFunction runExternScript "$newLocation" mcfunctions.sh downloadMCjar "$newMCName" "$ServerVersion" "$ServerType" "$newMCName"
			newJar=$(getSSHFunction runExternScript "$newLocation" mcfunctions.sh downloadMCcheck "$newMCName")
			if [[ $lastJar == $newJar ]];then
				lastMsg="${lred}[ERROR/downloadMC]: ${norm}-> Download fehlgeschlagen!${norm}"
			else
				lastMsg="${lgreen}[DONE/downloadMC]: ${norm}-> Download für [$newMCName] erfolgreich!\n> Nutze ${lblue}ServerWahl${norm} um den Server auszuwählen..."
			fi
		fi
		unset askQuestionWarning && return 1
	done
}

### DBT COMMANDS
GetScreen() {
	if ! [[ -z $1 ]];then local varScreen=$1;else local varScreen="MCS_$mcName";fi
	if [[ -z $mcName ]] || [[ -z $selectedMCSrv ]];then
		lastMsg="${lred}[ERROR/GetScreen]: ${norm}-> Kein Server ausgewählt! Command nicht möglich.${norm}"
	elif [[ $location == intern ]];then
		localCommand GetScreen
	else
		getSSHFunction listExternScreens
		if [[ -z $(echo -e "$externScreens" | grep $varScreen) ]];then
			lastMsg="${lred}[ERROR/GetScreen]: ${norm}-> Screen [$varScreen] nicht gefunden!"
		else
			getFunction changeTerminal TMUX00 screen,$physisIP,$varScreen &
			if ! [[ -z $(ps aux | grep ssh | grep $varScreen) ]];then
				lastMsg="${lgreen}[INFO/GetScreen]: ${norm}-> Screen [$varScreen] wird bereits recordet..."
			elif ! [[ -z $(echo -e "$externScreens" | grep $varScreen | grep Detached) ]];then
				lastMsg="${lgreen}[DONE/GetScreen]: ${norm}-> Screen [$varScreen] wird recordet!"
			elif ! [[ -z $(echo -e "$externScreens" | grep $varScreen | grep Attached) ]];then
				local a="${lgreen}[DONE/GetScreen]: ${norm}-> Screen [$varScreen] wird recordet!"
				lastMsg="$a\n> Externer Screen wurde zuvor recordet; Verbindung getrennt!"
			elif ! [[ -z $(echo -e "$externScreens" | grep $varScreen | grep  Dead) ]];then
				local a="${lred}[ERROR/GetScreen]: ${norm}-> Screen [$varScreen] ist [Dead]!"
				lastMsg="$a\n> Externer Screen wurde gekillt, bitte Versuche es erneut..."
				varIP=$physisIP
				dbtSendCommand noTMUX "screen -wipe $varScreen"
			else
				lastMsg="${lred}[ERROR/GetScreen]: ${norm}-> Fehler-Code [netCmd_GetScr001] unknown state please report on Github..."
			fi
		fi
	fi
}

htop() {
	if [[ -z $location ]] || [[ $location == intern ]];then
		localCommand htop
	else
		dataFunction readDBTData && newDBTEntry="htop,$physisIP"
		if ! [[ -z $(tmux capture-pane -pt "Terminal:0.2" -S -1 | grep -oF "SHR S CPU% MEM%") ]];then
			lastMsg="${lgreen}[DONE/CPU]: ${norm}-> Externe CPU-Anzeige geschlossen!"
			newDBTEntry=
		else
			lastMsg="${lgreen}[DONE/CPU]: ${norm}-> Externe CPU wird angezeigt!"
		fi
		getFunction changeTerminal TMUX02 $newDBTEntry &
	fi
}

### BACKUP COMMANDS
listToBackupServer() {
	n=0
	while IFS= read -a line; do
		n=$(( n + 1 ))
		if [[ $n == $selectedMCSrv ]];then
			printN="${lgreen}[$n]"
		else
			printN="${lblue}[$n]"
		fi
		dataFunction readNetData $n
		if [[ $doBackup == true ]];then
			echo -e "$printN ${norm}>> ${lblue}[$mcName] ${green}Autobackup true${norm} ($location)"
		elif [[ $doBackup == false ]];then
			echo -e "$printN ${norm}>> ${lblue}[$mcName] ${lred}Autobackup false${norm}"
		else
			echo -e "$printN ${norm}>> ${lblue}[$mcName] ${red}no config${norm}"
		fi
	done <$netData
	if [[ $n == 0 ]];then
		echo -e ">> ${lred}Keine MCServer installiert!"
	fi
	printSTD
}

BackupCommands() {
	setMCDailyBackup() {
		(
			setDailyBackup() {
				if [[ $location == intern ]];then
					echo -e "do [setMCBackupConf Backup $1]"
					setMCBackupConf Backup $1
					updateLocalToNetData
				else
					runExternScript functions.sh setMCBackupConf Backup $1 $mcName
					updateVarNetData
				fi
			}
			clear && readNetData $selectedMCSrv
			if [[ $doBackup == true ]];then
				askQuestion2 yes no "${yellow}[Terminal/backup]: -> Tägliche Backups für [$mcName] ${lred}deaktivieren${yellow}?" DailyBackup
			elif [[ $doBackup == false ]];then
				askQuestion2 yes no "${yellow}[Terminal/backup]: -> Tägliche Backups für [$mcName] ${lgreen}aktivieren${yellow}?" DailyBackup
			elif [[ -z $doBackup ]];then
				lastMsg="${lred}[ERROR/DailyBackup]: ${norm}-> Server [$mcName] wurde nie oder nicht korrekt gestartet!"
			fi
			
			if [[ $askedAnswer == yes ]] && [[ $doBackup == true ]];then
				setDailyBackup false
				lastMsg="${lgreen}[DONE/backup]: ${norm}-> [backup] von [$mcName] wurde auf [$askedAnswer] gesetzt!"
			elif [[ $askedAnswer == yes ]] && [[ $doBackup == false ]];then
				setDailyBackup true
				lastMsg="${lgreen}[DONE/backup]: ${norm}-> [backup] von [$mcName] wurde auf [$askedAnswer] gesetzt!"
			fi && unset askedAnswer
		)
	}
	setMCBackupTime() {
		readNetData $selectedMCSrv
		askQuestionTime "${yellow}[Terminal/syncTime]: -> Bitte gib eine neue Zeit an! ${norm}(aktuell $doBackupTime)" syncTime
		if [[ -z $askQuestionTime ]];then
			return 1
		elif ! [[ $askedAnswerTime == $doBackupTime ]];then
			if [[ $location == intern ]];then
				setMCBackupConf BackupTime $askedAnswerTime
				updateLocalToNetData
			elif [[ $location == extern ]];then
				runExternScript $physisIP functions.sh setMCBackupConf BackupTime $askedAnswerTime $mcName
				updateVarNetData
			fi
			lastMsg="${lgreen}[DONE/syncTime]: ${norm}-> [syncTime] wurde auf [$askedAnswerTime] gesetzt!"
		elif [[ $askedAnswerTime == $doBackupTime ]];then
			lastMsg="${lred}[ERROR/syncTime]: ${norm}-> [syncTime] ist bereits [${lred}$askedAnswerTime${norm}]!"	
		fi && unset askedAnswerTime
		command=printMCConf
	}
	BackupSetSyncTime() {
		askQuestionTime "${yellow}[Terminal/syncTime]: -> Bitte gib eine neue Zeit an! ${norm}(aktuell $syncTime)" syncTime
		if ! [[ $askedAnswerTime == $syncTime ]];then
			setNetConf syncTime $askedAnswerTime
			lastMsg="${lgreen}[DONE/syncTime]: ${norm}-> [syncTime] wurde auf [$askedAnswerTime] gesetzt!"
		elif [[ $askedAnswerTime == $syncTime ]];then
			lastMsg="${lred}[ERROR/syncTime]: ${norm}-> [syncTime] ist bereits [${lred}$askedAnswerTime${norm}]!"	
		fi && unset askedAnswerTime
	}
	doManualBackup() {
		if [[ -z $mcName ]];then
			lastMsg="${lred}[ERROR/Restart]${norm}: -> Kein Server ausgewählt! Command nicht möglich.${norm}"
		elif [[ $location == intern ]];then
			askQuestion2 yes no "Manuelles Backup von [$mcName] erstellen?" doBackup
			if [[ $askedAnswer == yes ]];then
				getBackupFunction cmdBackupManually $mcName && clear
				if [[ -f $varBackupFile ]];then
					lastMsg="${lgreen}[DONE/doBackup]: ${norm}-> Lokales Backup erstellt!\n> Pfad: $ManuallyBackupDir\n> Datei: $varTarFile.gz"
				else
					lastMsg="${lred}[ERROR/doBackup]: ${norm}-> Backup Fehlgeschlagen!n> Pfad: $ManuallyBackupDir\n> Datei: $varTarFile.gz"
				fi
			fi
		elif [[ $location == extern ]];then
			askQuestion2 yes no "Externes manuelles Backup von [$mcName] erstellen?" doBackup
			if [[ $askedAnswer == yes ]];then
				beforeBackup="$(runExternScript $physisIP backup.sh grepNewestBackup $mcName)"
				clear && echo -e "${yellow}> Starte externes Backup..."
				runExternScript $physisIP backup.sh cmdBackupManually $mcName
				afterBackup="$(runExternScript $physisIP backup.sh grepNewestBackup $mcName)"
				if [[ $beforeBackup == $afterBackup ]];then
					lastMsg="${lred}[ERROR/doBackup]: ${norm}-> Manuelles Backup fehlgeschlagen!"
				else
					lastSlash=$(( $(echo -e "$afterBackup" | grep -o "/" | wc -l) +1 ))
					varFile=$(echo -e "$afterBackup" | cut -f$lastSlash -d/)
					varPath=$(echo -e "$afterBackup" | sed "s/\/$varFile//g")/
					clear && lastMsg=$(echo -e "${lgreen}[Done/doBackup]: ${norm}-> Externes Backup erstellt!\n$(echo -e "> Datei: $varFile\n> Pfad: $varPath" | column -t)")
				fi
			fi
		fi
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
						dataFunction syncBackupConf &
						lastMsg="${lgreen}[DONE/DailyMax]: ${norm}-> Maximale Anzahl von täglichen Backups auf [$askedAnswerRange] gesetzt!"
					else
						return 1
					fi
				;;
				WeeklyMax)
					askQuestionNumberRange 1 52 "Maximale Wöchentliche Backups aktuell: ${green}$WeeklyBackupMax" WeeklyMax
					if ! [[ -z $askedAnswerRange ]];then
						setBackupConf WeeklyMax $askedAnswerRange
						dataFunction syncBackupConf &
						lastMsg="${lgreen}[DONE/WeeklyMax]: ${norm}-> Maximale Anzahl von täglichen Backups auf [$askedAnswerRange] gesetzt!"
					else
						return 1
					fi
				;;
				
				DayOfWeek)
					askQuestionNumberRange 1 7 "Day of Month aktuell: ${green}$WeeklyDay" DayOfWeek
					if ! [[ -z $askedAnswerRange ]];then
						setBackupConf WeeklyDay $askedAnswerRange
						dataFunction syncBackupConf &
						lastMsg="${lgreen}[DONE/DayOfWeek]: ${norm}-> Wöchentliche Kopie wird am [$askedAnswerRange.] Tag der Woche erstellt!"
					else
						return 1
					fi
				;;
				
				DayOfMonth)
					askQuestionNumberRange 1 28 "Day of Month aktuell: ${green}$MonthlyDay" DayOfMonth
					if ! [[ -z $askedAnswerRange ]];then
						setBackupConf MonthlyDay $askedAnswerRange
						dataFunction syncBackupConf &
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
	printCMDBackupHeader() {
		getSSHFunction assumeExOrIntern 
		printHeader && printSTD && printLastMessage
	}

	dataFunction syncNetConf & 
	getSSHFunction assumeExOrIntern
	while true;do
		readNetConf
		printCMDBackupHeader
		if [[ $command = printMCConf ]];then
			printBackup_allMCConf
			local command=printNetConf
		else
			printNetConf
		fi

		if [[ $syncEnabled == true ]];then
			local doSyncText="disableSync"
		else
			local doSyncText="enableSync"
		fi
		echo -e "${yellow}[Terminal/Backup] Warte auf Eingabe..."
		echo -e "-> info, mcCheck, backupConf, syncTime, $doSyncText"
		echo -e "-> doBackup, setBackup, setTime${norm}"
		read INPUT_STRING && clear
		case $INPUT_STRING in
			info)
				getFunction printHelp cmdBackupInfo &
			;;
			syncTime)
				BackupSetSyncTime
			;;
			backupConf)
				BackupSetConf
			;;
			mcCheck)
				local command=printMCConf
			;;
			doBackup)
				doManualBackup
			;;
			setTime)
				setMCBackupTime
			;;
			setBackup)
				clear && setMCDailyBackup $1
				local command=printMCConf
			;;
			enableSync|disableSync)
				if [[ $syncEnabled == true ]];then
					askQuestion2 yes no "Tägliche Synchronisation ${lred}deaktivieren${norm}?"
					if [[ $askedAnswer == yes ]];then
						setNetConf syncEnabled false
						lastMsg="${lgreen}[DONE/enableSync]: ${norm}-> Tägliche Synchronisation wurde ${lred}deaktiviert${norm}!"
					fi
				else
					askQuestion2 yes no "Tägliche Synchronisation ${green}aktivieren${norm}?"
					if [[ $askedAnswer == yes ]];then
						setNetConf syncEnabled true
						lastMsg="${lgreen}[DONE/enableSync]: ${norm}-> Tägliche Synchronisation ${green}aktiviert${norm}!"
					fi
				fi
			;;
			*)
				if [[ -z $INPUT_STRING ]];then clear && return 1;fi
				clear && lastMsg="${lred}[ERROR] Falsche Eingabe!${norm} -> $INPUT_STRING"
			;;
			esac
			getBackupFunction updateCronJob &
	done
}

### SSH COMMANDS
sshCommands() {
	local ipPattern="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
	while true;do
		clear && printHeader && printSTD && printLastMessage
		echo -e "${yellow}[Terminal/SSH] Warte auf Eingabe..."
		echo -e "-> connect, addMCServer, addBackupServer, delConnection, addPubKey, changePort${norm}"
		read INPUT_STRING && clear
		case $INPUT_STRING in
			connect)
				if [[ $location == intern ]];then
					lastMsg="${lred}[ERROR/connect]: ${norm}-> Bitte wähle einen Exterenen Server aus!"
				elif [[ $location == extern ]];then
					getFunction changeTerminal TMUX00 sshTerminal,$physisIP
				fi
			;;
			addMCServer)
				echo -e "${yellow}[Terminal/addConnection] Warte auf Eingabe..."
				echo -e "-> Schreibe die IP zu welcher eine Verbindung aufgebaut werden soll."
				read INPUT_STRING && clear
				if [[ -z $INPUT_STRING ]];then
					return 1
				elif [[ $INPUT_STRING =~ $ipPattern ]];then
					getSSHFunction addConnection $INPUT_STRING MCServer
				else
					lastMsg="${lred}[ERROR/addMCServer]: ${norm}-> IP [$INPUT_STRING] ist nicht gültig! Nur Zahlen und Punkte sind erlaubt."
				fi
			;;
			addBackupServer)
				echo -e "${yellow}[Terminal/addConnection] Warte auf Eingabe..."
				if ! [[ -z $BackupServer ]];then
					echo -e "${lred}> Warnung ${yellow}-> ${norm}IP [$BackupServer] ist bereits als aktueller Backup-Server eingetragen!"
				fi
				echo -e "-> Schreibe die IP zu welcher eine Verbindung aufgebaut werden soll.${norm}"
				read INPUT_STRING && clear
				if [[ -z $INPUT_STRING ]];then
					return 1
				elif [[ $INPUT_STRING =~ $ipPattern ]];then
					getSSHFunction addConnection $INPUT_STRING BackupServer
				else
					lastMsg="${lred}[ERROR/addMCServer]: ${norm}-> IP [$INPUT_STRING] ist nicht gültig! Nur Zahlen und Punkte sind erlaubt."
				fi
			;;
			delConnection)
				lastMsg="coming soon, sorry..."
			;;
			addPubKey)
				getSSHFunction addUserKey
			;;
			changePort)
				if [[ $netHandler == majority ]];then
					askQuestionNumberRange 49152 65535 "Bitte neuen Standard-SSH Port eingeben!\n> Die Änderung wird vom ganzen Netzwerk übernommen." sshPort
				else
					askQuestionNumberRange 49152 65535 "Bitte neuen Standard-SSH Port eingeben!" sshPort
				fi
				if [[ -z $askedAnswerRange ]];then clear && return 1;fi
				askQuestionWarning="${lred}Warnung: ${norm}Du änderst gerade den Standard-SSH Port!"
				askQuestion2 yes no "Standard-Port zu [$askedAnswerRange] ändern..?" sshPort
				askedAnswer
				if ! [[ $askedAnswer == yes ]];then clear && return 1;fi
				clear 
				echo -e "> Drücke ENTER wenn du den neuen Port [$askedAnswerRange] notiert hast! (oder ESC um abzubrechen)"
				read -s -N 1 -t 30 answer || answer=timeout
				case $answer in
					$'\x0a') 
						if [[ $netHandler == majority ]];then
							for externMCServer in $(grep -E "^MCServer[0-9]+=" $dataFile | cut -f 2 -d '=');do
								getSSHFunction checkConnection $externMCServer
								if ! [[ $connected == true ]];then
									missingConnection=true
									missingIP=$externMCServer
								fi
							done
							if [[ -z $missingConnection ]];then
								for externMCServer in $(grep -E "^MCServer[0-9]+=" $dataFile | cut -f 2 -d '=');do
									getSSHFunction runExternScript $externMCServer sshfunctions.sh changeSTDsshPort $askedAnswerRange
								done
								getSSHFunction changeSTDsshPort $askedAnswerRange
							else
								lastMsg="${lred}[ERROR(sshPort]: ${norm}-> Änderung nicht möglich! Server [$missingIP] ist nicht verbunden..."
							fi
						elif [[ -z $netHandler ]];then
							getSSHFunction changeSTDsshPort $askedAnswerRange
						fi
					;;
					* )
						lastMsg="${yellow}> Abgrebrochen! ${norm}" && return 1
					;;
				esac
				lastMsg="[DONE/sshPort]: -> Port wurde geändert! Neuer Port -> [$stdSSHport]"
			;;
			*)
				if [[ -z $INPUT_STRING ]];then
					return 1
				else
					lastMsg="${lred}[ERROR] Falsche Eingabe!${norm} -> $INPUT_STRING"
				fi
			;;
			esac
	done
}

$ExecuteCommand $Argument2 $Argument3
