#!/bin/bash
SelfPath="$(dirname "$(readlink -fn "$0")")/"
cd $SelfPath
source ./stdvariables.sh

getFunction() {
	source ""$SelfPath"functions.sh" $1 $2 $3
}

Terminal() {
	tmux new-session -s Terminal -d bash
	tmux rename-window "Terminal"
	tmux split-window -v -p 50 -t Terminal
	tmux split-window -h -p 50 -t Terminal
	echo -e "[INFO]: TMUX-Session [TerminalCMD] wurde initialisiert!"
	tmux send-key -t Terminal:0.1 "clear" C-m
	tmux send-key -t Terminal:0.1 "screen -r TerminalCMD" C-m
	tmux send-key -t Terminal:0.2 "clear" C-m
	tmux send-key -t Terminal:0.2 "htop" C-m
}

getFunction getTime
echo "[INFO]: Script wurde gestartet!"
echo "[Timestamp]: Date:[$date] Time:[$time]"
echo "[INFO]: Search files and check conditions..."
actDate=$date

if [[ -z $(pgrep -c tmux) ]];then
    tmux start-server
    echo "[REBOUND.SH]: TMUX wurde gestartet!"
fi

while true; do

	if ! $(screen -ls | grep -q TerminalCMD);then
		echo -e "[INFO]: SCREEN [TerminalCMD] nicht gefunden. Starte deamon..."
		screen -dmS "TerminalCMD" bash -c "./TerminalCMD.sh"
		if $(tmux ls | grep -q Terminal);then
			tmux send-key -t Terminal:0.1 "screen -r TerminalCMD" C-m
		fi
	fi

	if ! $(tmux ls | grep -q Terminal);then
		echo -e "[INFO]: TMUX-Session [TerminalCMD] wurde nicht gefunden! Initialisiere TMUX..."
		Terminal
	elif [[  $(tmux ls | grep -q Terminal | tmux display-message -p '#{window_panes}') != 3 ]];then
		echo -e "[INFO]: TMUX-Session [TerminalCMD] hat nicht 3 Panes! Initialisiere neu..."
		tmux kill-session -t Terminal
		Terminal
	fi

	for mcServer in $(ls -d $mcDir*/ | cut -f4 -d'/');do
		getFunction checkConditions
		if [[ $StartIsEnabled == doStart ]];then
			getFunction startMCScreen
			getFunction getTime
			if ! [[ $actDate == $date ]];then
				echo "[Timestamp]: Date:[$date] Time:[$time]"
				actDate=$date
			fi
			echo "[$time INFO]: Server [$mcServer] wurde gestartet"
		fi
	done
	sleep 5

done

