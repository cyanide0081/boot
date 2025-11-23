#!/bin/sh
set -e # exit on failure 

mkdir -p bin
nasm -f elf64 bootloader.asm -o bootloader.o
ld --script linker.ld bootloader.o -o linked.o
objcopy -O binary linked.o bin/image.bin
rm *.o
qemu-system-x86_64 -no-reboot -drive file=bin/image.bin,format=raw,index=0,media=disk
