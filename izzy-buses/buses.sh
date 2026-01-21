#!/usr/bin/env bash
cd $HOME/bin/izzy-buses
export TZ=America/Los_Angeles
source ./secrets.txt
uv run python ./buses.py

