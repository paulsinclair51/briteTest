/**
 * @file /paulsinclair51/include/litetest.h
 * 
 * @brief LiteTest is a lightweight, portable, robust, and
 * customizable testing API and framework.
 *
 * This header is included by test modules and a test orchestrator for
 * testing, e.g., a feature, API, or a project implementation. It provides
 * declarations, definitions (other than non-inline fumction definition), and the
 * definitve Doxygen documentation for LiteTest (see README.md in the
 * root directory for an overview of LiteTest).
 * 
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * See LICENSE in the repository root for details.
 */

/**
 * @defgroup Version
 *
 * @name LT_VERSION_MAJOR, LT_VERSION_MINOR 0, LT_VERSION_PATCH
 *
 * - Major version for incompatible API changes.
 * - Minor version for backward-compatible additions.
 * - Patch version for bug fixes or internal improvements.
 *
 * Incompatible API changes: The naming conventions, error semantics, and safety guarantees
 * are part of the documented and stable API and will not change without a
 * major version increment.
 * @{
 */
 
#define LT_VERSION_MAJOR 1
#define LT_VERSION_MINOR 0
#define LT_VERSION_PATCH 0

/** @} */

/**
 * @section Overview
 *
 * In the following, testing the LiteTest itself is used as an example of
 * using the LiteTest API and framework with test modules test_guards_1.c,
 * test_guards_2.c, and test_orchestrator.c, and test orchestrator
 * test_litetest.c in the repository tests directory.
 * 
 * The LiteTest API includes:
 * 
 * 1. Macros with a multi-level signal-guard mechanism
 *    to capture faults:
 *    - LT_TEST(func)
 *    - LT_ASSERT(assert_expr)
 *    - LT_ASSERT_FAIL
 *    - LT_ASSERT_FAULT
 *
 * 2. Macros for use in the test orchestrator (main) function:
 *    - LT_DECLARE_ORCHESTRATOR(funcname)[;]
 *    - LT_INIT_ORCHESTRATOR(funcname);
 *.   - LT_PARSE_ARGS("defaultreportname");
 *    - LT_OPEN_REPORT("reporttitle");
 *    - LT_WRITE_RESULT(t%%[t], "categoryname");
 *    - LT_CLOSE_REPORT("notes");
 *    - LT_EXIT(funcname);
 *
 *    funcname must be main.
 *
 * 2. Macros for use in a test finction function:
 *    - LT_DECLARE_TEST_FUNCTION(funcname)[;]
 *    - LT_INIT_TEST_FUNCTION(funcname);
 *    - LT_RETURN(funcnamm);
 *
 *    funcname must not be main and must be ssme for all three macros when
 *    defining a test function.
 *
 * 3. Miscellanous functions, macros, typedefs, and variables. For example, lt_executablename,
 *    lt_result_t, lt_dirpath, lt_path_usage, and LT_MAX_PATH_LEN.
 * 
 * This header requires at minimum POSIX.1-2001.

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
 * Use the orchestrator macros, variables and functions in the test
 * orchestrator logic plus the LT_TEST macro to execute test functions.
 * 
 * In the test* modules (e.g., test_guards_1.c, test_guards_2.c, and
 * test_orchestrator.c):
 *
 * @code
 #undef LT_ORCHESTRATOR
 #include "litetest.h"
 * @endcode
 *
 * Use the LT_TEST, LT_ASSERT_FAIL, and LT_ASSERT_FAULT macros in
 * the test function to execute tests.
 *
 * @note Other veriations are possible in the test orchestrator and test functions.
 */

/**
 * @section BuildingTestExecutable Building a Test Executable
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
 * LiteTest - Repository name (case-jnsensitive.
 *
 * litetest.h and litetest.c - filenames.
 * 
 * Public API:
 *
 * 1. lt_* - functions, typedefs, and variables.
 * 2. LT_* - macros, constants, and enum values.
 * 
 * Internal and private to the LiteTest framework:
 *
 * 1. litetest_* - functions, typedefs, and variables.
 * 2. LITETEST_* - Internal macros, constants, and enum values.
 *
 * These conventions are designed to provide a clean public API, strong
 * namespace isolation, and predictable behavior when LiteTest is embedded
 * into a larger C/C++ project.
 *
 * @example Public API Names
 *
 * 1. Utility macros: LT_TOK_PASTE, LT_TOK_STR, LT_RESULT, LT_TOTAL
 *    LT_STATIC_ASSERT
 * 2. Version macros: LT_VERSION, LT_VERSION_EQ, LT_VERSION_AT_LEAST
 * 4. Utility functions: lt_current_level.
 *
 * @example Public typedef Name
 *
 * lt_result_t, lt_state_t
 *
 * @example Private Variable Names
 *
 * litetest_result_internal, litetest_total_internal
 */

/**
 *
 * @section FaultGuarding Fault Guarding
 *
 * The test framework uses multi-level fault guarding to handle
 * faults (i.e., segmentation fault, bus error, or abort) during
 * test execution.
 * 
 * A test/assert macro wraps a guard around its argument, enabling
 * detection of a fault not handled at a lower level by the
 * argument rather than aborting. This allows counting pass,
 * fail, and fault without aborting due to a fault.
 * 
 * A fault detected by LT_TEST represents a fault 
 * in the use of the testing framework or in the testing framework
 * itself, and not in the feature being tested. Such a fault is
 * expected to be rare but guarding avoids a fault terminating
 * execution.
 */

#pragma once

/* Enable POSIX.1-2008 (sigaction, sigsetjmp, siglongjmp, sigjmp_buf). */
#if !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L
#endif

#include <stdlib.h>
#include <ctype.h>
#include <limits.h>ì
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
 * @brief Macro for pasting two expanded tokens togethe using the
 *        C/C++ preprocessor operator ##,
 *
 * @param t1 First token, 
 * @param t2 Second token.
 *
 * @return The result of pasting the expanded values of the
 *         two tokens together to form a single token.
 * 
 * @note Tokens t1 and t2 must each expand to a single token.
 * 
 * @note Macro LITETEST_TOK_PASTE_INTERNAL is defined to implement expanding
 *       the tokens for LT_TOK_PASTE. It is not intended for direct use.
 *.      Instead use the ## operator.
 * 
 * @note A preprocessor error is raised if either of these macros
 *       are already defined before including this header.
 * @{
 */

// Paste tokens without expanding.

#define LITETEST_TOK_PASTE_INTERNAL(t1, t2) a##b

// Expand tokens before pasting.

#define LT_TOK_PASTE(t1, t2) LITETEST_TOK_PASTE_INTERNAL(t1, t2)

/** @} */

/**
 * @defgroup TokenStringify Token Stringify
 *
 * @name LT_TOK_STR
 *
 * @brief Macro for stringifying an expanded token using the
 *        C/C++ preprocessor operator #,
 *
 * @param t Token.
 *
 * @return The result of stringifying the expanded value of
 *         token t as a string literal.
 * 
 * @note Token t must expand to a single token.
 * 
 * @note Macro LITETEST_TOK_STR_INTERNAL is defined to implement expanding
 *       the token for LT_TOK_STR. It is not intended for direct use.
 *       Instead use the # operator.
 * 
 * @note A preprocessor error is raised if either of these macros
 *       are already defined before including this header.
 * @{
 */

// Stringify token without expanding.
#define LITETEST_TOK_STR_INTERNAL(t) #s
// Expand token before stringifying.
#define LT_TOK_STR(t) LITETEST_TOK_STR_INTERNAL(t)

/** @} */

/**
 * @name LT_STATIC_ASSERT
 *
 * @brief Compile-time (static) assertion macro.
 *
 * @param cond Condition to be asserted. Condition must be such that it
 *             csn be evaluated at compile-time.
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
 * @section LiteTestVersionMacros LiteTest Version Macros
 */

/**
 * @defgroup LiteTestVersionMacros LiteTest Version Macros
 *
 * @name LT_VERSION, LT_VERSION_NUM, LT_VERSION_HEX, 
 *       LT_VERSION_EQ, LT_VERSION_AT_LEAST
 *
 * @brief Version macros for LiteTest (litetest.h and litetest.c):
 * 
 * The following version macros are provided:
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
 * @note The limit of 32 levels in unlikely to be
 *       eceeded if there are 2 or more TEST/ASSERT* macros at each level.
 *       It is expected that a level will generally have 2 or
 *       more per level.
 */

#define LT_MAX_PATH_LEN      ((size_T)4096)
#define LT_MAX_FILENAME_LEN  ((size_T)255)
#define LT_MAX_GUARD_LEVEL   ((size_T)32)

/**
 * @section result_t Result Type
 */

/**
 * @name lt_result_t
 *
 * @brief Type for result counters returned by a test function,
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
 * @name lt_state_t
 *
 * @brief Type for maintaining the state of the LiteTest framework.
 */

typedef struct
{ size_t current_guard_level;
  size_t category_id;
  size_t num_results_merged;
  size_t pass;
  size_t fail;
  size_t fault;
  size_t injected_fail;
  size_t injected_fault;
  size_t total_pass;
  size_t total_fail;
  size_t total_fault;
  size_t total_injected_fail;
  size_t total_injected_fault;
} lt_state_t;

/**
 * @section Guard Infrastructure
 * 
 * The internal guard infrastructure provides a mechanism to catch signals such as SIGSEGV,
 * SIGABRT, and SIGBUS that may occur during the evaluation of LT_TEST
 * and LT_ASSERT* macros.
 *
 * It uses sigsetjmp and siglongjmp to return control
 * to a known point in the code when a signal is caught, allowing the test framework
 * to count faults and continue running other tests instead of aborting the entire
 * test suite.
 * 
 * @note The internal guard infrastructure is not intended to be used directly.
 */

/**
 * @name litetest_sighandler_internal_t
 * 
 * @brief Type for signal handlers used in the guard infrastructure.
 *
 * @details litetest_sighandler_internal_t type is defined as a pointer to a function that takes
 * an int signal number as a parameter and returns void. This type is used for the
 * handler function pointer in the guard structure and for saving/restoring signal
 * handlers in the guard install and restore functions.
 * 
 * The litetest_sighandler_internal_t type ensures that the guard mechanism can properly
 * manage signal handlers for SIGSEGV, SIGABRT, and SIGBUS.
 * 
 * The use of litetest_sighandler_internal_t allows the guard mechanism to be flexible and compatible
 * with the signal handling conventions of this framework.
 */

typedef void (*litetest_sighandler_interal_t)(int);

/**
 * @name litetest_guard_internal_t
 * 
 * @brief Structure for a guard used to capture signals and manage
 *        state for fault recovery.
 */

typedef struct
{ void (*handler)(int sig);
  sigjmp_buf env;
  volatile sig_atomic_t active;
} litetest_guard_internal_internal_t;

/**
 * @name litetest_saved_guard_internal_t
 * 
 * @brief Structure for saving the current guard and when a guard 
 *        at a lower level is installed.
 */

typedef struct
{ litetest_guard_internal_t *guard;
  litetest_sighandler_internal_t segv_handler;
  litetest_sighandler_internal_t abrt_handler;
  litetest_sighandler_internal_t bus_handler;
  lt_state_t state;
} litetest_saved_guard_internal_t;

/**
 * @name litetest_current_guard_internal
 * 
 * @brief Pointer to the current guard used for signal handling
 *        and fault recovery.
 * 
 * @note Current guard is accessible internally by the guard
 *       infrastructure in the orchestrator and test functions.
 *       It is defined only for the orchestrator function.
 */

extern litetest_guard_internal_t *litetest_current_guard_internal;

/**
 * @name litetest_saved_guards_internal, litetest_num_saved_guards_internal
 * 
 * @brief Array of saved guards and the number of saved guards.
 * 
 * @note These are accessible internally by the guard infrastructure
 *       in the orchestrator and test functions. It is defined only
 *       for the orchestrator function.
 * @{
 */

extern litetest_saved_guard_internal_t litetest_saved_guards_internal[MAX_GUARD_LEVEL];
extern size_t litetest_num_saved_guards_internal;

/** @} */

/**
 * @name litetest_guardhandler_internal
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

static inline void litetest_guard_handler_internal(int sig)
{ if (litetest_guard_internal && litetest_guard_internal->active)
  { litetest_guard_internal->active = 0;
    siglongjmp(litetest_guard_interrnal->env, sig ? sig : 1); 
  }

  // Fault outside of active guard or misuse of guard framework.
  abort();
}

/**
 * @name litetest_install_guard_internal
 * 
 * @brief Install a new guard after saving the current guard.
 * 
 * @param new_guard Pointer to a new guard.
 * 
 * On error (too many nested guards or signal handler installation
 * failure), raises abort using abort() for POSIX/C behavior to
 * terminate the program without causing an infinite loop through
 * signal handling.
 */

void litetest_install_guard_internal(litetest_guard_internal_t *new_guard);

/**
 * @name litetest_restore_guard_internal
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
 * @note The guard mechanism allows for nested guards, and the litetest_restore_guard_internal
 * function ensures that the correct guard is restored in a last-in-first-out manner.
 */

void litetest_restore_guard_internal(void);

 * @name litetest_test_internal
 * 
 * @brief Internal function used by the LT_TEST macro: ezexutes func
 *        capturing a fault, if one occurs, with a guard.
 *        Saves the result internally and adds the result
 *        to the internal total.
 * 
 * @param func Pointer to a function to execute, which takes a
 *             char inject parameter and returns a lt_result_t value.
 * @param func_name Name of the function being executed that is used for error messages.
 * 
 * @return lt_result_t result from function or
 *         (lt_result_t){0, 0, SIZE_MAX, 0, 0} if a fault occurs.
 */

lt_result_t litetest_tests_internal
( lt_result_t (*func)(char),
  const char * const func_name,
  litetest_state_internal_t *litetest_caller_state_internal
);

/** @} */

/
 * @section GuardAPIFunctionS Guard API Functions
 * 
 * The guard functions provide a public API fot the guard mechanism status, such as the 
 * current guard level and whether the current guard is active.
 */

/**
 * @name lt_level
 * 
 * @brief Get the level indicating the number of nested LT_TEST and LT_ASSERT* macros.
 * 
 *        The level can be used for retrieving the results and total for the function,
 *        debugging, informational purposes,
 *        determining the depth of nested macros, or for checking against
 *        the maximum level (lt_max_level).
 * 
 * @return 0 if not nested.
 *         Otherwise, the current level.
 */

 static inline size_t lt_level(void)
 { return litetest_num_saved_guards_internal + 
          (litetest_current_guard_internal ? 1 : 0); }

/**
 * @name  lt_isguardactive
 * @brief Check if the current guard is active.
 * 
 * @return 1 if the current guard is active
 *         0 if current guard is not active.
 *        -1 if there is no current guard.
 */

static inline int lt_isguardactive(void)
  { return litetest_guard_internal ? litetest_guard_internal->active : -1; }

static inline char lt_categoryid(void)
{ return litetest_categoryid_internal; }

static inline lt_result_t currenttotal(void)
{ return litetest_total_internal; }

/**
 * @name lt_current_time
 * @brief Get the current time as a formatted string.
 *
 * @param current_time Buffer to store the formatted time string.
 * @param size Size of the buffer.
 * 
 * @return void. On error, current_time is set to "unknown time".
 */

void lt_current_time(char *current_time, size_t size);

/**
 * @section LT_TEST and LT_ASSERT* Macros
 * 
 * The LT_TEST, LT_ASSERT, LT_ASSERT_FAIL, and LT_ASSERT_FAULT macros
 * provide a interface for running tests with built-in fault recovery
 * using the multi-level guard infrastructure:
 * 
 * - Typically, the test orchestrator (main) function uses the LT_TEST macro
 *   to execute a test function. The LT_ASSERT, LT_ASSERT__FAIL, and
 *   LT_ASSERT_FAULT macros may be used in the test orchestrator
 *   function, but it is more common for test fucntions to  use these macros.
 * 
 * - Typically, a test function uses the LT_ASSERT, LT_ASSERT_FAIL,
 *   and LT_ASSERT_FAULT macros. A test module may also use the
 *   LT_TEST macro for a test that can not reasonably be expressed as
 *   a single assertion, as a single  assertion, such as a test that
 *   involves multiple steps, looping, or requires setup and teardown.
 */

/**
 * @name LT_TESTS
 * 
 * @brief A macro to run a function with a guard.
 *
 * After saving the current guard, setting up a new current guard to
 * capture a fault (SIGABRT, SIGSEGV,
 * or SIGBUS), calls the function named funcname.
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
 LT_TEST(funcname);
 * @endcode
 */

#define LT_TEST(funcname) \
   { t_result_t funcname(lt_state_t *litetest_state_internal); \
     litetest_test_internal(funcname, #funcname); }

/**
 * @name LT_ASSERT
 *
 * @brietf Evaluates assertexpr with a fault guard and updates the internal
 * totals for pass/fail/fault:
 *
 * - If assertexpr is true (not zero), increments pass count.
 * - If assertexpr false, increments fail count.
 * - IF fault, incremenet fault count
 *
 * @param assertexpr The expression to evaluate.
 *
 * @note The LT_ASSERT macro uses a guard to capture a fault that may occur during the
 *       evaluation of assertexpr. If a fault is causght, it counts as a fault.
 * 
 * @note For fail and fault, a message is appended to the test report.
 *       The message includes assertexpr, filename of the module, and line
 *       ine number for debugging purposes.
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

/**
 * @section Orchestrator Macros
 * 
 * The orchestrator macros provide an API for running tests as the
 * main function of an executable.
 * 
 * Typically, the test orchestrator (main) function uses the LT_TEST macro
 * to execute a test function. The LT_ASSERT, LT_ASSERT__FAIL, and
 * LT_ASSERT_FAULT macros may be used in the test orchestrator, but
 * it is more common for test fucntions to use these macros.
 *
 * @example Orchestrator function:
 * @code
LT_DECLARE_ORCHESTRATOR(main)
{ 
  LT_PARSE_ARGS ("LiteTest_test_report.txt");

  LT_INIT_ORCHESTRATOR(litetest, 1);
  
  LT_OPEN_REPORT("LiteTest");
 
  LT_WRITE_RESULT(LT_TEST(test_orchestrator), "Orchestrator Tests");

  LT_TEST(test_guard1);
  LT_WRITE_RESULT(LT_TEST(test_guard2), "Guard Tests 1 and 2");

  LT_CLOSE_REPORT;

  LT_RETURN_STATUS;
}
 * @endcode
 */

/**
 * @name LT_DECLARE_ORCHESTRATOR(funcmame)
 * 
 * @brief Declare the orchestrator (main) function as a forward teference or
 *        with a function body to define the orchestrator function.
 *
 * @param funcname Name of the function. funcname must be main.
 *
 * @note Compile-time error occurs if the macro is not syntactically
 *       alloewed in this context.
 *
 * @example Forward-reference
 * @code
 LT_DECLARE_ORCHESTRATOR(main);
 * @endcode
 *
 * @example Function Definition
 * @code
    LT_DECLARE_TEST_FUNCTION(main)
    { /* orchestrator (main) function body*/ }
 * @endcode
 */

#define LT_DECLARE_ORCHESTRATOR(funcnane) \
    void funcname \ return int?
    ( litetest_lcl_state_internal_t *const litetest_lcl_state_internal )

/**
 * @name LT_INIT_ORCHESTRATOR
 * 
 * @brief Initialize the orchestrator.
 *
 *        Exits the executable if the macro is not allowed in this context.
 * 
 * @param funcname Name of the function which must be main.
 *
 * @note Compile-time error occurs if the macro is not followed by a semicolon or
 *       the macro is not syntactically allowed in this context.
 *
 * @example
 * @code
 LT_INIT_ORCHESTRATOR(LT_TEST(main);
 * @endcode
 */

#define LT_INIT_ORCHESTRATOR(funcname) \
    do \
    { \
      if (strcmp(__func__, "main" || strcmp(#funcname, "main")) \
      { fprintf(stdout, "[ERROR] LT_INIT_ORCHESTRATOR must be used in main function.\n"); \
        exit(2); \
      } \
      if (litetest_state_internal.orchestrator) \
      { fprintf(stdout, "[ERROR] LT_EXIT not in orchestrator\n"); } \
        exit(litetest_state_internal.exit_code); \
      } \
      char litetest_runid; \
      lt_result_t internal_total; \
      char *internal_executable_name; \
      const char internal_default_path_msg[]; \
      const char *path_msg; \
    } while (0)


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

/**
 * @name OPEN_REPORT
 * 
 * @brief Open report file, open tmp file, and write header lines.
 *
 *        Exits the executable if the macro is not allowed in this context.
 * 
 *
 * @param report_title Pointer to a string of customized title lines for the report.
 *              If NULL or zero-length, a default title line is used.
 *              Each line must end with a newline character ('\n').
 *.             %t indicate replace with a timestamp "yyyy hh:mm:ss"
 *              RECOMMENDED: Each line should be less than 80
 *              characters for readability.
 *
 * @note Compile-time error occurs if the macro is not followed by a semicolon or
 *       the macro is not syntactically allowed in this context.
 *
 * @example
 * @code
 LT_OPEN_REPORT("LiteTest Test Report %t\n");
 * @endcode
 * @{
 */

int litetest_open_report_internal
( litetest_state_internal_t *const state, const char *const report_title );

#define OPEN_REPORT(reporttitle) \
    do \
    { \
      if (!strcmp(__func__, "main")) \
      { \
        fprintf(stdout, "[ERROR] LT_EXIT is not in the orchestrator "
                        "(main) function\n"); \
        exit(LT_MACRO_MISPLACED); \
      } \
      int rc = litetest_open_report_internal
                 (__func__, #funcname, &litetest_state_internal, (reporttitle)); \
      if (rc) exit(rc); \
    } while (0)

/**
 * @def LT_WRITE_RESULT
 * 
 * @brief Macro to write the results for a test category to the
 *        report and resets the result counts for the next category.
 *
 *        Exits the executable if the macro is not allowed in this context.
 * 
 * 
 * @param t An optional test/assert macro.
 * @param label The category label to display in the report,
 *
 * @note Compile-time error occurs if the macro is not followed by a semicolon or
 *       the macro is not syntactically allowed in this context.
 *
 * @example Write the results for a category with one test function:
 * @code
    LT_WRITE_RESULT(LT_TEST(test_orchestrator), "orchestrator");
 * @endcode
 *
 * @example Write results for a category with one test function (alternate):
 * @code
 LT_TEST(test_orchestrator);
 LT_WRITE_RESULT(, "orchestrator");
 * @endcode
 *
 * @example Write results for a category with two test functions:
 * @code
    LT_TEST(test_guard1);
    LT_WRITE_RESULT(LT_TEST(test_guard2), "guard 1 and 2");
 * @endcode
 *
 * @example Write results for a category with two test functions (alternate):
 * @code
    LT_TEST(test_guard1);
    LT_TEST(test_guard2);
    LT_WRITE_RESULT(, "guard 1 and 2");
 * @endcode
 */

#define LT_WRITE_RESULT(t, label) \
  do \
  { t; \
    ++cat_id; \
    char label_buf[96]; \
    const char *_label = category_label_with_inject_tag( \
             (label), result, inject, label_buf, sizeof(label_buf)); \
    litetest%_write_result_internal(report, cat_id, _label, result); \
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
 * @name LT_CLOSE_REPORT
 * 
 * @brief Write the final summary lines, notes, and error messasges
 *        to the report, closes the report, closes/deletes
 *        the temp file, and saves the final return code.
 *
 *        Exits the executable if the macro is not allowed in this context.
 * 
 * @param notes Pointer to a string of customized notes for the report.
 *              If NULL or zero-length, no customized notes are added to the report.
 *              Each line of the notes must end with a newline character ('\n').
 *              RECOMMENDED: Each line of the notes should be less than 80
 *              characters for readability.
 *
 * @note Compile-time error occurs if the macro is not followed by a semicolon or
 *       the macro is not syntactically allowed in this context.
 *
 * @example
 * @code
 LT_CLOSE_REPORT("guard: fault detection mechanism,\n"
                 "orchestrator: main function to run testd.\n");
 * @endcode
 * @{
 */

int litetest_close_report_internal
( litetest_state_internal_t *const state, const char *const notes );

#define LT_CLOSE_REPORT(notes) \
    do \
    { \
      if (!strcmp(__func__, "main")) \
      { \
        fprintf(stdout, "[ERROR] LT_CLOSE_REPORT is not in the "
                        "orchestrator (main) function.\n"); \
        exit(LT_MACRO_MISPLACED); \
      } \
      int rc = litetest_close_report_internal
                 (__func__, #funcname, litetest_state_internal, (notes)); \
      if (rc) exit(rc) \
    } while (0) \

/** @} */

/**
 * @name LT_EXIT
 * 
 * @brief Exit the orchestrator with exit code (0 if successful and
 *        no fails or faults).
 *
 *        Exits the executable if the macro is not allowed in this context.
 *
 * @param funcname Name of the function which must be main.
 * 
 * @note Compile-time error occurs if the macro is not followed by a semicolon or
 *       the macro is not syntactically allowed in this context.
 *
 * @example
 * @code
 LT_EXIT(main);
 * @endcode
 */

#define LT_EXIT(funcname) \
    do \
    { \
      if (!strcmp(__func__, "main")) \
      { \
        fprintf(stdout, "[ERROR] LT_EXIT is not in the "
                        "orchestrator (main) function.\n"); \
        exit(LT_MACRO_MISPLACED); \
      } \
      exit(litetest_exit_internal \
             (__func__, #funcname, litetest_state_internal, (notes)); \
    while (0)

/**
 * @section Test Function Macros
 * 
 * The test function macros provide an API for running a set of tests.
 * 
 * Typically, a test function uses the LT_ASSERT, LT_ASSERT_FAIL,
 * and LT_ASSERT_FAULT macros. A test module may also use the
 * LT_TEST macro for a test that can not reasonably be expressed as
 * a single assertion, as a single  assertion, such as a test that
 * involves multiple steps, looping, or requires setup and teardown.
 *
 * @example
 * @code
 LT_INIT_TEST_FUNCTION(test_guard1);
 * @endcode
 */

/**
 * @name LT_DECLARE_TEST_FUNCTION(funcname)
 * 
 * @brief Declare a test function as a forward teference or
 *.       with a function body to define the test function.
 * 
 * @param funcname Name of the test function. funcnsme must not be main.
 *
* @note Compile-time error occurs if the macro is not syntactically
*       alloewed in ths contrst.
 *
 * @example Forward-reference
 * @code
    LT_DECLARE_TEST_FUNCTION(test_guard1);
 * @endcode
 *
 * @example Function Definition
 * @code
 LT_DECLARE_TEST_FUNCTION(test_guard1)
 { /* test_guard1 function body*/ }
 * @endcode
 */

#define LT_DECLARE_TEST_FUNCTION(funcnane) \
    void funcname \
    ( litetest_lcl_state_internal_t *const litetest_lcl_state_internal )

/**
 * @name LT_INIT_TEST_FUNCTION
 * 
 * @brief Initialize a test function.
 *
 *        Exits the executable if the macro is not allowed in this context.
 * 
 * @param funcname Name of the test function. funcnsme must be the same
 *                 funcname as for the containing function.
 *
 * @note Compile-time error occurs if the macro is not followed by a semicolon or
 *       the macro is not syntactically allowed in this context.
 *
 * @example
 * @code
 LT_INIT_TEST_FUNCTION(test_guard1);
 * @endcode
 */

#define LT_INIT_TEST_FUNCTION(funcname) \
    do \
    { \
      if (!strcmp(__func__, "main" || !strcmp(#funcname, "main")) \
      { fprintf(stdout, "[ERROR] LT_INIT_TEST_FUNCTION is NOT allowed "
                        "in the orchesrator (main) function.\n"); \
        exit(LT_MACRO_MISPLACED); \
      } \
      int rc = litetest_init…test_function_internal \
                 (__func__, #funcname, litetest_lcl_state_internal) \
      if (rc) exit(rc);
    } while (0)

/**
 * @name LT_RETURN
 * 
 * @brief Return from test function.
 *
 *        Exits the executable if the macro is not allowed in this context.
 *
 * @param funcname Test function name. funcnsme must be the same
 *                 funcname as for the containing function.
 *
 * @note Compile-time error occurs if the macro is not followed by a semicolon or
 *       the macro is not syntactically allowed in this context.
 *
 * @example
 * @code
 LT_RETURN(test_guard1);
 * @endcode
 */

#define LT_RETURN(funcname) \
    do \
    { \
      if (!strcmp(__func__, "main")) \
      { \
        fprintf(stdout, "[ERROR] LT_RETURN is NOT allowed "
                        "in the orchestrator (main) function.\n"); \
        exit(LT_MACRO_MISPLACED); \
      } \
      int rc = litetest_return_internal \
                 (__func__, #funcname, litetest_lcl_state_internal) \
      if (rc) exit(rc); \
      return; \
    while (0)

/**
 * @section Glossary
assert
guard
header .h file
module .c file
orchestrator (main) function
test function
 */

#if defined(__cplusplus)
}
#endif


// End of litetest.h
