/**
 * @file paulsinclair51/LiteTest/tests/guard1_tests.c
 
 * @brief Test guard related functions and macros declared in
          /paulsinclair51/LiteTest/include/litetest.h (e.g.,
          LT_TEST, LT_ASSERT).
 *
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest GitHub repository.
 */

#define TEST_MODULE guard1_tests
#include "litetest.h"

DECLARE_FUNC(guard1_tests)
{ 
  LT_INIT_TEST;
 
  LT_ASSERT(!strcmp("dummy" == "dummy");
  LT_ASSERT_FAIL;
  LT_TEST(!strcmp("dummy" == "dummy");
  LT_ASSERT_FAIL;
  LT_ASSERT(!strcmp("dummy" == "dummy");

  LT_RETURN_RESULT;

}
