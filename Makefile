#-----------------------------------------------------------------
# Makefile for test_britetest (Linux/macOS)
#
# test_britetest is an executable that uses the briteTest
# Runner Framework/API to test itself.
#
#-----------------------------------------------------------------
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see the LICENSE file in the root directory.
#-----------------------------------------------------------------
#
# test_britetest can be run by submitting a command line of the
# following form to a shell:
#
#   [<directory_path>/]test_britetest [<option>],,, [<arg>]...
#
# For usage information about the options and args, submit the
# follpwing to a shell:
#
#   [<directory_path>/]test_britetest --help
#
# For an introduction to briteTest, see README.md in the root directory.
#-----------------------------------------------------------------

CC ?= clang
CFLAGS ?= -std=c11 -Wall -Wextra -Wno-clobbered -O2
CPPFLAGS ?= -Iinclude -D_POSIX_C_SOURCE=200809L

BUILD_DIR := build
TARGET := test_britetest

SOURCES := \
	runnerapi.c \
	testapi.c \
	test_runner.c \
	orchestrator_tests.c \
	file_compare_tests.c \
	guard1_tests.c \
	guard2_tests.c

VPATH := src tests/src

OBJECTS := $(addprefix $(BUILD_DIR)/,$(SOURCES:.c=.o))

all: $(TARGET)

# Build britetest.o (provides all API function bodies)

# Pattern rule for all .c -> build/*.o.

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# Link test_britetest executable.

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS)

#run the tests.
test: test_britetest
	./test_britetest

run: $(TARGET)
	mkdir -p ./reports
	./$(TARGET) ./reports
	./$(TARGET) -i ./reports
	./$(TARGET) --help > ./reports/britetest_help.txt
	./$(TARGET) -h > ./reports/britetest_.txt

lint-md:
	@find . -type f -name '*.md' ! -path './.git/*' -print0 | \
		xargs -0 npx -y markdownlint-cli --config config/markdownlint.json

check-doc:
	bash ./briteRepo/bin/report style -m -r

test-gendocs:
	bash ./briteRepo/tests/test_gendocs.sh

test-fixlocal:
	bash ./briteRepo/tests/test_fixlocal.sh

test-fixremote:
	bash ./briteRepo/tests/test_fixremote.sh

test-lsbranch:
	bash ./briteRepo/tests/test_lsbranch.sh

test-mkbranch:
	bash ./briteRepo/tests/test_mkbranch.sh

test-pulldown:
	bash ./briteRepo/tests/test_pulldown.sh

test-pushup:
	bash ./briteRepo/tests/test_pushup.sh

test-pushup-parent:
	bash ./briteRepo/tests/test_pushup_parent.sh

test-restore:
	bash ./briteRepo/tests/test_restore.sh

test-report-helpers:
	bash ./briteRepo/tests/test_report_helpers.sh

test-report-style:
	bash ./briteRepo/tests/test_report_style.sh

test-genpngs:
	bash ./briteRepo/tests/test_genpngs.sh

test-all-scripts:
	bash ./briteRepo/tests/test_scripts.sh

gendocs:
	bash ./briteRepo/bin/gendocs

genpngs:
	bash ./briteRepo/bin/genpngs

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: all run lint-md check-doc test-gendocs test-fixlocal test-fixremote test-lsbranch test-mkbranch test-pulldown test-pushup test-pushup-parent test-report-helpers test-report-style test-genpngs test-all-scripts gendocs genpngs clean
