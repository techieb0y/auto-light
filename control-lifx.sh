#!/bin/bash

# Called from nagios as:
# command_line    /etc/scripts/control-lifx.sh $HOSTSTATE$
# Called from setup-lifx.sh as:
# echo "/etc/scripts/control-lifx.sh ON" | at now + ${DELTA} minutes

TOKEN="REDACTED"
BULB="000000coffee"

light_off() {
	(cat << EOF
{
	"power": "off",
	"duration": 15
}
EOF
) > /tmp/$$
	curl -s -X PUT -T /tmp/$$ -H "Authorization: Bearer ${TOKEN}" https://api.lifx.com/v1/lights/id:${BULB}/state
	rm -f /tmp/$$
}

light_on() {
	(cat << EOF
{
	"power": "on",
	"duration": 15
}
EOF
) > /tmp/$$
	curl -s -X PUT -T /tmp/$$ -H "Authorization: Bearer ${TOKEN}" https://api.lifx.com/v1/lights/id:${BULB}/state
	rm -f /tmp/$$
}

logger "Cmd line was: $*"
# env > /tmp/lifx.$$

case "$1" in
UP)
	# Don't do anything special when we see the laptop come online
	;;
DOWN)
	light_off
	logger "Work PC detected as down; turn off lights."
	;;
ON)
	# Only turn the light on when we're actually in the office
	if [ x`cat /var/lib/nagios3/state/work-macbook` == "xUP" ];
	then
		light_on
	fi
	;;
OFF)
	# Normally covered by the DOWN case above, but for completeness:
	light_off
	;;
esac

exit 0
