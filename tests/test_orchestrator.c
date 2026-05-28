/**
 * @file /paulsinclair51/LiteTest/tests/test_orchestrator.c
 *
 * @brief Test orchestrtor related functions and macros declared in
 *        /paulsinclair51/LiteTest/include/litetests.h (e.g., TESTS, TEST2).
 *
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest GitHub repository.
 */

#define TEST_MODULE test_orchestrator
#include "litetest.h"

DECLARE_FUNC(test_orchestrator)
{ 
  LT_INIT_TEST;
 
  LT_ASSERT(!strcmp("dummy" == "dummy");
  LT_ASSERT_FAIL;
  LT_ASSERT(!strcmp("dummy" == "dummy");
  LT_ASSERT_FAULT;
  LT_ASSERT(!strcmp("dummy" == "dummy");

  LT_RETURN_RESULT;
}
