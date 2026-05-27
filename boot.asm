; boot.asm — TanOS kernel entry stub
; Linked with Rust kernel binary.
; TootBoot loads this at 0x200000 and jumps here.
;
; Build (via Cargo/Makefile):
;   nasm -f elf64 -o boot.o boot.asm
;   link with Rust kernel object

[BITS 64]
[SECTION .boot_header]

; ---------------------------------------------------------------------------
; TanOS kernel header — must be at offset 0 of the binary
; Matches TanOsKernelHeader in tan.h
; ---------------------------------------------------------------------------
global tanos_header
tanos_header:
    dd 0x544E4F53           ; magic: 'TNOS' as uint32 little-endian
    dd 0x00010000           ; version 1.0.0
    dq 0x200000             ; load_address
    dq kernel_entry         ; entry_point
    dd 0                    ; image_size (filled by linker via symbol)
    times 12 db 0           ; reserved

; ---------------------------------------------------------------------------
; Kernel entry point — called by TootBoot
; rdi = pointer to BootAbiParams
; rsp = 0x90000 (set by boot1)
; ---------------------------------------------------------------------------
[SECTION .text]

extern tan_kernel_main      ; Rust entry point

global kernel_entry
kernel_entry:
    ; Set up proper kernel stack (4MB mark)
    mov rsp, 0x400000

    ; Clear direction flag
    cld

    ; Zero BSS
    extern __bss_start
    extern __bss_end
    mov rdi, __bss_start
    mov rcx, __bss_end
    sub rcx, rdi
    xor al, al
    rep stosb

    ; rdi still = BootAbiParams* (preserved from TootBoot call)
    ; -> passed as first arg to tan_kernel_main
    mov rdi, rdi            ; explicit (no-op, just clarity)

    call tan_kernel_main

    ; If Rust returns (should never happen) — halt
.halt:
    cli
    hlt
    jmp .halt