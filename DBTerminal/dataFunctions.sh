#!/bin/bash
if [[ -z $SelfPath ]] || [[ $SelfPath != "$PWD"/ ]];then
	SelfPath="$(dirname "$(readlink -fn "$0")")/"
	cd $SelfPath
	source ./stdvariables.sh
	source ./inject.sh
fi

getFunction() {
	source ""$SelfPath"functions.sh" $1 $2 $3
}

##### DBTDATA ########################################################################
# dataFile="$dataDir"dbtdata
# includes attached services related to the 3 panes in the tmux session like MCserver, htop 
# or extern bash-Terminals via ssh
#############################################################################
fixEntries() {
	n=0
	for fullEntry in $(grep -E "^MCServer[0-9]+=.*" $dataFile);do
		varEntry=$(echo $fullEntry | cut -f2 -d=)
		if [[ -z $varEntry ]];then
			sed -i "s/$fullEntry//g" $dataFile
		else
			n=$(( n + 1 ))
			if ! [[ $(echo $fullEntry | cut -f1 -d=) == "MCServer$n" ]];then
				sed -i "s/$fullEntry/MCServer$n=$varEntry/g" $dataFile
			fi
			
		fi
	done
	sed -i '/^\s*$/d' $dataFile
}

addMCSrvEntry() {
	fixEntries && varIP=$1
	if [[ -z $(grep -oE "^MCServer[0-9]=$varIP" $dataFile) ]];then
		nr=$(( $(grep -Ec "^MCServer[0-9]+=.*" $dataFile) +1 ))
		echo -e "MCServer$nr=$1" >> $dataFile
	fi
}

delMCSrvEntry() {
	varIP=$1 && varEntry=$(grep ''$varIP'$' $dataFile)
	if ! [[ -z $varEntry ]];then
		sed -i "s/$varEntry//g" $dataFile && sed -i '/^$/d' $dataFile
		fixEntries
	fi
}

setBackupSrvEntry() {
	varIP=$1
	line=$(cat $dataFile | grep -o 'BackupServer=[^"]*')
	if ! [[ -z $line ]];then
		oldIP=$(echo $line | cut -f 2 -d '=')
		if ! [[ $varIP == $oldIP ]];then
			newLine="BackupServer=$varIP"
			sed -i "s/$line/$newLine/g" $dataFile
		fi
	else
		echo -e "BackupServer=$varIP" >> $dataFile
	fi
}

setDBTData() {
# setDBTData MCServer 1 or setDBTData TMUX00 "htop,$IP"
	entry=$1 && arg=$2
	case $entry in
		MCServer)
			sed -i s/ChoosedMCServer=.*/ChoosedMCServer=$arg/g $dataFile
		;;
		TMUX00)
			sed -i s/AttachedTMUX00=.*/AttachedTMUX00=$arg/g $dataFile
		;;
		TMUX02)
			sed -i s/^AttachedTMUX02=.*/AttachedTMUX02=$arg/g $dataFile
		;;
		NetServer)
			sed -i s/^NetworkServer=.*/NetworkServer=$arg/g $dataFile
		;;
	esac
	unset entry && unset arg
}

readDBTData() {
	if [[ -f $dataFile ]];then
		selectedMCSrv=$(grep -o 'ChoosedMCServer=[^"]*' $dataFile | cut -f2 -d'=')
		selectedTMUX00=$(grep -o 'AttachedTMUX00=[^"]*' $dataFile | cut -f2 -d'=')
		selectedTMUX02=$(grep -o 'AttachedTMUX02=[^"]*' $dataFile | cut -f2 -d'=')
		countOfExternServer=$(grep -c 'MCServer[0-9]=[^"]*' $dataFile)
		externBackupServer=$(grep -c 'BackupServer=[^"]*' $dataFile | cut -f2 -d'=')
	else
		echo -e "ChoosedMCServer=\nAttachedTMUX00=\nAttachedTMUX02=\nBackupServer=\nNetworkServer=" > $dataFile
	fi
}

#### LOCALDATA #########################################################################
# localData="$dataDir"localdata
# stores avaible infos about mc-servers. This will only list a created dir if it includes a jar-file.
#############################################################################
setLocalData() {
	countSlashes=$(echo $mcDir | grep -o "/" | wc -l)
	lastSlash=$(( countSlashes +1 )) && n=0
	tmpLocalData="$tmpDir"tmplocaldata
	if [[ -f $tmpLocalData ]];then
		rm $tmpLocalData
	fi
	for mcName in $(ls -d $mcDir*/ | cut -f$lastSlash -d '/');do
		cd $mcDir$mcName/ && jar=$(ls -f | grep -c '[0-9|a-z|A-Z].jar$')
		if [[ $jar == 1 ]];then
			n=$(( n +1 )) && getFunction getSTDFiles
			getFunction readMCBackupConf && getFunction readProperties
			local newEntry="$internalIP,$mcName,$MCipfull,$MCportfull,$AutostartLine,$BackupLine,$BackupTime"
			if [[ -f $tmpLocalData ]];then
				if [[ -z $(grep "$newEntry" $tmpLocalData) ]];then
					echo -e "$newEntry" >> $tmpLocalData
				fi
			else
				echo -e "$newEntry" >> $tmpLocalData
			fi
		fi
	done && cd $SelfPath && 
	if [[ -f $tmpLocalData ]];then
		cp $tmpLocalData $localData
	else
		touch $localData
	fi
}

readLocalData() {
	if ! [[ -f $localData ]];then setLocalData;fi
	if ! [[ -z $1 ]];then
		nr=$1 && oIFS="$IFS"
		unset fullEntry && fullEntry=$(sed "${nr}q;d" "${localData}" | sed s/' '//g)
		for varEntry in `echo $fullEntry`; do
			IFS=',' && arr=($varEntry)
			physisIP=${arr[0]} && mcName=${arr[1]}
			notedIP=$(echo ${arr[2]}  | cut -f2 -d'=')
			notedPort=$(echo ${arr[3]}  | cut -f2 -d'=')
			isRunning=$(echo ${arr[4]}  | cut -f2 -d'=')
			doBackup=$(echo ${arr[5]}  | cut -f2 -d'=')
			doBackupTime=$(echo ${arr[6]})
			location=intern
			if [[ $isRunning == false ]];then
				mcRunStateCode="${lred}\U274E"
			elif [[ -z $notedIP ]] || [[ -z $notedPort ]];then
				mcRunStateCode="${lred}\U2753"
			elif [[ $isRunning == true ]];then
				mcRunStateCode="${green}\U2705"
	#			mcRunStateCode="${green}\U2714"
			else
				mcRunStateCode="${lred}\U2755"
			fi
		done && IFS="$oIFS"
	else
		unset mcName
	fi
}

copyLocalDataSSH() {
	varIP=$1
	readSyncData $varIP
	if [[ -z $varDBTDir ]];then return 1;fi
	varLocalData="$varDBTDir"/data/localdata
	counttmp=$(ls -f | grep -c tmp$)
	touch "$dataDir"localDatatmp$counttmp
	scp -q -i $dbtKeyFile -P $stdSSHport root@$varIP:$varLocalData $tempDir
	while IFS= read -r line; do
		echo $line >> $netData
	done < "$tempDir"localdata
	rm "$tempDir"localdata && rm "$dataDir"localDatatmp$counttmp
}

##### NETDATA ########################################################################
# netData="$dataDir"netdata
# On a network this includes all data from the localdata-files from extern servers.
# On a local installation it's only a copy from the localdata
#############################################################################
setNetData() {
	if [[ -f $netData ]];then
		bufferIP=$(sed "${selectedMCSrv}q;d" $netData | sed s/' '//g | cut -f1,2 -d',')
		rm $netData
	fi
	setLocalData
	while IFS= read -r line; do
		echo $line >> $netData
	done < $localData
	for externMCServer in $(grep -E "^MCServer[0-9]+=" $dataFile | cut -f 2 -d '=');do
		getSSHFunction checkConnection $externMCServer
		if [[ $connected == true ]];then
			getSSHFunction runExternScript $externMCServer dataFunctions.sh setLocalData extern
			copyLocalDataSSH $externMCServer
		fi
	done
	if [[ -f $netData ]];then
		newIP=$(sed "${selectedMCSrv}q;d" $netData | sed s/' '//g | cut -f1,2 -d',')
		if ! [[ $bufferIP == $newIP ]];then
			newSel=$(grep -n "$bufferIP" $netData |  cut -f1 -d':')
			if [[ -z $newSel ]];then
				setDBTData MCServer
			else
				setDBTData MCServer $newSel
			fi
		fi
	fi
}

updateLocalToNetData() {
	setLocalData
	while IFS= read -r newEntry; do
		local varName=$(echo $newEntry | cut -f2 -d,)
		local oldEntry=$(grep "$(hostname -i),$varName" $netData)
		if [[ -z $oldEntry ]];then
			setNetData
		elif ! [[ $oldEntry == $newEntry ]];then
			sed -i "s/$oldEntry/$newEntry/g" $netData
		fi
	done < $localData
}

updateVarNetData() {
	getSSHFunction runExternScript $physisIP dataFunctions.sh setLocalData
	readSyncData
	local varLocalData="$varDBTDir"data/localdata
	local copyOf="$tmpDir"localdata
	local tmpFile="$tmpDir"localdata@$physisIP
	if [[ -f $tmpFile ]];then rm $tmpFile;fi
	scp -q -i $dbtKeyFile -P $stdSSHport root@$physisIP:$varLocalData $tmpDir
	if [[ -f $copyOf ]];then
		cp $copyOf $tmpFile && rm $copyOf
		while read newEntry;do
			local varName=$(echo $newEntry | cut -f2 -d,)
			local oldEntry=$(grep "$physisIP,$varName" $netData)
			if [[ -z $oldEntry ]];then
				setNetData &
				break
			elif ! [[ $oldEntry == $newEntry ]];then
				sed -i "s/$oldEntry/$newEntry/g" $netData
			fi
		done < $tmpFile
	fi
}

readNetData() { #read specific entry from netdata
	if ! [[ -f $netData ]];then
		setNetData
	fi
	if ! [[ -z $1 ]] && [[ -f $netData ]];then
		nr=$1 && oIFS="$IFS"
		unset fullEntry && fullEntry=$(sed "${nr}q;d" "${netData}" | sed s/' '//g)
		for varEntry in `echo $fullEntry`; do
			IFS=',' && arr=($varEntry)
			physisIP=${arr[0]} && mcName=${arr[1]}
			notedIP=$(echo ${arr[2]}  | cut -f2 -d'=')
			notedPort=$(echo ${arr[3]}  | cut -f2 -d'=')
			isRunning=$(echo ${arr[4]}  | cut -f2 -d'=')
			if [[ $isRunning == false ]];then
				mcRunStateCode="${lred}\U274E"
			elif [[ -z $notedIP ]] || [[ -z $notedPort ]];then
				mcRunStateCode="${lred}\U2753"
			elif [[ $isRunning == true ]];then
				mcRunStateCode="${green}\U2705"
			else
				mcRunStateCode="${lred}\U2755"
			fi
			doBackup=$(echo ${arr[5]}  | cut -f2 -d'=')
			doBackupTime=$(echo ${arr[6]})
			if [[ $internalIP == $physisIP ]];then
				location=intern
			else
				location=extern
			fi
		done
		IFS="$oIFS"
	fi
}

##### SYNCDATA ########################################################################
setSyncData() {
	if [[ -f $syncData ]];then
		rm $syncData 2>/dev/null && touch $syncData
	else
		touch $syncData
	fi
	for externMCServer in $(grep MCServer[0-9]= $dataFile | cut -f 2 -d '=');do
		getSSHFunction checkConnection $externMCServer
		if [[ $connected == true ]];then
			varDBTDir="$(ssh -i $dbtKeyFile -p $stdSSHport root@$externMCServer 'echo $DBTDIR')"
			VarTmpsyncdata=""$varDBTDir"/tmp/tmpsyncdata"
			getSSHFunction runExternScript $externMCServer dataFunctions.sh setTempSyncData
			scp -q -i $dbtKeyFile -P $stdSSHport root@$externMCServer:$VarTmpsyncdata $tempDir
			getSSHFunction runExternScript $externMCServer dataFunctions.sh setTempSyncData delete
			tmpsyncdata="$SelfPath"tmp/tmpsyncdata
			if [[ -f $tmpsyncdata ]];then
				varIP=$(grep internalIP= $tmpsyncdata | cut -f2 -d'=')
				varDBTDir=$(grep dbtDir= $tmpsyncdata | cut -f2 -d'=')
				varBackupDir=$(grep backupDir= $tmpsyncdata | cut -f2 -d'=')
				varMCDir=$(grep mcDir= $tmpsyncdata | cut -f2 -d'=')
				echo -e "$varIP=$varDBTDir,$varBackupDir,$varMCDir" >> $syncData
				rm $tmpsyncdata
			fi
		fi
	done
	
	if ! [[ -z $BackupServer ]];then
		entryExist=$(grep MCServer= $dataFile | grep -c $BackupServer)
		if [[ $entryExist == 0 ]];then
			varDBTDir=$(ssh -tt -i $dbtKeyFile -p $stdSSHport root@$BackupServer ps -aux | grep "SCREEN -dmS ReboundLoop bash" | cut -f 3 -d '-' | cut -f 2 -d ' ' | sed s/reboundloop.sh//g)
			VarTmpsyncdata="$varDBTDir"tmp/tmpsyncdata
			getSSHFunction runExternScript $BackupServer dataFunctions.sh setTempSyncData
			scp -q -i $dbtKeyFile -P $stdSSHport root@$BackupServer:$VarTmpsyncdata $tempDir
			getSSHFunction runExternScript $BackupServer dataFunctions.sh setTempSyncData delete
			tmpsyncdata="$SelfPath"tmp/tmpsyncdata
			if [[ -f $tmpsyncdata ]];then
				varIP=$(grep internalIP= $tmpsyncdata | cut -f2 -d'=')
				varDBTDir=$(grep dbtDir= $tmpsyncdata | cut -f2 -d'=')
				varBackupDir=$(grep backupDir= $tmpsyncdata | cut -f2 -d'=')
				varMCDir=$(grep mcDir= $tmpsyncdata | cut -f2 -d'=')
				echo -e "$varIP=$varDBTDir,$varBackupDir,$varMCDir" >> $syncData
				rm $tmpsyncdata
			fi
		fi
	fi
}

setTempSyncData() {
	tmpsyncdata="$SelfPath"tmp/tmpsyncdata
	if [[ $1 == delete ]];then
		rm $tmpsyncdata
	else
		echo -e "internalIP=$internalIP\ndbtDir=$SelfPath\nbackupDir=$backupDir\nmcDir=$mcDir" > $tmpsyncdata
	fi
}

readSyncData() {
	if ! [[ -f $syncData ]];then
		setSyncData
	fi
	local varIP=$1
	local syncEntry=$(grep "$varIP" $syncData | cut -f2 -d=)
	varDBTDir=$(echo $syncEntry | cut -f1 -d,)
	varBackupDir=$(echo $syncEntry | cut -f2 -d,)
	varMCDir=$(echo $syncEntry | cut -f3 -d,)
}
##### NETCONF ##########################################################################
syncNetConf() {
	downloadLocalConf() {
		for externMCServer in $(grep MCServer[0-9]= $dataFile | cut -f 2 -d '=');do
			if [[ -z $1 ]] || [[ $1 == $externMCServer ]];then
				getSSHFunction checkConnection $externMCServer
				if [[ $connected == true ]];then
					readSyncData $externMCServer
					getSSHFunction runExternScript $externMCServer dataFunctions.sh updateLocalConf			
					varLocalConf="$varDBTDir"data/localconf
					scp -q -i $dbtKeyFile -P $stdSSHport root@$externMCServer:$varLocalConf "$tempDir"localconf@$externMCServer
				fi
			fi
		done
	}
	addLocalToNetConf() {
		while IFS= read -r line;do
			case $line in
				' - '*)
					mcName=$(echo $line | cut -d' ' -f2 | cut -f2 -d,)
					newEntry="$(echo $line | sed "s/$(hostname -i)/intern/g")"
					searchEntry="$(echo $newEntry | sed "s/- //g")"
					varTime=$(echo $newEntry | cut -d',' -f4)
					ipAndName="intern,$mcName"

					varTime=$(echo $newEntry | cut -d',' -f4)
					if [[ -z $(grep -E "intern,$mcName" $netConf) ]];then
						lineNR=$(grep -n "intern-mcServer:" $netConf | cut -f1 -d:)
						if [[ $(wc -l $netConf | cut -f1 -d' ') == $lineNR ]];then
							echo -e " $newEntry" >>$netConf
						else
							lineNR=$(( lineNR + 1 ))
							sed -i ""$lineNR"i\ -$(echo $newEntry | cut -f2 -d-)" $netConf
						fi
					elif ! [[ -z $(grep -F "\- $searchEntry" $netConf) ]];then
						sed -i "s/$(grep "$ipAndName" $netConf)/ $(echo $newEntry)/g" $netConf
					fi
				;;
			esac
		done <$localConf
	}
	addExternLocalToNetConf() {
		cd $tempDir && for varLocalConf in localconf@*;do
			varIP=$(echo $varLocalConf | cut -f2 -d"@")
			if [[ -z $(grep "$varIP" $dataFile) ]];then
				return 1
			fi
			while IFS= read -r line; do
				case $line in
					' - '*)
						ipAndName=$(echo $line | cut -f2 -d' ')
						if [[ -z $(grep -x "$varIP:" $netConf) ]];then
							echo -e "$varIP:\n$line" >>$netConf
						elif [[ -z $(grep "$ipAndName" $netConf) ]];then
							lineNR=$(grep -n "$varIP:" $netConf | cut -f1 -d:)
							if [[ $(wc -l $netConf | cut -f1 -d' ') == $lineNR ]];then
								echo -e "$line" >>$netConf
							else
								lineNR=$(( lineNR + 1 ))
								sed -i ""$lineNR"i\ -$(echo $line | cut -f2 -d-)" $netConf
							fi
						elif [[ -z $(grep -x "$line" $netConf) ]];then
							sed -i "s/$(grep "$ipAndName" $netConf)/$line/g" $netConf
						fi
					;;
				esac
			done <$varLocalConf
		done && cd $SelfPath
	}
	cleanNetConf() {
		while IFS= read -r line; do
			case $line in
				' - '*)
					varEntry=$(echo $line | cut -f2 -d' ')
					varIP=$(echo $varEntry | cut -f1 -d,)
					if [[ $varIP == intern ]];then
						varConf=$localConf
						searchEntry=$internalIP,$(echo $line | cut -f2 -d' ' | cut -f2 -d,)
					else
						varConf="$tempDir"localconf@$varIP
						searchEntry=$(echo $line | cut -f2 -d' ')
					fi
					if [[ -z $(grep "$searchEntry" $varConf) ]];then
						sed -i "s/$line//g" $netConf
						sed -i '/^\s*$/d' $netConf
					fi
				;;
			esac
		done <$netConf
	}
	downloadLocalConf $1 && addLocalToNetConf && addExternLocalToNetConf && cleanNetConf
}

setNetConf() {
	case $1 in
		stdBackupTime)
			sed -i s/backup-time:.*/backup-time:$1/g $netConf
		;;
		syncTime)
			sed -i "s/sync-time:.*/sync-time: $2/g" $netConf
		;;
		syncEnabled)
			sed -i "s/sync-enabled:.*/sync-enabled: $2/g" $netConf
		;;
	esac
}

readNetConf() {
	if [[ -f $netConf ]];then 
		stdBackupTime=$(grep std-backup-time= $netConf | cut -f2 -d: | sed "s/ //g")	# 00:00-23:59
		syncTime=$(grep sync-time: $netConf | cut -f2 -d: | sed "s/ //g") # 00:00-23:59
		syncEnabled=$(grep sync-enabled: $netConf | cut -f2 -d':' | sed "s/ //g") # 00:00-23:59
	else
		echo -e "std-backup-time:03:00\nsync-enabled: false\nsync-time:\nintern-mcServer:" > $netConf
		syncTime="03:00"
		getSSHFunction syncNetConf
	fi
}
#### LOCALCONF #########################################################################
updateLocalConf() {
	if ! [[ -f $localConf ]];then
		echo -e "extern-backup: false\nmcServerList:" >$localConf
#		echo -e "local-mode: sync\nstd-backup-time: 04:00\nextern-backup: false\nmcServerList:" >$localConf
	fi
	while read line; do
		case $line in
			-*)
				matchExp="[^-]* [a-z|A-Z|0-9]* [of|0-9|:]*$"
				if [[ $line =~ $matchExp ]];then 
					mcName=$(echo $line | cut -d' ' -f2)
					if ! [[ -d $mcDir$mcName ]];then
						sed -i "s/$line//g" $localConf
					fi
				elif [[ $line =~ [^-]* ]];then 
					sed -i "s/$line//g" $localConf		
				fi
				;;
		esac
	done <$localConf
	sed -i '/^\s*$/d' $localConf
	countSlashes=$(echo $mcDir | grep -o "/" | wc -l) && lastSlash=$(( countSlashes +1 ))
	for mcName in $(ls -d $mcDir*/ | cut -f$lastSlash -d '/');do
		cd $mcDir$mcName/ && jar=$(ls -f | grep -c '[^*].jar')
		if [[ $jar == 1 ]];then
			getFunction getSTDFiles && getFunction readMCBackupConf && getFunction readProperties
			newEntry=" - $internalIP,$mcName,$doBackup,$BackupTime"
			if [[ -z $(grep "-" $localConf | grep "$mcName") ]];then
				echo -e "$newEntry" >>$localConf
			else
				varEntry=$(grep "-" $localConf | grep "$mcName")
				if [[ -z $varEntry ]];then
					varEntry="- $internalIP,$mcName,off,03:00"
					echo -e "$varEntry" >>$localConf
				elif [[ -z $(grep "$varEntry" $localConf) ]];then
					sed -i "s/*- $internalIP,$mcName*/$newEntry/g" $localConf
				fi
			fi
		fi
	done && cd $SelfPath && readLocalConf
}

setLocalConf() {
	case $1 in
		backupMode)
			sed -i "s/local-mode:.*/local-mode: $2/g" $localConf
		;;
		stdTime)
			sed -i "s/std-backup-time:.*/std-backup-time: $2/g" $localConf
		;;
		backupTime)
			newTime=$2
			varMCName=$3
			varString="$internalIP,$varMCName"
			sed -i "s/$varString(.*)[0-9][0-9]:[0-9][0-9]$/$varString\1$newTime/g" $localConf
		;;
		backupTimeALL)
			newTime=$2
			sed -i "s/$internalIP,(.*)[0-9][0-9]:[0-9][0-9]$/$internalIP,\1$newTime/g" $localConf
		;;
	esac
}

readLocalConf() {
	localBackupMode=$(grep "local-mode:" $localConf | cut -f2 -d: | sed "s/ //g")
	localSTDBackupTime=$(grep "std-backup-time:" $localConf | cut -f2 -d' ')
	doExternBackup=$(grep "extern-backup:" $localConf | cut -f2 -d: | sed "s/ //g")
}

setHandler() {
	if [[ $1 == majority ]];then
		sed -i s/^netHandler=.*/netHandler=$1/g stdvariables.sh
	elif [[ $1 == local ]];then
		sed -i s/^netHandler=.*/netHandler=$1/g stdvariables.sh
	elif [[ $1 == empty ]];then
		sed -i s/^netHandler=.*/netHandler=/g stdvariables.sh
	fi
}

#### BACKUPCONF #######################################################################
readBackupConf() {
	if ! [[ -f $backupConf ]];then
		echo -e "DailyBackupMax=31" >> $backupConf
		echo -e "WeeklyBackupMax=24" >> $backupConf
		echo -e "WeeklyDay=5" >> $backupConf
		echo -e "MonthlyDay=28" >> $backupConf
	fi
	DailyBackupMax=$(grep "DailyBackupMax=.*" $backupConf | cut -f2 -d=)
	WeeklyBackupMax=$(grep "WeeklyBackupMax=.*" $backupConf | cut -f2 -d=)
	WeeklyDay=$(grep "WeeklyDay=.*" $backupConf | cut -f2 -d=)
	MonthlyDay=$(grep "MonthlyDay=.*" $backupConf | cut -f2 -d=)
}

setBackupConf() {
	if [[ -z $1 ]] || [[ -z $2 ]];then return 1;fi
	case $1 in
		DailyMax)
			sed -i "s/DailyBackupMax=.*/DailyBackupMax=$2/g" $backupConf
		;;
		WeeklyMax)
			sed -i "s/WeeklyBackupMax=.*/WeeklyBackupMax=$2/g" $backupConf
		;;
		WeeklyDay)
			sed -i "s/WeeklyDay=.*/WeeklyDay=$2/g" $backupConf
		;;
		MonthlyDay)
			sed -i "s/MonthlyDay=.*/MonthlyDay=$2/g" $backupConf
		;;
	esac
}

syncBackupConf() {
	for externMCServer in $(grep MCServer[0-9]= $dataFile | cut -f 2 -d '=');do
		getSSHFunction checkConnection $externMCServer
		if [[ $connected == true ]];then
			readSyncData $externMCServer
			local externBackupConf="$varDBTDir"data/backupconf
			scp -q -i $dbtKeyFile -P $stdSSHport -pr $backupConf root@$externMCServer:$externBackupConf
		fi
	done
}

$1 $2 $3 $4 $5 $6 $7
