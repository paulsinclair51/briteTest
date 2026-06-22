/**
 * @file /paulsinclair51/BriteTest/tests/test_orchestrator.c
 *
 * @brief Test orchestrator related functions and macros declared
 *        in /paulsinclair51/BriteTest/include/britetest_runner.h (e.g., 
 *        BT_INIT_ORCHESTRATOR, BT_EXIT).
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/BriteTest GitHub repository.
 */

#include "britetest_runner.h"

BT_DECLARE_TEST(test_orchestrator)
{ 
  BT_INIT_TEST(test_orchestrator, 1);
 
  BT_ASSERT(!strcmp("dummy", "dummy"), 0);
  BT_ASSERT_FAIL(0);
  BT_ASSERT(!strcmp("dummy", "dummy"), 0);
  BT_ASSERT_FAULT(0);
  BT_ASSERT(!strcmp("dummy", "dummy"), 0);

  BT_RETURN;
}
