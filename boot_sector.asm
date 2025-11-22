section .boot_sector
global __start

[bits 16]

__start:
    mov bx, msg
    call bios_print

    mov si, disk_addr_packet
    mov ah, 0x42 ; BIOS extended read proc
    mov dl, 0x80 ; drive number
    int 0x13 ; BIOS disk service
    jc error_reading_disk

ignore_error_reading_disk:
    jmp 0: SND_STAGE_ADDR

error_reading_disk:
    cmp word[dap_sectors_count], READ_SECTORS_COUNT
    jle ignore_error_reading_disk

    mov bx, error_reading_disk_msg
    call bios_print

end:
    hlt
    jmp end

bios_print:
    pusha
    mov ah, 0x0e ; BIOS display char proc

bios_print_loop:
    cmp byte[bx], 0
    je bios_print_ret

    mov al, [bx]
    int 0x10 ; BIOS video service

    inc bx
    jmp bios_print_loop

bios_print_ret:
    popa
    ret

align 4

disk_addr_packet:
    db 0x10 ; packet size
    db 0 ; always 0

dap_sectors_count:
    dw READ_SECTORS_COUNT ; number of read sectors
    dd (BOOT_LOAD_ADDR + SECTOR_SIZE) ; dest addr
    dq 1 ; sector to start at 0 (boot)

SECTOR_SIZE equ 512
READ_SECTORS_COUNT equ 64
BOOT_LOAD_ADDR equ 0x7c00
SND_STAGE_ADDR equ (BOOT_LOAD_ADDR + SECTOR_SIZE)

msg:
    db "Hello, World!", 13, 10, 0 
error_reading_disk_msg:
    db "Error: failed to read disk with 0x13/ah=0x42", 13, 10, 0
