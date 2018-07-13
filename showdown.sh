#!/bin/bash

TEMPFILE="/tmp/foo.$$.md"
while read line
do
  echo "$line" >> "$TEMPFILE"
done < "${1:-/dev/stdin}"
showdown makehtml -i "$TEMPFILE" 2>/dev/null

