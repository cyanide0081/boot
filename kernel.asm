;; simple kernel with prompts that echo back user input

[bits 64]

kernel_start:
    ;; setup
    call vga_clear_screen

    mov rax, 0
    call vga_set_cursor

    mov rbx, kernel_banner
    call k_print

    call vga_adv_line

    mov rbx, kernel_prompt
    call k_print
    ;; TODO user input loop

    ret

;; video attributes
VGA_BUF equ 0xB8000
VGA_DEF_STYLE equ 0x07

VGA_ROWS equ 25
VGA_COLS equ 80

VGA_CELLS equ VGA_ROWS * VGA_COLS

;; screen device IO ports
REG_SCREEN_CTRL equ 0x3D4
REG_SCREEN_DATA equ 0x3D5

;; rbx: null-terminated string
k_print:
.loop:
    cmp byte [rbx], 0
    je .ret

    mov dil, byte [rbx]
    mov rsi, -1
    mov rdx, -1
    mov rcx, 0
    call k_print_char

    add rbx, 1
    jmp .loop

.ret:
    ret

;; rdi: char, rsi: col, rdx: row, rcx: attr
k_print_char:
    push rbx

    mov rax, VGA_DEF_STYLE
    cmp rcx, 0
    cmove rcx, rax

    mov rbx, VGA_BUF

    cmp rsi, 0
    jl .get_cursor
    cmp rdx, 0
    jl .get_cursor

.get_screen_offset:
    ; call get_screen_offset ; rax
    jmp .check_newline

.get_cursor:
    call vga_get_cursor ; rax
    shl rax, 1 ; cells == chars * 2
    jmp .check_newline

.check_newline:
    ; cmp rdi, 10 ; \n
    ; je .goto_row_end

    mov ch, cl
    mov cl, dil
    mov word [rbx + rax], cx

    add rax, 2
    shr rax, 1 ; chars == cells / 2
    call vga_set_cursor
    
.ret:
    pop rbx
    ret

vga_clear_screen:
    push rax
    push rbx
    push rcx

    mov rax, VGA_BUF
    mov rbx, 0

.loop:
    cmp rbx, VGA_CELLS
    je .ret

    mov cl, 0x20 ; ' '
    mov ch, VGA_DEF_STYLE
    mov word [rax], cx

    add rax, 2 ; next VGA buffer cell
    add rbx, 1
    jmp .loop

.ret:
    pop rcx
    pop rbx
    pop rax
    ret

;; cursor -> rax
vga_get_cursor:
    xor rax, rax

    mov dx, REG_SCREEN_CTRL ; port
    mov al, 14 ; reg 14: high byte of cursor offset
    out dx, al

    mov dx, REG_SCREEN_DATA
    in al, dx

    mov r8b, al
    shl r8b, 8

    mov dx, REG_SCREEN_CTRL ; port
    mov al, 15 ; reg 15: low byte of cursor offset
    out dx, al

    mov dx, REG_SCREEN_DATA
    in al, dx

    ret
 

;; rax: cursor
vga_set_cursor:
    push rbx
    mov rbx, rax

    mov dx, REG_SCREEN_CTRL ; port
    mov al, 14 ; reg 14: high byte of cursor offset
    out dx, al

    mov dx, REG_SCREEN_DATA
    mov al, bh
    out dx, al

    mov dx, REG_SCREEN_CTRL ; port
    mov al, 15 ; reg 15: low byte of cursor offset
    out dx, al

    mov dx, REG_SCREEN_DATA
    mov al, bl
    out dx, al

    mov rax, rbx
    pop rbx
    ret

vga_adv_line:
    call vga_get_cursor

    add rax, VGA_COLS
    mov rsi, VGA_COLS
    push rax
    xor ecx, ecx
    mov edx, ecx
    div rsi
    pop rax
    sub rax, rdx

    call vga_set_cursor
    ret


kernel_banner:
    db "simpkernel v0.01-alpha", 0
kernel_prompt:
    db "kernel> ", 0
