 /**
 * @file /paulsinclair51/include/britetest_runner.h
 * 
 * @brief BriteTest Runner is a lightweight framework and Application Programming and
 * Interface (API) framework for defining, running, and reporting tests in C/C++ projects.
 * It is implemented as a single .h and .c pair with no external dependencies requiring
 * only a POSIX.1‑2001 environment and a C99‑compliant compiler.
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * See LICENSE in the repository root for details.
 */

/**
 * @section HeaderUsage Header Usage
 *
 * This header is included by modules defining an orchestrator (main) and 
 * testing functions for testing, e.g., a feature, API, or a project implementation.
 * It provides declarations, definitions (other than non-inline function definitions
 * provided by britetest_runner.c in the repository src directory).
 *
 * See README.md in the repository root directory for an introduction to BriteTest.
 *
 * See BriteTest Docucmentation Guide for ,,,
 *
 * @note BriteTest requires POSIX.1-2001 (IEEE Std 1003.1-2001) compatibility and a
 *       C99-compliant compiler. Linux, macOS, and the BSD family natively meet these
 *       requirements. Windows requires a POSIX compatibility layer such as Cygwin,
 *       MSYS2, or WSL.
 *
 * @note BriteTest Runner has been exercised in a POSIX environment; however, users must
 *       confirm correct behavior in their own environment.
 */

/**
 * @section RunnerVersonMacro Runner Version Macro
 *
 * @name BT_RUNNER_VERSION
 *
 * @brief Version for britetest_runner.h which must be the same as
 *.       BT_RUNNER_VERSION_C for britetest_runner.c.
 *
 * The version is a literal string of type char[n], where n is
 * between 5 and 9 (including the terminating null character).
 * 
 * Format: "M.m.p", where M, m, and p are one or two digits.
 * 
 * M is the major version, m is the minor version, and p is the patch version.
 *
 * The major version is incremented for major additions, removal of
 * deprecated features, or unavoidable incompatible API changes.
 *
 * The minor version is incremented for backward-compatible additions or
 * deprecating features.
 *
 * The patch version is incremented for bug fixes or internal improvements.
 */
 
#define BT_RUNNER_VERSION "1.0.0"

/**
 * @section ChangeHistory Change History
 *
 * 2026/09/27 Initial version "1.0.0.".
 *
 **/

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
 * @section Enums
 */

typedef enum
{
  // Success
    BT_OK = 0,
    
  // Compare
    BT_LESS = -1,
    BT_EQUAL = 0,
    BT_GREATER = 1,
    
  // Boolean
    BT_FALSE = 0,
    BT_TRUE = 1,

  // -100 to -199: Invalid Usage.
    BT_INVALID = -100,
    BT_INVALID_ARG = -101,
    BT_INVALID_ARG_VERSION = -102,
    BT_INVALID_ARG_TOO_LONG = -103,

  // -300 to -399: Failed system call.
    BT_SYSTEM = -300,
    BT_SYSTEM_OPEN = -301,
    BT_SYSTEM_READ = -302,
    BT_SYSTEM_WRITE = -303,
    BT_SYSTEM_FORK = -304,
    BT_SYSTEM_THREAD = -305
} bt_return_code_t;

/**
 * @section UtilityMacros Utility Macros
 */

#if defined(BT_STATIC_ASSERT))
#error "britetest_runner.h: An BT_STATIC_ASSERT " \
       "macro is unexpectedly already defined. " \
       "#undef before including britetest_runner.h."
#endif // defined macro

/*
 * @defgroup TokenPaste Token Paste
 *
 * @name BT_TOK_PASTE
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
 * @note Macro BRITETEST_TOK_PASTE_INTERNAL is defined to implement expanding
 *       the tokens for BT_TOK_PASTE. It is not intended for direct use.
 *.      Instead use the ## operator.
 * 
 * @note A preprocessor error is raised if either of these macros
 *       are already defined before including this header.
 * @{
 */

// Paste tokens without expanding.

#define BRITETEST_TOK_PASTE_INTERNAL(t1, t2) a##b

// Expand tokens before pasting.

#define BT_TOK_PASTE(t1, t2) BRITETEST_TOK_PASTE_INTERNAL(t1, t2)

/** @} */

/**
 * @defgroup TokenStringify Token Stringify
 *
 * @name BT_TOK_STR
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
 * @note Macro BRITETEST_TOK_STR_INTERNAL is defined to implement expanding
 *       the token for BT_TOK_STR. It is not intended for direct use.
 *       Instead use the # operator.
 * 
 * @note A preprocessor error is raised if either of these macros
 *       are already defined before including this header.
 * @{
 */

// Stringify token without expanding.
#define BRITETEST_TOK_STR_INTERNAL(t) #s
// Expand token before stringifying.
#define BT_TOK_STR(t) BRITETEST_TOK_STR_INTERNAL(t)

/** @} */

/**
 * @name BT_STATIC_ASSERT
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
BT_STATIC_ASSERT(sizeof(int) == 4, int_must_be_4_bytes);
 * @endcode
 * For C99, if assertion is true (and the type is not already defined), expands to:
 * @code
typedef char BT_STATIC_ASSERT_int_must_be_4_bytes[1];
 * @endocde
 * And the type is defined (which can be ignored).
 *
 * Or if false, expands to:
 * @code
typedef char BT_STATIC_ASSERT_int_must_be_4_bytes[-1];
 * @endcode
 *  Compiler error raised due to typedef statement with an
 *  invalid array bound -1.
 */

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L

// C11 and later: use the built‑in assertion macro.
#define BT_STATIC_ASSERT(cond, msg) _Static_assert(cond, #msg)

#else

// C99: typedef with invalid negative array size if assertion not satisfied.

#define BT_STATIC_ASSERT(cond, msg) \
    typedef char BT_TOK_PASTE(BT_STATIC_ASSERT_, msg)[(cond) ? 1 : -1]

#endif

/**
 * @section BriteTestVersionMacros BriteTest Version Macros
 */

/**
 * @defgroup BriteTestVersionMacros BriteTest Version Macros
 *
 * @name BT_VERSION_MAJOR, BT_VERSION_MINOR, BT_VERSION_PATCH,
 *       BT_VERSION_NUM, BT_VERSION_HEX, 
 *       BT_VERSION_CMP
 *
 * @brief Version macros for BriteTest (britetest_runner.h and britetest_runner.c):
 * @{
 */

#if !defined(BT_TEST_VERSION)

int britetest_get_runner_major_internal(v);
#define BT_VERSION_MAJOR britetest_get_runner_major_internal()

int britetest_get_runner_minor_internal(v);
#define BT_VERSION_MINOR britetest_get_runner_minor_internal((v))

int britetest_get_version_patch_internal(v);
#define BT_VERSION_PATCH britetest_get_runner_patch_internal((v))

// BriteTest version as an integer for comparisons.

int britetest_get_runner_num_internal(v);
#define BT_VERSION_NUM britetest_get_runner_num_internal((v))

// BriteTest version encoded as 0xMMmmpp (major, minor, patch) for display/debug.

int britetest_get_runner_hex_internal(v);
#define BT_VERSION_HEX britetest_get_runner_hex_internal((v))

// BriteTest version compared to specified version (1 if true, otherwie 0).

int britetest_runner_cmp_internal
( const char *v1, const char *v2 );
#define BT_VERSION_CMP(v1, v2) britetest_runner_cmp_internal((v1), (v2))

#endif

/** @} */ // End of Version Macros.

/**
 * @section Limits
 */

/**
 * @name BT_MAX_PATH_LEN, BT_MAX_FILENAME_LEN, BT_MAX_LEVEL
 * 
 * @brief Maximum values for path length, filename length,
 *        and guard levels.
 */

#define BT_MAX_PATH_LEN      ((size_t)4096)
#define BT_MAX_FILENAME_LEN  ((size_t)255)
#define BT_MAX_LEVEL         ((size_t)32)

/**
 * @section resubt_t Result Type
 */

/**
 * @name bt_resubt_t
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
} bt_resubt_t;

/**
 * @name bt_state_t
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
  bt_state_t parent;
  bt_state_t prev;
  bt_state_t next;
} bt_state_t;

/**
 * @name BT_PRINT_ERR_HELP(err)
 *
 * @brief Print err and help text to stdout.
 *        err is prefixed with bt_err_prefix().
 *.       help text is formed using bt_usage() and bt_help().
 *
 * @param err Pointer to error string.
 * @param help 0: don't print help text.
 *             non-zero: print help text.
 *
 * @note Use bt_set_err_prefix() to set the prefix.
 *
 * @note Use bt_set_usage() and/or bt_set_help() to
 *       define the help text.
 */

void britetest_print_err_help_internal
( char *err, char help,
  char *func, char *file, int line,
  britetest_state_internal_t *const state
);

#define BT_PRINT_ERR_HELP(err, help) \
  do \
  { \
    britetest_print_err_help_internal \
      ( \
       (err), (help) \
       __func__, __FILE__, __LINE__, \
       britetest_state_internal \
      ); \
   } while (0)

// Customization: Get and set.

char *bt_executable_name(void);
void bt_set_executable_name(char *en);
char *bt_defaubt_dirpath(void);
void bt_set_defaubt_dirpath(char *dp);
char *bt_err_prefix(void);
void bt_set_err_prefix(char *pe);
char *bt_args_options(void);
void bt_set_args_options(char *ao);
char *bt_usage(void):
void bt_set_usage(char *u);
char *bt_help(void);
void bt_set_help(char *h);

// Customization Helper Functions

size_t bt_currentlevel(void);
bt_resubt_t bt_currentresult(void);
bt_total_t bt_currenttotal(void);
size_t bt_maxparallel(size@_t level);
size_t bt_currentparallel(void);}
int bt_isisolated(void);
int bt_isthreadisolated(void);
int bt_isprocessisolated(void);
size_t bt_groupid(void);
char *bt_groupname(void);

char *bt_project(void);
size_t bt_maxargs(void);
char *bt_title(void);
size_t bt_categoryid(void);
char *bt_category(void);
char *bt_funcname(void);
char *bt_notes(void);
char *bt_assertexpression(void);
char bt_inject(void);
char bt_isolation(void);
char bt_orchestrator(void);
char bt_testfunction(void);
char bt_assert(void);

char *bt_dirpath(void);
char *bt_filepath(void);
char *bt_filename(void);

// 1 true, 0 false
int bt_isfilename(char *name);

// 1 true, 0 false, -1 not a directory path
int bt_isreaddirpath(char *path);
int bt_iswritedirpath(char *path);

// 1 true, 0 false, -1 not a file path
int bt_isreadfilepath(char *path);
int bt_iswritefilepath(char *path);

/**
 * @name bt_current_time
 * @brief Get the current time as a formatted string.
 *
 * @param current_time Buffer to store the formatted time string.
 * @param size Size of the buffer.
 * 
 * @return void. On error, current_time is set to "unknown time".
 */

void bt_current_time(char *current_time, size_t size);

/**
 * @name BT_GROUP
 *
 * @brief A macro to call a test group function with a fault guard.
 *
 * - BT_GROUP(funcname, [isolation])[;]
 *
 * The semicolon is omitted if used as an argument to the BT_WRITE_RESULT macro;
 * otherwise it is required.
 *
 * The BT_GROUP macro provides an interface for running a group of tests with
 * built-in fault recovery using the multi-level guard infrastructure:
 *
 * Result counts and totals updated.
 *
 * @param func Pointer to test function.
 * @param isolation 0: same thread (no paralleliam)
 *                  1: separate thread.
 *                  2: separate process.
 * 
 * @note If no signal, bt_resubt_t result from test function is used.
 *       If signal caught, (bt_resubt_t){0, 0, SIZE_MAX, 0, 0} is used.
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
 * @note Typically, the orchestrator (main) function uses the BT_GROUP macro
 *       to execute a test group function. The BT_TEST macro may be used in the
 *       orchestrator function, but it is more common for test group functions
 *       to use these macros.
 * 
 * @example In the orchestrator module (e,g., test_britetest.c) to
 *          run the test function in a test module (e.g., test_orchestrator.c):
 *
 * @code
BT_GROUP(test_guard_2, 0);
 * @endcode
 */

#define BT_GROUP(func, isolation, maxparallel) \
   { t_resubt_t func(bt_state_t *britetest_state_internal); \
     britetest_group_internal(funcname, #funcname); }

/**
 * @name BT_TEST
 *
 * @brief Evaluates expression with a fault guard and updates the
 *        totals for pass/fail/fault:
 *
 * - BT_TEST(expression, include, [isolation])[;]
 *
 * The semicolon is omitted if used as an argument to the BT_WRITE_RESULT macro;
 * otherwise it is required.
 *
 * The BT_TEST macrosprovides an interface for running tests with
 * built-in fault recovery using the multi-level guard infrastructure:
 */
 *
 * - If expression is true (non-zero), increments pass count.
 * - If expressions is false (zero), increments fail count.
 * - If fault, incremenet fault count
 *
 * @param expression The expression to evaluate.
 * @param include I or 0 to 9.
 * @param isolation 0: same thread (no paralleliam)
 *                  1: separate thread.
 *                  2: separate process.
 *
 * @note The BT_TEST macro uses a guard to capture a fault that may occur during the
 *       evaluation of expression. If a fault is causght, it counts as a fault.
 * 
 * @note For fail and fault, a message is appended to the test report.
 *       The message includes expression, filename of the module, and
 *       line number for debugging purposes.
 *
 * BT_TEST with I argument value for include:
 *
 * - Only executes if injection is enabled (see @ref IOption `-I` Option.
 * - Result is counted as an injected pass/fail/fault.
 *
 * Special values that can be used in any expression:
 *
 * - BT_PASS: returns 1.
 * - BT_FAIL: returns 0.
 * - BT_FAULT(type): causes a fault of the specified type:
 *.                  1 (`SIGSEGV`). 2 (`SIGABRT`), 3 (`SIGBUS`).
 * 
 * For other values of type, BT_FAULT returns 0.
 *
 * @note Typically, a test group function uses the BT_TEST macro. A test group
 *       function may also use the BT_GROUP macro.
 * 
 * @example
 * @code
BT_TEST(func("hello", 'l') == 2, 0);
 * @endcode
 */

#define BT_TEST(expression, include, isolation) \
  do \
   { int func_assert( void ) { return (int)(assert_expr); }
     britetest_guarded_assert_expr_internal
         (&func_assert, #assert_expr, __FILE__, __LINE__)


     britetest_guard_internal_t test_guard = { 0 }; \
     test_guard.handler = britetest_guard_handler_internal; \
     britetest_install_guard_internal(&test_guard); \
     if (sigsetjmp(test_guard.env, 1) == 0) \
     { test_guard.active = 1; \
	if (assert_expr)
       { ++test_result.pass; } \
	else \
	{ ++test_result.fail; \
         britetest_print_resubt_internal \
           (1, #assert_expr, __FILE__, __LINE__); \
       } \
       test_guard.active = 0; \
     } \
     else \
     { ++test_result.fault; \
	britetest_print_resubt_internal \
           (-1, #assert_expr, __FILE__, __LINE__); \
     } \
     britetest_restore_guard_internal(); \
   } while (0)

/**
 * @name BT_DECLARE_ORCHESTRATOR(funcmame)
 * 
 * @brief Declare the orchestrator (main) function as a forward teference by
 *        following it with a semicolum or follow it  with a functio
 *        body to define the orchestrator function.
 *       The orchestrator macro provides an API for .
 *
 * @param funcname Name of the function. funcname must be main.
 *
 * @note Compile-time error occurs if the macro is not syntactically
 *       allowed in this context.
 *
 * Typically, the orchestrator (main) function uses the BT_GROUP macro
 * to execute a test group function. The BT_Test macro may be used in the
 * test orchestrator, but it is more common for test group functions to use
 * the BT_Test macro.
 *
 * @example Orchestrator function:
 * @code
BT_DECLARE_ORCHESTRATOR(main)
{ 
  BT_PARSE_ARGS ("BriteTest_test_report.txt");

  BT_INIT_ORCHESTRATOR(britetest, 1);
  
  BT_OPEN_REPORT("BriteTest");
 
  BT_WRITE_RESULT(BT_TEST(test_orchestrator), "Orchestrator Tests");

  BT_TEST(test_guard1);
  BT_WRITE_RESULT(BT_TEST(test_guard2), "Guard Tests 1 and 2");

  BT_CLOSE_REPORT;

  BT_RETURN_STATUS;
}
 * @endcode
 *
 * @example Forward-reference
 * @code
BT_DECLARE_ORCHESTRATOR(main);
 * @endcode
 *
 * @example Function Definition
 * @code
BT_DECLARE_TEST_FUNCTION(main)
{ /* orchestrator (main) function body*/ }
 * @endcode
 */

#define BT_DECLARE_ORCHESTRATOR(funcnane) \
    void funcname \ return int?
    ( britetest_lcl_state_internal_t *const britetest_lcl_state_internal )

/**
 * @name BT_INIT_ORCHESTRATOR
 * 
 * @brief Initialize the orchestrator.
 *
 *        Exits the executable if the macro is not allowed in this context.
 * 
 * @param funcname Name of the function which must be main.
 * @param project Single token project identifier.
 * @param maxparallel Value must be at least 1.
 *
 * @note Compile-time error occurs if the macro is not followed by a semicolon or
 *       the macro is not syntactically allowed in this context.
 *
 * @example
 * @code
BT_INIT_ORCHESTRATOR(main, BriteTest, 1);
 * @endcode
 */

void britetest_init_orchestrator_internal
( char *funcname,
  char *func, char *file, int line,
  britetest_state_internal_t *const state,
  britetest_lcl_state_internal_t *const lcl_state
);

#define BT_INIT_ORCHESTRATOR(funcname) \
  typedef int bt_use_BT_INIT_ORCHESTRATOR_once; \
  britetest_state_internal_t britetest_state_internal; \
  britetest_lcl_state_internal_t britetest_lcl_state_internal; \
  do \
  { \
    britetest_init_orchestrator_internal \
    ( #funcname, \
      __func__, __FILE__, __LINE__, \
      &britetest_state_internal, \
      &britetest_lcl_state_internal \
      ); \
  } \
  while (0)

/**
 * @name BT_PARSE_ARGS
 * 
 * @brief Parse optionss and the first two arguments (executabe name and PATH).
 *
 * @note Compile-time error occurs if the macro is not followed by a semicolon or
 *       the macro is not syntactically allowed in this context.
 *
 * @example
 * @code
BT_PARSE_ARGS(2, "");
 * @endcode
 * @{
 */

void britetest_parse_args_internal
( const int argc, const char *const *const argv,
  const size_t maxargs, char *const defaultfilenamename,
  char *func, char *file, int line,
  britetest_state_internal_t *const state
);

#define BT_PARSE_ARGS(maxargs, defaultreportfilename) \
  do \
  { \
    britetest_parse_args_internal \
    ( argc, argv,
      (maxargs), (defaultreportfilename), \
      __func__, __FILE__, __LINE__, \
      &britetest_state_internal \
      ); \
  } \
  while (0)

/**
 * @name BT_OPEN_REPORT
 * 
 * @brief Open report file, open tmp file, and write header lines.
 *
 *        Exits the executable if the macro is not allowed in this context.
 * 
 * @param title Pointer to a string of customized title lines for the report.
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
BT_OPEN_REPORT("BriteTest Test Report %t\n");
 * @endcode
 * @{
 */

void britetest_open_report_internal
( const char *const title,
  char *func, char *file, int line,
  britetest_state_internal_t *const state
);

#define BT_OPEN_REPORT(reporttitle) \
  typedef int bt_use_BT_OPEN_REPORT_once; \
  do \
  { \
    britetest_open_report_internal \
    ( (title), \
      __func__, __FILE__, __LINE__, \
      &britetest_state_internal \
    ); \
  } \
  while (0)

/**
 * @def BT_WRITE_RESULT
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
    BT_WRITE_RESULT(BT_TEST(test_orchestrator), "orchestrator");
 * @endcode
 *
 * @example Write results for a category with one test function (alternate):
 * @code
 BT_TEST(test_orchestrator);
 BT_WRITE_RESULT(, "orchestrator");
 * @endcode
 *
 * @example Write results for a category with two test functions:
 * @code
    BT_TEST(test_guard1);
    BT_WRITE_RESULT(BT_TEST(test_guard2), "guard 1 and 2");
 * @endcode
 *
 * @example Write results for a category with two test functions (alternate):
 * @code
BT_TEST(test_guard1);
BT_TEST(test_guard2);
BT_WRITE_RESULT(, "guard 1 and 2");
 * @endcode
 */

void britetest_write_resubt_internal
( const char *const label,
  char *func, char *file, int line,
  britetest_lcl_state_internal_t *const lcl_state
);

#define BT_WRITE_RESULT(t, label) \
  do \
  { \
    britetest_write_resubt_internal \
    ( (label),
      __func__, __FILE__, __LINE__, \
      &britetest_state_internal \
    ); \
  } \
  while (0)

#define BT_WRITE_RESULT(t, label) \
  do \
  { t; \
    ++category_id; \
    char label_buf[96]; \
    const char *_label = categorylabel_with_inject_tag( \
             (label), result, inject, label_buf, sizeof(label_buf)); \
    britetest_write_resubt_internal(report, categoryid, categorylabel, result); \
    total = (bt_resubt_t) \
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
 * @name BT_CLOSE_REPORT
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
 BT_CLOSE_REPORT("guard: fault detection mechanism,\n"
                 "orchestrator: main function to run testd.\n");
 * @endcode
 * @{
 */

void britetest_close_report_internal
( const char *const notes,
  char *func, char *file, int line,
  britetest_state_internal_t *const state
);

#define BT_CLOSE_REPORT(notes) \
  typedef int bt_use_BT_CLOSE_REPORT_once; \
  do \
  { \
    britetest_ lose_report_internal \
    ( (notes), \
      __func__, __FILE__, __LINE__, \
      &britetest_state_internal \
    ); \
  } \
  while (0)

/** @} */

/**
 * @name BT_EXIT_ORCHESTRATOR
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
 BT_EXIT_ORCHESTRATOR(main);
 * @endcode
 */

void britetest_exit_orchestrator_internal
( const char *const funcname,
  char *func, char *file, int line,
  britetest_state_internal_t *const state
);

#define BT_EXIT_ORCHESTRATOR(notes) \
  typedef int bt_use_BT_CLOSE_REPORT_once; \
  do \
  { \
    britetest_ lose_report_internal \
    ( (notes), \
      __func__, __FILE__, __LINE__, \
      &britetest_state_internal \
    ); \
  } \
  while (0)

#define BT_EXIT(funcname) \
    do \
    { \
      if (!strcmp(__func__, "main")) \
      { \
        fprintf(stdout, "[ERROR] BT_EXIT is not in the "
                        "orchestrator (main) function.\n"); \
        exit(BT_MACRO_MISPLACED); \
      } \
      exit(britetest_exit_internal \
             (__func__, #funcname, britetest_state_internal, (notes)); \
    while (0)

/**
 * @name BT_DECLARE_GROUP(funcname)
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
    BT_DECLARE_TEST_FUNCTION(test_guard1);
 * @endcode
 *
 * @example Function Definition
 * @code
 BT_DECLARE_TEST_FUNCTION(test_guard1)
 { /* test_guard1 function body*/ }
 * @endcode
 */

#define BT_DECLARE_GROUP(funcnane) \
    void funcname \
    ( britetest_lcl_state_internal_t *const britetest_lcl_state_internal )

/**
 * @name BT_INIT_TEST_FUNCTION
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
 BT_INIT_TEST_FUNCTION(test_guard1);
 * @endcode
 */

#define BT_INIT_TEST_FUNCTION(funcname) \
    do \
    { \
      if (!strcmp(__func__, "main" || !strcmp(#funcname, "main")) \
      { fprintf(stdout, "[ERROR] BT_INIT_TEST_FUNCTION is NOT allowed "
                        "in the orchesrator (main) function.\n"); \
        exit(BT_MACRO_MISPLACED); \
      } \
      int rc = britetest_init…test_function_internal \
                 (__func__, #funcname, britetest_lcl_state_internal) \
      if (rc) exit(rc);
    } while (0)

/**
 * @name BT_RETURN
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
 BT_RETURN(test_guard1);
 * @endcode
 */

#define BT_RETURN(funcname) \
    do \
    { \
      if (!strcmp(__func__, "main")) \
      { \
        fprintf(stdout, "[ERROR] BT_RETURN is NOT allowed "
                        "in the orchestrator (main) function.\n"); \
        exit(BT_MACRO_MISPLACED); \
      } \
      int rc = britetest_return_internal \
                 (__func__, #funcname, britetest_lcl_state_internal) \
      if (rc) exit(rc); \
      return; \
    while (0)

#if defined(__cplusplus)
}
#endif

// End of britetest_runner.h
