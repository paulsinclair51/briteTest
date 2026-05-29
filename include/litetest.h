/**
 * @file /paulsinclair51/include/litetest.h
 * 
 * @brief LiteTest is a reusable, portable, robust, and lightweight
 * test API and framework.
 *
 * This header is included by test modules and a test orchestrator for
 * testing, e.g., a feature, API, or a project implementation. It provides
 * declarations, definitions (other than non-inline fumction definition), and the
 * definitve Doxygen documentation for LiteTest (see README.md in the
 * root directory for an overview of LiteTest).
 *
 * In the following, testing the LiteTest itself is used as an example of
 * using the LiteTest API and framework with test modules test_guards_1.c,
 * test_guards_2.c, and test_orchestrator.c, and test orchestrator
 * test_litetest.c in the repository tests directory.
 * 
 * The LiteTest API includes:
 * 
 * 1. Domain-specific test macros with a multi-level signal-guard mechanism
 *    based on sigsetjmp/siglongjmp to capture faults:
 *    - `LT_ASSERT(assert_expr)`
 *    - `LT_TEST(func)`
 *    - `LT_ASSERT_FAIL`
 *    - `LT_ASSERT_FAULT`
 *
 * 2. Domain-specific reporting macros (for use in test orchestrator):
 *    - `OPEN_REPORT`
 *    - `CLOSE_REPORT`
 *    - `WRITE_RESULT`
 *
 * 3. Miscellanous functions, macros, typedefs, and variables with names prefixed
 *    with lt_* or  LT_*; see @ref NamingConventions). For example, lt_executablename,
 *    lt_result_t, lt_dirpath, lt_path_usage, and LT_MAX_PATH_LEN.
 * 
 * This header requires POSIX.1-2008 for signal handling and sigsetjmp/siglongjmp.
 * 
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * See @ref ../LICENSE "LICENSE" in the
 * repository root for details.
 */

/**
 * @section HeaderUsage Header Usage
 * 
 * In the test orchestrator source file (e.g., test_litetest.c),
 * include the following:
 *
 * @code
#include "litetest.h"
 * @endcode
 *
 * Use the orchestrator macros, variables and functions in the test orchestrator
 * logic plus the TESTS[MREGE[n]] macros to execute test modules.
 * 
 * In the test* modules (e.g., test_guards_1.c, test_guards_2.c, and
 * test_orchestrator.c):
 *
 * @code
 #undef LT_ORCHESTRATOR
 #include "litetest.h"
 * @endcode
 *
 * Use the TEST, TEST_FAIL, and TEST_FAULT macros in the test modules to
 * execute a test.
 *
 * @note Other veriations are possible. e.g., using the other test macros
 *       in the test orchestrator and test modules.
 */

/**
 * @section BuildTestExecutable Build the test executable
 * 
 * - Linux/macOS: make
 * 
 *   Defaults to use Makefile in the current directory.
 * 
 * - Windows PowerShell: .\build_test_lubtype.ps1
 */
 
/**
 * @section NameConventions Naming Conventions
 *
 * LiteTest uses the following naming conventions:
 *
 * File naming: litetest.h and litetest.c (lowercase for portability).
 * 
 * Public API:
 *
 * 1. lt_* - Public functions, typedefs, and variables.
 * 2. LT_* - Public macros, constants, and enum values.
 * 
 * Internal and private to the API:
 *
 * 1. Internal functions, typedefs, and variables: litetest_*
 * 2. Internal macros, constants, and enum values: LITETEST_*
 *
 * These conventions are designed to provide a clean public API, strong
 * namespace isolation, and predictable behavior when LiteTest is embedded
 * into a larger C/C++ project.
 *
 * @example Public API Names
 * 1. Utility macros: LT_TOK_PASTE, LT_TOK_STR, LT_RESULT, LT_TOTAL
 *    LT_STATIC_ASSERT
 * 2. Version macros: LT_VERSION, LT_VERSION_EQ, LT_VERSION_AT_LEAST
 * 4. Uitlity functions: lt_current_guard_level.
 *
 * @example Public typedef Name
 * lt_result_t
 *
 * @example Private Variable Names
 * litetest_result, litetest_total
 */

/**
 *
 * @section FaultGuarding Fault Guarding
 *
 * The test framework uses a multi-level fault (up to 32 levels)
 * guarding approach to catch unexpected termination due to a
 * fault (i.e., segmentation fault, bus error, or abort) during
 * test execution.
 * 
 * A test macro wraps a guard around its argument, enabling
 * detection of a fault not handled at a lower level  by the
 * argument rather than aborting. This allows counting pass,
 * fail, and fault without aborting due to a fault.
 * 
 * A fault detected by LT_TEST represents a fault
 * in the use of the testing framework or in the testing framework
 * itself, and not in the feature being tested. Such a fault is
 * expected to be rare but guarding avoids an abort trminating
 * execution.
 */

#pragma once

/* Enable POSIX.1-2008 (sigaction, sigsetjmp, siglongjmp, sigjmp_buf). */
#if !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L
#endif

#include <stdlib.h>
#include <ctype.h>
#include <limits.h>
#include <setjmp.h>
#include <signal.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

// Allow functions to be invoked from C++.
#if defined(__cplusplus)
extern "C" {
#endif

/**
 * @section UtilityMacros Utility Macros
 */

#if defined(LT_TOK_PASTE) || defined(LITETEST_TOK_PASTE_INTRRNAL)
#error "litetest.h: A LT_TOK_PASTE or LITETEST_TOK_PASTE_INTRRNAL " \
       "macro is unexpectedly already defined. " \
       "#undef before including litetest.h."
#endif // defined macros

#if defined(LT_TOK_STR) || defined(LITETEST_TOK_STR_INTERNAL)
#error "litetest.h: A LT_TOK_STR or LITETEST_TOK_STR_INTERNAL " \
       "macro is unexpectedly already defined. " \
       "#undef before including litetest.h."
#endif // defined macros

#if defined(LT_STATIC_ASSERT))
#error "litetest.h: An LT_STATIC_ASSERT " \
       "macro is unexpectedly already defined. " \
       "#undef before including litetest.h."
#endif // defined macro

/*
 * @defgroup TokenPaste Token Paste
 *
 * @name LT_TOK_PASTE
 *
 * @brief Macro for pasting two expanded tokens together.
 *
 * @param t1 First token, 
 * @param t2 Second token.
 *
 * @return The result of pasting the expanded values of the
 *         two tokens together to form a single token.
 * 
 * @note Tokens a and b must each expand to a single token.
 * 
 * @note Macro LITETEST_TOK_PASTE is defined to implement expanding
 *       the tokens for LT_TOK_PASTE. It is not intended for direct use.
 * 
 * @note A preprocessor error is raised if either of these macros
 *       are already defined before including this header.
 * @{
 */

// Paste tokens without expanding.
#define LITETEST_TOK_PASTE(t1, t2) a##b
// Expand tokens before pasting.
#define LT_TOK_PASTE(t1, t2) LITETEST_TOK_PASTE(t1, t2)

/** @} */

/**
 * @defgroup TokenStringify Token Stringify
 *
 * @name LT_TOK_STR
 *
 * @brief Macro for stringifying an expanded token.
 *
 * @param t Token.
 *
 * @return The result of stringifying the expanded value of
 *         token t as a string literal.
 * 
 * @note Token s must expand to a single token.
 * 
 * @note Macro LITETEST_TOK_STR is defined to implement expanding
 *       the token for TOK_STR. It is not intended for direct use.
 * 
 * @note A preprocessor error is raised if either of these macros
 *       are already defined before including this header.
 * @{
 */

// Stringify token without expanding.
#define LITETEST_TOK_STR(t) #s
// Expand token before stringifying.
#define LT_TOK_STR(t) LITETEST_TOK_STR(t)

/** @} */

/**
 * @name LT_STATIC_ASSERT
 *
 * @brief Compile-time (static) assertion macro.
 *
 * @param cond Condition to be asserted.
 * @param msg A single token (message) to be displayed if
 *            the assertion fails.
 *
 * @return Compiler error if the assertion fails. Otherwise,
 *         a type is defined which can be ignored and a compiler
 *         error is not raised.
 *
 * @note A preprocessor error is raised if this macro is already
 *       defined before including this header.
 * 
 * @example Static Assert Example
 * @code
LT_STATIC_ASSERT(sizeof(int) == 4, int_must_be_4_bytes);
 * @endcode
 * For C99, if assertion is true (and the type is not already defined), expands to:
 * @code
typedef char LT_STATIC_ASSERT_int_must_be_4_bytes[1];
 * @endocde
 * And the type is defined (which can be ignored).
 *
 * Or if false, expands to:
 * @code
typedef char LT_STATIC_ASSERT_int_must_be_4_bytes[-1];
 * @endcode
 *  Compiler error raised due to typedef statement with an
 *  invalid array bound -1.
 */

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
// C11 and later: use the built‑in assertion macro.
#define LT_STATIC_ASSERT(cond, msg) _Static_assert(cond, #msg)
#else
// C99: typedef with invalid negative array size if assertion not satisfied.
#define LT_STATIC_ASSERT(cond, msg) \
    typedef char LT_TOK_PASTE(LT_STATIC_ASSERT_, msg)[(cond) ? 1 : -1]
#endif

/**
 * @section VersionMacros LiteTest Version Macros
 */

/**
 * @defgroup LiteTestVersionMacros LiteTest Version Macros
 *
 * @name LT_VERSION_MAJOR, LT_VERSION_MINOR, LT_VERSION_PATCH,
 *       LT_VERSION, LT_VERSION_NUM, LT_VERSION_HEX, 
 *       LT_VERSION_EQ, LT_VERSION_AT_LEAST
 *
 * @brief Version macros for LiteTest (litetest.h and litetest.c):
 *
 * Increment LT_VERSION_MAJOR for incompatible API changes.
 * Increment LT_VERSION_MINOR for backward-compatible additions.
 * Increment LT_VERSION_PATCH for bug fixes or internal improvements.
 * Do not modify the other version macros.
 *
 * Incompatible API changes: The naming conventions, error semantics, and safety guarantees
 * are part of the documented and stable API and will not change without a
 * major version increment.
 * 
 * The following version macros are provided:
 *
 * LT_VERSION_MAJOR
 *    Untyped numeric form, e.g., 1 for major version 1.
 * 
 * LT_VERSION_MINOR
 *    Untyped numeric form, e.g., 0 for minor version 0,
 *    or 22 for minor version 22.
 * 
 * LT_VERSION_PATCH
 *    Untyped umeric form, e.g., 0 for patch version 0,
 *    or 12 for patch version 12.
 * 
 * LT_VERSION
 *    String form, e.g., "1.0.0".
 * 
 * LT_VERSION_NUM
 *    uint32_t form MMmmpp for comparisons, e.g., 10000 for
 *    version 1.0.0, 10200 for version 1.2.0, or 11212 for version 1.12.12.
 * 
 * LT_VERSION_HEX
 *    Hexadecimal form 0xMMmmpp for display/debugging, e.g.,
 *    0x010000 for version 1.0.0, 0x010200 for version 1.2.0,
 *    or 0x011212 for version 1.12.12.
 * 
 * LT_VERSION_EQ(maj, min, pat)
 *    True if current version is exactly maj.min.pat
 *
 * LT_VERSION_AT_LEAST(maj, min, pat)
 *    True if current version is at least maj.min.pat.
 *
 * @note A compiler error is raised if any of the version macros
 *       are already defined before including litetest.h.
 * @{
 */

#if defined(LT_VERSION_MAJOR) || defined(LT_VERSION_MINOR) || \
    defined(LT_VERSION_PATCH) || \
    defined(LT_VERSION) || \
    defined(LT_VERSION_NUM) || defined(LT_VERSION_HEX) || \
    defined(LT_VERSION_EQ) || defined(LT_VERSION_AT_LEAST)
#error "lubtype.h: A LT_VERSION_* macro is unexpectedly " \
       "already defined. #undef before including lubtype.h."
#endif // defined macros

// Define current LiteTest version major, minor, patch.
// Increment major version for incompatible API changes.
// Increment minor version for backward-compatible additions.
// Increment patch version for bug fixes or internal improvements.
 
#define LT_VERSION_MAJOR 1
#define LT_VERSION_MINOR 0
#define LT_VERSION_PATCH 0

// Ensure major version is greater than 0.

LT_STATIC_ASSERT((uint32_t)LT_VERSION_MAJOR, major_version_not_zero);

// Ensure version components fit in the encoding fields.

LT_STATIC_ASSERT((uint32_t)LT_VERSION_MAJOR <= 99, major_fits_in_field);
LT_STATIC_ASSERT((uint32_t)LT_VERSION_MINOR <= 99, minor_fits_in_field);
LT_STATIC_ASSERT((uint32_t)LT_VERSION_PATCH <= 99, patch_fits_in_field);

// LiteTest version string in "major.minor.patch" format.

#define LT_VERSION \
  (LT_TOK_STR(LT_VERSION_MAJOR) "." \
   LT_TOK_STR(LT_VERSION_MINOR) "." \
   LT_TOK_STR(LT_VERSION_PATCH))

// LiteTest version as an integer for comparisons.

#define LT_VERSION_NUM \
    ((uint32_t)LT_VERSION_MAJOR * 10000 + \
     (uint32_t)LT_VERSION_MINOR * 100 + \
     (uint32_t)LT_VERSION_PATCH)

// LiteTest version encoded as 0xMMmmpp (major, minor, patch) for display/debug.

#define LT_VERSION_HEX \
    (((uint32_t)LT_VERSION_MAJOR << 16) | \
     ((uint32_t)LT_VERSION_MINOR << 8) | \
     (uint32_t)LT_VERSION_PATCH)

// LiteTest version is the specified version (1 if true, otherwie 0).
#define LT_VERSION_EQ(maj, min, pat) \
    ((LT_VERSION_NUM == (uint32_t)(maj) * 10000 + \
                             (uint32_t)(min) * 100 + \
                             (uint32_t)(pat)) ? 1 : 0)

// LiteTest version is at least the specified version (1 if true, otherwise 0).
#define LT_VERSION_AT_LEAST(maj, min, pat) \
    ((LT_VERSION_NUM >=  (uint32_t)(maj) * 10000 + \
                         (uint32_t)(min) * 100 + \
                         (uint32_t)(pat)) ? 1 : 0)

/** @} */ // End of Version Macros.

/**
 * @section Limits
 */

/**
 * @name LT_MAX_PATH_LEN, LT_MAX_FILENAME_LEN, LT_MAX_GUARD_LEVEL
 * 
 * @brief Maximum values for path length, filename length,
 *        and guard levels.
 *
 * @note The limit of 32 guaard levels in unlikely to be ever
 *       eceeded if there are 2 or more tests at each level.
 *       It is expected that a level will generally have 2 or
 *       more tests per level.
 */

#define LT_MAX_PATH_LEN ((size_T)4096)
#define LT_MAX_FILENAME_LEN  ((size_T)255)
#define LT_MAX_GUARD_LEVEL ((size_T)32)

/**
 * @section result_t Result Type
 */

/**
 * @name lt_result_t
 * @brief Type for result counters returned by a test function and for
 *        accumulating results across multiple test functions.
 * 
 * @note A test function with a fault returns a result with the fault count
 *       set to SIZE_MAX to indicate a function-level fault.
 */

typedef struct
{ size_t pass;
  size_t fail;
  size_t fault;
  size_t injected_fail;
  size_t injected_fault;
} lt_result_t;

/**
 * @section Guard Infrastructure
 * 
 * The guard infrastructure provides a mechanism to catch signals such as SIGSEGV,
 * SIGABRT, and SIGBUS that may occur during the evaluation of TEST* macros
 * It uses sigsetjmp and siglongjmp to return control
 * to a known point in the code when a signal is caught, allowing the test framework
 * to count faults and continue running other tests instead of aborting the entire
 * test suite.
 * 
 * Type, function, and static variable names are prefixed with  "litetest_".
 * 
 * The guard infrastructure is not intended to be used directly by test
 * modules or the test orchestrator, but is used by the TEST* macros.
 */

/**
 * @name litetest_sighandler_t
 * 
 * @brief Type for signal handlers used in the guard infrastructure.
 *
 * @details litetest_sighandler_t type is defined as a pointer to a function that takes
 * an int signal number as a parameter and returns void. This type is used for the
 * handler function pointer in the guard structure and for saving/restoring signal
 * handlers in the guard installation and restoration functions.
 * 
 * The litetest_sighandler_t type ensures that the guard mechanism can properly
 * manage signal handlers for SIGSEGV, SIGABRT, and SIGBUS.
 * 
 * The use of litetest_sighandler_t allows the guard mechanism to be flexible and compatible
 * with the signal handling conventions of this framework.
 */

typedef void (*litetest_sighandler_t)(int);

/**
 * @name litetest_guard_t
 * 
 * @brief Structure for a guard used to capture signals and manage
 *        state for fault recovery.
 */

typedef struct
{ void (*handler)(int sig);
  sigjmp_buf env;
  volatile sig_atomic_t active;
} litetest_guard_t;

/**
 * @name litetest_saved_guard_t
 * 
 * @brief Structure for saving the current guard when a guard 
 *        at a lower level is installed.
 */

typedef struct
{ litetest_guard_t *guard;
  litetest_sighandler_t segv_handler;
  litetest_sighandler_t abrt_handler;
  litetest_sighandler_t bus_handler;
} litetest_saved_guard_t;

/**
 * @name litetest_guard
 * 
 * @brief Pointer to the current guard used for signal handling
 *        and fault recovery.
 * 
 * @note Current guard is accessible internally by the guard
 *       infrastructure in the orchestrator and test modules.
 *       It is defined only in the orchestrator module.
 */

extern litetest_guard_t *litetest_guard;

/**
 * @name litetest_saved_guards, litetest_num_saved_guards
 * 
 * @brief Array of saved guards and the number of saved guards.
 * 
 * @note These are accessible internally by the guard infrastructure
 *       in the orchestrator and test modules. It is defined only
 *       in the orchestrator module.
 * @{
 */

extern litetest_saved_guard_t litetest_saved_guards[MAX_GUARD_LEVEL];
extern size_t litetest_num_saved_guards;

/** @} */

/**
 * @name litetest_guardhandler
 * 
 * @brief Captures signals and siglongjmps back to the guard point.
 * 
 * @param sig The signal number that was caught (e.g., SIGSEGV, SIGABRT, SIGBUS).
 * 
 * If sig is 0, uses 1 as the siglongjmp value to distinguish from a signal number.
 * 
 * If there is no active guard, aborts to indicate a fatal error or framework
 * misuse.
 * 
 * If guard is active, sets it to inactive and siglongjmps back to the guard point
 * with the signal number (or 1 if sig is 0) as the value.
 * 
 * Note: The guard handler is designed to be simple and signal-safe, and does not
 * perform any complex logic or I/O. It relies on the guard structure to manage state
 * and the testing framework to handle the results appropriately.
 */

static inline void litetest_guard_handler(int sig)
{ if (litetest_guard && litetest_guard->active)
  { litetest_guard->active = 0; siglongjmp(litetest_guard->env, sig ? sig : 1); }

  /* Fault outside of active guard or misuse of guard framework. */
  abort();
}

/**
 * @name litetest_install_guard
 * 
 * @brief Install a new guard and save the current guard.
 * 
 * @param new_guard Pointer to a new guard.
 * 
 * On error (too many nested guards or signal handler installation
 * failure), raises abort using abort() for POSIX/C behavior to
 * terminate the program without causing an infinite loop through
 * signal handling.
 */

void litetest_install_guard(litetest_guard_t *new_guard);

/**
 * @name litetest_restore_guard
 * 
 * @brief Restore the previous guard.
 * 
 * On error (no saved guard), raises abort using abort() for
 * POSIX/C behavior to terminate the program without causing
 * an infinite loop through signal handling.
 * 
 * @note This function restores the previous guard by checking if
 * there are any saved guards. If there are no saved guards, it raises a SIGABRT
 * to indicate a fatal error in the testing framework. If there is a saved guard,
 * it restores the signal handlers for SIGSEGV, SIGABRT, and SIGBUS to their
 * previous handlers and sets the current guard to the saved guard.
 * 
 * @note This function is designed to be called after a guard has
 * been used to ensure that the previous guard is properly restored.
 * 
 * @note The guard mechanism allows for nested guards, and the restore_guard_internal
 * function ensures that the correct guard is restored in a last-in-first-out manner.
 */

void litetest_restore_guard(void);

/**
 * @name litetest_result
 * 
 * @brief Internal static variable in which to save result by TEST
 *        and TESTS[_MERGE[n]] macros. Value used by TESTS_MERGE[n]
 *        macros to merge results and by WRITE_CATEOGORY_RESULTS.
 */

static lt_result_t litetest_result;

/**
 * @name litetest_total
 * 
 * @brief Internal static variable in which to total results by TEST
 *        and TESTS[_MERGE[n]]macros and sed by CLOSE_REPORT if
 *        variable is in orchestrator module.
 */

static lt_result_t litetst_totol;

 * @name litetest_tests
 * 
 * @brief Internal function used by the TESTS macro: runs func
 *        capturing a fault, if one occurs, with a guard.
 *        Saves the result internally and adds the result
 *        to the internal total.
 * 
 * @param func Pointer to the test function to run, which takes a
 *             char inject parameter and returns a lt_result_t.
 * @param merge Flag to indicate merge results.
 *              0: don't merge.
 *              1: merge.
 * @param inject Flag to pass to the test function.
 *                 0: normal run.
 *                 1: enable inject fail/fault tests, if any, in the function.
 * @param func_name Name of the function being run, used for error messages.
 * 
 * @return lt_result_t result from test function or
 *         (lt_result_t){0, 0, SIZE_MAX, 0, 0} if a fault occurs.
 */

lt_result_t litetest_tests
( lt_result_t (*func)(char),
  const char merge, const char inject,
  const char * const func_name );

/** @} */

/
 * @section GuardFunction GuardFunctions
 * 
 * The guard functions provide status about the guard mechanism, such as the 
 * current guard level and whether the current guard is active.
 */

/**
 * @name lt_current_guard_level
 * 
 * @brief Get the current guard level (number of nested guards).
 * 
 *        The guard level can be used for debugging, informational purposes to
 *        understand the depth of nested guards, or for checking against
 *        the maximum guard level (MAX_GUARD_LEVEL).
 * 
 * @return 0 if there are no installed guards.
 *         Otherwise, the current guard level, which is the number
 *         of nested guards currently installed.
 */

 static inline size_t lt_guard_level(void)
 { return internal_num_saved_guards + (internal_guard ? 1 : 0); }

/**
 * @name  lt_is_current_guard_active
 * @brief Check if the current guard is active.
 * 
 * @return 1 if the current guard is active
 *         0 if current guard is not active.
 *        -1 if there is no current guard.
 */

  static inline int lt_is_current_guard_active(void)
  { return litetest_guard ? litetest_guard->active : -1; }

/**
 * @section TEST Macros
 * 
 * The test macros (TEST, TRSTS, TESTS_MERGE[n], TEST_FAIL, and TEST_FAULT
 * provide a convenient interface for running tests with
 * built-in fault recovery using the multi-level guard infrastructure:
 * 
 * - Typically, the test orchestrator uses one of the TESTS[_MERGE[n]]
 *   macros to execute the test function in a test module. The TEST, TEST_FAIL,
 *   and TEST_FAULT macros may be used in the test orchestrator, but it is
 *   more common for test category modules to  use these macros.
 * 
 * - Typically, test modules use the TEST, TEST_FAIL, and TEST_FAULT macros.
 *   A test module may also use the TESTS[_MERGE[n]] macros for a test that
 *   can not reasonably be expressed as a single assertion, as a single
 *   assertion, such as a test that involves multiple steps, looping, or
 *   requires setup and teardown.
 */

/**
 * @name TESTS
 * 
 * @brief A macro to run a function with a guard.
 *
 * After saving the current guard, setting up a new current guard to capture a fault (SIGABRT, SIGSEGV,
 * or SIGBUS), calls the function pointed to by parameter func
 * with parameter inject. If a fault occurs this level, siglongjmps back to
 * the guard point, the result is saved and added to total. Then the saved
 * guard is set as the current guard.
 *
 * @param func Pointer to function.
 * @param inject Flag to pass to the function.
 *               0: normal run.
 *               1: enable inject fail/fault tests, if any, in the function.
 * 
 * @note If no signal, lt_result_t result from test function is used.
 *       If signal caught, (lt_result_t){0, 0, SIZE_MAX, 0, 0} is used.
 * 
 * @note If a fault is captured, a message is printed to stderr
 *       including the function name, file name, and line number
 *       for debugging purposes.
 * 
 * @note A fault is considered a fault in the testing framework or in the use of the
 *       testing framework, rather than a fault in the feature being tested. The use
 *       of SIZE_MAX for the fault count allows the macro to distinguish between
 *       a function-level fault and faults counted by the function itself.
 * 
 * @example In the orchestrator module (e,g., test_litetest.c) to
 *          run the test function in a test module (e.g., test_orchestrator.c):
 *
 * @code
 TESTS(test_arg_handlers, inject);
 * @endcode
 */

#define TESTS(func, inject) \
   { t_result_t func(char inject); \
     litetest_tests(func, 0, inject, #func); }

/**
 * @name TESTS_MERGE, TESTS_MERGE3, TESTS_MERGE4
 * 
 * @brief Macros to run two, three, or four functions each with a guard and
 * merge their results.
 *
 * After setting up a guard to capture a fault (SIGABRT, SIGSEGV,
 * or SIGBUS), calls the function pointed to by parameter func1
 * with parameter inject, calls the function pointed to by parameter
 * func2 and merges their results, etc. If a fault occurs for a call,
 * siglongjmps back to the guard point.
 *
 * @param func1 Pointer to function 1.
 * @param func2 Pointer to function 2.
 * @param func3 Pointer to function 3 (for TESTS_MERGE3 and TESTS_MERGE4).
 * @param func4 Pointer to function 4 (for TESTS_MERGE4).
 * @param inject Flag to pass to the function.
 *               0: normal run.
 *               1: enable inject fail/fault tests, if any, in the function.
 * 
 * @botr If no signal, the result from the test function is merged.
 *         If signal caught, (lt_result_t){0, 0, SIZE_MAX, 0, 0} is merged.
 * 
 * @note If a fault is captured, a message is printed to stderr
 *       including the function name, file name, and line number
 *       for debugging purposes.
 * 
 * @note A fault is considered a fault in the testing framework or in the use of the
 *       testing framework, rather than a fault in the feature being tested. The use
 *       of SIZE_MAX for the fault count allows the macro to distinguish between
 *       a function-level fault and faults counted by the function itself.
 * 
 * @example In the orchestrator module (e,g., test_litetest.c) to
 *          run the 2 test functions (e.g., test_guards_1.c and
 *          test_guards_2.c) and merge their results:
 *
 * @code
 TESTS_MERGE(test_guards_1, test_guards_2, inject)
 * @endcode
 */

#define TESTS_MERGE(func1, func2, inject) \
   {  { lt_result_t func1(char inject); \
        tests_internal(func1, 0, inject, #func1); }
      { lt_result_t func2(char inject); \
        tests_internal(func2, 1, inject, #func2); } \
   }

#define TESTS_MERGE3(func1, func2, func3, inject) \
   {  { lt_result_t func1(char inject); \
        tests_internal(func1, 0, inject, #func1); }
      { lt_result_t func2(char inject); \
        tests_internal(func2, 1, inject, #func2); } \
      { lt_result_t func3(char inject); \
        tests_internal(func3, 1, inject, #func3); } \
}

#define TESTS_MERGE3(func1, func2, func3, inject) \
   {  { lt_result_t func1(char inject); \
        tests_internal(func1, 0, inject, #func1); }
      { lt_result_t func2(char inject); \
        tests_internal(func2, 1, inject, #func2); } \
      { lt_result_t func3(char inject); \
        tests_internal(func3, 1, inject, #func3); } \
      { lt_result_t func4(char inject); \
        tests_internal(func4, 1, inject, #func4); } \
}			

/**
 * @name TEST
 *
 * @brief Evaluates assert_expr with a fault guard and updates the internal
 * static variable litetest_total for pass/fail/fault:
 *
 * - If assert_expr is true (not zero), increments pass count.
   - If false, increments fail count.
   - IF fault, incremenet fault count.
   
 * For fail and fault, prints a message to stderr.
 *
 * @param assert_expr The expression to evaluate as a test assertion.
 *
 * @note The TEST macro uses a guard to capture signals that may occur during the
 *       evaluation of assert_expr. If a signal is caught, it counts as a fault.
 *       The macro also prints messages to stderr for failed assertions and faults,
 *       including the expression, file name, and line number for debugging purposes.
 * 
 *
 * @example In a test module (e.g., test_guard_2.c):
 * 
 * @code
 lt_result_t test_count(const char inject)
 { lt_result_t result = {0, 0, 0, 0, 0};
   TEST(func("hello", 'l') == 2);
   return result;
 }
 * @endcode
 */

#define TEST(assert_expr) \
  do \
   { internal_guard_t test_guard = { 0 }; \
     test_guard.handler = guard_handler_internal; \
     install_guard_internal(&test_guard); \
	   if (sigsetjmp(test_guard.env, 1) == 0) \
     { test_guard.active = 1; \
	     if (assert_expr) { ++test_result.pass; } \
	     else \
	     { ++test_result.fail; \
		     fprintf(stderr, "Test fail: %s (%s:%d)\n", \
                         #assert_expr, __FILE__, __LINE__); \
	     } \
       test_guard.active = 0; \
	   } \
	   else \
	   { ++test_result.fault; \
	     fprintf(stderr, "Test fault: %s (%s:%d)\n", \
                       #assert_expr, __FILE__, __LINE__); \
	   } \
    restore_guard_internal(); \
   } while (0)

#if defined(TEST_ORCHESTRATOR)

static char litetest_runid;
extern lt_result_t internal_total;
extern char *internal_executable_name;
extern const char internal_default_path_msg[];
extern const char *path_msg;

static inline char current_run_id(void)
{ return internal_run_id; }

static inline lt_result_t current_total(void)
{ return internal_total; }

static inline char *executable_name(char *const buf, size_t n)
{ if (!buf || !n) { return NULL; }
  const char *name = internal_executable_name ?
                     internal_executable_name : "UnknownExecutable";
  size_t capped_len = strnlen(name, MAX_PATH_LEN + 1);
  if (capped_len > MAX_PATH_LEN) { capped_len = MAX_PATH_LEN; }
  int len = snprintf(buf, n, "%.*s", (int)capped_len, name);
  if (len < 0) { buf[0] = '\0'; return buf; }
  if ((size_t)len >= n) { buf[n - 1] = '\0'; }
  return buf;
}

void print_err_usage(const char *err_msg);
int parse_args
( const int argc, const char *const *const argv,
  char *const dir_path, char *const filename
);

int is_writable_dir(char *dirpath, char *path);

void write_category
( FILE * const report,
  const size_t index,
  const char *label,
  lt_result_t result
);

const char *category_label_with_inject_tag
( const char *base_label,
  lt_result_t result,
  char inject,
  char *label_buf,
  size_t label_buf_len
);

FILE *open_report(const char *report_path, const char *report_title);
int close_report
( FILE *report,
  lt_result_t total,
  int cat_faults,
  char inject,
  const char *note
);

void get_current_time(char *current_time, size_t size);

/**
 * @def REPORT
 * 
 * @brief Macro to execute a test category and record its result in the test
 *        report.
 *
 * @note Increments the static variable cat_id adn updates static variable
 *       total result with the result of the test category. If the 
 *      result has a category-level fault (fault == SIZE_MAX), increments the
 *      static variable cat_faults to count the number of category-level faults.
 * @param label The category label to display in the report (e.g., "Error/edge cases").
 * @param result_expr An expression that evaluates to a lt_result_t struct containing
 *                   the pass/fail/fault counts for the test category. * 
 * @note If result_expr has a category-level fault (fault == SIZE_MAX), the
 */

#define REPORT(label, result_expr) \
  do \
  { ++cat_id; \
    lt_result_t result = (result_expr); \
	  char label_buf[96]; \
	  const char *_label = category_label_with_inject_tag( \
	   					 (label), result, inject, label_buf, sizeof(label_buf)); \
	  write_category(report, cat_id, _label, result); \
    total = (lt_result_t) \
		    { total.pass + result.pass, \
		      total.fail + result.fail, \
		      total.fault + \
			    (result.fault == SIZE_MAX ? 1 : result.fault), \
			  total.injected_fail + result.injected_fail, \
			  total.injected_fault + result.injected_fault \
		   	}; \
	if (result.fault == SIZE_MAX) ++cat_faults; \
  } while (0)

/**
 * @name open_report
 * 
 * @brief Open report file and write header lines.
 *
 * @param report_path Output file path for the report.
 * @param report_title Title of the report.
 * 
 * @return Open FILE* on success, NULL on error.
 */


/**
 * @name close_report
 * 
 * @brief Write the final summary lines to the report and close it.
 * 
 * @param report The open FILE* for the report.
 * @param total The accumulated total result for all categories.
 * @param cat_faults The number of category-level faults.
 * @param inject Indicates if fail/fault injection was used.
 * @param note Additional string of 1 or more notes (can be NULL).
 * 
 * @return 0 if all tests passed (fail=0, fault=0); 1 otherwise.
 */

/**
 * @name get_current_time
 * @brief Get the current time as a formatted string.
 *
 * @param current_time Buffer to store the formatted time string.
 * @param size Size of the buffer.
 * 
 * @return void. On error, current_time is set to "unknown time".
 */

#endif // defined(TEST_ORCHESTRATOR)

#if defined(__cplusplus)
}
#endif

// End of litetest.h
