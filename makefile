ASM=nasm
SRC_DIR=src
BUILD_DIR=build

TARGET_IMG=main_floppy.img

.PHONY: all floppy_image kernel bootloader clean always

#
# Floppy Image
#
floppy_image: $(BUILD_DIR)/$(TARGET_IMG)

$(BUILD_DIR)/$(TARGET_IMG): bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/$(TARGET_IMG) bs=512 count=2880
	mkfs.fat -F 12 -n "NYXOS" $(BUILD_DIR)/$(TARGET_IMG)
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/$(TARGET_IMG) conv=notrunc
	mcopy -i $(BUILD_DIR)/$(TARGET_IMG) $(BUILD_DIR)/kernel.bin "::kernel.bin"

#
# bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin

$(BUILD_DIR)/bootloader.bin: always $(SRC_DIR)/bootloader/bootloader.asm
	$(ASM) $(SRC_DIR)/bootloader/bootloader.asm -f bin -o $(BUILD_DIR)/bootloader.bin

#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: always $(SRC_DIR)/kernel/main.asm
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

always:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
