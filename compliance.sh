#!/bin/bash

set -evx
 
if [[ "$(acme --compliance-status --json | jq .data.compliance_status)" != "4" ]]; then 
    h=$(acme --compliance-status -vvv | md5sum | awk '{print $1}')
    if [ ! -e /tmp/$h ]; then
        notify-send "Compliance problem" "$(acme --compliance-status -vvv)" -u critical
        acme --compliance-status -vvv > /tmp/$h
    else
        echo "Already notified: /tmp/$h"
        cat /tmp/$h
    fi
fi
