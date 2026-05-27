/**
 * @file /paulsinclair51/include/litetest.h
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
 * - A tewt macros with reusable signal-guard mechanism based on sigsetjmp/siglongjmp
 *   to capture faults:
 * 
 * - `TEST(assert_expr)`
 * 
 * - `TESTS(func, inject)`
 * 
 * - `TESTSMERGE(func1, func2, inject)`.
 *
 * - `TESTFAIL(inject)
 *
 * - `TESTFAULT(inject)`
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

/**
 * @section HeaderUsage Header Usage
 * 
 * In the test orchestration source file (for example, test_lubtype.c)
 * include the following:
 *
 * @code
#if !defined(TEST_ORCHESTRATOR)
#define TEST_ORCHESTRATOR
#endif
#include "litetest.h"
 * @endcode
 *
 * Use the Orchestrator variables and functions defined in this header
 * in the test orchestration logic plus the RUN macro to execute test
 * categories and result_t type defined in this header.
 * 
 * In the other test source files (e.g., test_count.c and test_skip.c),
 * include the following:
 *
 * @code
 * #undef TEST_ORCESTRATOR
 * #include "litetest.h"
 * @endcode
 * 
 * Use test macros in the test
 * modules.
 *
 * @section BuildTestExecutable Build the test executable
 * 
 * - Linux/macOS: make
 * 
 *   Defaults to use Makefile in the current directory.
 * 
 * - Windows PowerShell: .\build_test_lubtype.ps1
 *
 * @section FaultGuarding Fault Guarding
 *
 * The test framework uses a multi-level fault (up to 10 levels)
 * guarding approach to catch unexpected termination due to a
 * fault (i.e., segmentation fault, bus error, or abort) during
 * test execution.
 * 
 * A test macro wraps a guard around its argument, enabling
 * detection of a fault not handled at a lower level
 * by the argument rather than aborting.
 * This allows counting pass, fail,
 * and fault without aborting due to a fault.
 * 
 * A fault detected by TESTS or TESTSMERGE represent a fault
 * in the use of the testing
 * framework or in the testing framework itself, and not in
 * the feature being tested.Such a fault is expected to be
 * rare but guarding is provided to avoid an abort if it does.
 */

#if !defined(LITETEST_H)
#define LITETEST_H

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

/**
 * @section Limits
 */

/**
 * @name MAX_PATH_LEN, MAX_FILENAME_LEN, MAX_GUARD_LEVEL
 * 
 * @brief Maximum values for path length, filename length,
 *        and guard levels.
 */

enum
{ MAX_PATH_LEN = 4096,
  MAX_FILENAME_LEN = 255,
  MAX_GUARD_LEVEL = 10
};

/**
 * @section result_t Result Type
 */

/**
 * @name result_t
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
} result_t;

/**
 * @section Guard Infrastructure
 * 
 * The guard infrastructure provides a mechanism to catch signals such as SIGSEGV,
 * SIGABRT, and SIGBUS that may occur during the evaluation of test macros
 * It uses sigsetjmp and siglongjmp to return control
 * to a known point in the code when a signal is caught, allowing the test framework
 * to count faults and continue running other tests instead of aborting the entire
 * test suite.
 * 
 * Type and and static variable names are prefixed with  "internal_".
 * 
 * Function names in the guard infrastructure are suffixed with "_internal".
 * 
 * The guard infrastructure is not intended to be used directly by test
 * modules or the test orchestrator, but is used by the RUN and TEST macros.
 */

/**
 * @name internal_sighandler_t
 * 
 * @brief Type for signal handlers used in the guard infrastructure.
 *
 * @details internal_sighandler_t type is defined as a pointer to a function that takes
 * an int signal number as a parameter and returns void. This type is used for the
 * handler function pointer in the guard structure and for saving/restoring signal
 * handlers in the guard installation and restoration functions.
 * 
 * The internal_sighandler_t type ensures that the guard mechanism can properly
 * manage signal handlers for SIGSEGV, SIGABRT, and SIGBUS.
 * 
 * The use of internal_sighandler_t allows the guard mechanism to be flexible and compatible
 * with the signal handling conventions of this framework.
 */

typedef void (*internal_sighandler_t)(int);

/**
 * @name internal_guard_t
 * 
 * @brief Structure for a guard used to capture signals and manage
 *        state for fault recovery.
 */

typedef struct
{ void (*handler)(int sig);
  sigjmp_buf env;
  volatile sig_atomic_t active;
} internal_guard_t;

/**
 * @name internal_saved_guard_t
 * 
 * @brief Structure for saving the current guard when a guard 
 *        at a lower level is installed.
 */

typedef struct
{ internal_guard_t *guard;
  internal_sighandler_t segv_handler;
  internal_sighandler_t abrt_handler;
  internal_sighandler_t bus_handler;
} internal_saved_guard_t;

/**
 * @name internal_guard
 * 
 * @brief Pointer to the current guard used for signal handling
 *        and fault recovery.
 * 
 * @note Current guard is accessible internally by the guard
 *       infrastructure in the orchestrator and test modules.
 *       It is defined only in the orchestrator module.
 */

extern internal_guard_t *internal_guard;

/**
 * @name saved_guards, internal_num_saved_guards
 * 
 * @brief Array of saved guards and the number of saved guards.
 *  Array of saved guards (one for the entire test suite).
 * 
 * @note These are accessible internally by the guard infrastructure
 *       in the orchestrator and test modules. It is defined only
 *       in the orchestrator module.
 * @{
 */

extern internal_saved_guard_t saved_guards[MAX_GUARD_LEVEL];
extern size_t internal_num_saved_guards;

/** @} */

/**
 * @name guardhandler_internal
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

static inline void guard_handler_internal(int sig)
{ if (internal_guard && internal_guard->active)
  { internal_guard->active = 0; siglongjmp(internal_guard->env, sig ? sig : 1); }

  /* Fault outside of active guard or misuse of guard framework. */
  abort();
}

/**
 * @name install_guard_internal
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

void install_guard_internal(internal_guard_t *new_guard);

/**
 * @name restore_guard_internal
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

void restore_guard_internal(void);

/**
 * @name tests_internal
 * 
 * @brief Internal function used by the RUN macro: runs func
 *        capturing a fault, if one occurs, with a guard.
 * 
 * @param func Pointer to the test function to run, which takes a
 *             char inject parameter and returns a result_t.
 * @param merge Flag to indicate merge results.
 *              0: don't merge.
 *              1: merge.
 * @param inject Flag to pass to the test function.
 *                 0: normal run.
 *                 1: enable inject fail/fault tests, if any, in the function.
 * @param func_name Name of the function being run, used for error messages.
 * 
 * @return result_t result from test function or
 *         (result_t){0, 0, SIZE_MAX, 0, 0} if a fault occurs.
 */

result_t tests_internal
( result_t (*func)(char),
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
 * @name current_guard_level
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

 static inline size_t guard_level(void)
 { return internal_num_saved_guards + (internal_guard ? 1 : 0); }

/**
 * @name  is_current_guard_active
 * @brief Check if the current guard is active.
 * 
 * @return 1 if the current guard is active
 *         0 if current guard is not active.
 *        -1 if there is no current guard.
 */

  static inline int is_current_guard_active(void)
  { return internal_guard ? internal_guard->active : -1; }

/**
 * @section Test Macros
 * 
 * The test macros (TEST, TRSTS, TESTSMERGE, TESTFAIL, and TESTFAULT
 * provide a convenient interface for running tests with
 * built-in fault recovery using the multi-levrl guard infrastructure:
 * 
 * - Typically, the test orchestrator uses the TESTS and TESTSMERGE
 *   macros to oexecute the test function in a test module and does not use
 *   the other 3 macros. The TEST, TESTFAIL, and TESTFAULT macros may be used in the
 *   test orchestrator, but it is more common for test category modules to
 *   use these macros.
 * 
 * - Typically, test modules use the TEST, TESTFAIL, and TESTFAULT macros.
 *   A test module may also use the TESTS and TESTSMERGE macros
 *   for a test that can not reasonably be expressed
 *   as a single assertion, such as a test that involves
 *   multiple steps, looping, or requires setup and teardown.
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
 * @note If no signal, result_t result from test function is used.
 *       If signal caught, (result_t){0, 0, SIZE_MAX, 0, 0} is used.
 * 
 * @note If a fault is captured, a message is printed to stderr
 *       including the function name, file name, and line number
 *       for debugging purposes.
 * 
 * @note A fault is considered a fault in the testing framework or in the use of the
 *       testing framework, rather than a fault in the feature being tested. The use
 *       of SIZE_MAX for the fault count allows the caller to distinguish between
 *       a function-level fault and faults counted by the function itself.
 * 
 * @example In the orchestrator module (e,g., test_litetest.c) to
 *          run the test function in a test module (e.g., test_guards.c):
 *
 * @code
 TESTS(test_guards, inject);
 * @endcode
 */

#define TESTS(func, inject) \
  result_t func(char inject); \
  tests_internal(func, 0, inject, #func);

/**
 * @name TESTSMERGE
 * 
 * @brief A macro to run two functions each with a guard and
          merge their results.
 *
 * After setting up a guard to capture a fault (SIGABRT, SIGSEGV,
 * or SIGBUS), calls the function pointed to by parameter func1
 * with parameter inject, calls the function pointed to by parameter
 * func2 and merges their results. If a fault occurs, siglongjmps back to
 * the guard point.
 *
 * @param func1 Pointer to function 1.
 * @param func2 Pointer to function 2.
 * @param inject Flag to pass to the function.
 *               0: normal run.
 *               1: enable inject fail/fault tests, if any, in the function.
 * 
 * @botr If no signal, the merged result from the test functions is used.
 *         If signal caught, (result_t){0, 0, SIZE_MAX, 0, 0} is used.
 * 
 * @note If a fault is captured, a message is printed to stderr
 *       including the function name, file name, and line number
 *       for debugging purposes.
 * 
 * @note A fault is considered a fault in the testing framework or in the use of the
 *       testing framework, rather than a fault in the feature being tested. The use
 *       of SIZE_MAX for the fault count allows the caller to distinguish between
 *       a function-level fault and faults counted by the function itself.
 * 
 * @example In the orchestrator module (e,g., test_litetest.c) to
 *          run the 2 test functions (e.g., test_guards_1.c and
 *          test_guards_2.c) and merge their results:
 *
 * @code
 result_t result = TESTSMERGE(test_guards_1, test_guards_2, inject);
 * @endcode
 */

#define TESTSMERGE(func1, func2, inject) \
  result_t func1(char inject); \
  tests_internal(func1, 0, inject, #func1);
  result_t func2(char inject); \
  tests_internal(func2, 1, inject, #func2);

/**
 * @name TEST
 * @brief Test an assert expression with fault recovery.
 *
 * Evaluates assert_expr and updates test_result counters for pass/fail/fault.
 * If assert_expr is true, increments pass count; if false, increments fail count
 * and prints a message to stderr. If a signal occurs during evaluation, increments
 * fault count and prints a message to stderr.
 *
 * @param assert_expr The expression to evaluate as a test assertion.
 *
 * @note The TEST macro uses a guard to capture signals that may occur during the
 *       evaluation of assert_expr. If a signal is caught, it counts as a fault.
 *       The macro also prints messages to stderr for failed assertions and faults,
 *       including the expression, file name, and line number for debugging purposes.
 * 
 *
 * @example In a test module (e.g., test.func.c):
 * 
 * @code
 result_t test_count(const char inject)
 { result_t result = {0, 0, 0, 0, 0};
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

extern char internal_run_id;
extern result_t internal_total;
extern char *internal_executable_name;
extern const char internal_default_path_msg[];
extern const char *path_msg;

static inline char current_run_id(void)
{ return internal_run_id; }

static inline result_t current_total(void)
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
  result_t result
);

const char *category_label_with_inject_tag
( const char *base_label,
  result_t result,
  char inject,
  char *label_buf,
  size_t label_buf_len
);

FILE *open_report(const char *report_path, const char *report_title);
int close_report
( FILE *report,
  result_t total,
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
 * @param result_expr An expression that evaluates to a result_t struct containing
 *                   the pass/fail/fault counts for the test category. * 
 * @note If result_expr has a category-level fault (fault == SIZE_MAX), the
 */

#define REPORT(label, result_expr) \
  do \
  { ++cat_id; \
    result_t result = (result_expr); \
	  char label_buf[96]; \
	  const char *_label = category_label_with_inject_tag( \
	   					 (label), result, inject, label_buf, sizeof(label_buf)); \
	  write_category(report, cat_id, _label, result); \
    total = (result_t) \
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

#endif // !defined(LITETEST_H)

// End of litetest.h
