;; base addr of the 64-bit GDT should be 16-byte aligned
align 16

gdt64_start:
    dq 0 ; 8-byte null descriptor

gdt64_code_seg:
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
    ;;   6: default operation size of 64 bits
    ;;   7: granularity of 4kb
    db 10101111b
    ;; last 8 bits of segment base addr
    db 0

gdt64_data_seg:
    dw 0xffff
    dw 0
    db 0
    ;; 0-3: rwx segment
    db 10010010b
    db 10101111b
    db 0

gdt64_end:

gdt64_pseudo_descriptor:
    ;; limit value of the GDT (length - 1)
    dw (gdt64_end - gdt64_start - 1)
    ;; start addr of the GDT
    dd gdt64_start

CODE_SEG64 equ gdt64_code_seg - gdt64_start
DATA_SEG64 equ gdt64_data_seg - gdt64_start
