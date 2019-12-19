#!/bin/bash
SelfPath="$(dirname "$(readlink -fn "$0")")/"
cd $SelfPath
source ./stdvariables.sh

DailyBackupMax=30
WeeklyDay=4
MonthlyDay=1

installCronJob() {
	CRON_FILE=/var/spool/cron/crontabs/root
	sfFile="$(dirname "$(readlink -fn "$0")")/backup.sh"
	cronJob="0 4 * * * $sfFile"
	cronExist=$(grep -o "$sfFile" $CRON_FILE)
	if [[ -z $cronExist  ]];then
		crontab -l | { cat; echo "$cronJob"; } | crontab -
		echo CronJob für backup.sh wurde installiert!
	fi
}

getFunction() {
	source ""$SelfPath"functions.sh" $1 $2 $3
}
getMCFunction() {
	source ""$SelfPath"mcfunctions.sh" $1 $2 $3
}

getConfig() {
    bkupconfig=$mcDir$mcServer/$bkupconfName
}

getDenizenDir() {
	denizenDir=$mcDir$mcServer/plugins/Denizen/
}

getBackupDir() {
	DenizenbackupDir="$backupDir"minecraft/$mcServer/denizenScripts/$year/
	FullDailyBackupDir="$backupDir"minecraft/$mcServer/full/$year/
	denizenDir=$mcDir$mcServer/plugins/Denizen/
}

getBackupFiles() {
	getTime
	DnzScrBackupFile="$date"_dnzScrBkup.tar
	McSrvBackupFile="$date"_McSrvFullBkup.tar
}

getTime() {
	time=$( date +"%T" )
	date=$( date +"%Y-%m-%d" )
	year=$( date +"%Y" )
	month=$( date +"%m" )
	day=$( date +"%d" )
	DayOfWeek=$(date +%u)
	DayOfMonth=$(date +%m)
}

doDailyBackup() {
	varTarFile=$1
	varZipFile="$varTarFile".gz
	varToCopyDir=$2
	varBackupDir="$3"daily/
	cd $varBackupDir
	echo varZipFile == $varZipFile
	if [[ -f $varZipFile ]];then
		echo Datei existiert... Erstelle weitere Datei
		count=$(ls $varBackupDir$date*.tar.gz | wc -l)
		varName=${varTarFile%.tar*}
		varTarFile="$varName"_"$count".tar
		unset varName
	fi
	tar -cf $varTarFile -C $varToCopyDir .
	gzip $varTarFile
}

doWeeklyBackup() {
	echo doWeeklyBackup
	if [[ $DayOfWeek == $WeeklyDay ]];then
		varCopyFile=$1
		varCopyDir=$(dirname $(readlink -f "$varCopyFile"))
		varBackupDir="$2"weekly/
		count=$(ls $varCopyDir/$date*.tar.gz | wc -l)
		count=$(( count -1 ))
		varName=${varCopyFile##*_}
		varName=${varName%%.*}
		echo $varName
# Note: Manual backups preparation // $date is probably not the actual day lol
		varDate=$(awk -F '[:_]' '{print $1}' <<< "$varCopyFile")
		varCopyFile="$varDate"_"$varName"_"$count".tar.gz
		cp $varCopyFile $varBackupDir
	fi
}

doMonthlyBackup() {
	if [[ $DayOfMonth == $MonthlyDay ]];then
		varCopyFile=$1
		varBackupDir="$2"monthly/
		cp $varCopyFile $varBackupDir
	fi
}

rmFilesOlderAs() {
	varDir=$1
	type=$2
	MaxDays=$3
	varFile=$(find $varDir -type f -name '*.'$type'' -mtime +$MaxDays)
	if ! [[ -z $varFile ]];then
		echo File Removed! [$varFile]
	fi
}

CreatebackupDirStructure() {
    getTime
	if ! [[ -z $denizenDir ]];then
		mkdir -p "$backupDir"minecraft/$mcServer/{full,denizenScripts}/$year/{monthly,weekly,daily}
	else
		mkdir -p "$backupDir"minecraft/$mcServer/full/$year/{monthly,weekly,daily}
	fi
}

echo "start copy..."
installCronJob

# Jeweiliger Ordner-Name
countSlashes=$(echo $mcDir | grep -o "/" | wc -l)
lastSlash=$(( countSlashes +1 ))
for varMCDirectory in $(ls -d $mcDir*/);do
	mcServer="$(echo "$varMCDirectory" | cut -d'/' -f$lastSlash)"
# Variabeln
	getTime
	getFunction getBackupConfig
# Config-Prüfung
	if [ -f $bkupconfig ];then
# Prüft ob autobackup=true ist
		getFunction readBackupConf
		if [[ $doBackup == true ]];then
# Erstellt die nötige Ordner-Struktur (falls nötig)
			getDenizenDir
			CreatebackupDirStructure
			getBackupDir
			getBackupFiles
# Prüft ob der Server läuft (Screen +config)
			if [[ $doAutostart == true ]];then
				prefix="[Backup]"
				text="Tägliches Backup in Vorbereitung"
				getMCFunction doEnsureMCStop
				sleep 5
				resetAutostart=true
			else
				resetAutostart=false
			fi
			if [[ -d $denizenDir ]];then
				echo Denizen Found...
				doDailyBackup $DnzScrBackupFile $denizenDir $DenizenbackupDir
				doWeeklyBackup $DnzScrBackupFile $DenizenbackupDir
				doMonthlyBackup $DnzScrBackupFile $DenizenbackupDir
				rmFilesOlderAs $DenizenbackupDir tar $DailyBackupMax
				echo DenizenScript-Backup erledigt!
			fi
			doDailyBackup $McSrvBackupFile $varMCDirectory $FullDailyBackupDir
			doWeeklyBackup $McSrvBackupFile $FullDailyBackupDir
			doMonthlyBackup $McSrvBackupFile $FullDailyBackupDir
			rmFilesOlderAs $FullDailyBackupDir tar $DailyBackupMax
			echo Server-Backup erledigt!
			if [[ $resetAutostart == true ]];then
				getConfig
				getFunction setBackupConf Autostart true
				echo Server $mcServer startet in wenigen Sekunden...
			fi
		fi
	fi
done

