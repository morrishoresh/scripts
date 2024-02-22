#!/bin/sh
INT_NET=192.168.0.0/24
UTUN=utun
for i in $(ifconfig | grep $UTUN | grep flags | awk '{print substr($1, 5)}'| awk '{print substr($0, 1, length($0)-1)}')
do
	ifconfig $UTUN$i | grep -- --\>
	if [ $? -eq 0 ]
	then
		TUNNEL=$UTUN$i
		break
	fi
done 

echo $TUNNEL

if [ "$1" = "--reset" ]
then
	route -n delete $INT_NET
else
	sysctl -w net.inet.ip.forwarding=1
	pfctl -e
	pfctl -F all
	echo "nat on $TUNNEL from 192.168.0.0/24 to any -> $TUNNEL" | pfctl -f -
	ROUTER=$(ifconfig en0 | grep -w inet | awk '{print $2}')
	route -n delete $INT_NET
	route -n add $INT_NET $ROUTER
fi
