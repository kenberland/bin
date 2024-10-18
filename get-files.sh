#!/bin/bash
set -e
BASE=https://s3.amazonaws.com/mykaarma-storage/ZSBC-2843/inspection/2024/10/09/vehicleInspect_ffufJx
FILES=$(curl -s $BASE/vehicleInspect_ffufJx_960.m3u8 | grep ts$)
for FILE in $FILES; do
    curl -o $FILE $BASE/$FILE
    echo $FILE
done

    
