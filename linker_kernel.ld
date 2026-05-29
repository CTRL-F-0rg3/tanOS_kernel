/* linker_kernel.ld — TanOS kernel linker script
 * Final flat binary loaded at 0x200000 by TootBoot
 */

OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
ENTRY(kernel_entry)

SECTIONS {
    . = 0x100000;

    /* Boot header must be first — TootBoot reads it at load address */
    .boot_header : {
        KEEP(*(.boot_header))
    }

    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    }

    /DISCARD/ : {
        *(.comment)
        *(.note*)
        *(.eh_frame*)
        *(.gcc_except_table*)
    }
}
