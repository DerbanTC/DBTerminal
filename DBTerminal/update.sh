#!/bin/bash
if [[ -z $SelfPath ]] || [[ $SelfPath != "$PWD"/ ]];then
	SelfPath="$(dirname "$(readlink -fn "$0")")/"
	cd $SelfPath
	source ./stdvariables.sh
	source ./inject.sh
fi

checkUpdates() {
	local tmpVersion="$SelfPath"tmp/dbtversion
	local varUrl=https://raw.githubusercontent.com/DerbanTC/DBTerminal/master/DBTerminal/update/version
	checkKnownBugs() {
		local actVersion=$(echo $dbtVersion | sed "s/\.//g")
		while read line;do
			if [[ $line =~ v[0-9]+\.[0-9]_.* ]];then
				varVersion="$(echo $line | cut -f1 -d_ | sed "s/v//g" | sed "s/\.//g")"
				if [[ $actVersion -le $varVersion ]];then
					doNoteError=true
				fi
			elif [[ $line =~ \>.* ]];then
				if [[ $doNoteError == true ]];then
					listMsgHeader="${yellow}Bekannte Errors:${lred}"
					n=$(( n + 1 )) || n=1
					lastListMsg="$line" && declare -g "magic_variable_$n=$(echo -e "$lastListMsg")"
				fi
			fi
		done < $tmpVersion && unset n
	}
	if [[ -f $tmpVersion ]] && [[ $(( $(date +%s) - $(date +%s -r $tmpVersion) )) -ge 10800 ]];then
		rm $tmpVersion && wget $varUrl -qO $tmpVersion
	elif ! [[ -f $tmpVersion ]];then
		wget $varUrl -qO $tmpVersion
	fi
	if [[ -f $tmpVersion ]];then
		if [[ $(grep "Version=.*" $tmpVersion | cut -f2 -d=) == $dbtVersion ]];then
			doUpdate=false
		else
			doUpdate=true
		fi
	fi
	checkKnownBugs
}

doUpdateDBT() {
	local varUrl=https://raw.githubusercontent.com/DerbanTC/DBTerminal/master/DBTerminal/update/
	local tmpVersion="$SelfPath"tmp/dbtversion
	local actVersion=$(echo $dbtVersion | sed "s/\.//g")
	if [[ -f $tmpVersion ]];then
		while read line;do
			if [[ $line =~ v[0-9]+\.[0-9]_.* ]];then
				varVersion="$(echo $line | cut -f1 -d_ | sed "s/v//g" | sed "s/\.//g")"
				if [[ $varVersion -gt $actVersion ]];then
					varShellName="updateV$(echo $line | cut -f1 -d_ | sed "s/v//g" | sed "s/\./_/g").sh"
					downloadFile="$SelfPath"tmp/$varShellName
					if [[ -f $downloadFile ]] && [[ -z $(grep "dbtTrusted=$varShellName" $downloadFile) ]];then
						rm $downloadFile
					fi
					if ! [[ -f $downloadFile ]];then
						varUpdateShell=""$varUrl"$varShellName"
						wget $varUpdateShell -qO $downloadFile
					fi
					if [[ -f $downloadFile ]] && ! [[ -z $(grep "dbtTrusted=$varShellName" $downloadFile) ]];then
						chmod +x $downloadFile
						source $downloadFile
					elif [[ -z $(grep "dbtTrusted=$varShellName" $downloadFile) ]];then
						rm $downloadFile
						return 1
					fi
				fi
			fi
		done < $tmpVersion
	fi
}

$1 $2 $3
