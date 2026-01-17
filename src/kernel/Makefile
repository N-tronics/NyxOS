ASM?=nasm
BUILD_DIR?=build/

.PHONY: all clean

all: kernel

kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: kernel.asm
	$(ASM) kernel.asm -f bin -o $(BUILD_DIR)/kernel.bin

clean:
	rm -f $(BUILD_DIR)/kernel.bin
