#!/bin/bash

NOW=`date +%s`
THEN=`python /etc/scripts/sunset.py`

DELTA=$(( ($THEN-$NOW) / 60 ))

echo "/etc/scripts/control-lifx.sh ON" | at now + ${DELTA} minutes
