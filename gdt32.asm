;; base addr of the GDT should be 8-byte aligned
align 8

gdt32_start:
    dq 0 ; 8-byte null descriptor

gdt32_code_seg:
    ;; 8-byte code segment descriptor
    dw 0xffff
    ;; first 24 bits of segment base addr
    dw 0
    db 0
    ;; 0-3: rwx segment
    ;;   4: code/data segment
    ;; 5-6: privilege level 0 (highest) 
    ;;   7: segment is present flag
    db 10011010b
    ;; 0-3: last 4 bits of segment limit
    ;;   4: unused (available)
    ;;   5: 64-bit code flag
    ;;   6: default operation size of 32 bits
    ;;   7: granularity of 4kb
    db 11001111b
    ;; last 8 bits of segment base addr
    db 0

gdt32_data_seg:
    dw 0xffff
    dw 0
    db 0
    ;; 0-3: rwx segment
    db 10010010b
    db 11001111b
    db 0

gdt32_end:

gdt32_pseudo_descriptor:
    ;; limit value of the GDT (length - 1)
    dw (gdt32_end - gdt32_start - 1)
    ;; start addr of the GDT
    dd gdt32_start

CODE_SEG32 equ gdt32_code_seg - gdt32_start
DATA_SEG32 equ gdt32_data_seg - gdt32_start
