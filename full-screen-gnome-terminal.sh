#!/bin/bash
set -e
GEO=$(xwininfo -root | grep geometry | tr -d \-| sed 's/^  //g')
gnome-terminal --${GEO}


