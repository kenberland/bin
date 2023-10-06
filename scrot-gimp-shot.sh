#!/bin/bash
#sleep 0.2 # https://bbs.archlinux.org/viewtopic.php?id=86507
#scrot '%Y-%m-%d-%H-%M-%S.png' -fs -e 'gimp $f'
FILE=~/$(date +%Y-%m-%d-%H-%M-%S).png
maim -s "$FILE" && gimp "$FILE"
