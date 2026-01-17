#!/bin/bash

set -e

LIST=$(find . -name Brokerage\ Statement\* -or -name Bank\ Statement\*)
IFS=$'\n'

for FILE in ${LIST}
do
    NEW_NAME=$(echo ${FILE} | sed -e's/ /_/')
    mv "${FILE}" "${NEW_NAME}"
done

exit
