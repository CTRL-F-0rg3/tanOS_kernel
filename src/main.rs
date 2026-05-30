//! TanOS kernel — entry point

#![no_std]
#![no_main]
#![allow(dead_code)]

use core::panic::PanicInfo;

// VGA buffer
const VGA: *mut u16 = 0xB8000 as *mut u16;
const WIDTH: usize = 80;

// Purple bg, bright colors
const C_TITLE: u16 = 0x5F00;   // white on purple
const C_GREEN: u16 = 0x5A00;   // green on purple
const C_NORM:  u16 = 0x5700;   // gray on purple

fn vga_clear() {
    unsafe {
        for i in 0..(80*25) {
            *VGA.add(i) = C_NORM | 0x20;
        }
    }
}

fn vga_write(x: usize, y: usize, s: &[u8], color: u16) {
    unsafe {
        for (i, &b) in s.iter().enumerate() {
            *VGA.add(y * WIDTH + x + i) = color | b as u16;
        }
    }
}

#[repr(C)]
pub struct BootParams {
    magic:   u32,
    os_type: u32,
    lba:     u64,
    pml4:    u64,
}

#[no_mangle]
pub extern "C" fn tan_kernel_main(_params: *const BootParams) -> ! {
    vga_clear();

    // Draw a simple box
    unsafe {
        // Top border
        *VGA.add(0) = C_GREEN | 0xDA;
        for i in 1..79 { *VGA.add(i) = C_GREEN | 0xC4; }
        *VGA.add(79) = C_GREEN | 0xBF;
        // Sides
        for r in 1..24 {
            *VGA.add(r*80)    = C_GREEN | 0xB3;
            *VGA.add(r*80+79) = C_GREEN | 0xB3;
        }
        // Bottom
        *VGA.add(24*80) = C_GREEN | 0xC0;
        for i in 1..79 { *VGA.add(24*80+i) = C_GREEN | 0xC4; }
        *VGA.add(24*80+79) = C_GREEN | 0xD9;
    }

    vga_write(30,  2, b"TanOS ",C_TITLE);
    vga_write(25,  4, b"Kernel loaded successfully", C_GREEN);
    vga_write(28,  6, b"Booted by TootBoot",  C_NORM);
    vga_write(20, 22, b"[ System halted -- press reset to reboot ]", C_NORM);

    loop {
        unsafe { core::arch::asm!("cli; hlt") };
    }
}

#[panic_handler]
fn panic(_: &PanicInfo) -> ! {
    unsafe {
        let vga = VGA;
        let msg = b"!! KERNEL PANIC !!";
        for (i, &b) in msg.iter().enumerate() {
            *vga.add(i) = 0x4F00 | b as u16;
        }
    }
    loop {
        unsafe { core::arch::asm!("cli; hlt") };
    }
}