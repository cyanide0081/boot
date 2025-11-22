section .stage_2

[bits 16]

stage_2_start:
    mov bx, stage_2_msg
    call bios_print

    ;; load GDT and switch to protected mode
    cli ; disable interrupts
    lgdt [gdt32_pseudo_descriptor]

    ;; setting cr0.PE (bit 0) enables protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ;; the far jump into the code segment from the new GDT
    ;; flushes the CPU pipeline removing any 16-bit decoded
    ;; instructions and updates the cs register with the new
    ;; code segment
    jmp CODE_SEG32: start_prot_mode

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

stage_2_msg:
    db "Stage 2 was your plan...", 13, 10, 0

[bits 32]
start_prot_mode:
    ;; old segments are now meaningless
    mov ax, DATA_SEG32
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax 

print_32:
    pusha

    VGA_BUF equ 0xb8000
    WB_COLOR equ 0xf

    mov edx, VGA_BUF

print_32_loop:
    cmp byte[ebx], 0
    je print_32_ret

    mov al, [ebx]
    mov ah, WB_COLOR
    mov [edx], ax

    add ebx, 1 ; next char
    add edx, 2 ; next VGA buffer cell
    jmp print_32_loop

print_32_ret:
    popa
    ret

%include "gdt32.asm"
