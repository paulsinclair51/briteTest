/**
 * @file guard1_tests.c
 *
 * @brief Part 1 of test guard related functions and macros in the
 *        Runner API (e.g., RA_TEST).
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see `LICENSE` in the repository root.
 */

#include "runnerapi.h"

RA_DECLARE_GROUP(guard1_tests)
{ 
  RA_INIT_GROUP(guard1_tests, 1);
 
  RA_TEST(!strcmp("dummy", "dummy"), 0);
  RA_TEST(RA_FAIL_EXPR, 0);
  RA_TEST(!strcmp("dummy", "dummy"), 0);
  RA_TEST(RA_FAIL_EXPR, 0);
  RA_TEST(!strcmp("dummy", "dummy"), 0);

  RA_RETURN;
}
