# tanOS_kernel/Makefile — kernel only
# make       — build build/tanos.bin
# make clean

NASM    := nasm
LD      := ld
CARGO   := cargo
OBJCOPY := objcopy

BUILD      := build
BOOT_OBJ   := $(BUILD)/boot.o
KERNEL_ELF := $(BUILD)/tanos.elf
KERNEL_BIN := $(BUILD)/tanos.bin
TARGET     := x86_64-tanos

.PHONY: all clean

all: $(KERNEL_BIN)

$(BOOT_OBJ): boot.asm | $(BUILD)
	$(NASM) -f elf64 -o $@ $<
	@echo "[AS]  $<"

$(BUILD)/libtanos.a: src/main.rs Cargo.toml | $(BUILD)
	$(CARGO) +nightly build --release \
		--target $(TARGET).json \
		-Z build-std=core,compiler_builtins \
		-Z build-std-features=compiler-builtins-mem \
		-Z json-target-specs
	cp target/$(TARGET)/release/libtanos.a $@
	@echo "[CARGO] $@"

$(KERNEL_ELF): $(BOOT_OBJ) $(BUILD)/libtanos.a linker_kernel.ld | $(BUILD)
	$(LD) -T linker_kernel.ld --no-dynamic-linker -nostdlib \
		-o $@ $(BOOT_OBJ) $(BUILD)/libtanos.a
	@echo "[LD]  $@"

$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@
	@echo "[BIN] $@ — $$(wc -c < $@) bytes"

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
	$(CARGO) clean
	@echo "[CLEAN]"
