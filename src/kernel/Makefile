PROJ_DIR?=.
ASM?=nasm
BUILD_DIR?=build/
override BUILD_DIR:=$(BUILD_DIR)/kernel/

ASMFLAGS?=-f bin

.PHONY: all clean

all: kernel

kernel: $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: kernel.asm always
	$(ASM) $(ASMFLAGS) -o $@ $<

always:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
