#!/bin/zsh

optionalCat() {
	if [[ -f $1 ]]; then
		cat $1
	fi
}

SERVER="$(cat config/server)"
PASSWRITE="$(optioalCat config/passwordWrite)"
PASSREAD="$(optionalCat config/passwordRead)"

MYPORT="$(optionalCat config/myport)"
MYNAME="$(optionalCat config/myname)"

ipaddr() {
	ifconfig | grep "inet addr" | grep -v "127\.0\.0\.1" | sed "s/.*inet addr:\([0-9.]*\).*/\1/"
}

writeInfo() {
	curl 2>/dev/null "$SERVER?update=True&ip=$(ipaddr | tail -n1)&name=$1&port=$MYPORT&password=$PASSWRITE" -k
}

readInfo() {
	INFO=$(curl 2>/dev/null "$SERVER?password=$PASSREAD&name=$1" -k)
	echo $INFO
}

list() {
	curl 2>/dev/null "$SERVER/list?password=$PASSREAD" -k
}

# Read the $1 attribute from the JSON
readAttr() {
	echo $INFO | jq -r ".$1"
}

if (( $# < 1 )); then
	echo "Usage:"
	echo "	stevestat.zsh read  [name]"
	echo "	stevestat.zsh write [name]"
	echo "	stevestat.zsh writeThis"
	echo "	stevestat.zsh list"
	echo "	stevestat.zsh ssh   [name]"
	echo "	stevestat.zsh sftp  [name]"
	exit
elif [[ $1 == "read" ]]; then
	readInfo $2
elif [[ $1 == "write" ]]; then
	writeInfo $2
elif [[ $1 == "writeThis" ]]; then
	writeInfo $MYNAME
elif [[ $1 == "list" ]]; then
	list
elif [[ $1 == "ssh" ]]; then
	readInfo $2
	ssh "$(readAttr ip)" -p "$(readAttr port)"
elif [[ $1 == "sftp" ]]; then
	readInfo $2
	sftp -P "$(readAttr port)" "scott@$(readAttr ip)"
fi
