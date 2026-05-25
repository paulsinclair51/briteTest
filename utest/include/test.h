/**
 * @file test.h
 * 
 * @brief Shared test infrastructure: result type, TEST macro,
 *        and RUN macro.
 *
 * This header is included by test modules (e.g., test_count.c and test_skip.c) and
 * the test orchestrator (e.g., test_lubtype.c) for a test suite to
 * provide shared infrastructure for testing:
 * 
 * - `result_t` counters.
 * 
 * - A reusable signal-guard mechanism based on sigsetjmp/siglongjmp
 *   used for testing an assertion expression or running a function.
 * 
 * - `TEST(assert_expr)` with fault recovery.
 * 
 * - `RUN(func, inject)` with fault recovery.
 * 
 * - Helper functions for the test orchestrator (e.g., PATH parsing,
 *   open/close reports).
 * 
 * This header requires POSIX.1-2008 for signal handling and sigsetjmp/siglongjmp.
 * 
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref ../LICENSE "LICENSE" in the
 * paulsinclair51/lubtype repository root.
 */

#if !defined(TEST_H)
#define TEST_H

#endif // !defined(TEST_H)

// End of test.h
