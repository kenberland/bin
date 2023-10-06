#!/bin/bash
set -evx

# tested restore like this

# duplicity --encrypt-key berlandk@amazon.com \
#           --use-agent \
#           restore \
#           pexpect+scp://dev-dsk-berlandk-2c-93070661.us-west-2.amazon.com/laptop-backup-v3 \
#           /tmp/restore-test/


duplicity \
    --encrypt-key berlandk@amazon.com \
    --use-agent \
    --include $HOME/bin \
    --include /home/ma/mail \
    --include $HOME/imapsync \
    --include $HOME/old-screenshots \
    --include $HOME/sample-code \
    --include $HOME/Documents \
    --include $HOME/Downloads \
    --include $HOME/INTEGRATIONS \
    --include $HOME/OLR \
    --include $HOME/PCS \
    --exclude '**' \
    / \
    pexpect+scp://dev-dsk-berlandk-2c-93070661.us-west-2.amazon.com/laptop-backup-v3



