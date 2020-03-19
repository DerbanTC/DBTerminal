#!/bin/bash

printFunction() {
	source ""$SelfPath"printFunctions.sh" $1 $2 $3
}
getFunction() {
	source ""$SelfPath"functions.sh" $1 $2 $3
}
getMCFunction() {
	source ""$SelfPath"mcfunctions.sh" $1 $2 $3 $4 $5
}
getSSHFunction() {
	source ""$SelfPath"sshfunctions.sh" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8"
}
getBackupFunction() {
	source ""$SelfPath"backup.sh" $1 $2 $3
}
dataFunction() {
	source ""$SelfPath"dataFunctions.sh" "$1" "$2" "$3" "$4" "$5"
}
netCommand() {
	source ""$SelfPath"netCommands.sh" $1 $2 $3
}
localCommand() {
	source ""$SelfPath"localCommands.sh" "$1" "$2" "$3" "$4" "$5"
}
