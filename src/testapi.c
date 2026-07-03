/**
 * @file src/testapi.c
 *
 * @mainpage Test API Definitions
 *
 * This file provides (non-inline) function definitions
 * for the Test API.
 *
 * For an overview of the Test API, see the
 * README.md file in the repository root directory.
 * See the header include/testapi.h for the API declarations.
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see LICENSE in the repository root directory.
 */

#define _POSIX_C_SOURCE 200809L

#include "testapi.h"

#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <regex.h>
#include <signal.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <utime.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>

/* Keep helper allocations bounded for predictable memory behavior. */
#define RA_ALLOC_MAX_BYTES ((size_t)(16u * 1024u * 1024u))

/* Global allocator hooks. */
static ra_malloc_fn g_malloc_fn = malloc;
static ra_realloc_fn g_realloc_fn = realloc;
static ra_free_fn g_free_fn = free;

void ta_set_allocator_hooks(ra_malloc_fn malloc_function,
                            ra_realloc_fn realloc_function,
                            ra_free_fn free_function)
{
  g_malloc_fn = malloc_function ? malloc_function : malloc;
  g_realloc_fn = realloc_function ? realloc_function : realloc;
  g_free_fn = free_function ? free_function : free;
}

void ta_get_allocator_hooks(ra_malloc_fn *malloc_function,
                            ra_realloc_fn *realloc_function,
                            ra_free_fn *free_function)
{
  if (malloc_function) *malloc_function = g_malloc_fn;
  if (realloc_function) *realloc_function = g_realloc_fn;
  if (free_function) *free_function = g_free_fn;
}

static int ra_add_overflow_size(size_t a, size_t b, size_t *out)
{
  if (!out) {
    return RA_EARG;
  }
  if (a > SIZE_MAX - b) {
    return RA_ESIZE;
  }
  *out = a + b;
  return 0;
}

static int ra_mul_overflow_size(size_t a, size_t b, size_t *out)
{
  if (!out) {
    return RA_EARG;
  }
  if (a != 0 && b > SIZE_MAX / a) {
    return RA_ESIZE;
  }
  *out = a * b;
  return 0;
}

static void *ra_malloc_checked(size_t n, int *err)
{
  if (err) *err = 0;
  if (n == 0 || n > RA_ALLOC_MAX_BYTES) {
    if (err) *err = RA_ESIZE;
    return NULL;
  }
  void *p = g_malloc_fn(n);
  if (!p && err) *err = RA_ENOMEM;
  return p;
}

static void *ra_realloc_checked(void *p, size_t n, int *err)
{
  if (err) *err = 0;
  if (n == 0 || n > RA_ALLOC_MAX_BYTES) {
    if (err) *err = RA_ESIZE;
    return NULL;
  }
  void *next = g_realloc_fn(p, n);
  if (!next && err) *err = RA_ENOMEM;
  return next;
}

static char *ra_strdup_checked(const char *s, int *err)
{
  size_t n;
  char *dup;

  if (err) *err = 0;
  if (!s) {
    if (err) *err = RA_EARG;
    return NULL;
  }

  n = strnlen(s, RA_ALLOC_MAX_BYTES + 1);
  if (n > RA_ALLOC_MAX_BYTES) {
    if (err) *err = RA_ESIZE;
    return NULL;
  }

  int alloc_err = 0;
  dup = (char *)ra_malloc_checked(n + 1, &alloc_err);
  if (!dup) {
    if (err) *err = alloc_err;
    return NULL;
  }

  memcpy(dup, s, n);
  dup[n] = '\0';
  return dup;
}

static long long ra_now_ms(void)
{
  struct timespec ts;
  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
    return -1;
  }
  return (long long)ts.tv_sec * 1000LL + (long long)ts.tv_nsec / 1000000LL;
}

static void ra_sleep_ms(int ms)
{
  struct timespec req;
  req.tv_sec = ms / 1000;
  req.tv_nsec = (long)(ms % 1000) * 1000000L;
  while (nanosleep(&req, &req) != 0 && errno == EINTR) {
  }
}

int ta_wait_for_condition(int (*condition)(void *callback_context),
                          void *callback_context,
                  int timeout_ms,
                  int poll_interval_ms)
{
  long long start;

  if (!condition || timeout_ms < 0) {
    return -1;
  }

  if (poll_interval_ms <= 0) {
    poll_interval_ms = 1;
  }

  if (timeout_ms == 0) {
    return condition(callback_context) ? 1 : 0;
  }

  start = ra_now_ms();
  if (start < 0) {
    return -1;
  }

  for (;;) {
    if (condition(callback_context)) {
      return 1;
    }

    if (ra_now_ms() - start >= timeout_ms) {
      return 0;
    }

    ra_sleep_ms(poll_interval_ms);
  }
}

/* Execution and runtime test helper functions. */

int ta_assert_completes_within(int (*callback)(void *callback_context),
                               void *callback_context,
                               int timeout_ms)
{
  pid_t pid;
  long long start_ms = -1;
  int status = 0;

  if (!callback || timeout_ms < 0) {
    return -1;
  }

  pid = fork();
  if (pid < 0) {
    return -1;
  }

  if (pid == 0) {
    int rc = callback(callback_context);
    _exit((rc < 0) ? 255 : (rc & 0xff));
  }

  if (timeout_ms > 0) {
    start_ms = ra_now_ms();
    if (start_ms < 0) {
      kill(pid, SIGKILL);
      waitpid(pid, NULL, 0);
      return -1;
    }
  }

  for (;;) {
    pid_t rc = waitpid(pid, &status, WNOHANG);
    if (rc == pid) {
      break;
    }
    if (rc < 0) {
      return -1;
    }

    if (timeout_ms > 0 && (ra_now_ms() - start_ms) >= timeout_ms) {
      kill(pid, SIGKILL);
      waitpid(pid, &status, 0);
      return 1;
    }

    ra_sleep_ms(1);
  }

  if (WIFEXITED(status)) {
    return WEXITSTATUS(status);
  }
  if (WIFSIGNALED(status)) {
    return 128 + WTERMSIG(status);
  }
  return -1;
}

int ta_capture_standard_error(int (*callback)(void *callback_context),
                              void *callback_context,
                              char *output_buffer,
                              size_t output_buffer_size)
{
  int pipefd[2] = {-1, -1};
  int saved_stderr;
  int fn_rc;
  size_t used = 0;

  if (!callback) {
    return -1;
  }

  if (output_buffer && output_buffer_size > 0) {
    output_buffer[0] = '\0';
  }

  if (pipe(pipefd) != 0) {
    return -1;
  }

  saved_stderr = dup(STDERR_FILENO);
  if (saved_stderr < 0) {
    close(pipefd[0]);
    close(pipefd[1]);
    return -1;
  }

  if (dup2(pipefd[1], STDERR_FILENO) < 0) {
    close(saved_stderr);
    close(pipefd[0]);
    close(pipefd[1]);
    return -1;
  }
  close(pipefd[1]);

  fn_rc = callback(callback_context);
  fflush(stderr);

  if (dup2(saved_stderr, STDERR_FILENO) < 0) {
    close(saved_stderr);
    close(pipefd[0]);
    return -1;
  }
  close(saved_stderr);

  for (;;) {
    char tmp[512];
    ssize_t n = read(pipefd[0], tmp, sizeof(tmp));
    if (n <= 0) {
      break;
    }
    if (output_buffer && output_buffer_size > 0) {
      size_t remain = (used < output_buffer_size) ? (output_buffer_size - 1 - used) : 0;
      size_t copy_n = ((size_t)n < remain) ? (size_t)n : remain;
      if (copy_n > 0) {
        memcpy(output_buffer + used, tmp, copy_n);
        used += copy_n;
        output_buffer[used] = '\0';
      }
    }
  }

  close(pipefd[0]);
  return fn_rc;
}

static int ra_set_nonblock(int fd)
{
  int flags = fcntl(fd, F_GETFL, 0);
  if (flags < 0) {
    return -1;
  }
  if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) {
    return -1;
  }
  return 0;
}

int ta_execute_command(const char *command_line,
               int timeout_ms,
               char *output_buffer,
               size_t output_buffer_size,
               int *exit_code)
{
  int pipefd[2] = {-1, -1};
  pid_t pid;
  size_t written = 0;
  long long start_ms = -1;
  int status = 0;
  int timed_out = 0;

  if (!command_line || timeout_ms < 0) {
    return -1;
  }

  if (output_buffer && output_buffer_size > 0) {
    output_buffer[0] = '\0';
  }

  if (pipe(pipefd) != 0) {
    return -1;
  }

  pid = fork();
  if (pid < 0) {
    close(pipefd[0]);
    close(pipefd[1]);
    return -1;
  }

  if (pid == 0) {
    dup2(pipefd[1], STDOUT_FILENO);
    dup2(pipefd[1], STDERR_FILENO);
    close(pipefd[0]);
    close(pipefd[1]);
    execl("/bin/sh", "sh", "-c", command_line, (char *)NULL);
    _exit(127);
  }

  close(pipefd[1]);
  if (ra_set_nonblock(pipefd[0]) != 0) {
    close(pipefd[0]);
    kill(pid, SIGKILL);
    waitpid(pid, NULL, 0);
    return -1;
  }

  if (timeout_ms > 0) {
    start_ms = ra_now_ms();
    if (start_ms < 0) {
      close(pipefd[0]);
      kill(pid, SIGKILL);
      waitpid(pid, NULL, 0);
      return -1;
    }
  }

  for (;;) {
    fd_set readfds;
    struct timeval tv;
    struct timeval *ptv = NULL;
    int sel_rc;
    char tmp[1024];
    ssize_t n;
    pid_t wait_rc;

    if (timeout_ms > 0) {
      long long elapsed = ra_now_ms() - start_ms;
      long long remain = timeout_ms - elapsed;
      if (remain <= 0) {
        timed_out = 1;
        break;
      }
      tv.tv_sec = (time_t)(remain / 1000);
      tv.tv_usec = (suseconds_t)((remain % 1000) * 1000);
      ptv = &tv;
    }

    FD_ZERO(&readfds);
    FD_SET(pipefd[0], &readfds);
    sel_rc = select(pipefd[0] + 1, &readfds, NULL, NULL, ptv);
    if (sel_rc < 0 && errno != EINTR) {
      close(pipefd[0]);
      kill(pid, SIGKILL);
      waitpid(pid, NULL, 0);
      return -1;
    }

    if (sel_rc > 0 && FD_ISSET(pipefd[0], &readfds)) {
      n = read(pipefd[0], tmp, sizeof(tmp));
      if (n > 0 && output_buffer && output_buffer_size > 0) {
        size_t remain = (written < output_buffer_size) ? (output_buffer_size - 1 - written) : 0;
        size_t copy_n = (remain < (size_t)n) ? remain : (size_t)n;
        if (copy_n > 0) {
          memcpy(output_buffer + written, tmp, copy_n);
          written += copy_n;
          output_buffer[written] = '\0';
        }
      }
    }

    wait_rc = waitpid(pid, &status, WNOHANG);
    if (wait_rc == pid) {
      for (;;) {
        n = read(pipefd[0], tmp, sizeof(tmp));
        if (n <= 0) {
          break;
        }
        if (output_buffer && output_buffer_size > 0) {
          size_t remain = (written < output_buffer_size) ? (output_buffer_size - 1 - written) : 0;
          size_t copy_n = (remain < (size_t)n) ? remain : (size_t)n;
          if (copy_n > 0) {
            memcpy(output_buffer + written, tmp, copy_n);
            written += copy_n;
            output_buffer[written] = '\0';
          }
        }
      }
      break;
    }
  }

  close(pipefd[0]);

  if (timed_out) {
    kill(pid, SIGKILL);
    waitpid(pid, &status, 0);
    if (exit_code) {
      *exit_code = -1;
    }
    return 1;
  }

  if (exit_code) {
    if (WIFEXITED(status)) {
      *exit_code = WEXITSTATUS(status);
    } else if (WIFSIGNALED(status)) {
      *exit_code = 128 + WTERMSIG(status);
    } else {
      *exit_code = -1;
    }
  }

  return 0;
}

int ta_copy_file(const char *source_path, const char *destination_path)
{
  FILE *in;
  FILE *out;
  char buf[8192];
  size_t n;

  if (!source_path || !destination_path) {
    return -1;
  }

  in = fopen(source_path, "rb");
  if (!in) {
    return -1;
  }

  out = fopen(destination_path, "wb");
  if (!out) {
    fclose(in);
    return -1;
  }

  while ((n = fread(buf, 1, sizeof(buf), in)) > 0) {
    if (fwrite(buf, 1, n, out) != n) {
      fclose(in);
      fclose(out);
      return -1;
    }
  }

  if (ferror(in) || fflush(out) != 0) {
    fclose(in);
    fclose(out);
    return -1;
  }

  fclose(in);
  fclose(out);
  return 0;
}

int ta_make_temp_dir(const char *prefix, char *out_path, size_t out_path_size)
{
  const char *use_prefix = "test-";
  char templ[PATH_MAX];
  int rc;

  if (!out_path || out_path_size == 0) {
    return -1;
  }

  if (prefix && *prefix) {
    use_prefix = prefix;
  }

  rc = snprintf(templ, sizeof(templ), "/tmp/%sXXXXXX", use_prefix);
  if (rc < 0 || (size_t)rc >= sizeof(templ)) {
    return -1;
  }

  if (!mkdtemp(templ)) {
    return -1;
  }

  rc = snprintf(out_path, out_path_size, "%s", templ);
  if (rc < 0 || (size_t)rc >= out_path_size) {
    return -1;
  }

  return 0;
}

/* Filesystem and path test helper functions. */

int ta_with_working_directory(const char *path,
                              int (*callback)(void *callback_context),
                              void *callback_context)
{
  int cwd_fd;
  int rc;

  if (!path || !callback) {
    return -1;
  }

  cwd_fd = open(".", O_RDONLY);
  if (cwd_fd < 0) {
    return -1;
  }

  if (chdir(path) != 0) {
    close(cwd_fd);
    return -1;
  }

  rc = callback(callback_context);

  if (fchdir(cwd_fd) != 0) {
    close(cwd_fd);
    return -1;
  }
  close(cwd_fd);

  return rc;
}

int ta_make_temp_file(const char *prefix, char *out_path, size_t out_path_size)
{
  const char *use_prefix = "test-";
  char templ[PATH_MAX];
  int fd;
  int rc;

  if (!out_path || out_path_size == 0) {
    return -1;
  }

  if (prefix && *prefix) {
    use_prefix = prefix;
  }

  rc = snprintf(templ, sizeof(templ), "/tmp/%sXXXXXX", use_prefix);
  if (rc < 0 || (size_t)rc >= sizeof(templ)) {
    return -1;
  }

  fd = mkstemp(templ);
  if (fd < 0) {
    return -1;
  }
  close(fd);

  rc = snprintf(out_path, out_path_size, "%s", templ);
  if (rc < 0 || (size_t)rc >= out_path_size) {
    return -1;
  }

  return 0;
}

int ta_make_dirs(const char *path)
{
  char tmp[PATH_MAX];
  char *p;

  if (!path || !*path) {
    return -1;
  }

  if (snprintf(tmp, sizeof(tmp), "%s", path) < 0) {
    return -1;
  }

  for (p = tmp + 1; *p; ++p) {
    if (*p == '/' || *p == '\\') {
      char saved = *p;
      *p = '\0';
      if (mkdir(tmp, 0777) != 0 && errno != EEXIST) {
        return -1;
      }
      *p = saved;
    }
  }

  if (mkdir(tmp, 0777) != 0 && errno != EEXIST) {
    return -1;
  }

  return 0;
}

int ta_path_join(const char *left_path_part,
                 const char *right_path_part,
                 char *output_path,
                 size_t output_path_size)
{
  int need_sep;
  int rc;

  if (!left_path_part || !right_path_part || !output_path || output_path_size == 0) {
    return -1;
  }

  need_sep = (*left_path_part && left_path_part[strlen(left_path_part) - 1] != '/' &&
              left_path_part[strlen(left_path_part) - 1] != '\\');
  rc = snprintf(output_path, output_path_size, "%s%s%s",
                left_path_part, need_sep ? "/" : "", right_path_part);
  if (rc < 0 || (size_t)rc >= output_path_size) {
    return -1;
  }
  return 0;
}

int ta_read_file_with_limit(const char *path, size_t max_bytes, char **content, size_t *length)
{
  FILE *f;
  char *buf;
  size_t cap = 1024;
  size_t limit = RA_ALLOC_MAX_BYTES;
  size_t used = 0;
  int alloc_err = 0;

  if (!path || !content || !length) {
    return RA_EARG;
  }

  *content = NULL;
  *length = 0;

  f = fopen(path, "rb");
  if (!f) {
    return RA_EIO;
  }

  if (max_bytes > 0) {
    if (max_bytes > RA_ALLOC_MAX_BYTES) {
      fclose(f);
      return RA_ESIZE;
    }
    limit = max_bytes;
  }

  if (cap > limit) {
    cap = limit;
  }
  if (cap == 0) {
    cap = 1;
  }

  buf = (char *)ra_malloc_checked(cap + 1, &alloc_err);
  if (!buf) {
    fclose(f);
    return alloc_err;
  }

  for (;;) {
    size_t n;
    if (used == cap) {
      size_t next_cap = cap * 2;
      char *next;
      if (cap >= limit) {
        g_free_fn(buf);
        fclose(f);
        return RA_ESIZE;
      }
      if (next_cap > limit || next_cap < cap) {
        next_cap = limit;
      }
      next = (char *)ra_realloc_checked(buf, next_cap + 1, &alloc_err);
      if (!next) {
        g_free_fn(buf);
        fclose(f);
        return alloc_err;
      }
      buf = next;
      cap = next_cap;
    }

    n = fread(buf + used, 1, cap - used, f);
    used += n;
    if (n == 0) {
      break;
    }
  }

  if (ferror(f)) {
    g_free_fn(buf);
    fclose(f);
    return RA_EIO;
  }

  buf[used] = '\0';
  *content = buf;
  *length = used;
  fclose(f);
  return RA_OK;
}

int ta_read_file(const char *path, char **content, size_t *length)
{
  return ta_read_file_with_limit(path, 0, content, length);
}

int ta_read_file_into(const char *path, char *buffer, size_t buffer_size, size_t *out_length)
{
  FILE *f;
  size_t n;

  if (!path || !buffer || buffer_size == 0 || !out_length) {
    return RA_EARG;
  }

  *out_length = 0;
  f = fopen(path, "rb");
  if (!f) {
    return RA_EIO;
  }

  n = fread(buffer, 1, buffer_size - 1, f);
  if (ferror(f)) {
    fclose(f);
    return RA_EIO;
  }
  buffer[n] = '\0';
  *out_length = n;

  if (!feof(f)) {
    fclose(f);
    return RA_ESIZE;
  }

  fclose(f);
  return RA_OK;
}

static int ra_remove_tree_impl(const char *path)
{
  struct stat st;

  if (lstat(path, &st) != 0) {
    return -1;
  }

  if (S_ISDIR(st.st_mode)) {
    DIR *dir = opendir(path);
    struct dirent *ent;
    if (!dir) {
      return -1;
    }
    while ((ent = readdir(dir)) != NULL) {
      char child[PATH_MAX];
      if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0) {
        continue;
      }
      if (snprintf(child, sizeof(child), "%s/%s", path, ent->d_name) >= (int)sizeof(child)) {
        closedir(dir);
        return -1;
      }
      if (ra_remove_tree_impl(child) != 0) {
        closedir(dir);
        return -1;
      }
    }
    closedir(dir);
    return rmdir(path);
  }

  return unlink(path);
}

int ta_remove_tree(const char *path)
{
  if (!path || !*path) {
    return -1;
  }
  return ra_remove_tree_impl(path);
}

int ta_stat_check(const char *path, int must_exist, long min_size)
{
  struct stat st;

  if (!path || !*path) {
    return -1;
  }

  if (stat(path, &st) != 0) {
    return must_exist ? -1 : 0;
  }

  if (min_size >= 0 && st.st_size < min_size) {
    return -1;
  }

  return 0;
}

int ta_touch(const char *path)
{
  int fd;

  if (!path || !*path) {
    return -1;
  }

  fd = open(path, O_CREAT | O_WRONLY, 0666);
  if (fd < 0) {
    return -1;
  }
  close(fd);

  if (utime(path, NULL) != 0) {
    return -1;
  }

  return 0;
}

int ta_write_file(const char *path, const void *buffer, size_t length)
{
  FILE *f;

  if (!path || (!buffer && length > 0)) {
    return -1;
  }

  f = fopen(path, "wb");
  if (!f) {
    return -1;
  }

  if (length > 0 && fwrite(buffer, 1, length, f) != length) {
    fclose(f);
    return -1;
  }

  if (fflush(f) != 0) {
    fclose(f);
    return -1;
  }

  fclose(f);
  return 0;
}

static int ra_cmp_file_result(int rc)
{
  if (rc > 0) {
    return RA_OK;
  }
  if (rc == 0) {
    return RA_MISMATCH;
  }
  return RA_EIO;
}

static size_t ra_line_content_len(const char *line, size_t len, int ignore_line_endings)
{
  if (len > 0 && line[len - 1] == '\n') {
    --len;
    if (ignore_line_endings && len > 0 && line[len - 1] == '\r') {
      --len;
    }
  }
  return len;
}

static size_t ra_trimmed_line_len(const char *line, size_t len, int ignore_line_endings)
{
  len = ra_line_content_len(line, len, ignore_line_endings);
  while (len > 0 && isspace((unsigned char)line[len - 1]) && line[len - 1] != '\n' &&
         line[len - 1] != '\r') {
    --len;
  }
  return len;
}

static int ra_line_is_empty_for_compare(const char *line, size_t len, int flags)
{
  size_t i;

  len = ra_line_content_len(line, len, (flags & RA_FILECMP_IGNORE_LINE_ENDINGS) != 0);
  for (i = 0; i < len; ++i) {
    if (!isspace((unsigned char)line[i])) {
      return 0;
    }
  }
  return 1;
}

static size_t ra_span_timestamp_token(const char *s, size_t len)
{
  size_t i = 0;

  if (len >= 10 && isdigit((unsigned char)s[0]) && isdigit((unsigned char)s[1]) &&
      isdigit((unsigned char)s[2]) && isdigit((unsigned char)s[3]) && s[4] == '-' &&
      isdigit((unsigned char)s[5]) && isdigit((unsigned char)s[6]) && s[7] == '-' &&
      isdigit((unsigned char)s[8]) && isdigit((unsigned char)s[9])) {
    i = 10;
    if (len > i && (s[i] == 'T' || s[i] == ' ')) {
      size_t t = i + 1;
      if (len >= t + 8 && isdigit((unsigned char)s[t]) && isdigit((unsigned char)s[t + 1]) &&
          s[t + 2] == ':' && isdigit((unsigned char)s[t + 3]) &&
          isdigit((unsigned char)s[t + 4]) && s[t + 5] == ':' &&
          isdigit((unsigned char)s[t + 6]) && isdigit((unsigned char)s[t + 7])) {
        i = t + 8;
        if (len > i && s[i] == '.') {
          ++i;
          while (i < len && isdigit((unsigned char)s[i])) {
            ++i;
          }
        }
        if (len > i && (s[i] == 'Z' || s[i] == 'z')) {
          ++i;
        } else if (len > i && (s[i] == '+' || s[i] == '-')) {
          size_t z = i + 1;
          if (len >= z + 4 && isdigit((unsigned char)s[z]) && isdigit((unsigned char)s[z + 1]) &&
              s[z + 2] == ':' && isdigit((unsigned char)s[z + 3]) &&
              isdigit((unsigned char)s[z + 4])) {
            i = z + 5;
          }
        }
      }
    }
    return i;
  }

  if (len >= 8 && isdigit((unsigned char)s[0]) && isdigit((unsigned char)s[1]) &&
      s[2] == ':' && isdigit((unsigned char)s[3]) && isdigit((unsigned char)s[4]) &&
      s[5] == ':' && isdigit((unsigned char)s[6]) && isdigit((unsigned char)s[7])) {
    i = 8;
    if (len > i && s[i] == '.') {
      ++i;
      while (i < len && isdigit((unsigned char)s[i])) {
        ++i;
      }
    }
    return i;
  }

  return 0;
}

static int ra_append_compare_char(char **dst, size_t *remaining, char c)
{
  if (!dst || !*dst || !remaining || *remaining == 0) {
    return RA_ESIZE;
  }
  **dst = c;
  ++(*dst);
  --(*remaining);
  return RA_OK;
}

static int ra_normalize_compare_line(const char *line,
                                     size_t len,
                                     int flags,
                                     char **out_line)
{
  size_t content_len;
  size_t out_cap;
  char *buf;
  char *dst;
  size_t remaining;
  size_t i;
  int alloc_err = 0;
  int ignore_line_endings = (flags & RA_FILECMP_IGNORE_LINE_ENDINGS) != 0;

  if (!line || !out_line) {
    return RA_EARG;
  }

  content_len = (flags & RA_FILECMP_IGNORE_TRAILING_WHITESPACE) != 0
                  ? ra_trimmed_line_len(line, len, ignore_line_endings)
                  : ra_line_content_len(line, len, ignore_line_endings);
  out_cap = (content_len * 2) + 8;
  buf = (char *)ra_malloc_checked(out_cap, &alloc_err);
  if (!buf) {
    return alloc_err;
  }

  dst = buf;
  remaining = out_cap;

  for (i = 0; i < content_len; ++i) {
    size_t span = 0;
    char c = line[i];

    if ((flags & RA_FILECMP_IGNORE_TIMESTAMPS) != 0) {
      span = ra_span_timestamp_token(line + i, content_len - i);
      if (span > 0) {
        if (ra_append_compare_char(&dst, &remaining, '<') != RA_OK ||
            ra_append_compare_char(&dst, &remaining, 'T') != RA_OK ||
            ra_append_compare_char(&dst, &remaining, 'S') != RA_OK ||
            ra_append_compare_char(&dst, &remaining, '>') != RA_OK) {
          g_free_fn(buf);
          return RA_ESIZE;
        }
        i += span - 1;
        continue;
      }
    }

    if ((flags & RA_FILECMP_CASE_INSENSITIVE) != 0) {
      c = (char)tolower((unsigned char)c);
    }
    if (ra_append_compare_char(&dst, &remaining, c) != RA_OK) {
      g_free_fn(buf);
      return RA_ESIZE;
    }
  }

  if (!ignore_line_endings && len > content_len) {
    if (len >= 2 && line[len - 2] == '\r' && line[len - 1] == '\n') {
      if (ra_append_compare_char(&dst, &remaining, '\r') != RA_OK ||
          ra_append_compare_char(&dst, &remaining, '\n') != RA_OK) {
        g_free_fn(buf);
        return RA_ESIZE;
      }
    } else if (line[len - 1] == '\n') {
      if (ra_append_compare_char(&dst, &remaining, '\n') != RA_OK) {
        g_free_fn(buf);
        return RA_ESIZE;
      }
    }
  }

  if (ra_append_compare_char(&dst, &remaining, '\0') != RA_OK) {
    g_free_fn(buf);
    return RA_ESIZE;
  }

  *out_line = buf;
  return RA_OK;
}

static int ra_compile_patterns(const char **patterns, size_t pattern_count, regex_t **out_patterns)
{
  regex_t *compiled;
  size_t i;
  int alloc_err = 0;

  if (!out_patterns) {
    return RA_EARG;
  }
  *out_patterns = NULL;
  if (!patterns || pattern_count == 0) {
    return RA_OK;
  }

  compiled = (regex_t *)ra_malloc_checked(sizeof(*compiled) * pattern_count, &alloc_err);
  if (!compiled) {
    return alloc_err;
  }

  for (i = 0; i < pattern_count; ++i) {
    if (!patterns[i] || regcomp(&compiled[i], patterns[i], REG_EXTENDED | REG_NOSUB) != 0) {
      while (i > 0) {
        --i;
        regfree(&compiled[i]);
      }
      g_free_fn(compiled);
      return RA_EPARSE;
    }
  }

  *out_patterns = compiled;
  return RA_OK;
}

static void ra_free_patterns(regex_t *patterns, size_t pattern_count)
{
  size_t i;

  if (!patterns) {
    return;
  }
  for (i = 0; i < pattern_count; ++i) {
    regfree(&patterns[i]);
  }
  g_free_fn(patterns);
}

static int ra_line_matches_patterns(const char *line,
                                    size_t len,
                                    regex_t *patterns,
                                    size_t pattern_count)
{
  size_t content_len;
  char *copy;
  size_t i;
  int alloc_err = 0;
  int matched = 0;

  if (!patterns || pattern_count == 0) {
    return 0;
  }

  content_len = ra_line_content_len(line, len, 1);
  copy = (char *)ra_malloc_checked(content_len + 1, &alloc_err);
  if (!copy) {
    return 0;
  }

  memcpy(copy, line, content_len);
  copy[content_len] = '\0';

  for (i = 0; i < pattern_count; ++i) {
    if (regexec(&patterns[i], copy, 0, NULL, 0) == 0) {
      matched = 1;
      break;
    }
  }

  g_free_fn(copy);
  return matched;
}

static int ra_next_compare_line(FILE *f,
                                char **line,
                                size_t *cap,
                                ssize_t *len,
                                int flags,
                                regex_t *patterns,
                                size_t pattern_count)
{
  ssize_t read_len;

  if (!f || !line || !cap || !len) {
    return RA_EARG;
  }

  for (;;) {
    read_len = getline(line, cap, f);
    if (read_len < 0) {
      if (ferror(f)) {
        return RA_EIO;
      }
      *len = -1;
      return RA_OK;
    }

    if ((flags & RA_FILECMP_IGNORE_EMPTY_LINES) != 0 &&
        ra_line_is_empty_for_compare(*line, (size_t)read_len, flags)) {
      continue;
    }
    if (ra_line_matches_patterns(*line, (size_t)read_len, patterns, pattern_count)) {
      continue;
    }

    *len = read_len;
    return RA_OK;
  }
}

static int ra_compare_file_streams(FILE *f1,
                                   FILE *f2,
                                   int flags,
                                   regex_t *patterns,
                                   size_t pattern_count)
{
  char *line1 = NULL;
  char *line2 = NULL;
  size_t cap1 = 0;
  size_t cap2 = 0;
  ssize_t len1 = 0;
  ssize_t len2 = 0;
  int rc;

  for (;;) {
    char *norm1 = NULL;
    char *norm2 = NULL;

    rc = ra_next_compare_line(f1, &line1, &cap1, &len1, flags, patterns, pattern_count);
    if (rc != RA_OK) {
      break;
    }
    rc = ra_next_compare_line(f2, &line2, &cap2, &len2, flags, patterns, pattern_count);
    if (rc != RA_OK) {
      break;
    }

    if (len1 < 0 || len2 < 0) {
      rc = (len1 == len2) ? RA_OK : RA_MISMATCH;
      break;
    }

    rc = ra_normalize_compare_line(line1, (size_t)len1, flags, &norm1);
    if (rc != RA_OK) {
      g_free_fn(norm1);
      break;
    }
    rc = ra_normalize_compare_line(line2, (size_t)len2, flags, &norm2);
    if (rc != RA_OK) {
      g_free_fn(norm1);
      g_free_fn(norm2);
      break;
    }

    if (strcmp(norm1, norm2) != 0) {
      g_free_fn(norm1);
      g_free_fn(norm2);
      rc = RA_MISMATCH;
      break;
    }

    g_free_fn(norm1);
    g_free_fn(norm2);
  }

  free(line1);
  free(line2);
  return rc;
}

static int ra_field_name_matches(const char *name,
                                 size_t name_len,
                                 const char **field_names,
                                 size_t field_count)
{
  size_t i;

  for (i = 0; i < field_count; ++i) {
    if (field_names[i] && strlen(field_names[i]) == name_len &&
        strncmp(name, field_names[i], name_len) == 0) {
      return 1;
    }
  }
  return 0;
}

static char *ra_skip_ws_chars(char *p)
{
  while (p && *p && isspace((unsigned char)*p) && *p != '\n' && *p != '\r') {
    ++p;
  }
  return p;
}

static char *ra_mask_json_value(char *p)
{
  char open;
  char close;
  int depth;

  if (!p || !*p) {
    return p;
  }

  p = ra_skip_ws_chars(p);
  if (*p == '"') {
    char *q = p + 1;
    while (*q) {
      if (*q == '\\' && q[1] != '\0') {
        *q = '#';
        ++q;
        *q = '#';
      } else if (*q == '"') {
        return q;
      } else {
        *q = '#';
      }
      ++q;
    }
    return q;
  }

  if (*p == '{' || *p == '[') {
    open = *p;
    close = (open == '{') ? '}' : ']';
    depth = 1;
    ++p;
    while (*p && depth > 0) {
      if (*p == '"') {
        char *q = p + 1;
        while (*q) {
          if (*q == '\\' && q[1] != '\0') {
            ++q;
          } else if (*q == '"') {
            break;
          }
          ++q;
        }
        p = q;
      } else if (*p == open) {
        ++depth;
      } else if (*p == close) {
        --depth;
      }
      if (depth > 0) {
        *p = '#';
      }
      ++p;
    }
    return p - 1;
  }

  while (*p && *p != ',' && *p != '\n' && *p != '\r' && *p != '}' && *p != ']') {
    if (!isspace((unsigned char)*p)) {
      *p = '#';
    }
    ++p;
  }
  return p - 1;
}

static void ra_mask_field_values(char *text, const char **field_names, size_t field_count)
{
  char *p;
  int line_start = 1;

  if (!text || !field_names || field_count == 0) {
    return;
  }

  p = text;
  while (*p) {
    if (line_start) {
      char *line = p;
      char *name_start;
      char *name_end;
      char *cursor;

      while (*line == ' ' || *line == '\t') {
        ++line;
      }
      name_start = line;
      while ((*line >= 'A' && *line <= 'Z') || (*line >= 'a' && *line <= 'z') ||
             (*line >= '0' && *line <= '9') || *line == '_' || *line == '-') {
        ++line;
      }
      name_end = line;
      cursor = ra_skip_ws_chars(line);
      if ((*cursor == '=' || *cursor == ':') &&
          ra_field_name_matches(name_start, (size_t)(name_end - name_start), field_names, field_count)) {
        cursor = ra_skip_ws_chars(cursor + 1);
        while (*cursor && *cursor != '\n' && *cursor != '\r') {
          if (!isspace((unsigned char)*cursor)) {
            *cursor = '#';
          }
          ++cursor;
        }
      }
    }

    if (*p == '"') {
      char *key_start = p + 1;
      char *q = key_start;
      while (*q) {
        if (*q == '\\' && q[1] != '\0') {
          q += 2;
          continue;
        }
        if (*q == '"') {
          break;
        }
        ++q;
      }
      if (*q == '"') {
        char *after = ra_skip_ws_chars(q + 1);
        if (*after == ':' && ra_field_name_matches(key_start, (size_t)(q - key_start), field_names, field_count)) {
          p = ra_mask_json_value(after + 1);
        }
      }
    }

    line_start = (*p == '\n' || *p == '\r');
    ++p;
  }
}

int ta_compare_files(FILE *left_file, FILE *right_file)
{
  int c1;
  int c2;

  if (!left_file || !right_file) {
    return -1;
  }

  if (fseek(left_file, 0L, SEEK_SET) != 0 || fseek(right_file, 0L, SEEK_SET) != 0) {
    return -1;
  }

  for (;;) {
    c1 = fgetc(left_file);
    c2 = fgetc(right_file);

    if (c1 != c2) {
      return 0;
    }

    if (c1 == EOF) {
      if (ferror(left_file) || ferror(right_file)) {
        return -1;
      }
      return 1;
    }
  }
}

int ta_compare_file_to_path(FILE *file, const char *path)
{
  FILE *other;
  int rc;

  if (!file || !path) {
    return -1;
  }

  other = fopen(path, "rb");
  if (!other) {
    return -1;
  }

  rc = ta_compare_files(file, other);
  fclose(other);
  return rc;
}

int ta_compare_paths(const char *left_path, const char *right_path)
{
  FILE *f1;
  FILE *f2;
  int rc;

  if (!left_path || !right_path) {
    return -1;
  }

  f1 = fopen(left_path, "rb");
  if (!f1) {
    return -1;
  }

  f2 = fopen(right_path, "rb");
  if (!f2) {
    fclose(f1);
    return -1;
  }

  rc = ta_compare_files(f1, f2);
  fclose(f1);
  fclose(f2);
  return rc;
}

int ta_compare_path_to_file(const char *path, FILE *file)
{
  return ta_compare_file_to_path(file, path);
}

int ta_compare_paths_with_options(const char *left_path,
                                  const char *right_path,
                                  const ra_path_compare_options_t *options)
{
  FILE *f1;
  FILE *f2;
  int rc;
  int flags = options ? options->flags : 0;

  if (!left_path || !right_path) {
    return RA_EARG;
  }
  if (flags == 0) {
    return ra_cmp_file_result(ta_compare_paths(left_path, right_path));
  }

  f1 = fopen(left_path, "rb");
  if (!f1) {
    return RA_EIO;
  }
  f2 = fopen(right_path, "rb");
  if (!f2) {
    fclose(f1);
    return RA_EIO;
  }

  rc = ra_compare_file_streams(f1, f2, flags, NULL, 0);
  fclose(f1);
  fclose(f2);
  return rc;
}

int ta_compare_paths_ignoring_patterns(const char *left_path,
                                       const char *right_path,
                               const char **ignore_patterns,
                               size_t pattern_count)
{
  FILE *f1;
  FILE *f2;
  regex_t *patterns = NULL;
  int rc;

  if (!left_path || !right_path || (pattern_count > 0 && !ignore_patterns)) {
    return RA_EARG;
  }

  rc = ra_compile_patterns(ignore_patterns, pattern_count, &patterns);
  if (rc != RA_OK) {
    return rc;
  }

  f1 = fopen(left_path, "rb");
  if (!f1) {
    ra_free_patterns(patterns, pattern_count);
    return RA_EIO;
  }
  f2 = fopen(right_path, "rb");
  if (!f2) {
    fclose(f1);
    ra_free_patterns(patterns, pattern_count);
    return RA_EIO;
  }

  rc = ra_compare_file_streams(f1, f2, 0, patterns, pattern_count);
  fclose(f1);
  fclose(f2);
  ra_free_patterns(patterns, pattern_count);
  return rc;
}

int ta_compare_paths_masking_fields(const char *left_path,
                                    const char *right_path,
                           const char **field_names,
                           size_t field_count)
{
  char *text1 = NULL;
  char *text2 = NULL;
  size_t len1 = 0;
  size_t len2 = 0;
  int rc;

  if (!left_path || !right_path || (field_count > 0 && !field_names)) {
    return RA_EARG;
  }

  rc = ta_read_file_with_limit(left_path, 0, &text1, &len1);
  if (rc != RA_OK) {
    return rc;
  }
  rc = ta_read_file_with_limit(right_path, 0, &text2, &len2);
  if (rc != RA_OK) {
    g_free_fn(text1);
    return rc;
  }

  (void)len1;
  (void)len2;
  ra_mask_field_values(text1, field_names, field_count);
  ra_mask_field_values(text2, field_names, field_count);

  rc = (strcmp(text1, text2) == 0) ? RA_OK : RA_MISMATCH;
  g_free_fn(text1);
  g_free_fn(text2);
  return rc;
}

static int ra_offset_is_masked(size_t offset,
                               const size_t *skip_offsets,
                               const size_t *skip_lengths,
                               size_t range_count)
{
  size_t i;

  for (i = 0; i < range_count; ++i) {
    size_t start = skip_offsets[i];
    size_t length = skip_lengths[i];
    size_t end;

    if (length == 0) {
      continue;
    }
    if (start > SIZE_MAX - length) {
      end = SIZE_MAX;
    } else {
      end = start + length;
    }
    if (offset >= start && offset < end) {
      return 1;
    }
  }

  return 0;
}

int ta_compare_paths_masking_ranges(const char *left_path,
                                    const char *right_path,
                           const size_t *skip_offsets,
                           const size_t *skip_lengths,
                           size_t range_count)
{
  char *buf1 = NULL;
  char *buf2 = NULL;
  size_t len1 = 0;
  size_t len2 = 0;
  size_t i;
  size_t limit;
  int rc;

  if (!left_path || !right_path ||
      (range_count > 0 && (!skip_offsets || !skip_lengths))) {
    return RA_EARG;
  }

  rc = ta_read_file_with_limit(left_path, 0, &buf1, &len1);
  if (rc != RA_OK) {
    return rc;
  }
  rc = ta_read_file_with_limit(right_path, 0, &buf2, &len2);
  if (rc != RA_OK) {
    g_free_fn(buf1);
    return rc;
  }

  limit = (len1 > len2) ? len1 : len2;
  rc = RA_OK;
  for (i = 0; i < limit; ++i) {
    unsigned char b1 = 0;
    unsigned char b2 = 0;
    int in1 = (i < len1);
    int in2 = (i < len2);

    if (ra_offset_is_masked(i, skip_offsets, skip_lengths, range_count)) {
      continue;
    }
    if (!in1 || !in2) {
      rc = RA_MISMATCH;
      break;
    }

    b1 = (unsigned char)buf1[i];
    b2 = (unsigned char)buf2[i];
    if (b1 != b2) {
      rc = RA_MISMATCH;
      break;
    }
  }

  g_free_fn(buf1);
  g_free_fn(buf2);
  return rc;
}

static int ra_mode_type(mode_t mode)
{
  if (S_ISREG(mode)) return S_IFREG;
  if (S_ISDIR(mode)) return S_IFDIR;
  if (S_ISLNK(mode)) return S_IFLNK;
  if (S_ISCHR(mode)) return S_IFCHR;
  if (S_ISBLK(mode)) return S_IFBLK;
  if (S_ISFIFO(mode)) return S_IFIFO;
#ifdef S_IFSOCK
  if (S_ISSOCK(mode)) return S_IFSOCK;
#endif
  return 0;
}

int ta_compare_path_metadata(const char *left_path,
                             const char *right_path,
                             const ra_path_metadata_compare_options_t *options)
{
  struct stat st1;
  struct stat st2;
  int flags = options ? options->flags : 0;

  if (!left_path || !right_path) {
    return RA_EARG;
  }
  if (flags == 0) {
    flags = RA_STATCMP_SIZE | RA_STATCMP_PERMS | RA_STATCMP_TYPE;
  }

  if (stat(left_path, &st1) != 0 || stat(right_path, &st2) != 0) {
    return RA_EIO;
  }

  if ((flags & RA_STATCMP_SIZE) != 0 && st1.st_size != st2.st_size) {
    return RA_MISMATCH;
  }
  if ((flags & RA_STATCMP_PERMS) != 0 &&
      (st1.st_mode & 07777) != (st2.st_mode & 07777)) {
    return RA_MISMATCH;
  }
  if ((flags & RA_STATCMP_MTIME) != 0 && st1.st_mtime != st2.st_mtime) {
    return RA_MISMATCH;
  }
  if ((flags & RA_STATCMP_OWNER) != 0 &&
      (st1.st_uid != st2.st_uid || st1.st_gid != st2.st_gid)) {
    return RA_MISMATCH;
  }
  if ((flags & RA_STATCMP_TYPE) != 0 &&
      ra_mode_type(st1.st_mode) != ra_mode_type(st2.st_mode)) {
    return RA_MISMATCH;
  }

  return RA_OK;
}

static int ra_cmp_entry_type(mode_t m1, mode_t m2)
{
  if (S_ISDIR(m1) && S_ISDIR(m2)) return 1;
  if (S_ISREG(m1) && S_ISREG(m2)) return 1;
  if (S_ISLNK(m1) && S_ISLNK(m2)) return 1;
  return 0;
}

static int ra_dircmp_impl(const char *dir1, const char *dir2, int recursive)
{
  DIR *d1;
  DIR *d2;
  struct dirent *ent;

  d1 = opendir(dir1);
  d2 = opendir(dir2);
  if (!d1 || !d2) {
    if (d1) closedir(d1);
    if (d2) closedir(d2);
    return RA_EIO;
  }

  while ((ent = readdir(d1)) != NULL) {
    struct stat s1;
    struct stat s2;
    char p1[PATH_MAX];
    char p2[PATH_MAX];

    if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0) {
      continue;
    }

    if (snprintf(p1, sizeof(p1), "%s/%s", dir1, ent->d_name) >= (int)sizeof(p1) ||
        snprintf(p2, sizeof(p2), "%s/%s", dir2, ent->d_name) >= (int)sizeof(p2)) {
      closedir(d1);
      closedir(d2);
      return RA_ESIZE;
    }

    if (lstat(p1, &s1) != 0 || lstat(p2, &s2) != 0) {
      closedir(d1);
      closedir(d2);
      return RA_EIO;
    }

    if (!ra_cmp_entry_type(s1.st_mode, s2.st_mode)) {
      closedir(d1);
      closedir(d2);
      return RA_MISMATCH;
    }

    if (S_ISREG(s1.st_mode)) {
      int frc = ta_compare_paths(p1, p2);
      if (frc != 1) {
        closedir(d1);
        closedir(d2);
        return (frc < 0) ? RA_EIO : RA_MISMATCH;
      }
    } else if (S_ISDIR(s1.st_mode) && recursive) {
      int dir_rc = ra_dircmp_impl(p1, p2, recursive);
      if (dir_rc != RA_OK) {
        closedir(d1);
        closedir(d2);
        return dir_rc;
      }
    }
  }

  while ((ent = readdir(d2)) != NULL) {
    char p1[PATH_MAX];
    if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0) {
      continue;
    }
    if (snprintf(p1, sizeof(p1), "%s/%s", dir1, ent->d_name) >= (int)sizeof(p1)) {
      closedir(d1);
      closedir(d2);
      return RA_ESIZE;
    }
    if (access(p1, F_OK) != 0) {
      closedir(d1);
      closedir(d2);
      return (errno == ENOENT) ? RA_MISMATCH : RA_EIO;
    }
  }

  closedir(d1);
  closedir(d2);
  return RA_OK;
}

int ta_compare_dirs(const char *left_path, const char *right_path, int recursive)
{
  if (!left_path || !right_path) {
    return RA_EARG;
  }
  return ra_dircmp_impl(left_path, right_path, recursive != 0);
}

int ta_hexdump_diff(const void *a, const void *b, size_t n, size_t context)
{
  const unsigned char *ba = (const unsigned char *)a;
  const unsigned char *bb = (const unsigned char *)b;
  size_t i;

  (void)context;

  if ((!a && n > 0) || (!b && n > 0)) {
    return RA_EARG;
  }

  for (i = 0; i < n; ++i) {
    if (ba[i] != bb[i]) {
      return RA_MISMATCH;
    }
  }
  return RA_OK;
}

typedef struct {
  char *data;
  size_t len;
  size_t cap;
} ra_sb_t;

typedef struct {
  char *key;
  char *value;
} ra_json_kv_t;

static int ra_sb_reserve(ra_sb_t *sb, size_t add)
{
  size_t need;
  size_t new_cap;
  char *next;
  int err = 0;

  if (!sb) {
    return RA_EARG;
  }

  if (ra_add_overflow_size(sb->len, add, &need) != 0 ||
      ra_add_overflow_size(need, 1, &need) != 0) {
    return RA_ESIZE;
  }
  if (need <= sb->cap) {
    return RA_OK;
  }

  if (need > RA_ALLOC_MAX_BYTES) {
    return RA_ESIZE;
  }

  new_cap = sb->cap ? sb->cap : 128;
  while (new_cap < need) {
    if (new_cap > (SIZE_MAX / 2)) {
      return RA_ESIZE;
    }
    new_cap *= 2;
    if (new_cap > RA_ALLOC_MAX_BYTES) {
      new_cap = RA_ALLOC_MAX_BYTES;
      break;
    }
  }

  next = (char *)ra_realloc_checked(sb->data, new_cap, &err);
  if (!next) {
    return err;
  }

  sb->data = next;
  sb->cap = new_cap;
  return RA_OK;
}

static int ra_sb_append_n(ra_sb_t *sb, const char *s, size_t n)
{
  if (!sb || (!s && n > 0) || ra_sb_reserve(sb, n) != 0) {
    return RA_EARG;
  }
  if (n > 0) {
    memcpy(sb->data + sb->len, s, n);
    sb->len += n;
  }
  sb->data[sb->len] = '\0';
  return RA_OK;
}

static int ra_sb_append_c(ra_sb_t *sb, char c)
{
  return ra_sb_append_n(sb, &c, 1);
}

static void ra_json_skip_ws(const char **p)
{
  while (p && *p && **p && isspace((unsigned char)**p)) {
    ++(*p);
  }
}

static int ra_json_append_string(const char **p, ra_sb_t *out)
{
  const char *start;
  int escape = 0;

  if (!p || !*p || **p != '"' || !out) {
    return RA_EPARSE;
  }

  start = *p;
  ++(*p);
  while (**p) {
    char c = **p;
    ++(*p);
    if (escape) {
      escape = 0;
      continue;
    }
    if (c == '\\') {
      escape = 1;
      continue;
    }
    if (c == '"') {
      return ra_sb_append_n(out, start, (size_t)(*p - start)) ? RA_ESIZE : RA_OK;
    }
  }

  return RA_EPARSE;
}

static int ra_json_append_number(const char **p, ra_sb_t *out)
{
  const char *start = *p;
  while (**p && strchr("0123456789+-.eE", **p) != NULL) {
    ++(*p);
  }
  if (*p == start) {
    return RA_EPARSE;
  }
  return ra_sb_append_n(out, start, (size_t)(*p - start)) ? RA_ESIZE : RA_OK;
}

static int ra_json_append_literal(const char **p, ra_sb_t *out)
{
  if (strncmp(*p, "true", 4) == 0) {
    *p += 4;
    return ra_sb_append_n(out, "true", 4) ? RA_ESIZE : RA_OK;
  }
  if (strncmp(*p, "false", 5) == 0) {
    *p += 5;
    return ra_sb_append_n(out, "false", 5) ? RA_ESIZE : RA_OK;
  }
  if (strncmp(*p, "null", 4) == 0) {
    *p += 4;
    return ra_sb_append_n(out, "null", 4) ? RA_ESIZE : RA_OK;
  }
  return RA_EPARSE;
}

static int ra_json_normalize_value(const char **p, ra_sb_t *out, int sort_keys);

static int ra_json_kv_cmp(const void *a, const void *b)
{
  const ra_json_kv_t *ka = (const ra_json_kv_t *)a;
  const ra_json_kv_t *kb = (const ra_json_kv_t *)b;
  return strcmp(ka->key, kb->key);
}

static int ra_json_normalize_object(const char **p, ra_sb_t *out, int sort_keys)
{
  ra_json_kv_t *items = NULL;
  size_t count = 0;
  size_t cap = 0;
  int rc = RA_EPARSE;
  size_t i;

  if (**p != '{' || ra_sb_append_c(out, '{') != 0) {
    return RA_EPARSE;
  }
  ++(*p);
  ra_json_skip_ws(p);

  if (**p == '}') {
    ++(*p);
    return ra_sb_append_c(out, '}') ? RA_ESIZE : RA_OK;
  }

  while (**p) {
    ra_sb_t key = {0};
    ra_sb_t value = {0};

    ra_json_skip_ws(p);
    if (ra_json_append_string(p, &key) != 0) {
      g_free_fn(key.data);
      goto cleanup;
    }

    ra_json_skip_ws(p);
    if (**p != ':') {
      g_free_fn(key.data);
      goto cleanup;
    }
    ++(*p);

    ra_json_skip_ws(p);
    if (ra_json_normalize_value(p, &value, sort_keys) != 0) {
      g_free_fn(key.data);
      g_free_fn(value.data);
      goto cleanup;
    }

    if (count == cap) {
      size_t next_cap = cap ? cap * 2 : 8;
      size_t bytes;
      ra_json_kv_t *next;
      int alloc_err = 0;

      if (next_cap < cap ||
          ra_mul_overflow_size(next_cap, sizeof(*items), &bytes) != 0 ||
          bytes > RA_ALLOC_MAX_BYTES) {
        g_free_fn(key.data);
        g_free_fn(value.data);
        goto cleanup;
      }

      next = (ra_json_kv_t *)ra_realloc_checked(items, bytes, &alloc_err);
      if (!next) {
        g_free_fn(key.data);
        g_free_fn(value.data);
        goto cleanup;
      }
      items = next;
      cap = next_cap;
    }

    items[count].key = key.data;
    items[count].value = value.data;
    ++count;

    ra_json_skip_ws(p);
    if (**p == ',') {
      ++(*p);
      continue;
    }
    if (**p == '}') {
      ++(*p);
      break;
    }
    goto cleanup;
  }

  if (sort_keys && count > 1) {
    qsort(items, count, sizeof(*items), ra_json_kv_cmp);
  }

  for (i = 0; i < count; ++i) {
    if (i > 0 && ra_sb_append_c(out, ',') != 0) {
      goto cleanup;
    }
    if (ra_sb_append_n(out, items[i].key, strlen(items[i].key)) != 0 ||
        ra_sb_append_c(out, ':') != 0 ||
        ra_sb_append_n(out, items[i].value, strlen(items[i].value)) != 0) {
      goto cleanup;
    }
  }
  if (ra_sb_append_c(out, '}') != 0) {
    goto cleanup;
  }

  rc = RA_OK;

cleanup:
  for (i = 0; i < count; ++i) {
    g_free_fn(items[i].key);
    g_free_fn(items[i].value);
  }
  g_free_fn(items);
  return rc;
}

static int ra_json_normalize_array(const char **p, ra_sb_t *out, int sort_keys)
{
  int first = 1;

  if (**p != '[' || ra_sb_append_c(out, '[') != 0) {
    return RA_EPARSE;
  }
  ++(*p);
  ra_json_skip_ws(p);

  if (**p == ']') {
    ++(*p);
    return ra_sb_append_c(out, ']') ? RA_ESIZE : RA_OK;
  }

  while (**p) {
    ra_json_skip_ws(p);
    if (!first && ra_sb_append_c(out, ',') != 0) {
      return RA_ESIZE;
    }
    if (ra_json_normalize_value(p, out, sort_keys) != 0) {
      return RA_EPARSE;
    }
    first = 0;

    ra_json_skip_ws(p);
    if (**p == ',') {
      ++(*p);
      continue;
    }
    if (**p == ']') {
      ++(*p);
      return ra_sb_append_c(out, ']') ? RA_ESIZE : RA_OK;
    }
    return RA_EPARSE;
  }

  return RA_EPARSE;
}

static int ra_json_normalize_value(const char **p, ra_sb_t *out, int sort_keys)
{
  ra_json_skip_ws(p);
  if (!p || !*p || !**p) {
    return RA_EPARSE;
  }

  if (**p == '{') {
    return ra_json_normalize_object(p, out, sort_keys);
  }
  if (**p == '[') {
    return ra_json_normalize_array(p, out, sort_keys);
  }
  if (**p == '"') {
    return ra_json_append_string(p, out);
  }
  if (**p == 't' || **p == 'f' || **p == 'n') {
    return ra_json_append_literal(p, out);
  }
  return ra_json_append_number(p, out);
}

static char *ra_json_normalize(const char *s, int sort_keys)
{
  const char *p = s;
  ra_sb_t out = {0};

  if (!s) {
    return NULL;
  }

  ra_json_skip_ws(&p);
  if (ra_json_normalize_value(&p, &out, sort_keys) != 0) {
    g_free_fn(out.data);
    return NULL;
  }
  ra_json_skip_ws(&p);
  if (*p != '\0') {
    g_free_fn(out.data);
    return NULL;
  }
  if (!out.data && ra_sb_append_c(&out, '\0') != 0) {
    return NULL;
  }

  return out.data;
}

int ta_compare_json_with_limit(const char *expected_json,
                               const char *actual_json,
                               const ra_json_compare_options_t *options)
{
  char *e;
  char *a;
  int rc;
  size_t max_bytes = options ? options->max_bytes : 0;
  int ignore_key_order = options ? options->ignore_key_order : 0;

  if (!expected_json || !actual_json) {
    return RA_EARG;
  }

  if (max_bytes > 0 && max_bytes < RA_ALLOC_MAX_BYTES) {
    size_t elen = strnlen(expected_json, max_bytes + 1);
    size_t alen = strnlen(actual_json, max_bytes + 1);
    if (elen > max_bytes || alen > max_bytes) {
      return RA_ESIZE;
    }
  }

  e = ra_json_normalize(expected_json, ignore_key_order != 0);
  a = ra_json_normalize(actual_json, ignore_key_order != 0);
  if (!e || !a) {
    if (e) g_free_fn(e);
    if (a) g_free_fn(a);
    return RA_EPARSE;
  }

  rc = strcmp(e, a) == 0 ? RA_OK : RA_MISMATCH;
  g_free_fn(e);
  g_free_fn(a);
  return rc;
}

int ta_compare_json(const char *expected_json, const char *actual_json)
{
  return ta_compare_json_with_limit(expected_json, actual_json, NULL);
}

static int ra_match_impl(const char *text, const char *pattern)
{
  while (*pattern) {
    if (*pattern == '*') {
      while (*pattern == '*') {
        ++pattern;
      }
      if (!*pattern) {
        return 1;
      }
      while (*text) {
        if (ra_match_impl(text, pattern)) {
          return 1;
        }
        ++text;
      }
      return 0;
    }

    if (*pattern == '?') {
      if (!*text) {
        return 0;
      }
      ++text;
      ++pattern;
      continue;
    }

    if (*text != *pattern) {
      return 0;
    }

    ++text;
    ++pattern;
  }

  return *text == '\0';
}

int ta_match(const char *text, const char *pattern)
{
  if (!text || !pattern) {
    return -1;
  }
  return ra_match_impl(text, pattern) ? 1 : 0;
}

int ta_compare_memory_detail(const void *left_buffer,
                             const void *right_buffer,
                             size_t length,
                             size_t *first_difference)
{
  const unsigned char *ba = (const unsigned char *)left_buffer;
  const unsigned char *bb = (const unsigned char *)right_buffer;
  size_t i;

  if ((!left_buffer && length > 0) || (!right_buffer && length > 0)) {
    return RA_EARG;
  }

  for (i = 0; i < length; ++i) {
    if (ba[i] != bb[i]) {
      if (first_difference) {
        *first_difference = i;
      }
      return RA_MISMATCH;
    }
  }

  if (first_difference) {
    *first_difference = length;
  }
  return RA_OK;
}

int ta_compare_text_normalized(const char *left_text,
                               const char *right_text,
                               const ra_text_compare_options_t *options)
{
  size_t ia = 0;
  size_t ib = 0;
  int ignore_whitespace = options ? options->ignore_whitespace : 0;
  int ignore_line_endings = options ? options->ignore_line_endings : 0;

  if (!left_text || !right_text) {
    return RA_EARG;
  }

  for (;;) {
    char ca = left_text[ia];
    char cb = right_text[ib];

    if (ignore_line_endings) {
      if (ca == '\r' && left_text[ia + 1] == '\n') {
        ++ia;
        ca = '\n';
      }
      if (cb == '\r' && right_text[ib + 1] == '\n') {
        ++ib;
        cb = '\n';
      }
    }

    if (ignore_whitespace) {
      while (ca && isspace((unsigned char)ca)) {
        ++ia;
        ca = left_text[ia];
      }
      while (cb && isspace((unsigned char)cb)) {
        ++ib;
        cb = right_text[ib];
      }
    }

    if (ca != cb) {
      return RA_MISMATCH;
    }
    if (ca == '\0') {
      return RA_OK;
    }

    ++ia;
    ++ib;
  }
}

/* Environment test helper functions. */

int ta_with_environment_variable(const char *variable_name,
                                 const char *temporary_value,
                                 int (*callback)(void *callback_context),
                                 void *callback_context)
{
  char *old_value = NULL;
  const char *existing;
  int had_existing;
  int rc;

  if (!variable_name || !*variable_name || !temporary_value || !callback) {
    return RA_EARG;
  }

  existing = getenv(variable_name);
  had_existing = (existing != NULL);
  if (had_existing) {
    int err = 0;
    old_value = ra_strdup_checked(existing, &err);
    if (!old_value) {
      return RA_ENOMEM;
    }
  }

  if (setenv(variable_name, temporary_value, 1) != 0) {
    g_free_fn(old_value);
    return RA_EIO;
  }

  rc = callback(callback_context);

  if (had_existing) {
    if (setenv(variable_name, old_value, 1) != 0) {
      g_free_fn(old_value);
      return RA_EIO;
    }
  } else {
    if (unsetenv(variable_name) != 0) {
      g_free_fn(old_value);
      return RA_EIO;
    }
  }

  g_free_fn(old_value);
  return rc;
}

/* Process exit code test helper functions. */

int ta_get_command_exit_code(const char *command_line, int *exit_code)
{
  int code = 0;
  pid_t pid;
  int status;

  if (!command_line || !exit_code) {
    return RA_EARG;
  }

  pid = fork();
  if (pid < 0) {
    return RA_EIO;
  }
  if (pid == 0) {
    execl("/bin/sh", "sh", "-c", command_line, (char *)NULL);
    exit(127);
  }

  if (waitpid(pid, &status, 0) < 0) {
    return RA_EIO;
  }

  if (WIFEXITED(status)) {
    code = WEXITSTATUS(status);
  } else if (WIFSIGNALED(status)) {
    code = 128 + WTERMSIG(status);
  } else {
    code = -1;
  }

  *exit_code = code;
  return RA_OK;
}

int ta_assert_command_exit_code(const char *command_line, int expected_code)
{
  int actual_code;
  int rc;

  if (!command_line) {
    return RA_EARG;
  }

  rc = ta_get_command_exit_code(command_line, &actual_code);
  if (rc != RA_OK) {
    return rc;
  }

  return (actual_code == expected_code) ? RA_OK : RA_MISMATCH;
}

/* Filesystem predicate test helper functions. */

int ta_exists(const char *path)
{
  if (!path) {
    return -1;
  }
  return (access(path, F_OK) == 0) ? 1 : 0;
}

int ta_is_file(const char *path)
{
  struct stat st;

  if (!path) {
    return -1;
  }
  if (stat(path, &st) != 0) {
    return 0;
  }
  return S_ISREG(st.st_mode) ? 1 : 0;
}

int ta_is_directory(const char *path)
{
  struct stat st;

  if (!path) {
    return -1;
  }
  if (stat(path, &st) != 0) {
    return 0;
  }
  return S_ISDIR(st.st_mode) ? 1 : 0;
}

int ta_get_size(const char *path, size_t *size_bytes)
{
  struct stat st;

  if (!path || !size_bytes) {
    return RA_EARG;
  }
  if (stat(path, &st) != 0) {
    return RA_EIO;
  }
  *size_bytes = (size_t)st.st_size;
  return RA_OK;
}

int ta_file_age(const char *path, time_t *age_seconds)
{
  struct stat st;
  time_t now;

  if (!path || !age_seconds) {
    return RA_EARG;
  }
  if (stat(path, &st) != 0) {
    return RA_EIO;
  }

  now = time(NULL);
  if (now < st.st_mtime) {
    *age_seconds = 0;
  } else {
    *age_seconds = now - st.st_mtime;
  }
  return RA_OK;
}

int ta_path_has_extension(const char *path, const char *extension)
{
  size_t plen;
  size_t elen;

  if (!path || !extension) {
    return -1;
  }

  plen = strlen(path);
  elen = strlen(extension);
  if (elen == 0 || plen < elen) {
    return 0;
  }

  return (strcmp(path + plen - elen, extension) == 0) ? 1 : 0;
}

/* String and text test helper functions. */

int ta_string_contains(const char *text, const char *substring, size_t *position)
{
  const char *found;

  if (!text || !substring) {
    return -1;
  }

  found = strstr(text, substring);
  if (!found) {
    return 0;
  }

  if (position) {
    *position = (size_t)(found - text);
  }
  return 1;
}

int ta_string_starts_with(const char *text, const char *prefix)
{
  size_t tlen;
  size_t plen;

  if (!text || !prefix) {
    return -1;
  }

  tlen = strlen(text);
  plen = strlen(prefix);
  if (plen > tlen) {
    return 0;
  }

  return (strncmp(text, prefix, plen) == 0) ? 1 : 0;
}

int ta_string_ends_with(const char *text, const char *suffix)
{
  size_t tlen;
  size_t slen;

  if (!text || !suffix) {
    return -1;
  }

  tlen = strlen(text);
  slen = strlen(suffix);
  if (slen > tlen) {
    return 0;
  }

  return (strcmp(text + tlen - slen, suffix) == 0) ? 1 : 0;
}

int ta_match_regex(const char *text, const char *pattern)
{
  regex_t re;
  int rc;

  if (!text || !pattern) {
    return -1;
  }

  if (regcomp(&re, pattern, REG_EXTENDED) != 0) {
    return -1;
  }

  rc = regexec(&re, text, 0, NULL, 0);
  regfree(&re);

  if (rc == 0) {
    return 1;
  } else if (rc == REG_NOMATCH) {
    return 0;
  } else {
    return -1;
  }
}

int ta_compare_file_lines(const char *left_path, const char *right_path)
{
  FILE *f1 = NULL;
  FILE *f2 = NULL;
  char line1[1024];
  char line2[1024];
  int match = 1;

  if (!left_path || !right_path) {
    return RA_EARG;
  }

  f1 = fopen(left_path, "r");
  if (!f1) {
    return RA_EIO;
  }

  f2 = fopen(right_path, "r");
  if (!f2) {
    fclose(f1);
    return RA_EIO;
  }

  while (fgets(line1, sizeof(line1), f1) != NULL) {
    if (fgets(line2, sizeof(line2), f2) == NULL || strcmp(line1, line2) != 0) {
      match = 0;
      break;
    }
  }

  if (match && fgets(line2, sizeof(line2), f2) != NULL) {
    match = 0;
  }

  fclose(f1);
  fclose(f2);
  return match ? RA_OK : RA_MISMATCH;
}

/* Extended file operation test helper functions. */

int ta_append_file(const char *path, const char *content, size_t length)
{
  FILE *f;

  if (!path || (!content && length > 0)) {
    return RA_EARG;
  }

  f = fopen(path, "ab");
  if (!f) {
    return RA_EIO;
  }

  if (length > 0 && fwrite(content, 1, length, f) != length) {
    fclose(f);
    return RA_EIO;
  }

  fclose(f);
  return RA_OK;
}

int ta_rename_file(const char *old_path, const char *new_path)
{
  if (!old_path || !new_path) {
    return RA_EARG;
  }
  return (rename(old_path, new_path) == 0) ? RA_OK : RA_EIO;
}

int ta_symlink(const char *target, const char *link_path)
{
  if (!target || !link_path) {
    return RA_EARG;
  }
  return (symlink(target, link_path) == 0) ? RA_OK : RA_EIO;
}

/* JSON data extraction test helper functions. */

static int ra_json_extract_simple(const char *json_text, const char *path, char **out_value)
{
  /* Simplified JSON path extractor using string search.
   * Handles basic paths like "key" or "key[0]" or "key.subkey".
   */
  const char *p = json_text;
  const char *path_p = path;
  ra_sb_t out = {0};

  if (!json_text || !path || !out_value) {
    return RA_EARG;
  }

  *out_value = NULL;

  /* Very basic implementation: search for quoted key in JSON. */
  while (*path_p) {
    char key_buf[256];
    size_t key_len = 0;

    if (*path_p == '.') {
      path_p++;
    }

    if (*path_p == '[') {
      /* Array index - skip for now */
      path_p++;
      while (*path_p && *path_p != ']') {
        path_p++;
      }
      if (*path_p == ']') {
        path_p++;
      }
    } else {
      /* Collect key name. */
      while (*path_p && *path_p != '.' && *path_p != '[') {
        if (key_len < sizeof(key_buf) - 1) {
          key_buf[key_len++] = *path_p;
        }
        path_p++;
      }
      key_buf[key_len] = '\0';

      if (key_len > 0) {
        /* Search for quoted key in JSON. */
        char search[512];
        snprintf(search, sizeof(search), "\"%s\"", key_buf);
        const char *found = strstr(p, search);
        if (!found) {
          return RA_EPARSE;
        }

        p = found + strlen(search);
        while (*p && isspace((unsigned char)*p)) {
          p++;
        }
        if (*p != ':') {
          return RA_EPARSE;
        }
        p++;
        while (*p && isspace((unsigned char)*p)) {
          p++;
        }

        /* Extract value. */
        if (*p == '"') {
          p++;
          const char *val_start = p;
          while (*p && *p != '"') {
            if (*p == '\\') {
              p++;
            }
            if (*p) p++;
          }
          if (ra_sb_append_n(&out, val_start, p - val_start) != 0) {
            g_free_fn(out.data);
            return RA_ESIZE;
          }
          if (*p == '"') {
            p++;
          }
        } else if (*p == '{' || *p == '[' || *p == '-' ||
                   isdigit((unsigned char)*p) || *p == 't' || *p == 'f' ||
                   *p == 'n') {
          /* Non-string value. */
          const char *val_start = p;
          int depth = 0;
          while (*p) {
            if ((*p == '{' || *p == '[') && depth >= 0) {
              depth++;
            } else if ((*p == '}' || *p == ']') && depth > 0) {
              depth--;
            } else if ((isspace((unsigned char)*p) || *p == ',' || *p == '}' ||
                       *p == ']') && depth == 0) {
              break;
            }
            if (*p == '\\') {
              p++;
            }
            p++;
          }
          if (ra_sb_append_n(&out, val_start, p - val_start) != 0) {
            g_free_fn(out.data);
            return RA_ESIZE;
          }
        }
      }
    }
  }

  if (out.len == 0) {
    return RA_EPARSE;
  }

  if (ra_sb_append_c(&out, '\0') != 0) {
    g_free_fn(out.data);
    return RA_ESIZE;
  }

  *out_value = out.data;
  return RA_OK;
}

int ta_json_extract(const char *json_text, const char *path, char **out_value)
{
  return ra_json_extract_simple(json_text, path, out_value);
}

int ta_json_has_path(const char *json_text, const char *path)
{
  char *value = NULL;
  int rc;

  rc = ta_json_extract(json_text, path, &value);
  if (value) {
    g_free_fn(value);
  }

  return (rc == RA_OK) ? 1 : 0;
}

/* Resource management test helper functions. */

#define RA_MAX_CLEANUPS 64
typedef struct {
  void (*fn)(void *);
  void *ctx;
} ra_cleanup_entry_t;

static ra_cleanup_entry_t g_cleanups[RA_MAX_CLEANUPS];
static size_t g_cleanup_count = 0;

int ta_cleanup_register(void (*cleanup_callback)(void *cleanup_context),
                        void *cleanup_context)
{
  if (!cleanup_callback || g_cleanup_count >= RA_MAX_CLEANUPS) {
    return RA_ENOMEM;
  }

  g_cleanups[g_cleanup_count].fn = cleanup_callback;
  g_cleanups[g_cleanup_count].ctx = cleanup_context;
  g_cleanup_count++;

  return RA_OK;
}

static void ra_temp_file_cleanup(void *ctx)
{
  char *path = (char *)ctx;
  if (path) {
    unlink(path);
    g_free_fn(path);
  }
}

int ta_temp_file_auto(const char *suffix, char *outpath, size_t outpathsz)
{
  char *template_str;
  size_t template_len;
  int fd;
  int rc;

  if (!suffix || !outpath || outpathsz == 0) {
    return RA_EARG;
  }

  template_len = sizeof("/tmp/test_XXXXXX") + strlen(suffix) + 1;
  template_str = (char *)g_malloc_fn(template_len);
  if (!template_str) {
    return RA_ENOMEM;
  }

  snprintf(template_str, template_len, "/tmp/test_XXXXXX%s", suffix);

  fd = mkstemp(template_str);
  if (fd < 0) {
    g_free_fn(template_str);
    return RA_EIO;
  }
  close(fd);

  if (strlen(template_str) >= outpathsz) {
    unlink(template_str);
    g_free_fn(template_str);
    return RA_ESIZE;
  }

  strcpy(outpath, template_str);

  rc = ta_cleanup_register(ra_temp_file_cleanup, template_str);
  if (rc != RA_OK) {
    unlink(template_str);
    g_free_fn(template_str);
    return rc;
  }

  return RA_OK;
}
