/**
 * @file litetest.c
 */

#include "litetest.h"

internal_guard_t *internal_guard = NULL;
internal_saved_guard_t saved_guards[MAX_GUARD_LEVEL] = { 0 };
size_t internal_num_saved_guards = 0;

char internal_run_id = 0;
result_t internal_total = {0, 0, 0, 0, 0};
char *internal_executable_name = NULL;
const char internal_default_path_msg[] =
  "PATH: A directory path, test report file name, or test report file path.\n"
  "      (optional quoted or as needed).\n\n"
  "      If PATH is a path to an existing directory (with or without a trailing\n"
  "      separator), the test report and the inject test report are written\n"
  "      in that directory with default names.\n\n"
  "      If PATH is a file name (not ending with a separator), the test\n"
  "      report is written with that file name in the current working directory (./).\n"
  "      The inject test report is also written in the current working directory"
  "      with a default name based on specified file name.\n\n"
  "      If PATH is a file path, the test report is written to that file.\n"
  "      The inject test report is written to the same directory\n"
  "      as the test report with a default name based on the file name\n"
  "      in the file path.\n\n"
  "      An already existing report file is overwritten.\n\n";
const char *path_msg = NULL;

void install_guard_internal(internal_guard_t *new_guard)
{ if (internal_num_saved_guards >= MAX_GUARD_LEVEL) { abort(); }
  internal_saved_guard_t *saved_guard = &saved_guards[internal_num_saved_guards++];
  saved_guard->guard = internal_guard;
  saved_guard->segv_handler = signal(SIGSEGV, new_guard->handler);
  saved_guard->abrt_handler = signal(SIGABRT, new_guard->handler);
  saved_guard->bus_handler = signal(SIGBUS, new_guard->handler);
  if (saved_guard->segv_handler == SIG_ERR ||
      saved_guard->abrt_handler == SIG_ERR ||
      saved_guard->bus_handler == SIG_ERR)
  { abort(); }
  internal_guard = new_guard;
}

void restore_guard_internal(void)
{ if (!internal_num_saved_guards) { abort(); }
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

void print_err_usage(const char *err_msg)
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

int parse_args
( const int argc, const char *const *const argv,
  char *const dir_path, char *const filename
)
{ const char *path_arg = NULL;

  char normalized_path[MAX_PATH_LEN + 2] = {0};

  if (argc > 0 && argv && argv[0] && *argv[0])
  { internal_executable_name = (char *)argv[0]; }

  if (!dir_path || !filename)
  { print_err_usage("Internal error: output buffers are NULL.");
    return 1;
  }

  if (run_path_parser_selftests())
  { print_err_usage("Internal PATH parser self-test failed.");
    return 1;
  }

  if (argc > 2)
  { print_err_usage("Unexpected number of arguments.");
    return 1;
  }

  if (argc == 2)
  { if (!argv || !argv[1])
    { print_err_usage("Non-standard call: missing first argument.");
      return 1;
    }

    if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)
    { print_err_usage(NULL);
      return -1;
    }

    if (is_blank_path_arg(argv[1]))
    { print_err_usage("PATH must not be empty or whitespace only.");
      return 1;
    }

    path_arg = argv[1];
    if (path_is_existing_directory(path_arg) &&
        !path_has_trailing_separator(path_arg))
    { int n = snprintf(normalized_path, sizeof(normalized_path), "%s/", path_arg);
      if (n < 0 || (size_t)n >= sizeof(normalized_path))
      { print_err_usage("Directory path is too long.");
        return 1;
      }
      path_arg = normalized_path;
    }

    int result = extract_dirpath_and_filename
                   (dir_path, filename,
                    path_arg, MAX_PATH_LEN + 1, MAX_FILENAME_LEN + 1);
    if (result == -4)
    { print_err_usage("File or directory path is too long.");
      return 1;
    }
    if (result == -5)
    { print_err_usage("Filename is too long.");
      return 1;
    }
  }

  return 0;
}

int is_writable_dir(char *dirpath, char *path)
{ if (!output_dir_is_writable(path))
  { fprintf(stderr,
            "[ERROR] Directory '%s' for test report is not writable.\n",
            dirpath);
    return 0;
  }
  return 1;
}

result_t merge_results(result_t a, result_t b)
{ return (result_t)
         { a.pass + b.pass, a.fail + b.fail,
           (a.fault == SIZE_MAX || b.fault == SIZE_MAX) ?
                      SIZE_MAX : a.fault + b.fault,
           a.injected_fail + b.injected_fail,
           a.injected_fault + b.injected_fault
         };
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
{ const int has_injected_fail = result.injected_fail > 0;
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

FILE *open_report(const char *report_path, const char *report_title)
{ FILE *report = fopen(report_path, "w");

  if (!report)
  { fprintf(stderr, "[ERROR] Could not open report file '%s' for writing.\n",
            report_path ? report_path : "(null)");
    return NULL;
  }

  (void)setvbuf(report, NULL, _IONBF, 0);

  fprintf(report, "%s", report_title);
  fprintf(report, "     Test Categories                           Pass  Fail  Fault\n");
  fprintf(report, "--------------------------------------------------------------------\n");

  internal_run_id = 0;
  internal_total = (result_t){0, 0, 0, 0, 0};

  return report;
}

int close_report
( FILE *report,
  result_t total,
  int cat_faults,
  char inject,
  const char *note
)
{ fprintf(report, "------------------------------------------------------------------\n");

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

  if (note) { fprintf(report, "\n\n%s", note); }
  if (cat_faults)
  { fprintf(report, "\n\n*: category-level fault (counts as 1 in fault total).\n"); }
  if (inject)
  { fprintf(report, "\nFAIL/FAULT: indicates fail/fault injected "
                    "to test fail/fault detection.\n"); }

  if (!total.fail && !total.fault)
  { fprintf(report, "\nAll tests passed.\n"); }
  else if (!total.fail)
  { fprintf(report, "\nTest run completed with faults.\n"); }
  else if (!total.fault)
  { fprintf(report, "\nTest run completed with failures.\n"); }
  else
  { fprintf(report, "\nTest run completed with failures and faults.\n"); }

  fclose(report);

  return (total.fail > 0 || total.fault > 0) ? 1 : 0;
}

void get_current_time(char *current_time, size_t size)
{ time_t now = time(NULL);
  struct tm *tm_now = localtime(&now);
  if (!tm_now || !strftime(current_time, size,
                           "%Y-%m-%d %H:%M:%S", tm_now))
  { snprintf(current_time, size, "unknown time"); }
}
