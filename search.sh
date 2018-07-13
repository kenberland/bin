#!/bin/bash
set -x

TARGET=$HOME/mail/mairix
rm -rf $TARGET
rm -rf $HOME/dcm/.mairix

THIS_YEAR=$(date +%Y)
LAST_YEAR=$(($THIS_YEAR - 1))
TODAY=$(date +%m%d)
DATE_RANGE=d:${LAST_YEAR}${TODAY}-${THIS_YEAR}${TODAY}

if [ "$#" != "1" ]; then
    shift
    mairix $@
else
    mairix $DATE_RANGE $@
fi

mv $TARGET $HOME/dcm/.mairix
alpine -f mairix

