PROJ_DIR?=.
ASM?=nasm
BUILD_DIR?=build
override BUILD_DIR:=$(BUILD_DIR)/stdlib
CC16?=$(PROJ_DIR)/tools/bin/wcc
LD16?=$(PROJ_DIR)/tools/bin/wlink
LIBM?=$(PROJ_DIR)/tools/bin/wlib
CFLAGS16?=-4 -d3 -s -wx -ms -zl -zq
ASMFLAGS?=-f obj

SRCS_C=$(wildcard *.c)
SRCS_ASM=$(wildcard *.asm)
OBJS_C=$(patsubst %.c, $(BUILD_DIR)/c/%.obj, $(SRCS_C))
OBJS_ASM=$(patsubst %.asm, $(BUILD_DIR)/asm/%.obj, $(SRCS_ASM))

.PHONY: all stdlib always clean 

all: stdlib

stdlib: $(BUILD_DIR)/stdlib.lib

$(BUILD_DIR)/stdlib.lib: $(OBJS_C) $(OBJS_ASM) 
	$(LIBM) $@ $(addprefix +, $(OBJS_C)) $(addprefix +, $(OBJS_ASM))

$(BUILD_DIR)/c/%.obj: %.c always
	$(CC16) $(CFLAGS16) -fo=$@ $<

$(BUILD_DIR)/asm/%.obj: %.asm always
	$(ASM) $(ASMFLAGS) -o $@ $<

always:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/c
	mkdir -p $(BUILD_DIR)/asm

clean:
	rm -rf $(BUILD_DIR)/
