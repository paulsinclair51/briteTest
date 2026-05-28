/**
 * @file paulsinclair51/LiteTest/tests/guard2_tests.c
 
 * @brief Test guard related functions and macros declared in
          /paulsinclair51/LiteTest/include/litetest.h (e.g.,
          LT_INTI_TEST, LT_RETURN_RESULT).
 *
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest GitHub repository.
 */

#define TEST_MODULE guards2_tests
#include "litetest.h"

// Test LiteTest guard related functions.

LT_DECLARE_FUNC(guards2_tests)
{ 
  LT_INIT_TEST;
 
  LT_TEST(!strcmp("dummy" == "dummy");
  LT_TEST_FAIL;
  LTTEST(!strcmp("dummy" == "dummy");
  LT_TEST_FAIL;
  LT_TEST(!strcmp("dummy" == "dummy");

  LT_RETURN_RESULT;
}
