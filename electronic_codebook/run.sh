#! /usr/bin/env bash

./run_c.sh

./run_asm.sh

cmp ./2.txt ./3.txt
