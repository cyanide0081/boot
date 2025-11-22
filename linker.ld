MEMORY {
    boot_sector (rwx) : ORIGIN = 0x7c00, LENGTH = 512
    stage_2 (rwx) : ORIGIN = 0x7e00, LENGTH = 32768 /* 512 * 64 */
}

ENTRY(__start)
SECTIONS {
    .boot_sector : { *(.boot_sector); } > boot_sector
    .bootsign (0x7c00 + 510) : {
        BYTE(0x55)
        BYTE(0xaa)
    } > boot_sector
    .stage_2 : { *(.stage_2); } > stage_2
}
