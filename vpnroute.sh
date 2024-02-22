#!/bin/sh
INT_NET=192.168.0.0/24
UTUN=utun
EN=en

if [ "$1" = "--reset" ]
then
	route -n delete $INT_NET
	for i in $(ifconfig | grep ^$EN | awk '{print $1}'| awk '{print substr($0, 1, length($0)-1)}')
	do
        	ifconfig $i | grep -w inet > /dev/null 2>/dev/null
        	if [ $? -eq 0 ]
        	then
                	ifconfig $i down
			sleep 2
			ifconfig $i up
        	fi
	done
else
	for i in $(ifconfig | grep ^$UTUN | awk '{print $1}'| awk '{print substr($0, 1, length($0)-1)}')
	do
        	ifconfig $i | grep -- --\> > /dev/null 2>/dev/null
        	if [ $? -eq 0 ]
       		then
                	TUNNEL=$i
                	break
        	fi
	done
	sysctl -w net.inet.ip.forwarding=1
	pfctl -e
	pfctl -F all
	CMD="nat on $TUNNEL from $INT_NET to any -> $TUNNEL"
	echo -------------------- $CMD
	echo "$CMD" | pfctl -f -
	ROUTER=$(ifconfig en0 | grep -w inet | awk '{print $2}')
	route -n delete $INT_NET
	route -n add $INT_NET $ROUTER
	route delete default
	route add default 172.20.123.24
fi
