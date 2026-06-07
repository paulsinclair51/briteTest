 /**
 * @file /paulsinclair51/include/litetest.h
 * 
 * @brief LiteTest is a lightweight C/C++ API and testing framework suitable for
 * embedding into other C/C++ projects. The API and framework are intentionally
 * minimal while still providing flexible and comprehensive testing capabilities.
 *
 * This header is included by modules defining an orchestrator (main) and 
 * testing functions for testing, e.g., a feature, API, or a project implementation.
 * It provides declarations, definitions (other than non-inline function definitions
 * provided by litetest.c in the repository src directory), and the complete
 * Doxygen documentation for LiteTest. See README.md in the repository root
 * directory for an overview of LiteTest plus a comparison to other frameworks.
 *
 * @note LiteTest requires POSIX.1-2001 (IEEE Std 1003.1-2001) compatibility and a
 *       C99-compliant compiler. Linux, macOS, and the BSD family natively meet these
 *       requirements. Windows requires a POSIX compatibility layer such as Cygwin,
 *       MSYS2, or WSL.
 *
 * @note LiteTest has been exercised in a POSIX environment; however, users must
 *       confirm correct behavior in their own environment.
 * 
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * See LICENSE in the repository root for details.
 */

/**
 * @section VersonMacro Version Macro
 *
 * @name LT_VERSION
 *
 * @brief Version "M.m.p" for litetest.h which must be the same as
 *.       LT_VERSION_C for litetest.c.
 *
 * M, m, and p are 1 or 2 digits (e.g., O, 00, 1, 01, 24):
 +
 * - M: Major version for incompatible API changes.
 * - m: Minor version for backward-compatible additions.
 * - p: Patch version for bug fixes or internal improvements.
 *
 * @note Incompatible API changes: The naming conventions, error semantics,
 *       and safety guarantees are part of the documented and stable API
 *       and will not change without a major version increment.
 */
 
#define LT_VERSION "1.0.0"

/**
 * @section ChangeHistory Change History
 *
 * 2026/09/27 Initial version "1.0.0.".
 **/

/**
 * @section Overview Overview
 *
 * @note In the following, testing the LiteTest itself is used as an example of
 *       using the LiteTest API and framework with test modules test_guards_1.c,
 *       test_guards_2.c, and test_orchestrator.c, and test orchestrator
 *       test_litetest.c in the repository tests directory.
 *
 * @subsection KeyPoints Key Points
 *
 * 1. A test executable is built from:
 *
 *   - An orchestrator (main) function and optional test functions
 *     organized into one or more modules,
 *
 *   - litetest.h, and litetest.c, unistd.h
 *
 *   - Modules and include files from the feature/project/API under test.
 *   
 * 2. The executable produces a report grouped by category, including
 *    pass/fail/fault counts per category and totals across all categories.
 *    Fail and fault messages are appended to the report.
 *
 * 3. The orchestrator and test functions may reside in one module
 *    or multiple modules. Recommended: put the orchestrator function
 *    in one module and each test function in its own module.
 *
 * 4. The test framework requires unistd.h for POSIX fork and signal capabilities.
 * 
 * @subsection OrchestratorMacros Orchestrator Function Macros
 *
 * Macros for use in the orchestrator (main) function:
 *
 * - LT_DECLARE_ORCHESTRATOR(funcname)[;]
 * - LT_INIT_ORCHESTRATOR(funcname, testsuitename, [maxparallel]);
 * - LT_PARSE_ARGS([maxargs], ["defaultreportfilename"]);
 * - LT_OPEN_REPORT(["reporttitle"]);
 * - test and assert macros
 * - LT_WRITE_RESULT([t], "categoryname");
 * - LT_CLOSE_REPORT(["notes"]);
 * - LT_EXIT;
 *
 * @note funcname must be main.
 * @note maxargs must be 2 or greater. The first arg is the executable name.
 *       The second optional arg is PATH. Additional args are for customization
 *       and must be parsed by custom code added to the function.
 * @note t is a test or assert macro.
 * @note For the first macro, a semicolon is required for a forward declaration;
 *       otherwise, it is omitted if is it followed by a definition in { }.
 *
 * @subsection TestFunctionMacros Test Function Macros
 *
 * Macros for use in a test function:
 *
 * - LT_DECLARE_TEST(funcname)[;]
 * - LT_INIT_TEST(funcname, [maxparallel]);
 * - test and assert macros
 * - LT_RETURN;
 *
 * @note funcname must not be main and must be same for the first two macros when
 *       defining a test function.
 * @note For the first macro, a semicolon is required for a forward declaration;
 *       otherwise, it is omitted if it is followed by a definition in {}.
 *
 * @subsection TestAndAssertMacros Test and Assert Macros
 *
 * These macros provide multi-level signal handling to capture faults
 * (SIGSEGV, SIGABRT, SIGBUS). Faults are counted without aborting
 * execution, allowing the test suite to continue and produce a complete
 * test report with fault counts and messages for each fault.
 *
 * - LT_TEST(funcname, [isolation])[;]
 * - LT_ASSERT(assertexpr, [isolation])[;]
 * - LT_ASSERT_FAIL([isolation])[;]
 * - LT_ASSERT_FAULT([isolation])[;]
 *
 * @note The semicolon is omitted if used as an argument to the
 *       LT_WRITE_RESULT macro; otherwise it is required.
 *
 * @subsubsection ParallelExecution Parallel Execution
 *
 * Parallel execution of the test/assert macros is enabled/disabled by the
 * maxparallel parameter for the LT_INIT_ORCHESTRATOR and LT_INIT_TEST
 * macros. Up to maxparallel test/assert macros are started and when one
 * finishes another is started.
 *
 * @subsubsection ParallelGroupExecution Parallel Group Execution
 *
 * Test/assert macros can run in parallel as a group (that is, they
 * are not started until they can all start without exceeding maxparallel).
 * A group is bracketed using the followug macros:
 *
 * - LT_BEGIN_GROUP(groupname, [isolation])
 * - LT_END_GROUP(groupname);
 *
 * @note A group cannot be nested in a group within a test function.
 *
 * @subsubsection TextIsolation Test Isolation
 *
 * For non-grouped test/assert macro, the isolation parameter 
 * indicates whether the macro runs in the same thread as the calling
 * function (no parallelism), a separate thread, or a separate process:
 *
 *     Isolation: 0 (none), 1 (thread), 2 (process)
 *
 * @note For a test/assert macro not in a group, the default is 0 (none).
 *
 * @note For a test/assert macro in a group, isolation must be 1 (thread)
 *       or 2 (process) with a default of 1 (thread).
 *
 * @subsection Miscellaneous
 * 
 * Miscellaneous functions, macros, typedefs, and variables.
 * Examples include:
 *
 * - lt_executablename
 * - lt_result_t
 * - lt_dirpath
 * - LT_MAX_PATH_LEN
 * - lt_currentlevel
 * - lt_currentresult
 * - lt_maxparallel
 * - lt_isisolated
 * - lt_groupname
 * - lt_iswritedirpath
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
 * @name LUB_VERSION_MAJOR, LUB_VERSION_MINOR, LUB_VERSION_PATCH,
 *       LT_VERSION_NUM, LT_VERSION_HEX, 
 *       LT_VERSION_CMP
 *
 * @brief Version macros for LiteTest (litetest.h and litetest.c):
 * 
 * LT_VERSION_MAJOR
 *    Major version
 *    size_t, 1 or greater.
 * 
 * LT_VERSION_MINOR
 *    Minor version nunber
 *    size_t, e.g., 0, 22.
 * 
 * LT_VERSION_PATCH
 *    Patch version number
 *    size_t, e.g., 0, 12.
 * 
 * LT_VERSION_NUM
 *    size_t, form MMmmpp for comparisons, e.g., 10000 for
 *    version 1.0.0, 10200 for version 1.2.0, or 11212 for version 1.12.12.
 * 
 * LT_VERSION_HEX
 *    Hexadecimal form 0xMMmmpp for display/debugging, e.g.,
 *    0x010000 for version 1.0.0, 0x010200 for version 1.2.0,
 *    or 0x011212 for version 1.12.12.
 * 
 * LT_VERSION_CMP(v)
 *    1 VERSION is greater than v,
 *    0 VERSION is equal to v,
 *   -1 VERSION is less than v,
 *.  -2 v has invalid version formatting,
 *    v is a string with the same format as VERSION,
 *
 * @{
 */

size_t litetest_get_version_major_internal(void);
#define LT_VERSION_MAJOR litetest_get_version_major_internal()

size_t litetest_get_version_minor_internal(void);
#define LT_VERSION_MINOR litetest_get_version_minor_internal()

size_t litetest_get_version_patch_internal(void);
#define LT_VERSION_PATCH litetest_get_version_patch_internal()

// LiteTest version as an integer for comparisons.

size_t litetest_get_version_num_internal(void);
#define LT_VERSION_NUM litetest_get_version_num_internal()

// LiteTest version encoded as 0xMMmmpp (major, minor, patch) for display/debug.

size_t litetest_get_version_hex_internal(void);
#define LT_VERSION_HEX litetest_get_version_hex_internal()

// LiteTest version compared to specified version (1 if true, otherwie 0).

int litetest_version_cmp_internal
( comst char *v);
#define LT_VERSION_CMP(v) \
    litetest_version_cmp_internal((v))

/** @} */ // End of Version Macros.

/**
 * @section Limits
 */

/**
 * @name LT_MAX_PATH_LEN, LT_MAX_FILENAME_LEN, LT_MAX_LEVEL
 * 
 * @brief Maximum values for path length, filename length,
 *        and guard levels.
 *
 * @note The limit of 32 levels in unlikely to be
 *       exceeded if there are 2 or more TEST/ASSERT* macros at each level.
 *       It is expected that a level will generally have 2 or
 *       more per level.
 */

#define LT_MAX_PATH_LEN      ((size_T)4096)
#define LT_MAX_FILENAME_LEN  ((size_T)255)
#define LT_MAX_LEVEL         ((size_T)32)

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
 * @brief Type for maintaining the state of the orchestrator (main)
 *        or a test function.
 */

typedef struct
{ size_t id;
  char *funcname;
  size_t current_level;
  size_t groupid;
  char *groupname;
  int isolation; // 0 none, 1 thread, 2 process.
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
  lt_state_t parent;
  lt_state_t prev;
  lt_state_t next;
} lt_state_t;

void print_err_usage(const char *err_msg);
int parse_args
( const int argc, const char *const *const argv,
  char *const dir_path, char *const filename
);

// Get and set defaults.

char *lt_executable_name(void);
void lt_set_executable_name(char *en);
char *lt_default_dirpath(void);
void lt_set_default_dirpath(char *dp);
char *lt_prefix_err_msg(void);
void lt_set_prefix_err_msg(char *pe);
char *lt_args_options_msg(void);
void lt_set_args_options_msg(char *ao);
char *lt_usage_msg(void):
void lt_set_usage_msgg(char *u);
char *lt_help_msg(void);
void lt_set_help_msg(char *h);

// Utility Functions

size_t lt_currentlevel(void);
lt_result_t lt_currentresult(void);
lt_total_t lt_currenttotal(void);
size_t lt_maxparallel(size@_t level);
size_t lt_currentparallel(void);}
int lt_isisolated(void);
int lt_isthreadisolated(void);
int lt_isprocessisolated(void);
size_t lt_groupid(void);
char *lt_groupname(void);

char *lt_testsuite(void);
char *lt_reporttitle(void);
size_t lt_categoryid(void);
char *lt_categoryname(void);
char *lt_funcname(void);
char *lt_testname(void)
char *lt_assertexpr(void);

char *lt_dirpath(void);
char *lt_filepath(void);
char *lt_filename(void);

// 1 true, 0 false
int lt_isfilename(char *name);

// 1 true, 0 false, -1 not a directory path
int lt_isreaddirpath(char *path);
int lt_iswritedirpath(char *path);

// 1 true, 0 false, -1 not a file path
int lt_isreadfilepath(char *path);
int lt_iswritefilepath(char *path);

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
 * @name LT_TEST
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
   { int func_assert( void ) { return (assert_expr); }
     litetest_guarded_assert_expr_internal
         (&func_assert, #assert_expr, __FILE__, __LINE__)





     litetest_guard_internal_t test_guard = { 0 }; \
     test_guard.handler = litetest_guard_handler_internal; \
     litetest_install_guard_internal(&test_guard); \
     if (sigsetjmp(test_guard.env, 1) == 0) \
     { test_guard.active = 1; \
	if (assert_expr)
       { ++test_result.pass; } \
	else \
	{ ++test_result.fail; \
         litetest_print_result_internal \
           (1, #assert_expr, __FILE__, __LINE__); \
       } \
       test_guard.active = 0; \
     } \
     else \
     { ++test_result.fault; \
	litetest_print_result_internal \
           (-1, #assert_expr, __FILE__, __LINE__); \
     } \
     litetest_restore_guard_internal(); \
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
 LT_INIT_ORCHESTRATOR(main);
 * @endcode
 */

void litetest_init_orchestrator_internal
( char *funcname,
  char *func, char *file, int line,
  litetest_state_internal_t *const state,
  litetest_lcl_state_internal_t *const lcl_state
);

#define LT_INIT_ORCHESTRATOR(funcname) \
  typedef int lt_use_LT_INIT_ORCHESTRATOR_once; \
  litetest_state_internal_t litetest_state_internal; \
  litetest_lcl_state_internal_t litetest_lcl_state_internal; \
  do \
  { \
    litetest_init_orchestrator_internal \
    ( #funcname, \
      __func__, __FILE__, __LINE__, \
      &litetest_state_internal, \
      &litetest_lcl_state_internal \
      ); \
  } \
  while (0)

/**
 * @name OPEN_REPORT
 * 
 * @brief Open report file, open tmp file, and write header lines.
 *
 *        Exits the executable if the macro is not allowed in this context.
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

void litetest_open_report_internal
( const char *const report_title,
  char *func, char *file, int line,
  litetest_state_internal_t *const state
);

#define LT_OPEN_REPORT(reporttitle) \
  typedef int lt_use_LT_OPEN_REPORT_once; \
  do \
  { \
    litetest_open_report_internal \
    ( (reporttitle), \
      __func__, __FILE__, __LINE__, \
      &litetest_state_internal \
    ); \
  } \
  while (0)

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

void litetest_write_result_internal
( const char *const label,
  char *func, char *file, int line,
  litetest_lcl_state_internal_t *const lcl_state
);

#define LT_WRITE_RESULT(t, label) \
  do \
  { \
    litetest_write_result_internal \
    ( (label),
      __func__, __FILE__, __LINE__, \
      &litetest_state_internal \
    ); \
  } \
  while (0)

#define LT_WRITE_RESULT(t, label) \
  do \
  { t; \
    ++category_id; \
    char label_buf[96]; \
    const char *_label = categorylabel_with_inject_tag( \
             (label), result, inject, label_buf, sizeof(label_buf)); \
    litetest_write_result_internal(report, categoryid, categorylabel, result); \
    total = (lt_result_t) \
		    { total.pass + result.pass, \
		      total.fail + result.fail, \
		      total.fault + \
			    (result.fault == SIZE_MAX ? 1 : result.fault), \
			  total.injected_fail + result.injected_fail, \
			  total.injected_fault + result.injected_fault \
		   	}; \
	if (result.fault == SIZE_MAX) ++category_faults; \
  } \
  while (0)

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

void litetest_close_report_internal
( const char *const notes,
  char *func, char *file, int line,
  litetest_state_internal_t *const state
);

#define LT_CLOSE_REPORT(notes) \
  typedef int lt_use_LT_CLOSE_REPORT_once; \
  do \
  { \
    litetest_ lose_report_internal \
    ( (notes), \
      __func__, __FILE__, __LINE__, \
      &litetest_state_internal \
    ); \
  } \
  while (0)

/** @} */

/**
 * @name LT_EXIT_ORCHESTRATOR
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
 LT_EXIT_ORCHESTRATOR(main);
 * @endcode
 */

void litetest_exit_orchestrator_internal
( const char *const funcname,
  char *func, char *file, int line,
  litetest_state_internal_t *const state
);

#define LT_EXIT_ORCHESTRATOR(notes) \
  typedef int lt_use_LT_CLOSE_REPORT_once; \
  do \
  { \
    litetest_ lose_report_internal \
    ( (notes), \
      __func__, __FILE__, __LINE__, \
      &litetest_state_internal \
    ); \
  } \
  while (0)

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
*       alloewed in ths context.
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
