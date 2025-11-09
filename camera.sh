#!/bin/bash
set -evx

DEVICE="/dev/video2"
#    v4l2-ctl -d "${DEVICE}" --set-ctrl=exposure_auto_priority=0
#    v4l2-ctl -d "${DEVICE}" --set-ctrl=exposure_auto=3
#    sleep 2
v4l2-ctl -d "${DEVICE}" --set-ctrl=auto_exposure=1
v4l2-ctl -d "${DEVICE}" --set-ctrl=exposure_time_absolute=450
#v4l2-ctl -d "${DEVICE}" --set-ctrl=focus_auto=0
#v4l2-ctl -d "${DEVICE}" --set-ctrl=focus_absolute=10
