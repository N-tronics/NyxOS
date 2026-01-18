ASM=nasm
CC=gcc
MAKE=make
CC16=./tools/bin/wcc
LD16=./tools/bin/wlink

SRC_DIR=src
BUILD_DIR=build
TOOLS_DIR=tools

TARGET_IMG=main_floppy.img

.PHONY: all floppy_image kernel bootloader clean always tools

#
# All
#
all: floppy_image tools

#
# Floppy Image
#
floppy_image: $(BUILD_DIR)/$(TARGET_IMG)

$(BUILD_DIR)/$(TARGET_IMG): bootloader kernel
	dd if=/dev/zero of=$@ bs=512 count=2880
	mkfs.fat -F 12 -n "NYXOS" $@
	dd if=$(BUILD_DIR)/boot/boot.bin of=$@ conv=notrunc
	mcopy -i $@ $(BUILD_DIR)/ext_boot/ext_boot.bin "::ext_boot.bin"
	mcopy -i $@ $(BUILD_DIR)/kernel/kernel.bin "::kernel.bin"
	mcopy -i $@ test.txt "::test.txt"

#
# bootloader
#
bootloader: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/ext_boot.bin
bootloader: boot ext_boot

boot: $(BUILD_DIR)/boot.bin

$(BUILD_DIR)/boot.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/boot BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM) PROJ_DIR=$(abspath .)

ext_boot: $(BUILD_DIR)/ext_boot.bin

$(BUILD_DIR)/ext_boot.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/ext_boot BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM) PROJ_DIR=$(abspath .)

#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM) PROJ_DIR=$(abspath .)

#
# Tools
#
tools: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: $(TOOLS_DIR)/fat/fat12.c always
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $@ $<


always:
	mkdir -p $(BUILD_DIR)

clean:
	$(MAKE) -C $(SRC_DIR)/bootloader/boot BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	$(MAKE) -C $(SRC_DIR)/bootloader/ext_boot BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	rm -rf $(BUILD_DIR)
