; boot.asm — TanOS kernel entry stub
; Linked at 0x100000 by TootBoot

[BITS 64]

[SECTION .boot_header]
global tanos_header
tanos_header:
    dd 0x544E4F53           ; magic 'TNOS'
    dd 0x00010000           ; version 1.0.0
    dq 0x100000             ; load_address
    dq kernel_entry         ; entry_point
    dd 0                    ; image_size
    times 12 db 0           ; reserved

[SECTION .text]
extern tan_kernel_main

global kernel_entry
kernel_entry:
    mov rsp, 0x400000
    and rsp, ~0xF
    cld
    xor edi, edi
    call tan_kernel_main

.halt:
    cli
    hlt
    jmp .halt