#!/bin/bash

#UUID=4b074c67-3f31-4a39-a724-467b9f7e914a
#PART=$(ls -l /dev/disk/by-uuid/ | grep 4b074c67-3f31-4a39-a724-467b9f7e914a | cut -d/ -f3)
#DEV=$(echo $PART | sed -e's/[0-9]//')

read -s -p"enter password: " PASS
echo

HD_PASS=$(echo $PASS | gpg --passphrase-fd 0 -d $HOME/ST1000NM0033-9ZM173-Z1W5ZKFL-4b074c67-3f31-4a39-a724-467b9f7e914a.password.txt.gpg)

echo $PASS | sudo -S -i <<EOF
echo "- - -" | tee /sys/class/scsi_host/host6/scan
hdparm --security-unlock $HD_PASS /dev/sdc >& /dev/null
partprobe
umount /mnt/sdc1
mount /mnt/sdc1
EOF

#cat > /tmp/${0##*/}.$$.tmp <<EOF
#EOF

