#!/bin/sh

HOST="$1"
if [ -z "$HOST" ]; then
    HOST=orca.amazon.com
fi
COOKIE=
eval $(openconnect --useragent AnyConnect \
                   --csd-wrapper /usr/bin/csd-wrapper --user $LOGNAME \
	--authgroup orca-Corp-VPN $HOST --authenticate | grep -v Opening)

if [ -z "$COOKIE" ]; then
    exit 1
fi

nmcli con up 'Amazon VPN' passwd-file /proc/self/fd/5 5<<EOF
vpn.secrets.cookie:$COOKIE
vpn.secrets.gwcert:$FINGERPRINT
vpn.secrets.gateway:$HOST
EOF
