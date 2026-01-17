ASM?=nasm
BUILD_DIR?=build/

.PHONY: all clean

all: boot

boot: $(BUILD_DIR)/boot.bin

$(BUILD_DIR)/boot.bin: boot.asm
	$(ASM) boot.asm -f bin -o $(BUILD_DIR)/boot.bin

clean:
	rm -f $(BUILD_DIR)/boot.bin
