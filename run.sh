#!/bin/bash

# Run build script
./build.sh
if [ $? -ne 0 ]; then
    echo "BUILD FAILED!"
    exit 1
fi
# Start NyxOS in QEMU
qemu-system-i386 -fda build/main_floppy.img
