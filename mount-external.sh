#!/bin/bash
set -evx
sudo cryptsetup open /dev/sda1 external
sudo mount /dev/mapper/external /mnt/ken
