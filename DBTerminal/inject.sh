#!/bin/bash

printFunction() {
	source ""$SelfPath"printFunctions.sh" $1 $2 $3
}
getFunction() {
	source ""$SelfPath"functions.sh" $1 $2 $3
}
getCMDFunction() {
	source ""$SelfPath"cmdfunctions.sh" $1 $2 $3
}
getMCFunction() {
	source ""$SelfPath"mcfunctions.sh" $1 $2 $3
}
getSSHFunction() {
	source ""$SelfPath"sshfunctions.sh" "$1" "$2" "$3" "$4" "$5"
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
