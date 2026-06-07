/**
 * @file /paulsinclair51/LiteTest/tests/test_orchestrator.c
 *
 * @brief Test orchestrator related functions and macros declared
 *        in /paulsinclair51/LiteTest/include/litetest.h (e.g., 
 *        LT_INIT_ORCHESTRATOR, LT_EXIT).
 *
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest GitHub repository.
 */

#include "litetest.h"

LT_DECLARE_TEST(test_orchestrator)
{ 
  LT_INIT_TEST(test_orchestrator, 1);
 
  LT_ASSERT(!strcmp("dummy", "dummy"));
  LT_ASSERT_FAIL;
  LT_ASSERT(!strcmp("dummy", "dummy"));
  LT_ASSERT_FAULT;
  LT_ASSERT(!strcmp("dummy", "dummy"));

  LT_RETURN;
}
