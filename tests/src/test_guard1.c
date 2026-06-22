/**
 * @file paulsinclair51/BriteTest/tests/guard1_tests.c
 *
 * @brief Part 1 of test guard related functions and macros declared
 *        in /paulsinclair51/BriteTest/include/britetest_runner.h (e.g.,
 *        BT_ASSERT, BT_ASSERT_FAIL).
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/BriteTest GitHub repository.
 */

#include "britetest_runner.h"

BT_DECLARE_TEST(test_guard1)
{ 
  BT_INIT_TEST(test_guard1, 1);
 
  BT_ASSERT(!strcmp("dummy", "dummy"), 0);
  BT_ASSERT_FAIL(0);
  BT_ASSERT(!strcmp("dummy", "dummy"), 0);
  BT_ASSERT_FAIL(0);
  BT_ASSERT(!strcmp("dummy", "dummy"), 0);

  BT_RETURN;
}
