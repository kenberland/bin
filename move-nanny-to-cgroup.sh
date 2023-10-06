#!/bin/bash
set -x

while :
do
    echo "moving nannyware to cgroups"
    cgconfigparser -l /etc/cgconfig.conf
    cgclassify -g cpu:nannyware $(pgrep -u root falcon-sensor)
    cgclassify -g cpu:nannyware $(pgrep TaniumClient | sort | head -1)
    cgclassify -g cpu:nannyware $(pgrep TaniumEndpoint)
    cgclassify -g cpu:nannyware $(pgrep amazon-kinesist)
    cgclassify -g cpu:ansible $(pgrep -u root ansible-playboo)
    sleep 60
done
