#!/bin/bash
#set -x
#set -v
TODAY=$(date +%Y-%m-%d)
mysql coinless_production -H -e'select * from rsvps; select event, sum(heads) from rsvps group by event;' | sed -e's/<\/TR>/<\/TR>\n/g' | mail  -a "Content-Type: text/html; charset=UTF-8" -s 'RSVPS' heather@hero.net ken@hero.net
