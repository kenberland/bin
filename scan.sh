#!/bin/bash
HOST=hero.net
read -p "Would you like to add a reference name: " LINK_NAME
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

echo "1) Double-sided letter"
echo "2) Single-sided letter"
echo "3) Double-sided legal"
echo "4) Single-sided legal"

while true; do
    read -p "Choose (1-4)?" type
    case $type in
	1*)
	    echo "scanning: duplex;letter;200dpi" && scanimage --source "ADF Duplex" --resolution=200 --format=tiff -b # double sided letter
	    break
	    ;;
	2*)
	    echo "scanning: single;letter;200dpi" && scanimage --resolution=200 --format=tiff -b # single sided letter
	    break
	    ;;
	4*)
	    echo "scanning: single;legal;200dpi"  && scanimage --resolution=200 --page-height=355 --format=tiff -b # single sided legal
	    break
	    ;;
	3*)
	    echo "scanning: duplex;legal;200dpi"  && scanimage --source "ADF Duplex" --resolution=200 --page-height=355 --format=tiff -b # double sided legal
	    break
	    ;;
	*)
	    echo "Invalid choice"
	    ;;
    esac
done

echo Scanning at Bates: $FIRST

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
/usr/bin/rsync -vzax --delete $HOME/scans/ $HOST:scans/


