#! /usr/bin/env bash

nasm -f elf32 ./ECB.asm
gcc -m32 ./ECB.o -o ./asm.out

./asm.out ./1.txt ./2.txt ffeeddccbbaa99887766554433221100f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff
