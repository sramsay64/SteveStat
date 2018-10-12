#!/bin/zsh

optionalCat() {
	if [[ -f $1 ]]; then
		cat $1
	fi
}

BASEPATH=$(dirname $(readlink -f $0))

SERVER="$(cat $BASEPATH/config/server)"
PASSWRITE="$(optionalCat $BASEPATH/config/passwordWrite)"
PASSREAD="$(optionalCat $BASEPATH/config/passwordRead)"

MYPORT="$(optionalCat $BASEPATH/config/myport)"
MYNAME="$(optionalCat $BASEPATH/config/myname)"
MYUSER="$(whoami)"

ipaddr() {
	ifconfig | grep "inet addr" | grep -v "127\.0\.0\.1" | sed "s/.*inet addr:\([0-9.]*\).*/\1/"
}

writeInfo() {
	curl 2>/dev/null "$SERVER?update=True&ip=$(ipaddr | tail -n1)&user=$MYUSER&name=$1&port=$MYPORT&password=$PASSWRITE" -k
}

readInfo() {
	INFO=$(curl 2>/dev/null "$SERVER?password=$PASSREAD&name=$1" -k)
	echo $INFO
}

list() {
	curl 2>/dev/null "$SERVER/list?password=$PASSREAD" -k
}

# Read the $1 attribute from the JSON
# Requires that readInfo has already been called
readAttr() {
	echo $INFO | jq -r ".$1"
}

# Read the `user@ip` string (which could just be `ip` if there is no user)
# Requires that readInfo has already been called
getSSHAddress() {
	if [[ "$(readAttr user)" != "" ]]; then
		echo "$(readAttr user)@$(readAttr ip)"
	else
		echo "$(readAttr ip)"
	fi
}

if (( $# < 1 )); then
	echo "Usage:"
	echo "	stevestat.zsh read  [name]"
	echo "	stevestat.zsh write [name]"
	echo "	stevestat.zsh writeThis"
	echo "	stevestat.zsh writeThisWhile	[delay]"
	echo "	stevestat.zsh list"
	echo "	stevestat.zsh listAll"
	echo "	stevestat.zsh ssh   [name]"
	echo "	stevestat.zsh sftp  [name]"
	exit
elif [[ $1 == "read" ]]; then
	readInfo $2
elif [[ $1 == "write" ]]; then
	writeInfo $2
elif [[ $1 == "writeThis" ]]; then
	writeInfo $MYNAME
elif [[ $1 == "writeThisWhile" ]]; then
	while :; do
		writeInfo $MYNAME
		sleep $2
	done
elif [[ $1 == "list" ]]; then
	list
elif [[ $1 == "listAll" ]]; then
	LIST="$(list)"
	LEN="$(echo $LIST | jq length)"
	(( LEN = $LEN - 1 ))
	for i in {0..$LEN}; do
		NAME=$(echo $LIST | jq -r ".[$i]")
		readInfo $NAME | jq
	done
elif [[ $1 == "ssh" ]]; then
	readInfo $2
	ssh "$(getSSHAddress)" -p "$(readAttr port)"
elif [[ $1 == "sftp" ]]; then
	readInfo $2
	sftp -P "$(readAttr port)" "$(getSSHAddress)"
fi
