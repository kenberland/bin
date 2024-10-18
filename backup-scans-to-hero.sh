#!/bin/bash
set -evx

# tested restore with
# duplicity restore pexpect+scp://hero.net/scans-encrypted-pre-2024 ./
# or
# duplicity restore pexpect+scp://hero.net/scans-encrypted-2024 ./

duplicity backup \
    --encrypt-key 8B5052EB407AD998A882DA154F03D8E8CCFDABBD \
    --use-agent \
    --include $HOME/scans/2024/ \
    --include $HOME/gnucash/ \
    --exclude '**' \
    $HOME \
    pexpect+scp://hero.net/scans-encrypted-2024



