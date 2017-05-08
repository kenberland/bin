#!/bin/bash

# pgpe -r"ken@hero.com" plain.txt
# pgpv plain.txt.pgp
	     
if (( $# == 1 )); then
    echo "read only"
    echo "decrypting file cryptext with pgp"
    gpg -d --output plain.txt plain.txt.gpg
    # pgpv plain.txt.pgp
    emacs -nw ./plain.txt
    rm ./plain.txt ./plain.txt~
else
    echo "read/write"
    cp ./plain.txt.gpg ./cryptext.$$
    # pgpv plain.txt.pgp
    gpg -d --output plain.txt plain.txt.gpg
    emacs -nw ./plain.txt
    gpg -e -r CCFDABBD plain.txt
    # pgpe -r"ken@hero.com" plain.txt
    rm ./plain.txt ./plain.txt~
fi




