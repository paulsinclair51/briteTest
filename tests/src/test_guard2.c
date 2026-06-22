/**
 * @file paulsinclair51/BriteTest/tests/guard2_tests.c
 *
 * @brief Part 2 of test guard related functions and macros declared
 *        in /paulsinclair51/BriteTest/include/britetest_runner.h (e.g.,
 *        BT_INiT_TEST, BT_RETURN).
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/BriteTest GitHub repository.
 */

#include "britetest_runner.h"

BT_DECLARE_TEST(test_guard2)
{ 
  BT_INIT_TEST(test_guard2, 1);
 
  BT_ASSERT(!strcmp("dummy", "dummy"), 0);
  BT_ASSERT_FAIL(0);
  BT_ASSERT(!strcmp("dummy", "dummy"), 0);
  BT_ASSERT_FAIL(0);
  BT_ASSERT(!strcmp("dummy", "dummy"), 0);

  BT_RETURN;
}
