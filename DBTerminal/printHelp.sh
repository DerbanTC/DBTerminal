#!/bin/bash

SelfPath="$(dirname "$(readlink -fn "$0")")/"
source "$SelfPath"stdvariables.sh
source "$SelfPath"inject.sh

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

printSTD() {
	echo -e "${yellow}$(for i in $(seq 1 $(tty -s && tput cols | cut -f2 -d' ')); do echo -n -; done)${norm}"
}

printHeader() {
	printSTD
	echo -e "$(printCenter "${yellow}***${green}[DBT COMMAND INFO]${yellow}***${norm}")"
	printSTD
}

cmdBackupInfo() {
	dataFunction readNetConf
	echo -e "${lblue}BACKUP-COMMANDS:"
	
	if [[ $netHandler == majority ]];then
		local x="${yellow}>>@mcCheck@->@${norm}Listet alle MC-Server im Netzwerk"
		local y="${yellow}>>@backupConf@->@${norm}Daily-Max, Weekly-Max, etc."
		local z="${yellow}>>@syncTime@->@${norm}Zeitpunkt für die Netz-Synchro"
		local a="$(echo -e "$x\n$y\n$z")\n${yellow}>>@en|disableSync@->@${norm}De-/Aktiviere Netz-Synchro"
	else
		local j="${yellow}>>@mcCheck@->@${norm}Liste alle MC-Server"
		local a="$(echo $j)\n${yellow}>>@backupConf@->@${norm}Daily-Max, Weekly-Max, etc."
	fi
	local b="${yellow}>>@doBackup@->@${norm}Erstelle ein manuelles Backup (MC-Server)"
	local c="${yellow}>>@setBackup@->@${norm}Aktiviere Tägliche Backups (MC-Server)"
	local d="${yellow}>>@setTime@->@${norm}Zeitpunkt f. d. Täglichen Backups (MC-Server)"

	echo -e "$(echo -e "$a\n$b\n$c\n$d" | column -s @ -t)"
	printSTD
	echo -e "${lblue}USAGE:\n${yellow}> Manuelle Backups werden Lokal gespeichert."
	echo -e "> Aktive MC-Server werden gestoppt und starten automatisch neu."
	echo -e "${lblue}NOTE:\n${yellow}> Ist Autobackup false werden keine Automatische Backups erstellt!"
	echo -e "> Manuelle Änderungen der mcConfig werden automatisch übernommen."
}

printBindKeyINFO() {
	local a="${lblue}HotKey@Description@Location"
	local b="${yellow}> ${green}[Ctrl-C]@${yellow}${lred}disabled! ${yellow}(use Ctrl-Z/F)@..."
	local d="${yellow}> ${green}[Alt-X/Y]@${yellow}en/disable Copy Mode @TMUX"
	local f="${yellow}> ${green}[Ctrl-A + ESC]@${yellow}enable Copy Mode@Screen"
	local g="${yellow}> ${green}[ESC]@${yellow}disable Copy Mode (if enabled)@Screen"
	echo -e "${bold}${yellow}DBT HOTKEYS:"
	echo -e "$a\n$b\n$c\n$d\n$e\n$f\n$g" | column -t -s @
	echo -e "COPY-MODE:"
	local h="${lblue}HotKey@ @Description@ @ @ @ @ @Location"
	local i="${yellow}> ${green}Left Mouse@ @${yellow}Copy marked text@ @ @ @ @ @..."
	local j="${yellow}> ${green}Right Mouse@ @${yellow}Paste at Cursor@ @ @ @ @ @..."
	echo -e "$h\n$i\n$j" | column -t -s @
}

printHeader
$1 $2 $3 $4 $5
printSTD
