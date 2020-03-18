#!/bin/bash

printSTD() {
	echo -e "${yellow}$(for i in $(seq 1 $(tty -s && tput cols | cut -f2 -d' ')); do echo -n -; done)${norm}"
}

addSpace() {
	echo "$(seq -s' ' $1|tr -d '[:digit:]')"
}

chColor() {
	if [[ -z $1 ]];then
		echo -e "${red}empty${norm}"
	else
		case $1 in 
			true|aktiv)
				echo -e "${lgreen}"$1"${norm}"
			;;
			false|inaktiv)
				echo -e "${lred}"$1"${norm}"
			;;
			async|sync|[0-9][0-9]:[0-9][0-9])
				echo -e "${lblue}"$1"${norm}"
			;;
			*)
				echo -e "$1"
			;;
		esac
	fi
}

printCenter() {
	pattern="[^\\][0-9]*\[[0-9];[0-9]*m"
	if [[ $1 =~ $pattern ]];then
		uncoloredString=$(echo $1 | sed -E "s/$pattern//g" | sed "s/\\\//g")
		size=$(echo $(echo $(tty -s && tput cols | cut -f2 -d' ') - $(echo $uncoloredString | wc -c) | bc) / 2 | bc)
		echo -e "$(tty -s && tput cuf $size)$1${norm}"
	else
		size=$(echo $(echo $(tput cols | cut -f2 -d' ') - $(echo $1 | wc -c) | bc) / 2 | bc)
		echo -e "$(tty -s && tput cuf $size)$1"
	fi
}

print3Colon() {
	pattern="[^\\][0-9]*\[[0-9];[0-9]*m"
	unixPattern="U[0-9][0-9][0-9][0-9|E]"
	getStringSize() {
		if [[ "$1" =~ $pattern ]] ||  [[ "$1" =~ $unixPattern ]];then
			uncoloredString="$(echo "$1" | sed -E "s/$unixPattern/YY/g" | sed -E "s/$pattern//g" | sed "s/\\\//g")"
			echo "$(echo -e "$uncoloredString" | wc -c)"
		else 
			echo "$(echo $1 | wc -c)"
		fi
	}
	full=$(( $(tty -s && tput cols | cut -f2 -d' ') + 1 ))
	sizeA=$(getStringSize "$1")
	sizeB=$(getStringSize "$2")
	sizeC=$(getStringSize "$3")
	lengthAB=$(( ( ( full - sizeB ) / 2 ) - sizeA ))
	lengthBC=$(( full - ( sizeA + lengthAB + sizeB ) - sizeC + 2 ))
	echo -e "$1$(tty -s && tput cuf $lengthAB)$2$(tty -s && tput cuf $lengthBC)$3${norm}"
}

printHeader() {
	selectedMCSrv=$(grep -o 'ChoosedMCServer=[^"]*' $dbtData | cut -f2 -d'=' 2>/dev/null)
	if [[ $netHandler == majority ]];then
		dataFunction readNetData $selectedMCSrv
		local header="${yellow}***${green}DBT [NETWORK]${yellow}***"
	elif [[ $netHandler == local ]];then
		dataFunction readLocalData $selectedMCSrv
		local header="${yellow}***${green}DBT [LOKAL]${yellow}***"
	else
		dataFunction readLocalData $selectedMCSrv
		local header="${yellow}***${green}DBT${yellow}***"
	fi
	getFunction getSTDFiles
	if [[ -z $mcName ]];then local mcName="${lred}empty${lblue}";fi
	echo -e "$(print3Colon "${yellow}[$(date +%R)]" "$header" "MC: ${lblue}[$mcName]$mcRunStateCode")${norm}"
}

printLocalBackupHeader() {
	if ! [[ $netHandler == majority ]];then
		echo -e "${yellow}[DBT/Backup] ${lblue}LOKALER MODUS${norm}" 
	elif [[ -z $BackupServer ]];then
		echo -e "${yellow}[DBT/Backup] ${lblue}NETZWERK ${lred}kein externer Backup-Server${norm}"
		echo -e "${yellow}-> SSH -> addConnection -> IP/intern${norm}"
	else
		echo -e "${yellow}[DBT/Backup] ${lblue}NETZWERK ${green}Backup-Server:$BackupServer ${norm}" 
	fi
	printBackupTime && printSTD
}

printLastMessage() {
	printListMessage() {
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
	printListMessage
	if ! [[ -z $printed ]];then printSTD && unset printed;fi
}

printBackup_allMCConf() {
	local n=0
	lastListMsg="${yellow}Netzwerk Config (MC-Einträge):${norm}" && declare -g "magic_variable_1=$(echo -e "$lastListMsg")"
	local tmpfile="$tmpDir"wrknetconf
	if [[ -f $tmpfile ]];then rm $tmpfile;fi
	echo -e "Nr.,mcServer,Backup,BackupTime,Location" > $tmpfile
	echo -e "---,--------,------,----------,--------" >> $tmpfile
	while IFS= read -r line;do
		n=$(( n + 1 ))
		local varIP="$(echo $line | cut -f1 -d,)"
		local varName="$(echo $line | cut -f2 -d,)"
		local varDoBackup="$(echo $line | cut -f6 -d, | cut -f2 -d=)"
		local varBackupTime="$(echo $line | cut -f7 -d, | cut -f2 -d=)"
		if ! [[ -z $varBackupTime ]];then
			local varBackupTime="${lblue}$varBackupTime${norm}"
		fi
		if [[ $varIP == $(hostname -i) ]];then
			local newEntry="[$n],$varName,$varDoBackup,$varBackupTime,intern"
		else
			local newEntry="[$n],$varName,$varDoBackup,$varBackupTime,$varIP"
		fi
		echo -e "$newEntry" >> $tmpfile	
	done < $netData
	sed -i "s/,,,/,empty,empty,/" $tmpfile
	sed -i "s/,,/,empty,/g" $tmpfile
	sed -i "s/true/$(echo -e "${lgreen}true${norm}")/g" $tmpfile
	sed -i "s/false/$(echo -e "${red}false${norm}")/g" $tmpfile
	sed -i "s/empty/$(echo -e "${lred}empty${norm}")/g" $tmpfile
	sed -i "s/\[$selectedMCSrv\]/$(echo -e "${lgreen}[$selectedMCSrv]${norm}")/g" $tmpfile
	lastListMsg=$(echo -e "$(cat $tmpfile)" | column -s , -t) && declare -g "magic_variable_2=$(echo -e "$lastListMsg")"
	printLastMessage
}

printCMDHeader() {
	dataFunction setLocalData &
	printHeader && printSTD && printLastMessage
	if [[ -z $mcName ]] || [[ -z $selectedMCSrv ]];then
		echo -e "${lred}[WARNUNG]${norm}: -> Du hast keinen Server ausgewählt!"
		printSTD
	fi
	echo -e "${yellow}[Terminal] Warte auf Eingabe..."
	if [[ $netHandler == local ]];then
		echo -e "-> ServerList, ServerWahl, ServerCheck, pingOther, GetScreen, htop"
		echo -e "-> Start, Stop, Restart, SendText, mcConfig, Backup, HotKey${norm}"
	else
		echo -e "-> ServerList, ServerWahl, ServerCheck, pingOther, GetScreen, htop, SSH"
		echo -e "-> Start, Stop, Restart, SendText, mcConfig, Backup, HotKey${norm}"
	fi
}

printNetConf() {
	dataFunction readBackupConf
	lastListMsg="${yellow}Netzwerk Config:${norm}" && declare -g "magic_variable_1=$(echo -e "$lastListMsg")"
	if [[ -z $BackupServer ]];then
		doExternBackup="${lred}false${norm}"
	else
		doExternBackup="$BackupServer"
	fi
	syncEnabled=$(grep "sync-enabled" $netConf | cut -f2 -d' ' | sed "s/ //g")
	syncTime=$(grep "sync-time" $netConf | cut -f2 -d' ' | sed "s/ //g")
	local a="Backup-Server,Sync-Time,Synchro"
	local b="$a\n$doExternBackup,$(chColor $syncTime),$(chColor $syncEnabled)"
	lastListMsg="$(echo -e "$b" | column -s , -t)" && declare -g "magic_variable_2=$(echo -e "$lastListMsg")"
	lastListMsg="${yellow}Backup Config:${norm}" && declare -g "magic_variable_3=$(echo -e "$lastListMsg")"
	local c="Daily-Max,Weekly-Max,Day of Week,Day of Month"
	local d="$c\n$DailyBackupMax,$WeeklyBackupMax,$WeeklyDay,$MonthlyDay"
	lastListMsg="$(echo -e "$d" | column -s , -t)" && declare -g "magic_variable_4=$(echo -e "$lastListMsg")"
	printLastMessage
}

printLocalBackupConf() {
	dataFunction readBackupConf
	lastListMsg="${yellow}Backup Config:${norm}" && declare -g "magic_variable_1=$(echo -e "$lastListMsg")"
	local a="Daily-Max,Weekly-Max,Day of Week,Day of Month"
	local b="$a\n$DailyBackupMax,$WeeklyBackupMax,$WeeklyDay,$MonthlyDay"
	lastListMsg="$(echo -e "$b" | column -s , -t)" && declare -g "magic_variable_2=$(echo -e "$lastListMsg")"
}

$1 $2 $3 $4 $5
