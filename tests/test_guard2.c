/**
 * @file paulsinclair51/LiteTest/tests/guard2_tests.c
 *
 * @brief Part 2 of test guard related functions and macros declared
 *        in /paulsinclair51/LiteTest/include/litetest_runner.h (e.g.,
 *        LT_INiT_TEST, LT_RETURN).
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest GitHub repository.
 */

#include "litetest_runner.h"

LT_DECLARE_TEST(test_guard2)
{ 
  LT_INIT_TEST(test_guard2, 1);
 
  LT_ASSERT(!strcmp("dummy", "dummy"), 0);
  LT_ASSERT_FAIL(0);
  LT_ASSERT(!strcmp("dummy", "dummy"), 0);
  LT_ASSERT_FAIL(0);
  LT_ASSERT(!strcmp("dummy", "dummy"), 0);

  LT_RETURN;
}
