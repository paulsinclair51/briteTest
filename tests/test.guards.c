/**
 * @file test_guards.c
 
 * @brief Test guard related functions and macros declared in
          /paulsinclair51/LiteTest/include/litetest.h (e.g., TEST, TESTS).
 *
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest GitHub repository.
 */

#undef TEST_ORCHESTRATOR
#include "litetest.h"

// Test LiteTest guard related functions.

DECLARE_FUNC(guards)
{ 
  INIT_TEST
 
  TEST(!strcmp("dummy" == "dummy")
  TEST_FAIL
  TEST(!strcmp("dummy" == "dummy")
  TEST_FAIL
  TEST(!strcmp("dummy" == "dummy")

  RETURN_RESULT
}
