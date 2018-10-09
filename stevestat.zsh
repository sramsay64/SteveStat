#!/bin/zsh

SERVER="http://houghtondigital.com.au:8912/"
PASS="icebound-snobby-shivery-dirties"

ipaddr() {
	ifconfig | grep "inet addr" | grep -v "127\.0\.0\.1" | sed "s/.*inet addr:\([0-9.]*\).*/\1/"
}

writeIP() {
	curl "$SERVER?update=True&ip=$(ipaddr | tail -n1)&passcode=$PASS" -k
}

readIP() {
	curl "$SERVER" -k
}

if (( $# < 1 )); then
	echo "Usage:"
	echo "	stevestat.zsh read"
	echo "	stevestat.zsh write"
	echo "	stevestat.zsh ssh"
	exit
elif [[ $1 == "read" ]]; then
	readIP
elif [[ $1 == "write" ]]; then
	writeIP
elif [[ $1 == "ssh" ]]; then
	ssh $(readIP)
fi
