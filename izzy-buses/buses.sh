#!/usr/bin/env bash
cd $HOME/izzy-buses
export LD_LIBRARY_PATH=/usr/local/lib:/home/ken/hero_backup_exclude/ssl-1.1.1k/lib
export TZ=America/Los_Angeles
source .venv/bin/activate
source ./secrets.txt
./buses.py

