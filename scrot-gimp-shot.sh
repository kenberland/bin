#!/bin/bash
sleep 0.2 # https://bbs.archlinux.org/viewtopic.php?id=86507
scrot '%Y-%m-%d-%H-%M-%S.png' -s -e 'gimp $f'

