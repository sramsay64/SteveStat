#!/bin/zsh

optionalCat() {
	if [[ -f $1 ]]; then
		cat $1
	fi
}

optionalExec() {
	if [[ -f $1 ]]; then
		source $1
	fi
}

# Patch for mac, where readlink has no -f option
readlinkF() {
	RESULT="$@"
	while [[ -L "$RESULT" ]]; do # While RESULT is a symlink
		RESULT="$(readlink $RESULT)"
	done
	echo $RESULT
}

BASEPATH=$(dirname $(readlinkF $0))

SERVER="$(cat $BASEPATH/config/server)"
PASSWRITE="$(optionalCat $BASEPATH/config/passwordWrite)"
PASSREAD="$(optionalCat $BASEPATH/config/passwordRead)"

MYPORT="$(optionalCat $BASEPATH/config/myport)"
MYNAME="$(optionalCat $BASEPATH/config/myname)"
MYUSER="$(whoami)"

ipaddr() {
	if [[ $(uname) == "Darwin" ]] then
		ifconfig | grep "inet " | grep -v "127\.0\.0\.1" | sed "s/.*inet \([0-9.]*\).*/\1/" | tail -n1
	else
		ifconfig | grep "inet addr" | grep -v "127\.0\.0\.1" | sed "s/.*inet addr:\([0-9.]*\).*/\1/" | tail -n1
	fi
}

status() {
	optionalExec "$BASEPATH/config/mystatus.zsh" | sed 's/%/%25/g;s/ /%20/g'
}

clock() {
	date | sed 's/%/%25/g;s/ /%20/g'
}

# Find the section of ifconfigs output that ipaddr got it's ip from and print it's interface name
network() {
	if [[ $(uname) == "Darwin" ]] then
		/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | sed -e 's/^ *SSID: \(.*\)/\1/p' -e d
	else
		ifconfig | grep -zPo ".*\n.*$(ipaddr)." | tr -d '\0' | grep -o '^[^ ]*'
	fi
}

writeInfo() {
	curl 2>/dev/null "$SERVER?password=$PASSWRITE&update=True&ip=$(ipaddr)&port=$MYPORT&name=$1&user=$MYUSER&status=$(status)&network=$(network)&clock=$(clock)&comment=$2" -k
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
	echo "	stevestat.zsh read  name"
	echo "	stevestat.zsh write name	[comment]"
	echo "	stevestat.zsh writeThis	[comment]"
	echo "	stevestat.zsh writeThisWhile	delay	[comment]"
	echo "	stevestat.zsh list"
	echo "	stevestat.zsh listAll"
	echo "	stevestat.zsh ssh   name"
	echo "	stevestat.zsh sftp  name"
	echo "	stevestat.zsh wget  name	[port]"
	exit
elif [[ $1 == "read" ]]; then
	readInfo $2
elif [[ $1 == "write" ]]; then
	writeInfo $2
elif [[ $1 == "writeThis" ]]; then
	writeInfo $MYNAME $2
elif [[ $1 == "writeThisWhile" ]]; then
	while :; do
		writeInfo $MYNAME $3
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
		readInfo $NAME | jq .
	done
elif [[ $1 == "ssh" ]]; then
	readInfo $2
	ssh $3 "$(getSSHAddress)" -p "$(readAttr port)"
elif [[ $1 == "sftp" ]]; then
	readInfo $2
	sftp -P "$(readAttr port)" "$(getSSHAddress)"
elif [[ $1 == "wget" ]]; then
	readInfo $2
	ADDR="$(readAttr ip)"
	if (( $# > 2 )); then # optional port
		ADDR="$ADDR:$3"
	fi
	wget --content-disposition "$ADDR"
fi
