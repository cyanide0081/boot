;; simple kernel

[bits 64]

kernel_start:
    mov rbx, kernel_hello
    call print_64
    ret

;; video attributes
MAX_ROWS equ 25
MAX_COLS equ 80

;; screen device IO ports
REG_SCREEN_CTRL equ 0x3d4
REG_SCREEN_DATA equ 0x3d5

;; temporary long mode print function
print_64:
    mov rdx, VGA_BUF

.print_64_loop:
    cmp byte [rbx], 0
    je .print_64_ret

    mov al, [rbx]
    mov ah, WB_COLOR
    mov word [rdx], ax

    add rbx, 1 ; next char
    add rdx, 2 ; next VGA buffer cell
    jmp .print_64_loop

.print_64_ret:
    ret

;; rdi: char, rsi: col, rdx: row, rcx: attr
; print_char:
;     pusha

;     cmp rcx, 0
;     cmove rcx, WHITE_ON_BLACK

;     cmp rsi, 0
;     jl .print_char_get_cursor
;     cmp rdx, 0
;     jl .print_char_get_cursor

; .print_char_get_screen_offset:
;     call get_screen_offset ; rax
;     jmp .print_char_check_newline

; .print_char_get_cursor:
;     call get_cursor ; rax
;     jmp .print_char_check_newline

; .print_char_check_newline:
;     cmp rdi, 10 ; \n
    
; .print_char_ret:
;     popa
;     ret
 
kernel_hello:
    db "Hello from the kernel!", 0
