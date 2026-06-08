/**
 * @file paulsinclair51/LiteTest/tests/test_litetest.c
 *
 * @brief Test the LiteTest API and framework declared in
 *        /paulsinclair51/LiteTest/include/litetest.h (e.g.,
 *        LT_OPEN_REPORT, LT_TEST, LT_WRITE_RESULT).
 *
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest GitHub repository.
 */

#include "litetest.h"

LT_DECLARE_ORCHESTRATOR(main)
{ 
  LT_INIT_ORCHESTRATOR(main, LiteTest, 1);
  
  LT_PARSE_ARGS(2, "");

  LT_OPEN_REPORT("");
 
  LT_WRITE_RESULT(LT_TEST(test_orchestrator, 0), "Orchestrator");

  LT_TEST(test_guard1, 0);
  LT_WRITE_RESULT(LT_TEST(test_guard2, 0), "Guard 1 and 2");

  LT_CLOSE_REPORT;

  LT_EXIT;
}
