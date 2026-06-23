/**
 * @file test_runner.c
 *
 * @brief Test the Runner Framework and the Runner API (e.g., RA_OPEN_REPORT,
 *        RA_GROUP, RA_WRITE_RESULT).
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see `LICENSE` in the repository root.
 */

#include "runnerapi.h"

// Forward declarations of test groups.

RA_DECLARE_GROUP(orchestrator_tests);
RA_DECLARE_GROUP(guard1_tests);
RA_DECLARE_GROUP(guard2_tests);
RA_DECLARE_GROUP(file_compare_tests);

RA_DECLARE_ORCHESTRATOR(main)
{ 
  RA_INIT_ORCHESTRATOR(main, Runner, 1);
  
  RA_PARSE_ARGS(2, "");

  RA_OPEN_REPORT("");
 
  RA_WRITE_RESULT(RA_GROUP(orchestrator_tests, 0), "Orchestrator");

  RA_WRITE_RESULT(RA_GROUP(guard1_tests, 0), "Guard 1");
  RA_WRITE_RESULT(RA_GROUP(guard2_tests, 0), "Guard 2");
  
  RA_WRITE_RESULT(RA_GROUP(file_compare_tests, 0), "File Compare");

  RA_CLOSE_REPORT;

  RA_EXIT;
}
