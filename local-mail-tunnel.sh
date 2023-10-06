#!/bin/bash
set -evx
ssh -v -C -N -L 2525:localhost:25 ken@hero.net
