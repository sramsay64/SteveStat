#!/bin/zsh

SERVER="$(cat config/server)"
PASSWRITE="$(cat config/passwordWrite)"
PASSREAD="$(cat config/passwordWrite)"

ipaddr() {
	ifconfig | grep "inet addr" | grep -v "127\.0\.0\.1" | sed "s/.*inet addr:\([0-9.]*\).*/\1/"
}

writeIP() {
	curl "$SERVER?update=True&ip=$(ipaddr | tail -n1)&password=$PASSWRITE" -k
}

readIP() {
	curl "$SERVER?password=$PASSREAD" -k
}

if (( $# < 1 )); then
	echo "Usage:"
	echo "	stevestat.zsh read"
	echo "	stevestat.zsh write"
	echo "	stevestat.zsh ssh"
	echo "	stevestat.zsh sftp"
	exit
elif [[ $1 == "read" ]]; then
	readIP
elif [[ $1 == "write" ]]; then
	writeIP
elif [[ $1 == "ssh" ]]; then
	ssh $(readIP)
fi
