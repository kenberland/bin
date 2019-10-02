#!/bin/bash

set -e

TODAY=$(date +%Y-%m-%d)
LIST=/tmp/${$}.list.txt
OBJ="s3://kb-takeout/${TODAY}"
ls -1 | grep -v backup.sh > "${LIST}"

while IFS= read -r FILENAME
do
    S3NAME=$(echo "${FILENAME}" | sed -e's/ /-/g')
    S3NAME="${S3NAME}.gpg.bz2"
    echo "sending ${FILENAME} as ${OBJ}/${S3NAME}"
    gpg -r ken@hero.com -o - --encrypt "${FILENAME}" | bzip2 | aws s3 cp - "${OBJ}/${S3NAME}"
done < "${LIST}"

exit


