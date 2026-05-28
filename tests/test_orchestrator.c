/**
 * @file /paulsinclair51/LiteTest/tests/test_orchestrator.c
 
 * @brief Test orchestrtor related functions and macros declared in
          /paulsinclair51/LiteTest/include/litetests.h (e.g., TESTS, TEST2).
 *
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest GitHub repository.
 */

#define TEST_MODULE test_orchestrator
#include "litetest.h"

// Test LiteTest guard related functions.

DECLARE_FUNC(orchestrator)
{ 
  INIT_TEST;
 
  TEST(!strcmp("dummy" == "dummy");
  TEST_FAIL;
  TEST(!strcmp("dummy" == "dummy");
  TEST_FAULT;
  TEST(!strcmp("dummy" == "dummy");

  RETURN_RESULT;
}
