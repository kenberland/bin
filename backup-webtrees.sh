#!/bin/bash
set -e

docker exec 84883af311f6 tar -cvjf - /app/webtrees/data > ./webtrees-data.$(date +%s).tar
docker exec 84883af311f6 mysqldump webtrees | gzip -c > ./webtrees-mysql.$(date +%s).sql.gz
