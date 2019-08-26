#!/bin/bash
set -e
export PGPASSWORD=$(gpg -d ~/.ammetrix-pass.gpg)
psql -h ammetrix-ars1.co3d5bfeqgbh.us-east-1.redshift.amazonaws.com -p 8192 -U harley_ro -d ammetrix
