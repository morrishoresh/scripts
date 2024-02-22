#!/bin/sh
UTUN=utun
EN=en

#get the WiFi interface
WIFI=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{getline; print $2}')

# Run ifconfig and store the output in a variable
ifconfig_output=$(ifconfig $WIFI)

# Extract relevant network information using grep and awk
ipv4_address=$(echo "$ifconfig_output" | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | awk '{print $2}')
subnet_mask_raw=$(echo "$ifconfig_output" | grep -Eo 'netmask 0x[0-9a-fA-F]*' | awk '{print $2}')
subnet_mask=$(printf "%d.%d.%d.%d\n" $((0x${subnet_mask_raw:2:2})) $((0x${subnet_mask_raw:4:2})) $((0x${subnet_mask_raw:6:2})) $((0x${subnet_mask_raw:8:2})))

# Convert the subnet mask to network address
IFS='.' read -r -a subnet_mask_octets <<< "$subnet_mask"
IFS='.' read -r -a ipv4_address_octets <<< "$ipv4_address"
network_address=""
for ((i=0; i<4; i++)); do
    network_address_octet=$((subnet_mask_octets[i] & ipv4_address_octets[i]))
    network_address="$network_address$network_address_octet."
done

network_address="${network_address%?}"  # Remove the trailing dot

ROUTE_NET="-net $network_address -netmask $subnet_mask"

if [ "$1" = "--reset" ]
then
	# delete route and reset connctions
	route -n delete $ROUTE_NET > /dev/null

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
	# run through all utunX interfaces and find the vpn tunnel by indicative string "-->"
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
	pfctl -d
	pfctl -F all
	CMD="nat on $TUNNEL from $WIFI:network to any -> $TUNNEL"
	echo "$CMD" | pfctl -e -f -
	ROUTER=$(ipconfig getifaddr $WIFI)
	route -n delete $ROUTE_NET
	route -n add $ROUTE_NET $ROUTER
	route delete default
	route add default $(ifconfig $TUNNEL | grep inet | awk '{print $2}')
fi
