set -evx
. $HOME/eagle-creds.sh

NOW=$(date +%s)
date +%s

curlit () {
    curl --socks5 socks5://$SOCKS_CREDS@se.socks.nordhold.net -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'Accept-Language: en-US,en;q=0.9' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' -H 'Pragma: no-cache' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36' --insecure -o /tmp/output $1
}

curlit "$BASE/player_api.php?username=${USER}&password=${PASS}&action=get_live_streams"
mv /tmp/output channels.$NOW.json
curlit "$BASE/player_api.php?username=${USER}&password=${PASS}&action=get_live_categories"
mv /tmp/output categories.$NOW.json
create-m3u.py $NOW
curlit "$BASE/xmltv.php?username=$USER&password=$PASS&type=m3u_plus&output=mpegts"
cp /tmp/output epg.$NOW.xml
rm -f eagle.xml eagle.m3u
ln -s eagle.$NOW.m3u eagle.m3u
ln -s epg.$NOW.xml eagle.xml



