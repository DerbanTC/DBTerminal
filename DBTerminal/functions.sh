#!/bin/bash

getTime() {
	time=$( date +"%T" )
	date=$( date +"%Y-%m-%d" )
	year=$( date +"%Y" )
	month=$( date +"%m" )
	day=$( date +"%d" )
	DayOfWeek=$(date +%u)
	DayOfMonth=$(date +%d)
}

getSTDFiles() {
	mcSrvJar="$mcDir$mcName/$jarName"
	bash="$mcDir$mcName/$StartShellName"
	startShell="$mcDir$mcName/$StartShellName"
	bkupconfig="$mcDir$mcName/$bkupconfName"
	eula="$mcDir$mcName/eula.txt"
	mcSrvProperties="$mcDir$mcName/server.properties"
}

grepExtern() {
#	if ! [[ -z $1 ]] || ! [[ -z $3 ]];then
	if ! [[ -z $1 ]];then
		mcName=$1
		varPath="$(dirname "$(readlink -fn "$0")")/"
		cd $varPath
		source ./stdvariables.sh
		getSTDFiles
	fi
}

##### MC BACKUP.CONFIG ###############################################################
readMCBackupConf() {
	if [[ -f $bkupconfig ]];then
		AutostartLine=$(grep -o 'autorestart=[^"]*' $bkupconfig)
		doAutostart=${AutostartLine#*=}
		BackupLine=$(grep -o 'backup=[^"]*' $bkupconfig)
		doBackup=${BackupLine#*=}
		BackupTimeLine=$(grep -o 'backuptime=[^"]*' $bkupconfig)
		BackupTime=${BackupTimeLine#*=}
	else
		unset AutostartLine && unset doAutostart
		unset BackupLine && unset doBackup
		unset BackupTimeLine && unset BackupTime
	fi
}

setMCBackupConf() {
	grepExtern $3 && readMCBackupConf
	if [[ $1 == Autostart ]];then
		sed -i "s/$AutostartLine/autorestart=$2/g" $bkupconfig
	elif [[ $1 == BackupTime ]];then
		sed -i "s/$BackupTimeLine/backuptime=$2/g" $bkupconfig
	elif [[ $1 == Backup ]];then
		sed -i "s/$BackupLine/backup=$2/g" $bkupconfig
	else
		lastMsg="${lred}[ERROR/setMCBackupConf]: -${norm}> Argument2 [$1] (Autostart/Backup) wurde vergessen!"
	fi
}

##### MC SERVER.PROBERTIES ###########################################################
readProperties() {
	if [[ -f $mcSrvProperties ]];then
		MCportfull=$(grep -o 'server-port[^"]*' $mcSrvProperties)
		MCport=${MCportfull#*=}
		MCipfull=$(grep -o 'server-ip[^"]*' $mcSrvProperties)
		MCip=${MCipfull#*=}
	else
		unset MCipfull && unset MCport
		unset MCip && unset MCport
	fi
}

setProperties() {
	readProperties
	if [[ $Argument2 == Port ]];then
		Port=$Argument3
		sed -i "s/$MCportfull/server-port=$Port/g" $mcSrvProperties
	elif [[ $Argument2 == IP ]];then
		IP=$Argument3
		sed -i "s/$MCipfull/server-ip=$IP/g" $mcSrvProperties
	else
		lastMsg="${lred}[ERROR/setProperties]: ${norm}-> Argument2 (Port/IP) wurde vergessen!"
	fi
}

detachMCScreen() {
	for screen in $(screen -ls | grep Attached);do
		if [[ "$screen" == *"MCS_"* ]];then
			screen -d $screen
		fi
	done
}

dbtSendCommand() {
	if ! [[ -z $1 ]] && ! [[ -z $2 ]] && ! [[ -z $varIP ]];then
		local sendCommand="$2"
		case $1 in
			noTMUX)
				ssh -q -tt -i $dbtKeyFile -p $stdSSHport root@$varIP "$sendCommand"
			;;
			TMUX00)
				clearTMUXwindow TMUX00
				tmux send-key -t Terminal:0.0 "ssh -q -tt -i $dbtKeyFile -p $stdSSHport root@$varIP $sendCommand" C-m
			;;
			TMUX02)
				clearTMUXwindow TMUX02
				tmux send-key -t Terminal:0.2 "ssh -q -tt -i $dbtKeyFile -p $stdSSHport root@$varIP $sendCommand" C-m
			;;
		esac
	fi
}

detachService() {
	service=$(echo $1 | cut -f1 -d',') && varIP=$(echo $1 | cut -f2 -d',') && varName=$(echo $1 | cut -f3 -d',')
	terminal=$2
	case $service in
		htop)
			if [[ $varIP == intern ]];then
				if ! [[ -z $(tmux capture-pane -pt "Terminal:0.$terminal" -S -1 | grep -oF "SHR S CPU% MEM%") ]];then
					tmux send-key -t Terminal:0.$terminal "q" C-m
				fi
			else
				if ! [[ -z $(ps aux | grep ssh | grep root@$physisIP | grep htop) ]];then
					dbtSendCommand noTMUX "kill \$(pgrep "htop")"
				fi
			fi
		;;
		screen)
			if [[ $varIP == intern ]];then
				if ! [[ -z $(screen -ls | grep $varName | grep Attached) ]];then
					screen -d $varName
				fi
			else
				if ! [[ -z $(ps aux | grep ssh | grep $varName) ]];then
					dbtSendCommand noTMUX "screen -d $varName"
				fi
			fi
		;;
		sshTerminal)
			if [[ $varIP == extern ]];then
				for varPID in $(pidof ssh);do kill $varPID;done
			fi
		;;
	esac
}

clearTMUXwindow() {
	case $1 in
		TMUX00)
			tmux send-keys -t Terminal:0.2 Escape
			tmux send-keys -t Terminal:0.0 C-u
		;;
		TMUX02)
			tmux send-keys -t Terminal:0.2 C-u
		;;
	esac
	
}

attachService() {
	attachExternScreen() {
		getSSHFunction listExternScreens
		if [[ -z $(ps aux | grep ssh | grep $varName) ]] && ! [[ -z $(echo -e "$externScreens" | grep $varName | grep Detached) ]];then
			dbtSendCommand TMUX00 "screen -r $varName"
		elif [[ -z $(ps aux | grep ssh | grep $varName) ]] && ! [[ -z $(echo -e "$externScreens" | grep $varName | grep Attached) ]];then
			dbtSendCommand noTMUX "screen -d $varName"
			dbtSendCommand TMUX00 "screen -r $varName"
		fi
	}
	connectExternSSH() {
		clearTMUXwindow TMUX00
		tmux send-key -t Terminal:0.0 "ssh -tt -i $dbtKeyFile -p $stdSSHport root@$varIP" C-m
	}
	service=$(echo $1 | cut -f1 -d',') && varIP=$(echo $1 | cut -f2 -d',') && varName=$(echo $1 | cut -f3 -d',')
	terminal=$2
	case $service in
		htop)
			if [[ $varIP == intern ]];then
				if [[ -z $(tmux capture-pane -pt "Terminal:0.$terminal" -S -1 | grep -oF "SHR S CPU% MEM%") ]];then
					tmux send-key -t Terminal:0.$terminal "htop" C-m
				fi
			else
				if [[ -z $(ps aux | grep ssh | grep root@$varIP | grep htop) ]];then
					dbtSendCommand TMUX02 "htop"
				fi
			fi
		;;
		screen)
			if [[ $varIP == intern ]];then
				if ! [[ -z $(screen -ls | grep $varName | grep Detached) ]];then
					tmux send-key -t Terminal:0.$terminal "screen -r $varName" C-m
				fi
			else
				attachExternScreen
			fi
		;;
		sshTerminal)
			if [[ $varIP == extern ]];then
				connectExternSSH
			fi
		;;
	esac
}

changeTerminal() {
	newDBTEntry=$2 && getSSHFunction readDBTData
	case $1 in
		MCServer)
			if ! [[ -z $ChoosedMCServer ]] && ! [[ $entryExist == $ChoosedMCServer ]] || [[ -z $newDBTEntry ]];then
				detachService $ChoosedMCServer
			fi
			sed -i s/ChoosedMCServer=.*/ChoosedMCServer=$newDBTEntry/g $dataFile
		;;
		TMUX00)
			entryExist=$(grep -o 'AttachedTMUX00=.*' $dataFile | cut -f2 -d'=')
			if ! [[ $entryExist == $newDBTEntry ]] && ! [[ -z $entryExist ]] || [[ -z $newDBTEntry ]];then
				detachService $selectedTMUX00 0
			fi
			attachService $newDBTEntry 0
			sed -i s/AttachedTMUX00=.*/AttachedTMUX00=$newDBTEntry/g $dataFile
		;;
		TMUX02)
			entryExist=$(grep -o 'AttachedTMUX02=.*' $dataFile | cut -f2 -d'=')
			if ! [[ $entryExist == $newDBTEntry ]] && ! [[ -z $entryExist ]] || [[ -z $newDBTEntry ]];then
				detachService $selectedTMUX02 2
			fi
			attachService $newDBTEntry 2
			sed -i s/AttachedTMUX02=.*/AttachedTMUX02=$newDBTEntry/g $dataFile
		;;
	esac
}

reboundTerminal() {
	source ./stdvariables.sh
	attachService $(grep -o 'AttachedTMUX00=.*' $dataFile | cut -f2 -d=) 0
	attachService $(grep -o 'AttachedTMUX02=.*' $dataFile | cut -f2 -d=) 2
}

checkConditions() {
	grepExtern $1
	getSTDFiles
	StartIsEnabled=doNewInstall
	if [[ -f $bash ]] && [[ -f $mcSrvJar ]] && [[ -f $bkupconfig ]];then
		readMCBackupConf
		varScreen=$(screen -ls | grep MCS_$mcName)
		if [[ $doAutostart == true ]] && ! [[ -z $varScreen ]];then
			StartIsEnabled=isRunning
		elif ! [[ -f $mcSrvProperties ]];then
			StartIsEnabled=firstRun
		elif [[ $doAutostart == true ]];then
			StartIsEnabled=doStart
		elif [[ $doAutostart == false ]];then
			StartIsEnabled=noStart
		fi
	elif ! [[ -f $mcSrvJar ]];then
		StartIsEnabled=missingJar
	elif ! [[ -f $bash ]];then
		StartIsEnabled=missingStartShell
	fi
}

showTimer() {
	timerText="bis zum Stop des Servers..."
	headerText="${yellow}>> Manueller Stop! $onlinePlayersCount Spieler online"
	latestlog=$mcDir$mcName/logs/latest.log
	unset cancel
	seconds=$Argument2
	n=0
	tmpfile=./showTimerTmpfile
	if [[ -f $tmpfile ]];then
		rm $tmpfile
	fi
	while [[ "$n" -lt $seconds ]] && [[ -z $cancel ]] && [[ -z $finished ]];do
		clear
		n=$(( n + 1 ))
		subN=$(( seconds - n ))
		finished=$(grep -o 'INFO]: Done' $latestlog)
		tellN="${blue}${byellow}$subN Sekunden${norm}"
		if ! [[ -z $headerText ]];then
			echo -e "$headerText"
		fi
		echo -e "$tellN $timerText"
		echo -e "${lred}Tippe ENTER um abzubrechen!${norm}"
		read -t 1 answer
		if [ $? -eq 0 ];then
			echo "isCancelled" > showTimerTmpfile
			cancel=cancelled
		fi
	done
}

printMCConfig() {
	if [[ $netHandler == majority ]];then
		getSSHFunction readNetData $selectedMCSrv
	else
		getSSHFunction readLocalData $selectedMCSrv
	fi
	if [[ -f $bkupconfig ]] || [[ $location == extern ]];then
		if [[ $location == extern ]];then
			local bkupconfig="$(grep "$physisIP" $syncData | cut -f3 -d,)"$bkupconfName
		fi
		lastListMsg="${yellow}[mcConfig/$mcName] ${norm}($bkupconfig)" && declare -g "magic_variable_1=$(echo -e "$lastListMsg")"
		lastListMsg="${yellow}>,backup:,autorestart:,backuptime:\n>,$(chColor $doBackup),$(chColor $doAutostart),$(chColor $doBackupTime)"
		declare -g "magic_variable_2=$(echo -e "$lastListMsg" | column -t -s,)"
	else
		lastMsg="${lgreen}[INFO/backupConfig]: ${norm}-> Datei <$bkupconfName> nicht vorhanden!"
	fi
}

printHelp() {
	if ! [[ -z $1 ]];then
		getSSHFunction changeTerminal TMUX02
		tmux send-key -t Terminal:0.2 "cd ${PWD} && clear && ./printHelp.sh $1" C-m
	fi
}

askQuestionTime() {
	question=$1 && internCommand=$2
	unset askedAnswerTime && while true;do
		clear && printFunction printHeader && printFunction printSTD 
		if ! [[ -z $lastMsg ]];then echo -e "$lastMsg" && printSTD && unset lastMsg; fi
		if ! [[ -z $askQuestionWarning ]];then echo -e "$askQuestionWarning" && printSTD && unset askQuestionWarning; fi
		echo -e "$question" && printSTD
		echo -e "${yellow}> Bitte Uhrzeit angeben! Format: 00:00 - 23:59"
		echo -e "[Terminal/$internCommand]: Warte auf Eingabe...${norm}"
		read INPUT_STRING && clear
		if [[ -z $INPUT_STRING ]];then
			return 1
		elif ! [[ $INPUT_STRING =~ ^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$ ]];then
			lastMsg="${lred}[ERROR]: ${yellow}-> Falsches Format! 00:00 - 23:59"
		else
			askedAnswerTime=$INPUT_STRING && return 1
		fi
	done 
}

askQuestion2() {
#askQuestion2 yes no "Question" "internCommand"
	state1=$1 && state2=$2
	question=$3 && internCommand=$4
	unset askedAnswer && while true;do
		clear && printFunction printHeader && printSTD 
		if ! [[ -z $lastMsg ]];then echo -e "$lastMsg" && printSTD && unset lastMsg; fi
		if ! [[ -z $askQuestionWarning ]];then echo -e "$askQuestionWarning" && printSTD && unset askQuestionWarning; fi
		echo -e "${yellow}Frage: ${norm}$question" && printSTD
		echo -e "${yellow}[Terminal/$internCommand]: Warte auf Eingabe..."
		echo -e "-> $state1, $state2${norm}"
		read INPUT_STRING && clear
		case $INPUT_STRING in
			$state1)
				askedAnswer=$INPUT_STRING && return 1
			;;
			$state2)
				askedAnswer=$INPUT_STRING && return 1
			;;
			*)
				if [[ -z $INPUT_STRING ]];then
					return 1
				else
					lastMsg="${lred}[ERROR]: ${norm}-> Falsche Eingabe [$INPUT_STRING]!"
				fi
			;;
		esac
	done
	unset askQuestionWarning
}

printLastMSG() {
	printListMSG() {
		if ! [[ -z $listMsgHeader ]];then
			echo -e "$listMsgHeader" && unset listMsgHeader
		fi
		for varMsg in {1..25};do
			var="magic_variable_$varMsg"
			if ! [[ -z "$(echo ${!var})" ]];then	
				echo -e "${!var}" && unset `echo $var` && printed=true
			else
				return 1
			fi
		done
	}
	if ! [[ -z $lastMsg ]];then
		echo -e "$lastMsg" && printSTD && unset lastMsg
	fi
	printListMSG
	if ! [[ -z $printed ]];then printSTD && unset printed;fi
}

askQuestionNumberRange() {
	fromRange=$1 && toRange=$2
	question=$3 && internCommand=$4
	unset askedAnswerRange && while true;do
		clear && printFunction printHeader && printFunction printSTD 
		if ! [[ -z $lastMsg ]];then echo -e "$lastMsg" && printSTD && unset lastMsg; fi
		if ! [[ -z $askQuestionWarning ]];then echo -e "$askQuestionWarning" && printSTD && unset askQuestionWarning; fi
		echo -e "$question" && printSTD
		echo -e "${yellow}> Bitte neuer Wert angeben! ($fromRange - $toRange)"
		echo -e "[Terminal/$internCommand]: Warte auf Eingabe...${norm}"
		read INPUT_STRING && clear
		if [[ -z $INPUT_STRING ]];then
			return 1
		elif [[ $INPUT_STRING -lt $fromRange ]];then
			lastMsg="${lred}[ERROR]: ${yellow}-> Zu niedriger Wert! (min. $fromRange)"
		elif [[ $INPUT_STRING -gt $toRange ]];then
			lastMsg="${lred}[ERROR]: ${yellow}-> Zu hoher Wert! (max. $toRange)"
		else
			askedAnswerRange=$INPUT_STRING && return 1
		fi
	done 
}

waitUntilScreen() {
	unset varScreen && n=0
	while [[ -z $varScreen ]] && [[ $n -lt 120 ]];do
		sleep 1 && varScreen=$(screen -ls | grep -o "$1") && n=$(( n + 1 ))
	done
	if ! [[ -z $varScreen ]];then
		tmux send-key -t Terminal:0.0 "screen -r $1" C-m
	fi
}

waitUntilExternScreen() {
	unset varScreen && n=0 && local searchScreen=$1
	while [[ -z $varScreen ]] && [[ $n -lt 120 ]];do
		sleep 1
		varScreen=$(ssh -q -tt -i $dbtKeyFile -p 22 root@$physisIP echo -e "\$(screen -ls | grep $searchScreen)")
		n=$(( n + 1 ))
	done
	 if ! [[ -z $varScreen ]];then
		changeTerminal TMUX00 screen,$physisIP,$searchScreen
	 fi
}

$1 $2 $3 $4 $5
