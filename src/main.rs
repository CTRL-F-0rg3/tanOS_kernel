//! TanOS kernel — entry point
//! Called from boot.asm after TootBoot loads us.

#![no_std]
#![no_main]

// ---------------------------------------------------------------------------
// Panic handler (required for no_std)
// ---------------------------------------------------------------------------
use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    // Write 'PANIC' to top-right corner of VGA in red
    let vga = 0xB8000 as *mut u16;
    let msg = b"!! KERNEL PANIC !!";
    unsafe {
        for (i, &byte) in msg.iter().enumerate() {
            // red on black = 0x4F
            *vga.add(i) = (0x4F00) | byte as u16;
        }
    }
    loop {
        unsafe { core::arch::asm!("cli; hlt") };
    }
}

// ---------------------------------------------------------------------------
// VGA text mode helper
// ---------------------------------------------------------------------------
const VGA_BASE: *mut u16 = 0xB8000 as *mut u16;
const VGA_WIDTH: usize = 80;

// Purple bg (0x5), bright green text (0xA)
const COLOR_NORMAL: u8 = 0x5A;
const COLOR_TITLE: u8  = 0x5F;  // purple bg, white text

fn vga_write(x: usize, y: usize, s: &[u8], color: u8) {
    unsafe {
        for (i, &byte) in s.iter().enumerate() {
            let offset = y * VGA_WIDTH + x + i;
            *VGA_BASE.add(offset) = ((color as u16) << 8) | byte as u16;
        }
    }
}

fn vga_clear() {
    unsafe {
        for i in 0..(80 * 25) {
            *VGA_BASE.add(i) = (0x50 << 8) | b' ' as u16;
        }
    }
}

// ---------------------------------------------------------------------------
// BootABI params struct (must match bootabi.h)
// ---------------------------------------------------------------------------
#[repr(C)]
pub struct BootAbiParams {
    pub magic:               u32,
    pub os_type:             u32,
    pub partition_lba:       u64,
    pub pml4_address:        u64,
    pub cmdline:             [u8; 256],
    pub kernel_path:         [u8; 128],
    pub bootloader_version:  u32,
    pub reserved:            [u8; 64],
}

// ---------------------------------------------------------------------------
// Kernel main — called from boot.asm
// params: pointer to BootAbiParams passed by TootBoot
// ---------------------------------------------------------------------------
#[no_mangle]
pub extern "C" fn tan_kernel_main(params: *const BootAbiParams) -> ! {
    vga_clear();

    vga_write(30, 1,  b"TanOS v0.1.0",       COLOR_TITLE);
    vga_write(25, 3,  b"Kernel loaded successfully", COLOR_NORMAL);
    vga_write(25, 5,  b"Booted by TootBoot",  COLOR_NORMAL);

    // Show bootloader version from params
    if !params.is_null() {
        let ver = unsafe { (*params).bootloader_version };
        let major = (ver >> 16) & 0xFF;
        let minor = (ver >> 8)  & 0xFF;

        vga_write(25, 7, b"Bootloader version: ", COLOR_NORMAL);

        // Write major digit
        let major_char = b'0' + major as u8;
        let minor_char = b'0' + minor as u8;
        unsafe {
            let offset = 7 * VGA_WIDTH + 45;
            *VGA_BASE.add(offset)     = ((COLOR_NORMAL as u16) << 8) | major_char as u16;
            *VGA_BASE.add(offset + 1) = ((COLOR_NORMAL as u16) << 8) | b'.' as u16;
            *VGA_BASE.add(offset + 2) = ((COLOR_NORMAL as u16) << 8) | minor_char as u16;
        }
    }

    vga_write(22, 22, b"[ System halted — press reset to reboot ]", COLOR_NORMAL);

    loop {
        unsafe { core::arch::asm!("cli; hlt") };
    }
}