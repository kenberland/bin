#!/bin/bash
set -e
set -v

adb root
adb install -r app/build/outputs/apk/app-debug.apk

adb push com.amazon.harley.testshell_preferences.xml /data/data/com.amazon.harley.testshell/shared_prefs/com.amazon.harley.testshell_preferences.xml

adb push song.m4a /sdcard/song.m4a

