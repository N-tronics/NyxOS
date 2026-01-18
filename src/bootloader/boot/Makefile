PROJ_DIR?=.
ASM?=nasm
BUILD_DIR?=build/
override BUILD_DIR:=$(BUILD_DIR)/boot

ASMFLAGS?=-f bin

.PHONY: all clean

all: boot

boot: $(BUILD_DIR)/boot.bin

$(BUILD_DIR)/boot.bin: boot.asm always
	$(ASM) $(ASMFLAGS) -o $@ $<

always:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
