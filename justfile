# tanOS_kernel/justfile

nasm    := "nasm"
ld      := "ld"
objcopy := "objcopy"
cargo   := "cargo +nightly"
build   := "build"
target  := "x86_64-tanos"

# Default: build kernel binary
default: build

build: (build + "/tanos.bin")

{{build + "/boot.o"}}: boot.asm
    mkdir -p {{build}}
    {{nasm}} -f elf64 -o {{build}}/boot.o boot.asm
    @echo "[AS]  boot.asm"

{{build + "/libtanos.a"}}: src/main.rs Cargo.toml
    mkdir -p {{build}}
    {{cargo}} build --release \
        --target {{target}}.json \
        -Z build-std=core,compiler_builtins \
        -Z build-std-features=compiler-builtins-mem \
        -Z json-target-specs
    cp target/{{target}}/release/libtanos.a {{build}}/libtanos.a
    @echo "[CARGO] {{build}}/libtanos.a"

{{build + "/tanos.elf"}}: (build + "/boot.o") (build + "/libtanos.a") linker_kernel.ld
    {{ld}} -T linker_kernel.ld --no-dynamic-linker -nostdlib \
        -o {{build}}/tanos.elf \
        {{build}}/boot.o {{build}}/libtanos.a
    @echo "[LD]  {{build}}/tanos.elf"

{{build + "/tanos.bin"}}: (build + "/tanos.elf")
    {{objcopy}} -O binary {{build}}/tanos.elf {{build}}/tanos.bin
    @echo "[BIN] {{build}}/tanos.bin — $(wc -c < {{build}}/tanos.bin) bytes"

clean:
    rm -rf {{build}}
    cargo clean
    @echo "[CLEAN]"
