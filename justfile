# tanOS_kernel/justfile

nasm    := "nasm"
ld      := "ld"
objcopy := "objcopy"
target  := "x86_64-tanos"

default: build

build: _dirs boot_obj rust_lib link strip

_dirs:
    mkdir -p build

boot_obj:
    {{nasm}} -f elf64 -o build/boot.o boot.asm
    @echo "[AS]  boot.asm"

rust_lib:
    cargo +nightly build --release \
        --target {{target}}.json \
        -Z build-std=core,compiler_builtins \
        -Z build-std-features=compiler-builtins-mem \
        -Z json-target-spec
    cp target/{{target}}/release/libtanos.a build/libtanos.a
    @echo "[CARGO] build/libtanos.a"

link:
    {{ld}} -T linker_kernel.ld --no-dynamic-linker -nostdlib \
        -o build/tanos.elf \
        build/boot.o build/libtanos.a
    @echo "[LD]  build/tanos.elf"

strip:
    {{objcopy}} -O binary build/tanos.elf build/tanos.bin
    @echo "[BIN] build/tanos.bin — $(wc -c < build/tanos.bin) bytes"

clean:
    rm -rf build
    cargo clean
    @echo "[CLEAN]"
