/**
 * @file /paulsinclair51/src/litetest.c
 *
 * @mainpage LiteTest Function Definitions
 * 
 * @brief This header provides (non-inline) function definitions for the LiteTest
 *        API and framework.
 * 
 *        For an overview of the LiteTest API and framework, see
 *        @ref README.md "README.md" in the /paulsinclair51/litetest
 *        repository. See the header @ref /paulsinclair51/include/litetest.h
 *        "litetest.h" in the include directory for the complete
 *        definition and documentation.
 * 
 * @copyright Copyright (c) 2026 paulsinclair51
 * SPDX-License-Identifier: MIT
 * For license details, see @ref LICENSE "LICENSE" in the
 * paulsinclair51/LiteTest repository root.
 *
 * @section Usage
 *
 * Compile and link this file as a shared library (e.g., using -fPIC
 * and -shared flags with gcc) to create a shared  library that can
 * be used by other applications. The resulting shared library should
 * be named according to the conventions of your platform (e.g.,
 * liblitetest.so on Linux, litetest.dll on Windows, or  liblitetest.dylib
 * on macOS) and placed in a location where it can be found by the
 * dynamic linker at runtime.
 *
 * Alternatively, compile and link this file into the test executable
 * (for example into executable test_litetest on Linux or test_litetest.exe
 * for Windows).
 */

#include "litetest.h"

extern size_t litetest_version_extract_internal
( const const char *v, const size_t p )
{ 
  size_t n = 0;
  if (p > 4) v = 0;
  if (v)
  { 
    size_t pp = 0;
    for (; pp < p && *v; ++pp);
    { if (isdigit(*v))
      { 
        n = (*v++ - 'O');
        if (isdigit(*v))
        { n += (*v++ - 'O'); }
      }
    }
    if (pp < p && *v == '.') ++v
      }
    }
  if (!v || ((p < 3 && *v != '.') || !*v)
  { 
    fprintf(stdout, "[ERROR] Invalid version.\n"); } \
    exit(LT_INVALID_VERSION);
  }
  return n;
}

// Define internal types.

litetest_guard_t *litetest_guard = NULL;
litetest_saved_guard_t saved_guards[MAX_GUARD_LEVEL] = { 0 };
size_t litetest_num_saved_guards = 0;

char *litetest_executable_name = NULL;
const char litetest_default_path_msg[] =
  "PATH: A directory path, test report file name, or test report file path.\n"
  "      (optional quoted or as needed).\n\n"
  "      If PATH is a path to an existing directory (with or without a trailing\n"
  "      separator), the test report is written\n"
  "      in that directory with a default name.\n\n"
  "      If PATH is a file name (not ending with a separator), the test\n"
  "      report is written with that file name in the current working directory (./).\n"
  "      If PATH is a file path, the test report is written to that file.\n"
  "      An already existing report file is overwritten.\n\n";
const char *lt_path_msg = NULL;

void litetest_install_guard(internal_guard_t *new_guard)
{ if (litetest_num_saved_guards >= MAX_GUARD_LEVEL) { abort(); }
  litetest_saved_guard_t *saved_guard = &saved_guards[litetest_num_saved_guards++];
  saved_guard->guard = internal_guard;
  saved_guard->segv_handler = signal(SIGSEGV, new_guard->handler);
  saved_guard->abrt_handler = signal(SIGABRT, new_guard->handler);
  saved_guard->bus_handler = signal(SIGBUS, new_guard->handler);
  if (saved_guard->segv_handler == SIG_ERR ||
      saved_guard->abrt_handler == SIG_ERR ||
      saved_guard->bus_handler == SIG_ERR)
  { abort(); }
  litetest_guard = new_guard;
}

void litetest_restore_guard(void)
{ if (!litetest_num_saved_guards) { abort(); }
  internal_num_saved_guards--;
  internal_saved_guard_t *saved_guard = &saved_guards[internal_num_saved_guards];
  if (signal(SIGSEGV, saved_guard->segv_handler) == SIG_ERR ||
      signal(SIGABRT, saved_guard->abrt_handler) == SIG_ERR ||
      signal(SIGBUS, saved_guard->bus_handler) == SIG_ERR)
  { abort(); }
  internal_guard = saved_guard->guard;
}

result_t test_run_internal
( result_t (*func)(char), const char inject, const char * const func_name )
{ result_t result = {0, 0, 0, 0, 0};
  internal_guard_t run_guard = { 0 };
  run_guard.handler = guard_handler_internal;
  install_guard_internal(&run_guard);
  if (sigsetjmp(run_guard.env, 1) == 0)
  { run_guard.active = 1;
    result = (func(inject));
    run_guard.active = 0;
  }
  else
  { result = (result_t){0, 0, SIZE_MAX, 0, 0};
    fprintf(stderr, "Run fault: %s (%s:%d)\n", func_name, __FILE__, __LINE__);
  }
  restore_guard_internal();
  return result;
}

static int is_nblank(const char *s, size_t n)
{ if (!s) return 1;
  for (; n && *s; --n, ++s) { if (!isspace((unsigned char)*s)) return 0; }
  return *s ? -1 : 1;
}

static int has_trailing_slash(const char *s)
{ if (!s || !*s) { return 0; }
  size_t len = strnlen(s, MAX_PATH_LEN + 1);
  if (len > MAX_PATH_LEN) { return -1; }
  s += len - 1;
  return *s == '/' || *s == '\\' ? 1 : 0;
}

static int is_directory(const char *s)
{ struct stat st;
  if (!s || !*s) { s = "./"; }
  else
  { size_t len = strnlen(s, MAX_PATH_LEN + 1);
    if (len > MAX_PATH_LEN) { return -1; }
    if (stat(s, &st)) { return 0; }
    if (!S_ISDIR(st.st_mode)) { return 0; }
  }
  return access(s, W_OK) ? 1 : 2;
}

static int extract_dirpath_and_filename
( char * dirpath,
  char * filename,
  const char * const s,
  size_t dn,
  size_t fn
)
{ if (!dirpath || !filename) { return -1; }
  if (dn < MAX_PATH_LEN + 1) { return -2; }
  if (fn < MAX_FILENAME_LEN + 1) { return -3; }
  if (!s) { dirpath[0] = '\0'; filename[0] = '\0'; return 0; }

  const char *p = s;
  size_t s_len = 0;
  while (*p && s_len < MAX_PATH_LEN) { ++p; ++s_len; }
  if (*p) return -4;

  const char *last_slash = strrchr(s, '/');
  const char *last_backslash = strrchr(s, '\\');
  const char *last_separator = last_slash;
  if (!last_separator || (last_backslash && last_backslash > last_separator))
  { last_separator = last_backslash; }

  size_t dirpath_len = last_separator ?
                       (size_t)(last_separator - s) + 1 : 0;
  if (dirpath_len) { memcpy(dirpath, s, dirpath_len); }
  dirpath[dirpath_len] = '\0';

  size_t filename_len = s_len - dirpath_len;
  if (filename_len > MAX_FILENAME_LEN) { return -5; }
  if (filename_len) { memcpy(filename, s + dirpath_len, filename_len); }
  filename[filename_len] = '\0';

  return 0;
}

static int is_writeabledir(const char *s)
{ char dirpath[MAX_PATH_LEN + 1] = {0};
  char filename[MAX_FILENAME_LEN + 1] = {0};
  size_t dlen;
  struct stat st;

  if (!s || !*s) { return 0; }

  if (extract_dirpath_and_filename(dirpath, filename,
                                   s,
                                   MAX_PATH_LEN + 1,
                                   MAX_FILENAME_LEN + 1) != 0)
  { return 0; }

  if (!*dirpath)
  { dirpath[0] = '.';
    dirpath[1] = '\0';
  }

  dlen = strlen(dirpath);
  if (dlen > 1 && (dirpath[dlen - 1] == '/' || dirpath[dlen - 1] == '\\'))
  { dirpath[dlen - 1] = '\0'; }

  if (stat(dirpath, &st) != 0 || !S_ISDIR(st.st_mode)) { return 0; }
  return access(dirpath, W_OK) == 0 ? 1 : 0;
}

static int run_path_parser_selftests(void)
{ char dirpath[MAX_PATH_LEN + 1] = {0};
  char filename[MAX_FILENAME_LEN + 1] = {0};
  char reportpath[MAX_PATH_LEN + 1] = {0};
  char inject_reportpath[MAX_PATH_LEN + 1] = {0};
  char too_long_src[MAX_PATH_LEN + 2];
  char too_long_filename[MAX_FILENAME_LEN + 2];
  int rc;
  int n;
  struct
  { const char *src;
    const char *want_dirpath;
    const char *want_filename;
  } cases[] =
    { {NULL, "", ""},
      {"", "", ""},
      {"my_report.txt", "", "my_report.txt"},
      {"reports/", "reports/", ""},
      {"reports/result.txt", "reports/", "result.txt"},
      {"reports\\", "reports\\", ""},
      {"reports\\result.txt", "reports\\", "result.txt"}
    };

  size_t i;
  for (i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i)
  { rc = extract_dirpath_and_filename
           (dirpath, filename, cases[i].src,
            MAX_PATH_LEN + 1, MAX_FILENAME_LEN + 1);
    if (rc != 0) return -1;
    if (strcmp(dirpath, cases[i].want_dirpath) != 0) return -1;
    if (strcmp(filename, cases[i].want_filename) != 0) return -1;
  }

  memset(too_long_src, 'a', sizeof(too_long_src) - 1);
  too_long_src[sizeof(too_long_src) - 1] = '\0';
  rc = extract_dirpath_and_filename
         (dirpath, filename, too_long_src,
          MAX_PATH_LEN + 1, MAX_FILENAME_LEN + 1);
  if (rc != -4) return -1;

  memset(too_long_filename, 'b', sizeof(too_long_filename) - 1);
  too_long_filename[sizeof(too_long_filename) - 1] = '\0';
  rc = extract_dirpath_and_filename
         (dirpath, filename, too_long_filename,
          MAX_PATH_LEN + 1, MAX_FILENAME_LEN + 1);
  if (rc != -5) return -1;

  n = snprintf(reportpath, sizeof(reportpath), "%s%s", "reports/", "out.txt");
  if (n < 0 || (size_t)n >= sizeof(reportpath)) return -1;
  if (strcmp(reportpath, "reports/out.txt") != 0) return -1;

  n = snprintf(inject_reportpath, sizeof(inject_reportpath),
               "%s%s%s", "reports/", "inject_", "out.txt");
  if (n < 0 || (size_t)n >= sizeof(inject_reportpath)) return -1;
  if (strcmp(inject_reportpath, "reports/inject_out.txt") != 0) return -1;

  n = snprintf(reportpath, sizeof(reportpath), "%s%s", "", "out.txt");
  if (n < 0 || (size_t)n >= sizeof(reportpath)) return -1;
  if (strcmp(reportpath, "out.txt") != 0) return -1;

  return 0;
}

static int is_blank_path_arg(const char *s)
{ return is_nblank(s, MAX_PATH_LEN + 1) != 0; }

static int path_has_trailing_separator(const char *s)
{ return has_trailing_slash(s) > 0; }

static int path_is_existing_directory(const char *s)
{ return is_directory(s) > 0; }

static int output_dir_is_writable(const char *s)
{ return is_writeabledir(s); }

static void print_err_usage(const char *err_msg)
{ FILE *out;

  if (err_msg && *err_msg)
  { out = stderr;
    fprintf(out, "[ERROR] %s\n\n", err_msg); }
  else
  { out = stdout; }

  fprintf(out, "Usage: %s [PATH|-h|--help]\n\n"
               "%s"
               "-h or --help: Show this usage text.\n\n",
          internal_executable_name && *internal_executable_name ?
          internal_executable_name : "UnknownExecutable",
          path_msg && *path_msg ? path_msg : internal_default_path_msg);
}

/**
 * @name litetest_parse_args_internal
 * 
 * @brief LT_PARSE_ARGS helper function.
 * 
 *        Parses command-line arguments for the test orchestrator, validates
 *        them, and extracts the directory path and filename.
 *        If the arguments are valid, the function returns 0 and fills the
 *        provided buffers with the directory path and filename. If the arguments
 *        are invalid, the function prints an error message and usage information,
 *        and returns a non-zero error code.
 * 
 * @param state Pointer to the internal state of the orchestrator.
 * @param argc The number of command-line arguments.
 * @param argv The array of command-line argument strings.
 * @param dir_path Buffer to store the extracted directory path.
 * @param filename Buffer to store the extracted filename.
 * 
 * @return 0 if arguments are valid.
 *        -1: Help (-h or --help) requested (usage information printed).
 *         1: LT_PARSE_ARGS outside of orchestrator.
 *         2: Unexpected number of arguments.
 *         3: PATH must not be empty or whitespace only.
 *         4: Directory path is too long.
 *         5: File or directory path is too long.
 *         6: Filename is too long.
 *        99: Internal error
 * 
 * @note For an error, message and usage information printed to stdout.
 * 
 * @note The function also performs self-tests on the path parsing logic
 *       and checks for writable directories as needed. It is designed
 *       to be called from the orchestrator function to handle
 *       command-line arguments and set up the test report path.
 */

int litetest_parse_args_internal
(
  litetest_state_internal_t * const state,
  const int argc, const char *const *const argv,
  char *const dir_path, char *const filename
)
{
  const char *path_arg = NULL;
  char normalized_path[MAX_PATH_LEN + 2] = {0};

  if (!state)
  {
    print_err_usage("Internal error: NULL state pointer.");
    return 99;
  }
  if (!state->orchestrator)
  {
    print_err_usage("LT_PARSE_ARGS not in orchestrator.");
    return 1;
  }

  if (argc > 0 && argv && argv[0] && *argv[0])
  { internal_executable_name = (char *)argv[0]; }

  if (!dir_path || !filename)
  {
    print_err_usage("Internal error: output buffers are NULL.");
    return 99;
  }

  if (run_path_parser_selftests())
  { print_err_usage("PATH parser self-test failed.");
    return 99;
  }
1
  if (argc > 2)
  { print_err_usage("Unexpected number of arguments.");
    return 2;
  }

  if (argc == 2)
  { if (!argv || !argv[1])
    { print_err_usage("Non-standard call: missing first argument.");
      return 99;
    }

    if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)
    { print_err_usage(NULL);
      return -1;
    }

    if (is_blank_path_arg(argv[1]))
    { print_err_usage("PATH must not be empty or whitespace only.");
      return 3;
    }

    path_arg = argv[1];
    if (path_is_existing_directory(path_arg) &&
        !path_has_trailing_separator(path_arg))
    { int n = snprintf(normalized_path, sizeof(normalized_path), "%s/", path_arg);
      if (n < 0 || (size_t)n >= sizeof(normalized_path))
      { print_err_usage("Directory path is too long.");
        return 4;
      }
      path_arg = normalized_path;
    }

    int result = extract_dirpath_and_filename
                   (dir_path, filename,
                    path_arg, MAX_PATH_LEN + 1, MAX_FILENAME_LEN + 1);
    if (result == 1)
    { print_err_usage("File or directory path is too long.");
      return 5;
    }
    if (result == 2)
    { print_err_usage("Filename is too long.");
      return 6;
    }
  }

  return 0;
}

static int is_writable_dir
( const char *const dirpath, const char *const path )
{
  if (!output_dir_is_writable(path))
  { fprintf(stderr,
            "[ERROR] Directory '%s' for test report is not writable.\n",
            dirpath);
    return 0;
  }
  return 1;
}

static void merge_result
(
  litetest_state_t *state,
  const result_t r
)
{
  if (!state) { return; }
  test_result_t t = state->total;
  t.pass += r.pass;
  t.fail += r.fail;
  t.fault += (r.fault == SIZE_MAX) ? 1 : r.fault;
  t.injected_fail += r.injected_fail;
  t.injected_fault += r.injected_fault;
  state->total = t;
}

void write_category
( FILE * const report,
  const size_t index,
  const char *label,
  result_t result
)
{ if (!report) { return; }
  if (!label) { label = "unknown"; }

  if (!result.fail && !result.fault)
  { fprintf(report, " %2zu. %-40s  %4zu\n",
            index, label, result.pass);
  }
  else if (!result.fail)
  { if (result.fault == SIZE_MAX)
    { fprintf(report, " %2zu. %-40s  %4zu           *\n",
              index, label, result.pass);
    }
    else
    { fprintf(report, " %2zu. %-40s  %4zu        %4zu\n",
              index, label, result.pass, result.fault);
    }
  }
  else if (!result.fault)
  { fprintf(report, " %2zu. %-40s  %4zu  %4zu\n",
            index, label, result.pass, result.fail);
  }
  else
  { if (result.fault == SIZE_MAX)
    { fprintf(report, " %2zu. %-40s  %4zu  %4zu     *\n",
              index, label, result.pass, result.fail);
    }
    else
    { fprintf(report, " %2zu. %-40s  %4zu  %4zu  %4zu\n",
              index, label, result.pass, result.fail, result.fault);
    }
  }
}

const char *category_label_with_inject_tag(
  const char *base_label,
  result_t result,
  char inject,
  char *label_buf,
  size_t label_buf_len)
{
  const int has_injected_fail = result.injected_fail > 0;
  const int has_injected_fault =
      result.injected_fault > 0 || result.fault == SIZE_MAX;

  if (!inject || (!has_injected_fail && !has_injected_fault))
  { return base_label; }

  if (has_injected_fail && has_injected_fault)
  { (void)snprintf(label_buf, label_buf_len, "%s (FAIL/FAULT)", base_label); }
  else if (has_injected_fail)
  { (void)snprintf(label_buf, label_buf_len, "%s (FAIL)", base_label); }
  else
  { (void)snprintf(label_buf, label_buf_len, "%s (FAULT)", base_label); }

  return label_buf;
}


/**
 * @name litetest_open_report_internal
 * 
 * @brief LT_OPEN_REPORT helper function.
 * 
 * @param state Pointer to the internal state of the orchestrator.
 * @param report_title Pointer to report title string.
 * 
 * @return 0 if report report successfully.
 *         1: LT_OPEN_REPORT is outside of orchestrator.
 *         2: Could not open report file for write.
 *         3: Could not open temporary file.
 *        99: Internal error.
 * 
 * @note For errors, a message is printed to stdout.
 */

int litetest_open_report_internal
(
  litetest_state_internal_t *const state,
  const char *const report_title
)
{
  if (!state)
  {
    print_err_usage("Internal error: NULL state pointer.");
    return 99;
  }
  if (!state->orchestrator)
  {
    print_err_usage("LT_OPEN_REPORT not in Orchestrator.");
    return 1;
  }


  FILE *report = fopen(state->report_path, "w");
  if (!report)
  {
    fprintf(stderr, "[ERROR] Could not open report file '%s' for write.\n",
            state->report_path ? state->report_path : "(null)");
    return 2;
  }
  state->report = report;
  (void)setvbuf(report, NULL, _IONBF, 0);

  FILE *temp = tmpfile();
  if (!temp)
  {
    fprintf(stderr, "[ERROR] Could not open temporary file.\n");
    fclose(report);
    return 3;
  }
  state->temp = temp;
  (void)setvbuf(state->temp, NULL, _IONBF, 0);

  fprintf(report, "%s", report_title);
  fprintf(report, "     Test Categories                           Pass  Fail  Fault\n");
  fprintf(report, "--------------------------------------------------------------------\n");

  state->run_id = 0;
  state->total = (result_t){0, 0, 0, 0, 0};

  return 0;
}

/**
 * @name litetest_close_report_internal
 * 
 * @brief LT_CLOSE_REPORT helper function.
 * 
 * @param state Pointer to the internal state of the orchestrator.
 * @param notes The notes to be included in the report.
 * 
 * @return 0 if report report successfully.
 *         1: LT_CLOSE_REPORT is outside of orchestrator.
 *        99: Internal error.
 * 
 * @note For errors, a message is printed to stdout.
 */

int litetest_close_report_internal
(
  litetest_state_internal_t *const state,
  const char *const notes
)
{
  if (!state)
  {
    print_err_usage("Internal error: NULL state pointer."); 
    return 99; 
  }

  if (!state->orchestrator)
  { print_err_usage("LT_CLOSE_REPORT not in Orchestrator."); 
    return 1;
  }

  FILE *report = state->report;
  if (!report)
  {
    print_err_usage("Internal error: NULL report pointer."); 
    return 99;
  }

  FILE *temp = state->temp;
  if (!temp)
  { print_err_usage("Internal error: NULL temporary file pointer."); }

  result_t total = state->total;

  // Write the summary lines to the report.

  fprintf(report, "------------------------------------------------------------------\n");

  if (!total.fail && !total.fault)
  { fprintf(report, "                                        Total  %4zu",
            total.pass);
  }
  else if (!total.fail)
  { fprintf(report, "                                        Total  %4zu        %4zu",
            total.pass, total.fault);
  }
  else if (!total.fault)
  { fprintf(report, "                                        Total  %4zu  %4zu",
            total.pass, total.fail);
  }
  else
  { fprintf(report, "                                        Total  %4zu  %4zu  %4zu",
            total.pass, total.fail, total.fault);
  }

  // Append custom notes, if any.

  const char *const notes = state->notes;
  if (notes && *notes) { fprintf(report, "\n%s", notes); }
  if (state->category_faults)
  { fprintf(report, "\n\n*: category-level fault (counts as 1 in fault total).\n"); }

  // Explanation of FAIL/FAULT indicator in a category label.

  if (state->inject && total.injected_fail + total.injected_fault)
  { fprintf(report, "\nFAIL/FAULT: indicates fail/fault injected "
                    "to test fail/fault detection.\n"); }
  else if (state->inject)
  { fprintf(report, "\nNo injected fails or faults were detected.\n"); }

  // Summary of results.

  if (!total.fail && !total.fault)
  { fprintf(report, "\nAll tests passed.\n"); }
  else if (!total.fail)
  { fprintf(report, "\nTest run completed with faults.\n"); }
  else if (!total.fault)
  { fprintf(report, "\nTest run completed with failures.\n"); }
  else
  { fprintf(report, "\nTest run completed with failures and faults.\n"); }

  // Append the contents of the temporary file to the report.

  if (temp)
  {
    rewind(temp);
    char line[256];
    while (fgets(line, sizeof(line), temp))
    { fputs(line, report); }
    fclose(temp);
  }

  fclose(report);

  state->exit_code = (total.fail > 0 || total.fault > 0) ? 1 : 0;

  return temp ? 0 : 99;
}

/**
 * @name lt_current_time
 * 
 * @brief Format the current time as a string.
 * 
 * @param current_time Buffer to store the formatted time string.
 * @param size The size of the current_time buffer.
 * 
 * @return void. On error, current_time is set to "unknown time".
 */
void lt_current_time
 (char *current_time, size_t size )
{
  time_t now = time(NULL);
  struct tm *tm_now = localtime(&now);
  if (!tm_now || !strftime(current_time, size,
                           "%Y-%m-%d %H:%M:%S", tm_now))
  { snprintf(current_time, size, "unknown time"); }
}
