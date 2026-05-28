/**
 * @file paulsinclair51/LiteTest/tests/test_litetest.c
 
 * @brief Test guard related functions and macros declared in
          /paulsinclair51/LiteTest/include/litetest.h (e.g., TEST, TESTS).
 *
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest GitHub repository.
 */

#define TEST_ORCHESTRATOR test_litetest
#include "litetest.h"

LT_DECLARE_MAIN
{ 
  LT_PARSE_ARGS;
  
  LT_OPEN_REPORT("LiteTest");
 
  LT_WRITE_RESULTS(TEST(test_orchestrator), "Orchestrator");
  LT_TEST(test_guards1);
  LT_WRITE_RESULTS((TEST(test_guards2), "Guards 1 and 2");

  LT_CLOSE_REPORT;

  LT_RETURN_STATUS;
}
