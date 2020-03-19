#!/bin/bash
if [[ -z $SelfPath ]] || [[ $SelfPath != "$PWD"/ ]];then
	SelfPath="$(dirname "$(readlink -fn "$0")")/"
	cd $SelfPath
	source ./stdvariables.sh
	source ./inject.sh
fi

runExternScript() {
	local varIP=$1
	local script="$2 $3 $4 $5 $6 $7"
	local chDir='cd $DBTDIR' # <-- This variable will be escaped on the extern server ('...')
	ssh -q -t  -i $dbtKeyFile -p $stdSSHport root@$varIP "$chDir; ./$script;exit"
}

listExternScreens() {
	if ! [[ -z $1 ]];then local physisIP=$1;fi
	externScreens="$(ssh -q -t -i $dbtKeyFile -p $stdSSHport root@$physisIP screen -ls)"
}

#### SSH-FUNCTIONS ######################################################################
# in networks only needed on the head-server
# todo: prevent to-way connections via DBT (security)
#############################################################################
genSSHKey() {
	ssh-keygen -t rsa -b 4096 -C "DBTerminal SSHKey" -P "" -f "$dbtKeyFile"
	chmod +400 $dbtKeyFile && chmod +400 $dbtpubKeyFile
}

copyPubKey() {
	varIP=$1 && if ! [[ -z $varIP ]];then
		ssh-copy-id -i $dbtpubKeyFile -p $stdSSHport root@$varIP
	fi
}

addUserKey() {
	SSHDir=~/.ssh/
	authKeysFile=~/.ssh/authorized_keys
	if ! [[ -d $SSHDir ]];then
		mkdir $SSHDir && chmod 700 $SSHDir
		touch $authKeysFile && chmod 644 $authKeysFile
	elif ! [[ -f $authKeysFile ]];then
		touch $authKeysFile && chmod 644 $authKeysFile
	fi
	echo -e "${yellow}[Terminal/addPubKey] Fügen den Key (ssh-rsa ...) ein (Shift+Insert)...${norm}"
	read UserKey
	if [[ -z $UserKey ]];then
		return 1
	elif ! [[ $UserKey =~ ^ssh-rsa\ .* ]];then
		lastMsg= "${lred}[ERROR/addPubKey]: ${norm}-> PubKey startet mit "ssh-rsa ...""
		return 1
	elif ! [[ -z $(grep "$UserKey.*" $authKeysFile) ]];then
		count=$(grep "$UserKey.*" $authKeysFile | grep "dbt:count_.*" | cut -f2 -d_)
		lastMsg="${lred}[ERROR/addPubKey]: ${norm}-> PubKey (Nr.$count) wurde bereits hinzugefügt!"
	else
		count=$(grep -c "dbt:count_" $authKeysFile)
		echo -e "$UserKey dbt:count_$count" >>$authKeysFile
		lastMsg="${lgreen}[DONE/addPubKey]: ${norm}-> PubKey Nr.$count wurde hinzugefügt.\n> Bitte neu einloggen um den die Connection zu prüfen..."
	fi
}

checkConnection() {
	varIP=$1 && if ! [[ -z $varIP ]];then
		varState=$(ssh -tt -q -i $dbtKeyFile -p $stdSSHport root@$varIP -o 'ConnectTimeout=2' -o 'BatchMode=yes' -o 'ConnectionAttempts=1' true; echo $?)
		if [[ $varState == 0 ]];then
			connected=true
		elif [[ $varState == 255 ]];then
			connected=false
		else
			connected=ERROR
		fi
	fi
}

addConnection() {
	addSSHConnection() {
		getFunction changeTerminal TMUX00
		tmux send-key -t Terminal:0.0 "cd \$DBTDIR && ./sshfunctions.sh copyPubKey $addIP" C-m &
		while true;do
			clear
			echo -e "${yellow}[Info/addConnection]: -> Bitte gib das Passwort (oben) ein!"
			echo -e ">> Drücke ${lblue}ENTER ${yellow}wenn das Login per SSH vollzogen wurde...${norm}"
			read doEnter && return 1
		done && unset doEnter
	}
	saveSSHEntry() {
		if [[ $TypeOfServer == MCServer ]];then
			addMCSrvEntry $addIP
		elif [[ $TypeOfServer == BackupServer ]];then
			setBackupSrvEntry $addIP && getFunction readNetConf
		fi
	}
	checkExternDBT() {
		local exDBTDIR=$(ssh -q -tt -i $dbtKeyFile -p $stdSSHport root@$addIP 'if [[ -z $DBTDIR ]];then echo false;else echo true;fi')
		local exDBTBACKUPDIR=$(ssh -q -tt -i $dbtKeyFile -p $stdSSHport root@$addIP 'if [[ -z $DBTBACKUPDIR ]];then echo false;else echo true;fi')
		if [[ $exDBTDIR =~ true ]] && [[ $exDBTBACKUPDIR =~ true ]];then
			runExternScript $addIP dataFunctions.sh setHandler local &
			runExternScript $addIP dataFunctions.sh setDBTData NetServer $internalIP &
			saveSSHEntry
			lastMsg="[Info/addConnection]: -> Die Verbindung zu [$addIP] wurde erfolgreich installiert!"
			setSyncData &
			if [[ -z $netHandler ]];then
				setHandler majority
				lastListMsg="${lgreen}[INFO]: ${norm}-> DBT-Modus von Lokal zu Netzwerk gewechselt!" 
				declare -g "magic_variable_1=$(echo -e "$lastListMsg")"
			fi	
		else
			lastMsg="${lred}[ERROR/addConnection]: ${norm}-> DBT wurde nicht installiert!"
		fi
	}
	
	addIP=$1 && TypeOfServer=$2
	if ! [[ -f $dbtKeyFile ]];then
		genSSHKey && clear
		echo -e "${yellow}[INFO/SSH]: -> Es wurde ein SSH-Key generiert!"
	fi
	checkConnection $addIP
	if [[ $connected == true ]];then
		checkExternDBT
	elif [[ $connected == ERROR ]];then
		lastMsg="${lred}[ERROR/addConnection]: ${norm}-> Die Verbindung zu [$addIP] kann nicht hergestellt werden! \n>> IP falsch oder anderer Standard-SSH Port [$stdSSHport] auf dem Server..."
	elif [[ $connected == false ]];then
		addSSHConnection
		checkConnection $addIP
		if [[ $connected == true ]];then
			checkExternDBT
		else
			lastMsg="${lred}[ERROR/addConnection]: ${norm}-> Installation der Verbindung zu [$addIP] fehlgeschlagen!"
		fi
	else
		lastMsg="${lred}[ERROR/addConnection]: ${norm}-> Code [ssh_addConn_001] Unknown state, please report on github..."
	fi
}

changeSTDsshPort() {
	local sshdConf="/etc/ssh/sshd_config"
	newPort=$1
	if [[ $newPort -gt 49151 ]] && [[ $newPort -lt 65536 ]];then
		stdPort=$(grep "Port.*" $sshdConf | cut -f2 -d' ')
		if ! [[ -z $(grep "#Port.*" $sshdConf) ]];then
			sed -i "s/#Port.*/Port $newPort/g" $sshdConf
		else
			sed -i "s/Port.*/Port $newPort/g" $sshdConf
		fi
		/usr/sbin/ufw delete allow $stdSSHport
		/usr/sbin/ufw allow $newPort/tcp
		sed -i "s/stdSSHport=.*/stdSSHport=$newPort/g" stdvariables.sh
		service sshd restart
	fi
}

assumeExOrIntern() {
	selectedMCSrv=$(grep -o 'ChoosedMCServer=[^"]*' $dataFile | cut -f2 -d'=')
	if ! [[ -z $selectedMCSrv ]];then
		readNetData $selectedMCSrv
		if [[ $internalIP == $physisIP ]];then
			location=intern
		else
			location=extern
		fi
	fi
}

$1 $2 $3 $4 $5 $6 $7
