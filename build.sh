#!/bin/sh
nasm -f elf64 boot_sector.asm -o boot_sector.o
nasm -f elf64 stage_2.asm -o stage_2.o
ld --script linker.ld boot_sector.o stage_2.o -o linked.o
objcopy -O binary linked.o boot_image
qemu-system-x86_64 -no-reboot -drive file=boot_image,format=raw,index=0,media=disk
