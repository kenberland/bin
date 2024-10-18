#!/bin/bash
set -e
xinput disable "ELAN067B:00 04F3:31F8 Touchpad"
xfconf-query -c xsettings -p /Xft/DPI -s 196
