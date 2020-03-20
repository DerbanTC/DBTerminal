#!/bin/bash
#text-color

lred='\033[1;31m'
lgreen='\033[1;32m'
lblue='\033[1;34m'
yellow='\033[1;33m'
norm=$(tput sgr0)
loginLog="$DBTDIR/log/loginlog"
loginDir="$DBTDIR/log/"
dbtData="$DBTDIR/data/dbtdata"

knownNetHandler="$(grep NetworkServer= $dbtData 2>/dev/null | cut -f2 -d=)"

checkOrigin() {
	User_IP=$(who am i | grep -o "(.*)" | sed "s/[()]//g")
	User_Name=$(whoami)
	if [[ -f $dbtData ]];then	
		if [[ $knownNetHandler == $User_IP ]];then
			connectionType=viaNetHandler
			connectLog="via NetHandler \"$knownNetHandler\""
			local sshPort=$(echo $SSH_CLIENT | cut -f3 -d' ')
			User_IP=$(netstat -tapen | grep root@no | sed "s/.*$(hostname -i):$sshPort//g" | cut -f1 -d:)
		fi
	fi
}

checkConnectingMethod() {
	if ! [[ -d $loginDir ]];then 
		mkdir $loginDir
	fi
	if ! [[ -f $loginLog ]];then
		touch $loginLog && echo -e "lastlogged_with=" > $loginLog
	fi
	if ! [[ -z $(tail -10 "/var/log/auth.log" | grep "$(who am i | grep -o "(.*)" | sed "s/[()]//g")" | grep Accepted | grep publickey) ]];then
		sed -i "s/lastlogged_with=.*/lastlogged_with=publickey/g" $loginLog
	else
		sed -i "s/lastlogged_with=.*/lastlogged_with=password/g" $loginLog
	fi
}

logLogin() {
	lastDay=$(tac $loginLog | grep -oEm 1 "^Date 2[0-1][0-9][0-9]-[0-1][0-9]-[0-3][0-9]:$" | sed "s/Date //g" | sed "s/://g")
	actDate="$( date +"%Y-%m-%d" )"
	if [[ -z $lastDay ]];then
		echo -e "Date $actDate:" >> $loginLog
	elif ! [[ $lastDay == $actDate ]];then
		echo -e "Date $actDate:" >> $loginLog
	fi
	if [[ $connectionType == viaNetHandler ]];then
		echo -e "[$( date +"%T" )] [DBT_Login]: User \"$User_Name\" with IP \"$User_IP\" connected via NetHandler \"$knownNetHandler\"" >> $loginLog
	else
		echo -e "[$( date +"%T" )] [DBT_Login]: User \"$User_Name\" with IP \"$User_IP\" connected" >> $loginLog
	fi
}

printLoginHeader() {
	printINFO() {
		local header="${yellow}> ${lblue}DBT/INFO:${yellow}"
		echo -e "${yellow}$(for i in $(seq 1 $(tput cols | cut -f2 -d' ')); do echo -n -; done)${norm}"
		if [[ -z $(screen -ls | grep ReboundLoop) ]];then
			echo -e "$header Screen [ReboundLoop] not found..\n> something wents wrong, please take a look on (crontab -l) and reboot..."
			loginError=true
		elif [[ -z $(pgrep -c tmux) ]];then
			echo -e "$header TMUX not running..\n> something wents wrong, please take a look on (screen -r ReboundLoop)"
			loginError=true
		elif [[ -z $(tmux ls | grep Terminal) ]];then
			echo -e "$header TMUX-Session [Terminal] not found..\n> something wents wrong, pleasy take a look on (screen -r ReboundLoop)"
			loginError=true
		elif ! [[ -z $(tmux ls | grep Terminal | grep attached) ]];then
			echo -e "$header TMUX-Session [Terminal] already attached.\n> Do not type (tmux a -t Terminal)!"
			loginError=true
		elif [[ -z $(tmux ls | grep Terminal | grep attached) ]];then
			echo -e "$header Welcome back..."
		else
			echo -e "$header unknown state, please report on github"
			loginError=true
		fi
		echo -e "${yellow}$(for i in $(seq 1 $(tput cols | cut -f2 -d' ')); do echo -n -; done)${norm}"
	}
	ConnectTerminal() {
		echo -e "${yellow}> Du wirst in ${lgreen}5 Sekunden ${yellow}automatisch verbunden (tmux a -t Terminal)"
		echo -e "> Tippe ${lblue}ENTER ${yellow}um direkt zu connecten oder ${lblue}ESC ${yellow}um abzubrechen${norm}"
		IFS=''
		read -s -N 1 -t 5 answer || answer=timeout
		case $answer in
			$'\x0a' |timeout) echo -e "\n " && tmux a -t Terminal:0.1;;
			* ) echo -e "${yellow}> Abgrebrochen! Tippe ${lblue}tmux a -t Terminal${yellow} um dich mit DBT zu verbinden${norm}";;
		esac
	}

	printINFO
	if [[ -z $loginError ]] ;then
		ConnectTerminal
	fi
}

checkOrigin
checkConnectingMethod
logLogin

if [[ $connectionType == viaNetHandler ]];then
	echo -e "> ${lred}WARNING: ${yellow}You are connected from the DBT-NetHandler!"
	echo -e "> Do not use DBT as local, you can fully handle DBT from the NetHandler..."
	echo -e "> Do not type (tmux -a -t Terminal)${norm}"
else
	printLoginHeader
fi
