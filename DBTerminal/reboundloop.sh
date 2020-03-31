#!/bin/bash
SelfPath="$(dirname "$(readlink -fn "$0")")/"
cd $SelfPath
source ./stdvariables.sh
source ./inject.sh

dbtLog() {
	local dbtLogFile="$SelfPath"log/dbtlog
	local lastDay=$(tac $dbtLogFile | grep -oEm 1 "^>> Date 2[0-1][0-9][0-9]-[0-1][0-9]-[0-3][0-9]:$" | sed "s/>> Date //g" | sed "s/://g")
	local actDate="$( date +"%Y-%m-%d" )"
	if [[ -z $lastDay ]];then
		echo -e ">> Date $actDate:" >> $dbtLogFile
	elif ! [[ $lastDay == $actDate ]];then
		echo -e ">> Date $actDate:" >> $dbtLogFile
	fi
	echo -e "[$(date +%H:%M:%S)] [$1]: $2" >> $dbtLogFile
}

Terminal() {
	dbtLog TMUX "new-session \"Terminal\" started"
	tmux new-session -s Terminal -d bash
	tmux rename-window "Terminal"
	tmux split-window -v -p 50 -t Terminal
	tmux split-window -h -p 50 -t Terminal
	echo -e "[INFO]: TMUX-Session [TerminalCMD] wurde initialisiert!"
	getFunction reboundTerminal
}

dbtLog DBT "reboundloop.sh initialized"
getFunction getTime
echo "[INFO]: Script wurde gestartet!"
echo "[Timestamp]: Date:[$date] Time:[$time]"
echo "[INFO]: Search files and check conditions..."
actDate=$date

if [[ $(pgrep -c "tmux") == 0 ]];then
	dbtLog TMUX "Server started"
    tmux start-server
    echo "[REBOUND.SH]: TMUX wurde gestartet!"
fi

while true; do
	if [[ -z $(tmux ls | grep -o "Terminal") ]];then
		echo -e "[INFO]: TMUX-Session [TerminalCMD] wurde nicht gefunden! Initialisiere TMUX..."
		Terminal
	elif [[ $(tmux ls | grep -q Terminal | tmux display-message -p '#{window_panes}') != 3 ]];then
		dbtLog TMUX "kill session \"Terminal\" (has not 3 panes)"
		echo -e "[INFO]: TMUX-Session [TerminalCMD] hat nicht 3 Panes! Initialisiere neu..."
		tmux kill-session -t Terminal && Terminal
	fi
	if [[ -z $(screen -ls | grep -o "TerminalCMD") ]];then
		dbtLog Screen "\"TerminalCMD\" started"
		echo -e "[INFO]: SCREEN [TerminalCMD] nicht gefunden. Starte deamon..."
		screen -dmS "TerminalCMD" "./TerminalCMD.sh"
	fi
	if [[ -z $(screen -ls | grep "TerminalCMD" | grep "Attached") ]];then
		dbtLog Screen "\"TerminalCMD\" not attached. Send \"screen -r\" to Terminal"
		tmux send-key -t Terminal:0.1 C-m
		tmux send-key -t Terminal:0.1 "screen -r TerminalCMD" C-m
	fi
	countSlashes=$(echo $mcDir | grep -o "/" | wc -l)
	lastSlash=$(( countSlashes +1 ))
	for mcName in $(ls -d $mcDir*/ | cut -f$lastSlash -d'/');do
		getFunction checkConditions
		if [[ $StartIsEnabled == missingStartShell ]];then
			echo -e "[INFO]: start.sh in [$mcName] not found... \n> copy start.sh from $copyDir..."
			cp $copyDir$StartShellName $mcDir$mcName/ && chmod +x $startShell
			getFunction checkConditions
		fi
		if [[ $StartIsEnabled == doStart ]];then
			getMCFunction startMCScreen
			getFunction getTime
			if ! [[ $actDate == $date ]];then
				echo "[Timestamp]: Date:[$date] Time:[$time]"
				actDate=$date
			fi
			echo "[$time INFO]: Server [$mcName] wurde gestartet"
		fi
	done
	sleep 5
done
