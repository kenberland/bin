#!/bin/bash
set -evx
sudo umount /mnt/ken
sudo cryptsetup close external
