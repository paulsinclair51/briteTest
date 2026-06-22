/**
 * @file paulsinclair51/BriteTest/tests/test_britetest.c
 *
 * @brief Test the BriteTest API and framework declared in
 *        /paulsinclair51/BriteTest/include/britetest_runner.h (e.g.,
 *        BT_OPEN_REPORT, BT_TEST, BT_WRITE_RESULT).
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/BriteTest GitHub repository.
 */

#include "britetest_runner.h"

BT_DECLARE_ORCHESTRATOR(main)
{ 
  BT_INIT_ORCHESTRATOR(main, BriteTest, 1);
  
  BT_PARSE_ARGS(2, "");

  BT_OPEN_REPORT("");
 
  BT_WRITE_RESULT(BT_TEST(test_orchestrator, 0), "Orchestrator");

  BT_TEST(test_guard1, 0);
  BT_WRITE_RESULT(BT_TEST(test_guard2, 0), "Guard 1 and 2");
  BT_WRITE_RESULT(BT_TEST(test_file_compare_helpers, 0), "File Compare Helpers");

  BT_CLOSE_REPORT;

  BT_EXIT;
}
