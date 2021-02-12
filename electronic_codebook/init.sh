#! /usr/bin/env bash

rm *.o
rm *.out

nasm -f elf32 ./ECB.asm
gcc -m32 ./ECB.o -o ./ECB_asm.out

gcc ./ECB.c -o ./ECB_c.out


