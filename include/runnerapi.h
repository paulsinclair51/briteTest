/**
 * @file /include/runnerapi.h
 *
 * @brief Runner API declarations.
 *
 * This header declares the Runner API that can be used
 * to orchestrate test execution, report generation, and
 * result aggregation.
 *
 * Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * See LICENSE in the repository root for details.
 */ /**
 * @file src/runnerapi.h
 *
 * @mainpage Runner API Function Declarations
 *
 * This file provides declarations for the Runner API.
 *
 * For an overview of the Runner Framwork and API, see the
 * README.md file in the repository root directory.
 * See src/runnerapi.c for the API definitions.
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see LICENSE in the repository root directory.
 */

#pragma once

#include <setjmp.h>
#include <signal.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(__cplusplus)
extern "C" {
#endif

#define RA_RUNNER_VERSION "1.0.0"
#define RA_RUNNER_VERSION_C "1.0.0"

#define RA_MAX_PATH_LEN ((size_t)4096)
#define RA_MAX_FILENAME_LEN ((size_t)255)
#define RA_MAX_LEVEL ((size_t)32)

typedef enum {
  RA_LESS = -1,
  RA_EQUAL = 0,
  RA_GREATER = 1,
  RA_FALSE = 0,
  RA_TRUE = 1,
  RA_INVALID = -100,
  RA_INVALID_ARG = -101,
  RA_INVALID_ARG_VERSION = -102,
  RA_INVALID_ARG_TOO_LONG = -103,
  RA_SYSTEM = -300,
  RA_SYSTEM_OPEN = -301,
  RA_SYSTEM_READ = -302,
  RA_SYSTEM_WRITE = -303,
  RA_SYSTEM_FORK = -304,
  RA_SYSTEM_THREAD = -305,
  RA_MACRO_MISPLACED = -1000
} ra_return_code_t;

typedef struct {
  size_t pass;
  size_t fail;
  size_t fault;
  size_t injected_fail;
  size_t injected_fault;
} ra_result_t;

/* Backward-compatible alias kept for older code that used the misspelled name. */
typedef ra_result_t ra_resubt_t;
typedef ra_result_t ra_total_t;
typedef ra_result_t (*ra_test_fn)(void);

extern jmp_buf ra_internal_assert_jmp;
void ra_internal_assert_signal_handler(int signo);

#define RA_INTERNAL_TOK_PASTE_INTERNAL(a, b) a##b
#define RA_TOK_PASTE(a, b) RA_INTERNAL_TOK_PASTE_INTERNAL(a, b)
#define RA_INTERNAL_TOK_STR_INTERNAL(t) #t
#define RA_TOK_STR(t) RA_INTERNAL_TOK_STR_INTERNAL(t)

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#define RA_STATIC_ASSERT(cond, msg) _Static_assert((cond), #msg)
#else
#define RA_STATIC_ASSERT(cond, msg) typedef char RA_TOK_PASTE(ra_static_assert_, msg)[(cond) ? 1 : -1]
#endif

int ra_internal_get_runner_major_internal(const char *v);
int ra_internal_get_runner_minor_internal(const char *v);
int ra_internal_get_runner_patch_internal(const char *v);
int ra_internal_get_runner_num_internal(const char *v);
int ra_internal_get_runner_hex_internal(const char *v);
int ra_internal_runner_cmp_internal(const char *v1, const char *v2);

#define RA_VERSION_MAJOR(v) ra_internal_get_runner_major_internal((v))
#define RA_VERSION_MINOR(v) ra_internal_get_runner_minor_internal((v))
#define RA_VERSION_PATCH(v) ra_internal_get_runner_patch_internal((v))
#define RA_VERSION_NUM(v) ra_internal_get_runner_num_internal((v))
#define RA_VERSION_HEX(v) ra_internal_get_runner_hex_internal((v))
#define RA_VERSION_CMP(v1, v2) ra_internal_runner_cmp_internal((v1), (v2))

/* Runner internals used by macros. */
void ra_internal_runner_reset_current(void);
void ra_internal_runner_set_report_path(int argc, char **argv, const char *default_report_filename);
void ra_internal_runner_open_report(const char *title);
void ra_internal_runner_write_result(ra_result_t result, const char *label);
void ra_internal_runner_close_report(const char *notes);
int ra_internal_runner_exit_code(void);
ra_result_t ra_internal_runner_run_test(ra_test_fn fn, const char *name, int include);

/* Execution macros. */
#define RA_PASS (1)
#define RA_FAIL_EXPR (0)
#define RA_FAULT(type) \
  ((type) == 1 ? (raise(SIGSEGV), 0) : ((type) == 2 ? (raise(SIGABRT), 0) : (raise(SIGBUS), 0)))

#define RA_DECLARE_ORCHESTRATOR(funcname) int funcname(int argc, char **argv)
#define RA_INIT_ORCHESTRATOR(funcname, project, maxparallel) \
  do { (void)(funcname); (void)sizeof(#project); (void)(maxparallel); ra_internal_runner_reset_current(); } while (0)
#define RA_PARSE_ARGS(maxargs, defaultreportfilename) \
  do { (void)(maxargs); ra_internal_runner_set_report_path(argc, argv, (defaultreportfilename)); } while (0)
#define RA_OPEN_REPORT(title) \
  do { ra_internal_runner_open_report((title)); } while (0)
#define RA_GROUP(func, isolation) ra_internal_runner_run_test((ra_test_fn)(func), #func, (isolation))
#define RA_TEST(expression, include) RA_ASSERT((expression), (include))
#define RA_WRITE_RESULT(t, label) \
  do { ra_result_t _ra_wr = (t); ra_internal_runner_write_result(_ra_wr, (label)); } while (0)
#define RA_CLOSE_REPORT ra_internal_runner_close_report(NULL)
#define RA_EXIT do { return ra_internal_runner_exit_code(); } while (0)

/* Per-test function helpers. */
#define RA_DECLARE_TEST(funcname) ra_result_t funcname(void)
#define RA_DECLARE_GROUP(funcname) RA_DECLARE_TEST(funcname)
#define RA_DECLARE_TEST_FUNCTION(funcname) RA_DECLARE_TEST(funcname)
#define RA_INIT_TEST(funcname, maxparallel) \
  ra_result_t ra_internal_result_internal = {0, 0, 0, 0, 0}; \
  (void)(funcname); (void)(maxparallel)
#define RA_INIT_GROUP(funcname, maxparallel) RA_INIT_TEST(funcname, maxparallel)
#define RA_INIT_TEST_FUNCTION(funcname, maxparallel) RA_INIT_TEST(funcname, maxparallel)
#define RA_ASSERT(expression, include) \
  do { \
    (void)(include); \
    signal(SIGSEGV, ra_internal_assert_signal_handler); \
    signal(SIGABRT, ra_internal_assert_signal_handler); \
    signal(SIGBUS, ra_internal_assert_signal_handler); \
    if (setjmp(ra_internal_assert_jmp) == 0) { \
      if ((expression)) ++ra_internal_result_internal.pass; \
      else ++ra_internal_result_internal.fail; \
    } else { \
      ++ra_internal_result_internal.fault; \
    } \
  } while (0)
#define RA_ASSERT_FAIL(include) \
  do { (void)(include); ++ra_internal_result_internal.fail; } while (0)
#define RA_ASSERT_FAULT(include) \
  do { (void)(include); ++ra_internal_result_internal.fault; } while (0)
#define RA_RETURN do { return ra_internal_result_internal; } while (0)
#define RA_RETURN_STATUS RA_EXIT

#if defined(__cplusplus)
}
#endif
