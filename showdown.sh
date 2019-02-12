#!/bin/bash
env >> /tmp/foo.txt
TEMPFILE="/tmp/foo.$$.md"
while read line
do
  echo "$line" >> "$TEMPFILE"
done < "${1:-/dev/stdin}"
showdown makehtml -i "$TEMPFILE" --tables 2>/dev/null

