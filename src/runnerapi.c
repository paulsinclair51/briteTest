#include "runnerapi.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static ra_total_t g_total = {0, 0, 0, 0, 0};
static char g_report_path[RA_MAX_PATH_LEN + 1] = "test_report.txt";
static FILE *g_report = NULL;
jmp_buf ra_internal_assert_jmp;

void ra_internal_assert_signal_handler(int signo)
{
  longjmp(ra_internal_assert_jmp, signo ? signo : 1);
}

static int parse_version(const char *v, int *maj, int *min, int *pat)
{
  int a = 0;
  int b = 0;
  int c = 0;

  if (!v || sscanf(v, "%d.%d.%d", &a, &b, &c) != 3) {
    return RA_INVALID_ARG_VERSION;
  }
  if (a < 0 || b < 0 || c < 0) {
    return RA_INVALID_ARG_VERSION;
  }
  if (maj) *maj = a;
  if (min) *min = b;
  if (pat) *pat = c;
  return 0;
}

int ra_internal_get_runner_major_internal(const char *v)
{
  int m = 0;
  return parse_version(v, &m, NULL, NULL) == 0 ? m : RA_INVALID_ARG_VERSION;
}

int ra_internal_get_runner_minor_internal(const char *v)
{
  int m = 0;
  return parse_version(v, NULL, &m, NULL) == 0 ? m : RA_INVALID_ARG_VERSION;
}

int ra_internal_get_runner_patch_internal(const char *v)
{
  int p = 0;
  return parse_version(v, NULL, NULL, &p) == 0 ? p : RA_INVALID_ARG_VERSION;
}

int ra_internal_get_runner_num_internal(const char *v)
{
  int a = 0;
  int b = 0;
  int c = 0;

  if (parse_version(v, &a, &b, &c) != 0) {
    return RA_INVALID_ARG_VERSION;
  }
  return a * 10000 + b * 100 + c;
}

int ra_internal_get_runner_hex_internal(const char *v)
{
  int a = 0;
  int b = 0;
  int c = 0;

  if (parse_version(v, &a, &b, &c) != 0) {
    return RA_INVALID_ARG_VERSION;
  }
  return (a << 16) | (b << 8) | c;
}

int ra_internal_runner_cmp_internal(const char *v1, const char *v2)
{
  int n1 = ra_internal_get_runner_num_internal(v1);
  int n2 = ra_internal_get_runner_num_internal(v2);

  if (n1 < 0 || n2 < 0) {
    return -2;
  }
  if (n1 < n2) return -1;
  if (n1 > n2) return 1;
  return 0;
}

void ra_internal_runner_reset_current(void)
{
  g_total = (ra_total_t){0, 0, 0, 0, 0};
}

void ra_internal_runner_set_report_path(int argc, char **argv, const char *default_report_filename)
{
  if (default_report_filename && *default_report_filename) {
    snprintf(g_report_path, sizeof(g_report_path), "%s", default_report_filename);
  }
  if (argc > 1 && argv && argv[1] && *argv[1]) {
    if (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help")) {
      fprintf(stdout, "Usage: test_britetest [REPORT_PATH|-h|--help]\n");
      exit(0);
    }
    snprintf(g_report_path, sizeof(g_report_path), "%s", argv[1]);
  }
}

void ra_internal_runner_open_report(const char *title)
{
  const char *report_title = (title && *title) ? title : "BriteTest Report";

  g_report = fopen(g_report_path, "w");
  if (!g_report) {
    return;
  }
  fprintf(g_report, "%s\n", report_title);
  fprintf(g_report, "                             Pass   Fail     Fault\n");
  fprintf(g_report, "--------------------------------------------------\n");
}

ra_result_t ra_internal_runner_run_test(ra_test_fn fn, const char *name, int include)
{
  ra_result_t r = {0, 0, 0, 0, 0};
  (void)include;
  (void)name;

  if (!fn) {
    r.fault = 1;
    return r;
  }
  r = fn();
  return r;
}

void ra_internal_runner_write_result(ra_result_t result, const char *label)
{
  static size_t category = 0;

  ++category;
  g_total.pass += result.pass;
  g_total.fail += result.fail;
  g_total.fault += result.fault;
  g_total.injected_fail += result.injected_fail;
  g_total.injected_fault += result.injected_fault;

  if (g_report) {
    fprintf(g_report, "%zu. %-24s %5zu %6zu %9zu\n",
            category,
            (label && *label) ? label : "Category",
            result.pass,
            result.fail,
            result.fault);
  }
}

void ra_internal_runner_close_report(const char *notes)
{
  if (!g_report) {
    return;
  }

  fprintf(g_report, "--------------------------------------------------\n");
  fprintf(g_report, "                      Total %5zu %6zu %9zu\n",
          g_total.pass, g_total.fail, g_total.fault);
  if (notes && *notes) {
    fprintf(g_report, "\n%s", notes);
  }

  fclose(g_report);
  g_report = NULL;
}

int ra_internal_runner_exit_code(void)
{
  /* Self-test suite intentionally includes fail/fault scenarios. */
  return 0;
}
