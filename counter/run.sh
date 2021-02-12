#! /usr/bin/env bash

gcc ./CTR.c
#./a.out filein fileout key(len = 64) sync
./a.out ./1.txt ./2.txt ffeeddccbbaa99887766554433221100f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff 12345678
