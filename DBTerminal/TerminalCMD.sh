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
			ServerList) #done
				clear && localCommand ServerList
			;;
			ServerWahl) #done
				clear && localCommand ServerWahl
			;;
			ServerCheck) #done
				clear && localCommand doServerCheck
			;;
			Start) #done
				clear && localCommand doMCStart
			;;
			Stop) #done
				localCommand doMCStop
			;;
			Restart) #done
				clear && localCommand doMCRestart
			;;
			GetScreen) #done
				clear && localCommand GetScreen
			;;
			SendText) #done
				clear && localCommand sendText
			;;
			mcConfig) #done
				clear && localCommand mcConfig
			;;
			pingOther) #done
				clear && localCommand doPingOther $arg1 $arg2
			;;
			htop) #done
				clear && localCommand htop
			;;
			Backup) #done
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
			GetScreen) #done
				netCommand GetScreen "$arg1"
			;;
			ServerList) #done
				clear && netCommand ServerList
			;;
			ServerWahl) #done
				clear && netCommand ServerWahl
			;;
			ServerCheck) #done
				clear && localCommand doServerCheck
			;;
			Start) #done
				netCommand doMCStart
			;;
			Stop) #done
				netCommand doMCStop
			;;
			Restart) #done
				netCommand doMCRestart
			;;
			SendText) #done
				netCommand sendText
			;;
			mcConfig) #done
				netCommand mcConfig
			;;
			pingOther) #done
				clear && localCommand doPingOther $arg1 $arg2
			;;
			htop) #done
				netCommand htop
			;;
			Backup)  #done
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

localCommands() {
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
			ServerList) #done
				clear && localCommand ServerList
			;;
			ServerWahl) #done
				clear && localCommand ServerWahl
			;;
			ServerCheck) #done
				clear && localCommand doServerCheck
			;;
			Start) #done
				clear && localCommand doMCStart
			;;
			Stop) #done
				localCommand doMCStop
			;;
			Restart) #done
				clear && localCommand doMCRestart
			;;
			GetScreen) #done
				clear && localCommand GetScreen
			;;
			SendText) #done
				clear && localCommand sendText
			;;
			mcConfig) #done
				clear && localCommand mcConfig
			;;
			pingOther) #done
				clear && localCommand doPingOther $arg1 $arg2
			;;
			htop) #done
				clear && localCommand htop
			;;
			Backup) #done
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
