# Makefile for LiteTest test runner (Linux/macOS)
# Copyright (c) 2026 paulsinclair51
# SPDX-License-Identifier: MIT
# For license details, see the LICENSE file in the root directory.

CC ?= clang
CFLAGS ?= -std=c11 -Wall -Wextra -Wno-clobbered -O2
CPPFLAGS ?= -Iinclude -D_POSIX_C_SOURCE=200809L

BUILD_DIR := build
TARGET := test_litetest

SOURCES := \
	litetest.c \
	test_litetest.c \
	test_orchestrator.c \
	test_guard1.c \
	test_guard2.c

VPATH := src tests

OBJECTS := $(addprefix $(BUILD_DIR)/,$(SOURCES:.c=.o))

all: $(TARGET)

# Build litetest.o (provides all API function bodies)

# Pattern rule for all .c -> build/*.o.

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# Link test_litetest executable.

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS)

run: $(TARGET)
	mkdir -p ./reports
	./$(TARGET) ./reports
	./$(TARGET) -i ./reports
	./$(TARGET) --help > ./reports/litetest_help.txt
	./$(TARGET) -h > ./reports/litetest_.txt

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: all run clean
