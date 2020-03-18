#!/bin/bash

fixBashrc() {
	fixPath="export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	autoConnect='if ! [[ -z $(tmux ls | grep -o Terminal) ]];then tmux a -t Terminal; fi'
	CatchautoConnect='tmux a -t Terminal'
	bashrc="/root/.bashrc"
	tmpfile=instTempfile
	if [[ -f $bashrc ]];then
		while read -r line || [ -n "$line" ]; do 
			if [[ $line == $fixPath ]];then
				exportPathFound=true
			elif [[ $line =~ $CatchautoConnect ]];then
				autoConnectFound=true
				echo autoConnect found lol
			fi
		done < $bashrc
	fi

	if ! [[ $exportPathFound == true ]];then
		echo -e "$fixPath" >> $bashrc
		echo -e "[Done/fixBashrc]: -> Linie [$fixPath] wurde der Datei <$bashrc> hinzugefuegt!"
	fi
	if ! [[ $autoConnectFound == true ]];then
		echo -e "$autoConnect" >> $bashrc
		echo -e "[Done/fixBashrc]: -> Linie [$autoConnect] wurde der Datei <$bashrc> hinzugefuegt!"
	fi
}

fixBashrc

