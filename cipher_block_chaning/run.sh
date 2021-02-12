#! /usr/bin/env bash

gcc ./CBC.c
#./a.out filein fileout key(len = 64) sync (16*n)
./a.out ./1.txt ./2.txt ffeeddccbbaa99887766554433221100f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff 1234567890abcdef234567890abcdef1
