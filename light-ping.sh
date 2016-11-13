#!/bin/bash

GATEWAY=`/usr/sbin/netstat -nr -f inet | grep '^default' | grep -v 'utun' | awk '{print $2}'`
GWMAC=`/usr/sbin/arp ${GATEWAY} | head -1 | egrep -i -o 'at [0-9,A-F:]+' | sed 's/at //g'`

DOPING=0

case ${GWMAC} in
"86:8d:c7:ff:ff:ff")
	# Office - Comcast MTA - Wired
	DOPING=1
	;;
*)
	# Not a known network location. Play dead.
	;;
esac

if [ 1 -eq $DOPING ]
	then /usr/bin/curl -s -H "X-Auth-Token: REDACTED" https://my.server.url/api/heartbeat.php
	# /usr/bin/logger "Sending ping"
fi
