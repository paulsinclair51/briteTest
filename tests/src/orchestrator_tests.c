/**
 * @file orchestrator_tests.c
 *
 * @brief Test orchestrator related functions and macros in the
 *        Runner API (e.g., RA_INIT_ORCHESTRATOR, RA_EXIT).
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see `LICENSE` in the repository root.
 */

#include "runnerapi.h"

RA_DECLARE_GROUP(orchestrator_tests)
{ 
  RA_INIT_GROUP(orchestrator_tests, 1);
 
  RA_TEST(!strcmp("dummy", "dummy"), 0);
  RA_TEST(RA_FAIL_EXPR, 0);
  RA_TEST(!strcmp("dummy", "dummy"), 0);
  RA_TEST(RA_FAULT(1), 0);
  RA_TEST(!strcmp("dummy", "dummy"), 0);

  RA_RETURN;
}
