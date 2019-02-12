#!/bin/bash

mpg321 -w slow.wav $@
sox slow.wav fast.wav tempo 1.6
lame fast.wav -m m $@.faster.mp3 

