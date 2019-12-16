#!/bin/bash

#Hier den gewünschten Speicherort der Backups eintragen
backupDir=/home/backup/

#Minecraft-Ordner / Verzeichnis mit allen möglichen MC-Servern
mcDir=/home/minecraft/

#Name der Standard-JarDatei
jarName=minecraft_server.jar

#Bevorzugter Port beim installieren eines neuen MC-Server
stdMCPort=25552

##################################
# DO NOT EDIT!

mcSrvCheckAPI=https://api.mcsrvstat.us/2/
StartShellName=start.sh
bkupconfName=BackupConfig.txt
copyDir="$SelfPath"copyfolder/

#bold/lined/etc. ->${norm} to reset at the end of line
norm=$(tput sgr0)
bold=$(tput bold)
rev=$(tput rev)
lined=$(tput smul)

#text-color
black='\033[0;30m'
red='\033[0;31m'
lred='\033[1;31m'
green='\033[0;32m'
lgreen='\033[1;32m'
blue='\033[0;34m'
lblue='\033[1;34m'
#todo change yellow to lyellow in all scripts
#yellow='\033[0;33m'
#lyellow='\033[1;33m'
yellow='\033[1;33m'

#background-color
bred=$(tput setab 1)
bgreen=$(tput setab 2)
byellow=$(tput setab 3)
bblue=$(tput setab 4)
bmagenta=$(tput setab 5)
bcyan=$(tput setab 6)
bwhite=$(tput setab 7)

