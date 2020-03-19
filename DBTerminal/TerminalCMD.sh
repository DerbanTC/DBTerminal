#!/bin/bash
SelfPath="$(dirname "$(readlink -fn "$0")")/"
cd $SelfPath
source ./stdvariables.sh
source ./inject.sh
dataFunction readDBTData
source ./printFunctions.sh


getBackupFunction updateCronJob &

localCommands() {
	while [[ $netHandler == local ]];do
		clear && printCMDHeader && read -a INPUT_STRING -t 14440
		if [[ $? -gt 128 ]];then 
			lastMsg="${lgreen}[INFO]: ${yellow}-> Last update at [$( date +"%T" )] (auto-sync after 8h)"
			setLocalData
			getBackupFunction updateCronJob &
		fi
		command="${INPUT_STRING[0]}"
		arg1="${INPUT_STRING[1]}" && arg2="${INPUT_STRING[2]}"
		case $command in
			ServerList)
				clear && localCommand ServerList
			;;
			ServerWahl)
				clear && localCommand ServerWahl
			;;
			ServerCheck)
				clear && localCommand doServerCheck
			;;
			Start)
				clear && localCommand doMCStart
			;;
			Stop)
				localCommand doMCStop
			;;
			Restart)
				clear && localCommand doMCRestart
			;;
			GetScreen)
				clear && localCommand GetScreen
			;;
			SendText)
				clear && localCommand sendText
			;;
			mcConfig)
				clear && localCommand mcConfig
			;;
			downloadMC)
				clear && localCommand downloadMC
			;;
			pingOther)
				clear && localCommand doPingOther $arg1 $arg2
			;;
			htop)
				clear && localCommand htop
			;;
			Backup)
				clear && localCommand BackupCommands
			;;
			HotKey)
				printHelp printBindKeyINFO
			;;
			*)
				if [ -z $INPUT_STRING ];then
					clear
				else
					clear && lastMsg="${lred}[ERROR/Command]: ${norm}-> Command <$INPUT_STRING> ist falsch!"
				fi
			;;
		esac
	done
}

netCommands() {
	while [[ $netHandler == majority ]];do
		clear && printCMDHeader && read -a INPUT_STRING -t 14440
		if [[ $? -gt 128 ]];then 
			lastMsg="${lgreen}[INFO]: ${yellow}-> Last Net-Sync at [$( date +"%T" )] (auto-sync after 8h)"
			setNetData
			getBackupFunction updateCronJob &
		fi
		command="${INPUT_STRING[0]}"
		arg1="${INPUT_STRING[1]}" && arg2="${INPUT_STRING[2]}"
		case $command in
			GetScreen)
				netCommand GetScreen "$arg1"
			;;
			ServerList)
				clear && netCommand ServerList
			;;
			ServerWahl)
				clear && netCommand ServerWahl
			;;
			ServerCheck)
				clear && localCommand doServerCheck
			;;
			Start)
				netCommand doMCStart
			;;
			Stop)
				netCommand doMCStop
			;;
			Restart)
				netCommand doMCRestart
			;;
			SendText)
				netCommand sendText
			;;
			mcConfig)
				netCommand mcConfig
			;;
			downloadMC)
				clear && netCommand downloadMC
			;;
			pingOther)
				clear && localCommand doPingOther $arg1 $arg2
			;;
			htop)
				netCommand htop
			;;
			Backup)
				clear && netCommand BackupCommands
			;;
			SSH)
				netCommand sshCommands
			;;
			HotKey)
				printHelp printBindKeyINFO
			;;
			*)
				if [ -z $INPUT_STRING ];then
					clear
				else
					clear
					lastMsg="${lred}[ERROR/Command]: ${norm}-> Command <$INPUT_STRING> ist falsch!"
				fi
			;;
		esac
	done
}

unknownCommands() {
	while [[ -z $netHandler ]];do
		clear && printCMDHeader && read -a INPUT_STRING -t 14440
		if [[ $? -gt 128 ]];then 
			lastMsg="${lgreen}[INFO]: ${yellow}-> Last update at [$( date +"%T" )] (auto-sync after 8h)"
			setLocalData
			getBackupFunction updateCronJob &
		fi
		command="${INPUT_STRING[0]}"
		arg1="${INPUT_STRING[1]}" && arg2="${INPUT_STRING[2]}"
		case $command in
			ServerList)
				clear && localCommand ServerList
			;;
			ServerWahl)
				clear && localCommand ServerWahl
			;;
			ServerCheck)
				clear && localCommand doServerCheck
			;;
			Start)
				clear && localCommand doMCStart
			;;
			Stop)
				localCommand doMCStop
			;;
			Restart)
				clear && localCommand doMCRestart
			;;
			GetScreen)
				clear && localCommand GetScreen
			;;
			SendText)
				clear && localCommand sendText
			;;
			mcConfig)
				clear && localCommand mcConfig
			;;
			downloadMC)
				clear && localCommand downloadMC
			;;
			pingOther)
				clear && localCommand doPingOther $arg1 $arg2
			;;
			htop)
				clear && localCommand htop
			;;
			Backup)
				clear && localCommand BackupCommands
			;;
			SSH)
				netCommand sshCommands
			;;
			HotKey)
				printHelp printBindKeyINFO
			;;
			*)
				if [ -z $INPUT_STRING ];then
					clear
				else
					clear && lastMsg="${lred}[ERROR/Command]: ${norm}-> Command <$INPUT_STRING> ist falsch!"
				fi
			;;
		esac
	done
}

while true; do
	unknownCommands
	localCommands
	netCommands
done
