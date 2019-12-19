#!/bin/bash
SelfPath="$(dirname "$(readlink -fn "$0")")/"
cd $SelfPath
source ./stdvariables.sh

Terminal=$(tmux lsw -F '#{window_name}#{window_active}'|sed -n 's|^\(.*\)1$|\1|p')

getFunction() {
	source "./functions.sh" $1 $2 $3
}
getCMDFunction() {
	source "./cmdfunctions.sh" $1 $2 $3
}
getMCFunction() {
	source "./mcfunctions.sh" $1 $2 $3
}

countSlashes=$(echo $mcDir | grep -o "/" | wc -l)
lastSlash=$(( countSlashes +1 ))
for varMCDirectory in $(ls -d $mcDir*/ | cut -f$lastSlash -d'/');do
	if $(screen -ls | grep -q MCS_$varMCDirectory);then
		mcServer=$varMCDirectory
		getFunction detachMCScreen
		getFunction attachMCScreen
	fi
done

clear
while true; do
	getCMDFunction stdPrintText
	read -a INPUT_STRING
	command="${INPUT_STRING[0]}"
	arg1="${INPUT_STRING[1]}"
	arg2="${INPUT_STRING[2]}"
	case $command in
		GetScreen)
			clear
			getFunction attachMCScreen
		;;
		ServerList)
			clear
			getCMDFunction ServerList
		;;
		ServerWahl)
			clear
			getCMDFunction ServerWahl
		;;
		GetPort)
			clear
			getCMDFunction getMCPort
		;;
		Restart)
			clear
			getCMDFunction doMCRestart
		;;
		Stop)
			clear
			getCMDFunction doMCStop
		;;
		Start)
			clear
			getCMDFunction doMCStart
		;;

		SendText)
			clear
			getCMDFunction sendText
		;;
		CheckConfig)
			clear
			getCMDFunction checkConfig
		;;
		SetConfig)
			clear
			getCMDFunction setConfig
		;;
		ServerCheck)
			clear
			getCMDFunction doServerCheck
		;;
		pingOther)
			clear
			varIP=$arg1
			varPort=$arg2
			getCMDFunction doPingOther
		;;
		cpu)
			clear
			getCMDFunction htop
		;;
		*)
			if [ -z $INPUT_STRING ];then
				clear
			else
				clear
				echo -e "${lred}[ERROR/Command]: ${norm}-> Command <$INPUT_STRING> ist falsch!"
			fi
		;;
	esac
done

