#!/bin/bash

#Hier den gewünschten Speicherort der Backups eintragen
backupDir=/home/dbtbackup/

#Minecraft-Ordner / Verzeichnis mit allen möglichen MC-Servern
mcDir=/minecraft/

#Name der Standard-JarDatei
jarName=minecraft_server.jar

#Bevorzugter Port beim installieren eines neuen MC-Server
stdMCPort=25552

##################################
# DO NOT EDIT!

dbtVersion=1.0
mcSrvCheckAPI=https://api.mcsrvstat.us/2/
internalIP=$(hostname -i)
StartShellName=start.sh
bkupconfName=dbtbackup.conf
SelfPath="$(dirname "$(readlink -fn "$0")")/"
copyDir="$SelfPath"copyfolder/
tempDir="$SelfPath"tmp/
tmpDir="$SelfPath"tmp/
dataDir="$SelfPath"data/
netData="$dataDir"netdata
syncData="$dataDir"syncdata
dbtKeyFile="$dataDir"dbt_sshkey
dbtpubKeyFile="$dataDir"dbt_sshkey.pub
dataFile="$dataDir"dbtdata
dbtData="$dataDir"dbtdata
localData="$dataDir"localdata
localConf="$dataDir"localconf
netConf="$dataDir"netconf
backupConf="$dataDir"backupconf
netHandler=
NetworkServer=$(grep NetworkServer= $dataFile 2>/dev/null | cut -f2 -d'=')
BackupServer=$(grep BackupServer= $dataFile 2>/dev/null | cut -f2 -d'=')
stdSSHport=22

localBackupDir="$backupDir"local/
netBackupDir="$backupDir"network/

timeStamp="^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$"

#bold/lined/etc. ->${norm} to reset at the end of line
norm=$(tty -s && tput sgr0)
bold=$(tty -s && tput bold)
rev=$(tty -s && tput rev)
lined=$(tty -s && tput smul)

#text-color
black='\033[0;30m'
red='\033[0;31m'
lred='\033[1;31m'
green='\033[0;32m'
lgreen='\033[1;32m'
blue='\033[0;34m'
lblue='\033[1;34m'
yellow='\033[1;33m'

#background-color
bred=$(tty -s && tput setab 1)
bgreen=$(tty -s && tput setab 2)
byellow=$(tty -s && tput setab 3)
bblue=$(tty -s && tput setab 4)
bmagenta=$(tty -s && tput setab 5)
bcyan=$(tty -s && tput setab 6)
bwhite=$(tty -s && tput setab 7)
