/**
 * @file file_compare_tests.c
 *
 * @brief Focused tests for file comparison functions.
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see `LICENSE` in the repository root.
 */

#include "runnerapi.h"
#include "testapi.h"

#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <utime.h>
#include <unistd.h>

static int test_write_text(const char *path, const char *text)
{
  return ta_write_file(path, text, strlen(text));
}

static int test_join_path(char *out, size_t outsz, const char *dir, const char *name)
{
  int n;

  if (!out || !dir || !name) {
    return -1;
  }
  n = snprintf(out, outsz, "%s/%s", dir, name);
  if (n < 0 || (size_t)n >= outsz) {
    return -1;
  }
  return 0;
}

static int test_set_mtime(const char *path, time_t ts)
{
  struct utimbuf t;

  t.actime = ts;
  t.modtime = ts;
  return utime(path, &t);
}

RA_DECLARE_GROUP(file_compare_tests)
{
  char tmpdir[] = "/tmp/test_runner_cmp_XXXXXX";
  char fp1[RA_MAX_PATH_LEN];
  char fp2[RA_MAX_PATH_LEN];
  char fp3[RA_MAX_PATH_LEN];
  char fp4[RA_MAX_PATH_LEN];
  char fp5[RA_MAX_PATH_LEN];
  char fp6[RA_MAX_PATH_LEN];
  const char *ignore_patterns[] = {"^generated:", "^timestamp:"};
  const char *masked_fields[] = {"id", "timestamp"};
  const size_t skip_offsets[] = {6};
  const size_t skip_lengths[] = {8};
  const ra_path_compare_options_t ignore_timestamp_options = {
    RA_FILECMP_IGNORE_TIMESTAMPS
  };
  const ra_path_metadata_compare_options_t default_metadata_options = {
    RA_STATCMP_SIZE | RA_STATCMP_PERMS | RA_STATCMP_TYPE
  };
  const ra_path_metadata_compare_options_t metadata_with_mtime_options = {
    RA_STATCMP_SIZE | RA_STATCMP_PERMS | RA_STATCMP_TYPE | RA_STATCMP_MTIME
  };

  RA_INIT_GROUP(file_compare_tests, 1);

  RA_TEST(mkdtemp(tmpdir) != NULL, 0);

  RA_TEST(test_join_path(fp1, RA_MAX_PATH_LEN, tmpdir, "control_time.txt") == 0, 0);
  RA_TEST(test_join_path(fp2, RA_MAX_PATH_LEN, tmpdir, "actual_time.txt") == 0, 0);
  RA_TEST(test_join_path(fp3, RA_MAX_PATH_LEN, tmpdir, "control_generated.txt") == 0, 0);
  RA_TEST(test_join_path(fp4, RA_MAX_PATH_LEN, tmpdir, "actual_generated.txt") == 0, 0);
  RA_TEST(test_join_path(fp5, RA_MAX_PATH_LEN, tmpdir, "control_masked.bin") == 0, 0);
  RA_TEST(test_join_path(fp6, RA_MAX_PATH_LEN, tmpdir, "actual_masked.bin") == 0, 0);

  RA_TEST(test_write_text(fp1, "timestamp: 2026-06-14 10:11:12\nvalue: stable\n") == 0, 0);
  RA_TEST(test_write_text(fp2, "timestamp: 2027-01-01 01:02:03\nvalue: stable\n") == 0, 0);
  RA_TEST(ta_compare_paths_with_options(fp1, fp2, NULL) == RA_MISMATCH, 0);
  RA_TEST(ta_compare_paths_with_options(fp1, fp2, &ignore_timestamp_options) == RA_OK, 0);

  RA_TEST(test_write_text(fp3, "generated: build-100\npayload=alpha\n") == 0, 0);
  RA_TEST(test_write_text(fp4, "generated: build-999\npayload=alpha\n") == 0, 0);
  RA_TEST(ta_compare_paths_ignoring_patterns(fp3, fp4, ignore_patterns, 2) == RA_OK, 0);

  RA_TEST(test_write_text(fp3, "{\"id\": 100, \"timestamp\": \"2026-06-14T10:11:12Z\", \"payload\": \"same\"}\n") == 0, 0);
  RA_TEST(test_write_text(fp4, "{\"id\": 999, \"timestamp\": \"2027-01-01T01:02:03Z\", \"payload\": \"same\"}\n") == 0, 0);
  RA_TEST(ta_compare_paths_masking_fields(fp3, fp4, masked_fields, 2) == RA_OK, 0);

  RA_TEST(test_write_text(fp5, "HEADER20240614TAIL") == 0, 0);
  RA_TEST(test_write_text(fp6, "HEADER20250101TAIL") == 0, 0);
  RA_TEST(ta_compare_paths_masking_ranges(fp5, fp6, skip_offsets, skip_lengths, 1) == RA_OK, 0);
  RA_TEST(ta_compare_paths_masking_ranges(fp5, fp6, skip_offsets, skip_lengths, 0) == RA_MISMATCH, 0);

  RA_TEST(chmod(fp5, 0600) == 0, 0);
  RA_TEST(chmod(fp6, 0600) == 0, 0);
  RA_TEST(test_set_mtime(fp5, 1700000000) == 0, 0);
  RA_TEST(test_set_mtime(fp6, 1700000100) == 0, 0);
  RA_TEST(ta_compare_path_metadata(fp5, fp6, &default_metadata_options) == RA_OK, 0);
  RA_TEST(ta_compare_path_metadata(fp5, fp6, &metadata_with_mtime_options) == RA_MISMATCH, 0);

  unlink(fp1);
  unlink(fp2);
  unlink(fp3);
  unlink(fp4);
  unlink(fp5);
  unlink(fp6);
  rmdir(tmpdir);

  RA_RETURN;
}