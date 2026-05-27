# TanOS kernel Makefile — kernel only
# make         — build tanos.bin
# make clean

NASM  := nasm
LD    := ld
CARGO := cargo

BUILD      := build
KERNEL_ELF := $(BUILD)/tanos.elf
KERNEL_BIN := $(BUILD)/tanos.bin
BOOT_OBJ   := $(BUILD)/boot.o

TARGET     := x86_64-tanos

.PHONY: all clean

all: $(KERNEL_BIN)

# 1. Assemble ASM entry stub
$(BOOT_OBJ): boot.asm | $(BUILD)
	$(NASM) -f elf64 -o $@ $<
	@echo "[AS]  $<"

# 2. Build Rust kernel (no_std, no_main)
$(BUILD)/libtanos.a: src/main.rs Cargo.toml | $(BUILD)
	$(CARGO) build --release --target $(TARGET).json -Z build-std=core,compiler_builtins
	cp target/$(TARGET)/release/libtanos.a $@
	@echo "[CARGO] kernel compiled"

# 3. Link ASM stub + Rust lib -> ELF
$(KERNEL_ELF): $(BOOT_OBJ) $(BUILD)/libtanos.a linker_kernel.ld | $(BUILD)
	$(LD) -T linker_kernel.ld --no-dynamic-linker -nostdlib \
		-o $@ $(BOOT_OBJ) $(BUILD)/libtanos.a
	@echo "[LD]  $@"

# 4. Strip to flat binary
$(KERNEL_BIN): $(KERNEL_ELF)
	objcopy -O binary $< $@
	@echo "[BIN] $@ — $$(wc -c < $@) bytes"

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
	cargo clean
	@echo "[CLEAN]"
