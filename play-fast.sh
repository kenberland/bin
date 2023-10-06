#!/bin/bash

set -evx

mpg321 -w slow.wav "${1}"
sox slow.wav fast.wav tempo 1.6
play fast.wav
