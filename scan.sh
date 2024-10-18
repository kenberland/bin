#!/bin/bash

set -o emacs
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'

COMP_WORDBREAKS=${COMP_WORDBREAKS//:}

#bind TAB:menu-complete
bind 'TAB:dynamic-complete-history'

THIS_YEAR=$(date +%Y)
LAST_YEAR=$(($THIS_YEAR - 1))

FILE_LIST=$(find ~/scans/ -type f \
		 -iwholename \*$LAST_YEAR\* -and -name \*pdf \
		 -printf '%f ' \
		 -o \
		 -iwholename \*$THIS_YEAR\* -and -name \*pdf \
		 -printf '%f ' \
	     )

ALL=""
for filename in $FILE_LIST; do
    onedot=${filename%.*}
    twodot=${onedot%.*}
    ALL="$ALL $twodot"
done
CHOICES=$(echo $ALL | ruby -e'f = STDIN.readline; puts f.split.sort.uniq.join("\n")')
for i in $CHOICES ; do
    history -s $i
done

compgen -W "$urls" http://sa

read -e -p "Would you like to add a reference name: " LINK_NAME


HOST=hero.net
TEMPDIR=/tmp/$$
FILENAME=$(date +%Y-%m-%d_%H:%M:%S)
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
mkdir -p $TEMPDIR
cd $TEMPDIR
LAST=$(ls -1 ~/scans/highwater-* | awk -F\- '{print $2}')
FIRST=$(($LAST + 1))
FIRST_PADDED=$(printf "%06d" $FIRST)

# Lookup page type from the db
FRIENDLY_LINK_NAME=$(echo "${LINK_NAME}" | sed -e's/-/_/g')
PAGE_PREF=$(jq -r ".files.\"${FRIENDLY_LINK_NAME}\"" $HOME/.scan-page-prefs.json)

if [ "${PAGE_PREF}" = "null" ]; then
    #choose a page pref
    echo "1) Double-sided letter"
    echo "2) Single-sided letter"
    echo "3) Double-sided legal"
    echo "4) Single-sided legal"
    echo "5) Double-sided checks"
    echo "6) Double-sided small bills (24cm)"
    echo "7) Single-sided checks"

    while true; do
	read -p "Choose (1-6)?" type
	case $type in
	    1*)
		echo "scanning: duplex;letter;200dpi"
		break
		;;
	    2*)
		echo "scanning: single;letter;200dpi"
		break
		;;
	    4*)
		echo "scanning: single;legal;200dpi"
		break
		;;
	    3*)
		echo "scanning: duplex;legal;200dpi"
		break
		;;
	    5*)
		echo "scanning: duplex;letter;200dpi"
		break
		;;
	    6*)
		echo "scanning: duplex;letter;200dpi"
		break
		;;
	    7*)
		echo "scanning: duplex;letter;200dpi"
		break
		;;
	    *)
		echo "Invalid choice"
		;;
	esac
    done
    # write the new pref to the db
    cat $HOME/.scan-page-prefs.json | \
	jq ".files += { \"${FRIENDLY_LINK_NAME}\" : \"${type}\" }" \
	   > $HOME/.scan-page-prefs.new.json
    mv $HOME/.scan-page-prefs.new.json $HOME/.scan-page-prefs.json
else
    echo 1: two-letter, 2: single-letter, 3: two-legal, 4: single-legal
    echo ${PAGE_PREF}
    type=${PAGE_PREF}
fi

case $type in
    1*)
	scanimage --source "ADF Duplex" --resolution=200 --format=tiff -b # double sided letter
	;;
    2*)
	scanimage --resolution=200 --format=tiff -b # single sided letter
	;;
    4*)
	scanimage --resolution=200 --page-height=355 --format=tiff -b # single sided legal
	;;
    3*)
	scanimage --source "ADF Duplex" --resolution=200 --page-height=355 --format=tiff -b # double sided legal
	;;
    5*)
	scanimage --source "ADF Duplex" --resolution=200 --format=tiff -b --page-height=90 # double sided checks
	;;
    6*)
	scanimage --source "ADF Duplex" --resolution=200 --format=tiff -b --page-height=240 # double sided small bills
	;;
    7*)
	scanimage --resolution=200 --format=tiff -b --page-height=90 # single sided checks
	;;
esac

FINAL_DIR=$HOME/scans/$YEAR/$MONTH/$DAY
echo Moving to $FINAL_DIR

mkdir -p $FINAL_DIR
SCANS=$(find $TEMPDIR -type f -printf '%f\n' | sed -e's/out//' | sort -n )
for f in $SCANS
do
    LAST=$(($LAST + 1))
    LAST_PADDED=$(printf "%06d" $LAST)
    tiffcp -c g4 $TEMPDIR/out${f} $FINAL_DIR/$LINK_NAME.$LAST_PADDED.tif
done

echo Making ${LINK_NAME}.${FIRST_PADDED}-${LAST_PADDED}.pdf
cd $FINAL_DIR/
FINAL_TIFFS=$(find . -type f -name $LINK_NAME\*.tif -printf '%f\n' | sort -n )
for f in $FINAL_TIFFS
do
    convert "${f}" "${f}.pdf"
done
rm $LINK_NAME.??????.tif

pdftk ${LINK_NAME}.*.tif.pdf cat output ${LINK_NAME}.${FIRST_PADDED}-${LAST_PADDED}.pdf
rm $LINK_NAME.??????.tif.pdf

find $HOME/scans/ -maxdepth 1 -type f -name highwater\* -exec rm {} \;
touch $HOME/scans/highwater-$LAST
#/usr/bin/rsync -vzax --delete $HOME/scans/ $HOST:scans/
#/usr/bin/rsync -vzax ~heather/2017.gz* $HOST:accounting/
LAST_BACKUP=$(ls -l  --time-style=+%s $HOME/scans/last-backup | awk '{print $6}')
NOW=$(date +%s)
ONE_DAY=86400
if [ $(($LAST_BACKUP + $ONE_DAY)) -lt $NOW ]; then
    backup-scans-to-hero.sh
    touch $HOME/scans/last-backup
else
    NEXT_BACKUP=$(($LAST_BACKUP + $ONE_DAY))
    NEXT_BACKUP_FORMATTED=$(date -d @${NEXT_BACKUP})
    echo not backing up until $NEXT_BACKUP_FORMATTED
fi


