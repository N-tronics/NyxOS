ASM=nasm
CC=gcc
SRC_DIR=src
BUILD_DIR=build
TOOLS_DIR=tools
MAKE=make

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
	dd if=/dev/zero of=$(BUILD_DIR)/$(TARGET_IMG) bs=512 count=2880
	mkfs.fat -F 12 -n "NYXOS" $(BUILD_DIR)/$(TARGET_IMG)
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/$(TARGET_IMG) conv=notrunc
	mcopy -i $(BUILD_DIR)/$(TARGET_IMG) $(BUILD_DIR)/ext_boot.bin "::ext_boot.bin"
	mcopy -i $(BUILD_DIR)/$(TARGET_IMG) $(BUILD_DIR)/kernel.bin "::kernel.bin"
	mcopy -i $(BUILD_DIR)/$(TARGET_IMG) test.txt "::test.txt"

#
# bootloader
#
bootloader: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/ext_boot.bin
bootloader: boot ext_boot

boot: $(BUILD_DIR)/boot.bin

$(BUILD_DIR)/boot.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/boot BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM)

ext_boot: $(BUILD_DIR)/ext_boot.bin

$(BUILD_DIR)/ext_boot.bin: always
	$(MAKE) -C $(SRC_DIR)/bootloader/ext_boot BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM)

#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR)) ASM=$(ASM)

#
# Tools
#
tools: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat12.c
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat12.c


always:
	mkdir -p $(BUILD_DIR)

clean:
	$(MAKE) -C $(SRC_DIR)/bootloader/boot BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	$(MAKE) -C $(SRC_DIR)/bootloader/ext_boot BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	$(MAKE) -C $(SRC_DIR)/kernel BUILD_DIR=$(abspath $(BUILD_DIR)) clean
	rm -rf $(BUILD_DIR)
