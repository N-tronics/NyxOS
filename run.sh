# Run build script
sh ./build.sh
# Start NyxOS in QEMU
qemu-system-i386 -fda build/main_floppy.img
