#!/bin/bash

env > /tmp/env.txt
TEMPFILE="/tmp/foo.$$.md"
while read line
do
  echo "$line" >> "$TEMPFILE"
done < "${1:-/dev/stdin}"
showdown makehtml -i "$TEMPFILE" --tables 2>/dev/null

