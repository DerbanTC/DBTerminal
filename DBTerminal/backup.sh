#!/bin/bash
if [[ -z $SelfPath ]] || [[ $SelfPath != "$PWD"/ ]];then
	SelfPath="$(dirname "$(readlink -fn "$0")")/"
	cd $SelfPath
	source ./stdvariables.sh
	source ./inject.sh
fi

CRON_FILE=/var/spool/cron/crontabs/root 
sfFile="$SelfPath"backup.sh

dataFunction readBackupConf

getConfig() {
	bkupconfig=$mcDir$mcName/$bkupconfName
}

grepExtern() {
	if ! [[ -z "$1" ]];then
		mcName="$1"
		getFunction getSTDFiles
	fi
}

#### MC FUNCTIONS ####
stopVarMC() {
	getFunction getSTDFiles && getFunction readMCBackupConf
	if [[ $doAutostart == true ]];then
		echo -e "> MCServer [$mcName] wird gestoppt..."
		prefix="[Backup]"
		text="Tägliches Backup in Vorbereitung"
		getMCFunction doEnsureMCStop
		sleep 5
		resetAutostart=true
	else
		resetAutostart=false
	fi
}

restartVarMC() {
	if [[ $resetAutostart == true ]];then
		getConfig && getFunction setMCBackupConf Autostart true
	fi
}

#### STD VARIABLES ####
getBackupFiles() {
	getFunction getTime
	McSrvBackupFile="$date"_"$mcName"_McSrvFullBkup.tar
	ManuallyBackupFile="$date"_"$mcName"_ManuallyBkup.tar
}

getBackupDir() {
	getFunction getTime
	FullLocalBackupDir="$backupDir"local/minecraft/$mcName/
	varDailyDir="$FullLocalBackupDir"daily/
	varWeeklyDir="$FullLocalBackupDir"weekly/
	varMonthlyDir="$FullLocalBackupDir"monthly/
	varMirrorDir="$FullLocalBackupDir"lastDay/
	ManuallyBackupDir="$backupDir"local/minecraft/$mcName/manually/
}

getBackupDirNET() {
	netMirrorDir="$mcDir"/lastDay/$mcName/
	netDailyDir="$mcDir"/daily/
	netWeeklyDir="$mcDir"/weekly/
	netMonthlyDir="$mcDir"/monthly/
}

mkManualBackupFolders() {
	if ! [[ -d $ManuallyBackupDir ]];then
		mkdir $ManuallyBackupDir
		echo -e ">> Manueller Backup-Ordner erstellt -> $ManuallyBackupDir"
	fi
}

mkStdBackupFolders() {
    getTime
	mkdir -p "$backupDir"local/minecraft/$mcName/{monthly,weekly,daily,lastDay}
}

mkNetBackupFolder() {
	getFunction getTime
	mkdir -p "$backupDir"NetworkBkup/$varIP/minecraft/$mcName/{monthly,weekly,daily}
}

rmOldFiles() {
	find $varDailyDir* -mtime +$DailyBackupMax -exec rm {} \; 2>/dev/null
	find $varWeeklyDir* -mtime +$WeeklyBackupMax -exec rm {} \; 2>/dev/null
	find $netDailyDir* -mtime +$DailyBackupMax -exec rm {} \; 2>/dev/null
	find $netWeeklyDir* -mtime +$WeeklyBackupMax -exec rm {} \; 2>/dev/null
}

#### TIMED FUNCTIONS ####
doTimingBackup() {
	if [[ $DayOfWeek == $WeeklyDay ]];then
		unset -v latest
		for file in "$varDailyDir"/*; do
		  [[ $file -nt $latest ]] && latest=$file
		done
		if ! [[ -z $latest ]];then
			cp -np $latest $varWeeklyDir
		fi
	fi
	if [[ $DayOfMonth == $MonthlyDay ]];then
		unset -v latest
		for file in "$varDailyDir"/*; do
		  [[ $file -nt $latest ]] && latest=$file
		done
		if ! [[ -z $latest ]];then
			cp -np $latest $varMonthlyDir
		fi
	fi
}

doTimingBackupNET() {
	netBackupDir="$backupDir"NetworkBkup
	if [[ $DayOfWeek == $WeeklyDay ]];then
		unset -v latest
		for file in "$dailyDir"/*; do
		  [[ $file -nt $latest ]] && latest=$file
		done
		if ! [[ -z $latest ]];then
			cp -np $latest $weeklyDir
		fi
	fi
	if [[ $DayOfMonth == $MonthlyDay ]];then
		unset -v latest
		for file in "$dailyDir"/*; do
		  [[ $file -nt $latest ]] && latest=$file
		done
		if ! [[ -z $latest ]];then
			cp -np $latest $monthlyDir
		fi
	fi
}

#### LOCAL BACKUP FUNCTIONS #####
doBackupOne_LOCAL() { # does only make a copy from the mirrorDir to the manually dir
	varTarFile=$1
	varZipFile="$varTarFile".gz
	varToCopyDir=$2
	varBackupDir="$3"
	getTime && cd $varBackupDir
	if [[ -f $varZipFile ]];then
		echo -e "> Datei [$varTarFile] existiert bereits. Erstelle weitere Datei..."
		count=$(ls $varBackupDir$date*.tar.gz | wc -l)
		varName=${varTarFile%.tar*}
		varTarFile="$varName"_"$count".tar
	else
		echo -e "> Erstelle Datei [$varTarFile]..."
	fi
	tar -cf $varTarFile -C $varToCopyDir .
	gzip $varTarFile
}

doMirrorMCServer() {
	cp -pr $1 $2
}

backupVarMC_LOCAL() {
	mkStdBackupFolders
	getBackupDir && getBackupFiles
	doMirrorMCServer  $varMCDirectory $varMirrorDir
	doBackupOne_LOCAL $McSrvBackupFile $varMirrorDir $varDailyDir
	doTimingBackup && rmOldFiles
}

doBackupAll_LOCAL() {
	countSlashes=$(echo $mcDir | grep -o "/" | wc -l)
	lastSlash=$(( countSlashes +1 ))
	for varMCDirectory in $(ls -d $mcDir*/);do
		mcName="$(echo "$varMCDirectory" | cut -d'/' -f$lastSlash)"
		getConfig && getFunction readMCBackupConf
		if [[ $doBackup == true ]] && [[ $BackupTime == $startTime ]];then
			getBackupDir && mkStdBackupFolders
			dailyBackupExist=$(ls $varDailyDir$date*.tar.gz 2>/dev/null | wc -l)
			BackupIsRunning="$varMCDirectory"tmpdbtfile
			if [[ $dailyBackupExist == 0 ]] && ! [[ -f $BackupIsRunning ]];then
				echo -e "Backup is running! Do not edit anything here..." >$BackupIsRunning &&
				stopVarMC && backupVarMC_LOCAL && restartVarMC &&
				rm $BackupIsRunning
			fi
		fi
	done
}

#### LOCAL DATA HANDLER ##### only needed on a $BackupServer
netBackupHandler() { 
	netBackupDir="$backupDir"NetworkBkup
	for varIPDir in "$netBackupDir"/*; do
		varIP=${varIPDir##*/}
		for mcDir in ${varIPDir}/minecraft/*; do
			mcName=${mcDir##*/} && mkNetBackupFolder
			getBackupDirNET && getBackupFiles
			doBackupOne_LOCAL $McSrvBackupFile $netMirrorDir $netDailyDir
			doTimingBackupNET && rmOldFiles
		done	
	done
}

#### NETWORK BACKUP FUNCTIONS (intern) #####
netSyncLocal() {	
# only needed if you have an mc-server on your BackupServer, badly...
	grepExtern $1
	stopVarMC
	backupVarMC_LOCAL
	varMCDir="$mcDir"$mcName/
	mirrorDir="$backupDir"NetworkBkup/$fromCopyIP/minecraft/$mcName/lastDay/
	varBackupDir="$netBackupDir"$internalIP/
	varLocalBackupDir="$localBackupDir"minecraft/
	if ! [[ -d $varBackupDir ]];then
		mkdir -p $varBackupDir
	fi
	echo -e "[INFO/netSync]: -> Starte lokale Synchronisation\n>>  [$varMCDir]\n>> nach [$mirrorDir]"
	cp -pr $varMCDir $mirrorDir
	restartVarMC
}

netSyncVarServer() {
# from $1 to $BackupServer (netSyncVarServer $IP $mcName ) 
	fromCopyIP=$1
	mcName=$2
	if [[ $fromCopyIP == $BackupServer ]] && [[ $BackupServer == $internalIP ]];then
		netSyncLocal
		return 1
	elif [[ $fromCopyIP == $BackupServer ]];then
		getSSHFunction runExternScript backup.sh netSyncLocal $mcName
		return 1
	else
		if [[ $fromCopyIP == $internalIP ]];then
			FromLocation=intern
			Arg1="$backupDir"local/minecraft/$mcName/lastDay/
		else
			FromLocation=extern
			mirrorDir=$(grep $fromCopyIP $syncData | cut -f2 -d'=' | cut -f2 -d',')local/minecraft/$mcName/lastDay/
			Arg1=root@$fromCopyIP:$mirrorDir
		fi
	
		if [[ $BackupServer == $internalIP ]];then
			ToLocation=intern
			Arg2="$BackupDir"NetworkBkup/$fromCopyIP/minecraft/$mcName/lastDay/
		else
			ToLocation=extern
			mirrorDir=$(grep $BackupServer $syncData | cut -f2 -d'=' | cut -f2 -d',')NetworkBkup/$fromCopyIP/minecraft/$mcName/lastDay/
			Arg2=root@$BackupServer:$mirrorDir
		fi
	fi
	if [[ $FromLocation == extern ]] && [[ $ToLocation == extern ]];then
		scp -i $dbtKeyFile -P $stdSSHport -3pr $Arg1 $Arg2
	else
		scp -i $dbtKeyFile -P $stdSSHport -pr $Arg1 $Arg2
	fi
}
netSyncALL() {
	if [[ -z $BackupServer ]];then
		return 1
	fi
	n=0
	while IFS= read -a line; do
		n=$(( n + 1 ))
		dataFunctions readNetData $n
		if [[ $doBackup == true ]];then
			netSyncVarServer $physisIP $mcName
		fi
	done < "$netData"
	if [[ $BackupServer == $internalIP ]];then
		netBackupHandler
	else
		runExternScript $BackupServer backup.sh netBackupHandler
	fi
}

####COMMAND BACKUP FUNCTIONS ##### Executed via DB-Terminal (TerminalCMD.sh)
cmdBackupManually() {
	grepExtern $1
	varMCDirectory="$mcDir"$1
	if ! [[ -d $varMCDirectory ]];then
		echo -e "${lred}[ERROR/Backup]: ${norm}-> Falscher MC-Name! Ordner [$varMCDirectory] nicht gefunden!" && return 1
	fi
	getBackupDir && getBackupFiles
	mkManualBackupFolders && mkStdBackupFolders
	getFunction readMCBackupConf && stopVarMC
	doMirrorMCServer $varMCDirectory $varMirrorDir
	doBackupOne_LOCAL $ManuallyBackupFile $varMirrorDir $ManuallyBackupDir
	restartVarMC
	varBackupFile=$ManuallyBackupDir$varTarFile.gz
	echo -e "> FINISHED! Lokale Kopie erstellt!\n> Datei: $ManuallyBackupDir\n> Pfad: $varTarFile.gz"
	cd $SelfPath
}

grepNewestBackup() {
	grepExtern $1
	getBackupDir && getBackupFiles
	if [[ -d $ManuallyBackupDir ]];then
		unset -v latest; for file in "$ManuallyBackupDir"*; do [[ $file -nt $latest ]] && latest=$file; done
	fi
	if [[ -z $latest ]];then
		echo -e "NoFiles"
	else
		echo -e "$latest"
	fi
}

#### CRON JOB UPDATE ######## 
updateCronJob() {
	addCronJob() {
		local varMin=$2 && local varHour=$1 && local jobType=$3
		cronJob="$varMin $varHour * * * $sfFile $jobType"
		cronExist=$(grep -F "$cronJob" $CRON_FILE)
		if [[ -z $cronExist  ]];then
			crontab -l | { cat; echo "$cronJob"; } | crontab -
		fi
	}
	removeCronJob() {
		local check=$(grep -F "$1" $CRON_FILE)
		local varJob="$1"
		if ! [[ -z "$check" ]];then
			crontab -l | grep -Fv "$varJob" | crontab -
		fi
	}
	checkConfigEntry() {
		unset found && local searchTime=$1 && local jobType=$2
		local allEntries="$(grep "\-*$(hostname -i),*" $localConf | sed "s/- //g")"
		for varEntry in $allEntries;do
			varTime=$(echo "$varEntry" | cut -f4 -d,)
			varDoBackup=$(echo "$varEntry" | cut -f3 -d,)
			if [[ $varTime =~ ^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$ ]] && [[ $varTime == $searchTime ]] && [[ $varDoBackup == true ]];then
				local found=true
			fi
		done
		if [[ -z "$found" ]];then
			local varMin=$(echo $searchTime | cut -f2 -d:)
			local varHour=$(echo $searchTime | cut -f1 -d:)
			varJob="$varMin $varHour * * * $sfFile $jobType"
			removeCronJob "$varJob"
		fi
		unset varTime && unset varJob
	}

	readLocalConfig() {
		local allEntries="$(grep "\-*$(hostname -i),*" $localConf | sed "s/- //g")"
		for varEntry in $allEntries;do
			local varTime=$(echo "$varEntry" | cut -f4 -d,)
			local varDoBackup=$(echo "$varEntry" | cut -f3 -d,)
			if [[ $varTime =~ ^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$ ]] && [[ $varDoBackup == true ]];then
				local varMin=$(echo $varTime | cut -f2 -d:)
				local varHour=$(echo $varTime | cut -f1 -d:)
				addCronJob $varHour $varMin doCronJob
			fi
		done
	}
	readNetConfig() {
		if [[ $netHandler == majority ]];then
			dataFunction readNetConf
			if [[ $netHandler == majority ]] && [[ $syncEnabled == true ]] && [[ $syncTime =~ ^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$ ]];then
				local varMin=$(echo $syncTime | cut -f2 -d:)
				local varHour=$(echo $syncTime | cut -f1 -d:)
				addCronJob $varHour $varMin doCronSync
			fi
		fi
	}
	checkCronEntries() {
		while read line;do
			searchTime="$(echo $line | cut -f2 -d' '):$(echo $line | cut -f1 -d' ')"
			checkConfigEntry "$searchTime" doCronJob
		done < <(crontab -l | grep doCronJob)
	}
	checkSyncEntries() {
		if [[ $netHandler == majority ]] && [[ $syncEnabled == true ]];then
			while read line;do
				local searchTime="$(echo $line | cut -f2 -d' '):$(echo $line | cut -f1 -d' ')"
				if ! [[ $searchTime == $syncTime ]];then
					removeCronJob "$line"
				fi
			done < <(crontab -l | grep "doCronSync")
		else
			#remove all Cronjobs called doCronSync
			while read line;do
				removeCronJob "$line"
			done < <(crontab -l | grep "doCronSync")
		fi
	}

	dataFunction updateLocalConf										#1 update localconf
	readLocalConfig																#2 add cronJob for all MC entries in localconf
	readNetConfig																#3 add cronJob for syncTime (only in networks)
	checkCronEntries && checkSyncEntries						#4 Remove unused cronJobs
	}

#### CRON JOB ######## This runs only via cronJob (crontab -l)
doCronJob() {
	startTime=$(date +%R)
	if [[ $netHandler == majority ]];then
		doBackupAll_LOCAL
		dataFunction readNetConf
		if [[ $syncEnabled == true ]] && [[ $syncTime == $startTime ]];then
			netSyncALL
		fi	
	else	
		doBackupAll_LOCAL
	fi
}

$1 $2 $3 $4 $5



