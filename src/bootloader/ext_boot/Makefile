ASM?=nasm
BUILD_DIR?=build/

.PHONY: all clean

all: ext_boot

ext_boot: $(BUILD_DIR)/ext_boot.bin

$(BUILD_DIR)/ext_boot.bin: ext_boot.asm
	$(ASM) ext_boot.asm -f bin -o $(BUILD_DIR)/ext_boot.bin

clean:
	rm -f $(BUILD_DIR)/ext_boot.bin
