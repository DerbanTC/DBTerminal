#!/bin/bash

if [[ -z $SelfPath ]] || [[ $SelfPath != "$PWD"/ ]];then
	SelfPath="$(dirname "$(readlink -fn "$0")")/"
	cd $SelfPath
	source ./stdvariables.sh
fi

cleanFile() {
	sed -i '/^$/g' $1 && sed -i "/^ *$/d" $1
}

installCronJob() {
	local CRON_FILE=/var/spool/cron/crontabs/root
	local cronJob="@reboot sleep 3 && screen -dmS \"ReboundLoop\" bash -c "$SelfPath"reboundloop.sh"
	rmAllJobs() {
		sed -i "s/$searchJob.*//g" $CRON_FILE
		cleanFile $CRON_FILE
	}
	addNewJob() {
		crontab -l 2>/dev/null | { cat; echo "$cronJob"; } | crontab -
		cleanFile $CRON_FILE
	}
	if [[ -f $CRON_FILE ]];then
		local searchJob="@reboot screen -dmS \"ReboundLoop\" bash -c.*"
		local cronExist=$(grep -o "$cronJob" $CRON_FILE 2>/dev/null)
		local cronCount=$(grep -c "$searchJob" $CRON_FILE 2>/dev/null)
		if [[ -z $cronExist ]] || [[ $(grep -c "@reboot screen -dmS \"ReboundLoop\".*" $CRON_FILE 2>/dev/null) -gt 1 ]];then
			rmAllJobs
			addNewJob
			cleanFile $CRON_FILE
		fi
	else
		echo -e "$cronJob" >> $CRON_FILE
	fi
}

fixDBTDIR() {
	local bashrc="/root/.bashrc"
	local backupDir="$(grep "backupDir=.*" stdvariables.sh | cut -f2 -d=)"
	if [[ ${backupDir: -1} == "/" ]];then
		local backupDir=${backupDir: : -1}
	fi
### ENTRIES IN BASHRC
	local dbtdirEntry="export DBTDIR=$(dirname "$(readlink -fn "$0")")"
	local dbtbkupEntry="export DBTBACKUPDIR=$backupDir"
	local pathEntry="export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
###
	adjustBashrc() {
		searchEntry=$1
		editEntry=$2
		if [[ -z $(grep "$searchEntry" $bashrc) ]];then
			echo "$editEntry" >> $bashrc
		else
			sed -i "s@$searchEntry@$editEntry@g" $bashrc
		fi
	}
	if [[ $DBTDIR != "$(dirname "$(readlink -fn "$0")")" ]] || [[ -z $(grep "export DBTDIR=" $bashrc) ]];then
		adjustBashrc "export DBTDIR=.*" "$dbtdirEntry"
	fi
	if [[ $DBTBACKUPDIR != $backupDir ]] || [[ -z $(grep "export DBTBACKUPDIR=" $bashrc) ]];then
		adjustBashrc "export DBTBACKUPDIR=.*" "$dbtbkupEntry"
	fi

	if [[ -z $(grep "$pathEntry" $bashrc) ]];then
		adjustBashrc "export PATH=.*" "$pathEntry"
	fi
	cleanFile $bashrc
	
}

fixSTDprofile() {
	local stdProfile="/root/.profile"
	
	local loginEntry1="if ! [[ \$- == *i* ]];then return;fi"
	local loginEntry2="source \$DBTDIR/login.sh"
	local sttyEntry="stty intr ^F"

	adjustProfile() {
		local searchEntry=$1
		local editEntry=$2
		if [[ -z $(grep -F "$searchEntry" $stdProfile) ]];then
			echo "$editEntry" >> $stdProfile
		else
			sed -i "s@$searchEntry@$editEntry@g" $stdProfile
		fi
	}
	
	if [[ -z $(grep -F "$loginEntry1" $stdProfile) ]];then
		adjustProfile "$loginEntry2" ""
		adjustProfile "$sttyEntry" ""
		adjustProfile "$loginEntry1" "$loginEntry1"
	fi
	if [[ -z $(grep -F "$sttyEntry" $stdProfile) ]];then
		adjustProfile "$sttyEntry" "$sttyEntry"
	fi
	if [[ -z $(grep -F "$loginEntry2" $stdProfile) ]];then
		adjustProfile "$loginEntry2" "$loginEntry2"
	fi
	cleanFile $stdProfile
}

fixScreenrc() {
	local screenRC="/root/.screenrc"
	local screenEntry1="bindkey "^C" echo 'Blocked! Kill -> [Ctrl+A] + [Enter] + [Y] Detach -> [Ctrl-A] + [D]'"
	local screenEntry2="bindkey "^D" echo 'Blocked! Kill -> [Ctrl+A] + [Enter] + [Y] Detach -> [Ctrl-A] + [D]'"
	local screenEntry3="bind ^M quit"
	if [[ -z $(grep -F "$screenEntry1" $screenRC) ]];then
		echo "$screenEntry1" >> $screenRC
	fi
	if [[ -z $(grep -F "$screenEntry2" $screenRC) ]];then
		echo "$screenEntry2" >> $screenRC
	fi
	if [[ -z $(grep -F "$screenEntry3" $screenRC) ]];then
		echo "$screenEntry3" >> $screenRC
	fi
}

chmodExe() {
	local gitUrl=https://raw.githubusercontent.com/DerbanTC/DBTerminal/master/DBTerminal/
	local DBTScripts=backup.sh,dataFunctions.sh,fixResources.sh,functions.sh,inject.sh,localCommands.sh,login.sh,mcfunctions.sh
	local DBTScripts=$DBTScripts,netCommands.sh,printFunctions.sh,printHelp.sh,reboundloop.sh,sshfunctions.sh,stdvariables.sh,TerminalCMD.sh
	IFS=, read -a DBTScriptsArray <<< "$DBTScripts"
	for varScript in "${DBTScriptsArray[@]}";do
		if [[ -f $varScript ]];then
			chmod +x $varScript
		else
			wget $gitUrl$varScript -qO $varScript
			if [[ -f $varScript ]];then
				chmod +x $varScript
			fi
		fi
	done
}

fixDBTDIR
fixSTDprofile
fixScreenrc
installCronJob
chmodExe
