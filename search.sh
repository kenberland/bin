#!/bin/bash
TARGET=$HOME/mail/mairix
rm -rf $TARGET
rm -rf $HOME/dcm/.mairix
mairix $1
mv $TARGET $HOME/dcm/.mairix
alpine -f mairix

