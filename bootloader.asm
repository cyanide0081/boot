section .boot_sector
global __start

[bits 16]

__start:
    mov bx, init_msg
    call bios_print

    mov si, disk_addr_packet
    mov ah, 0x42 ; BIOS extended read proc
    mov dl, 0x80 ; drive number
    int 0x13 ; BIOS disk service
    jc .error_reading_disk

.ignore_error_reading_disk:
    jmp 0: SND_STAGE_ADDR

.error_reading_disk:
    cmp word [dap_sectors_count], READ_SECTORS_COUNT
    jle .ignore_error_reading_disk

    mov bx, error_reading_disk_msg
    call bios_print

;; print string using BIOS video service (real mode only)
bios_print:
    pusha
    mov ah, 0x0E ; BIOS display char proc

.bios_print_loop:
    cmp byte [bx], 0
    je .bios_print_ret

    mov al, [bx]
    int 0x10 ; BIOS video service

    inc bx
    jmp .bios_print_loop

;; print a CRLF and return
.bios_print_ret:
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10

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
BOOT_LOAD_ADDR equ 0x7C00
SND_STAGE_ADDR equ (BOOT_LOAD_ADDR + SECTOR_SIZE)

init_msg:
    db "Initializing boot loader...", 0 
error_reading_disk_msg:
    db "Error: failed to read disk with 0x13/ah=0x42", 0

section .stage_2

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

stage_2_msg:
    db "Switching to 32-bit protected mode...", 0

[bits 32]
start_prot_mode:
    ;; old segments are now meaningless
    mov ax, DATA_SEG32
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax 

    ;; build page table and switch to long mode
    mov ebx, 0x1000
    call build_page_table
    mov cr3, ebx ; MMU finds the PML4 table in cr3

    ;; enable PAE (physical address extension)
    mov eax, cr4
    or eax, 1 << 5 ; eax | 100000b
    mov cr4, eax

    ;; the EFER (extended feature enable register)
    ;; MSR (model-specific register) contains information related to long mode
    ;; operation - bit 8 if this MSR is the LME (long mode enable)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ;; enable paging (PG flag in cr0, bit 31)
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    
    ;; new GDT has the 64-bit segment flag set
    lgdt [gdt64_pseudo_descriptor]

    jmp CODE_SEG64: start_long_mode

;; page table definitions
PAGE64_PAGE_SIZE equ 0x1000 ; 4096
PAGE64_TAB_SIZE equ 0x1000
PAGE64_TAB_ENT_NUM equ 512

;; build a four-level page table starting at the address in ebx
build_page_table:
    pusha

    ;; init all four tables to zero, ignoring all other bits in any entry if
    ;; the present flag is cleared
    mov ecx, PAGE64_TAB_SIZE ; number of repetitions
    mov edi, ebx ; base address
    xor eax, eax ; clear (eax stores the value)
    rep stosd ; ?

    ;; link first entry in PML4 table to the PDP table
    mov edi, ebx
    lea eax, [edi + (PAGE64_TAB_SIZE | 11b)] ; r/w and present flags
    mov dword [edi], eax

    ;; link first entry in PDP table to PD table
    add edi, PAGE64_TAB_SIZE
    add eax, PAGE64_TAB_SIZE
    mov dword [edi], eax

    ;; link first entry in PD table to page table
    add edi, PAGE64_TAB_SIZE
    add eax, PAGE64_TAB_SIZE
    mov dword [edi], eax

    ;; init only a single page on the lowest layer
    add edi, PAGE64_TAB_SIZE
    mov ebx, 11b
    mov ecx, PAGE64_TAB_ENT_NUM

.build_page_table_set_entry:
    mov dword [edi], ebx
    add ebx, PAGE64_PAGE_SIZE
    add edi, 8
    loop .build_page_table_set_entry

    popa
    ret

[bits 64]

start_long_mode:
    call kernel_start

end:
    hlt
    jmp end

%include "gdt32.asm"
%include "gdt64.asm"
%include "kernel.asm"
