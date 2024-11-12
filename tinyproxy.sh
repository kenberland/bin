#!/bin/bash
set -evx
PROXY_SERVER=$1
MY_ADDRESS=$(curl icanhazip.com)

cat > /tmp/tinyproxy.conf <<EOD
User nobody
Group nogroup
Port 443
Timeout 600
DefaultErrorFile "/usr/share/tinyproxy/default.html"
StatFile "/usr/share/tinyproxy/stats.html"
Logfile "/tmp/tinyproxy.log"
LogLevel Info
PidFile "/tmp/tinyproxy.pid"
MaxClients 100
Allow 127.0.0.1
Allow $MY_ADDRESS/32
ViaProxyName "tinyproxy"
ConnectPort 443
ConnectPort 563
EOD

scp /tmp/tinyproxy.conf ubuntu@$PROXY_SERVER:
cat > /tmp/setup.sh <<EOD
set -evx
sudo apt-get update
sudo apt-get install -y tinyproxy 
sudo cp ~/tinyproxy.conf /etc/tinyproxy/tinyproxy.conf 
sudo /etc/init.d/tinyproxy restart
EOD

scp /tmp/setup.sh ubuntu@$PROXY_SERVER:
ssh ubuntu@$PROXY_SERVER bash ./setup.sh






