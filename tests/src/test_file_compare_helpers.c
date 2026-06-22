/**
 * @file /paulsinclair51/BriteTest/tests/test_file_compare_helpers.c
 *
 * @brief Focused tests for BriteTest file comparison helper functions.
 *
 * Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 */

#include "britetest_runner.h"
#include "britetest_test.h"

#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <utime.h>
#include <unistd.h>

static int test_write_text(const char *path, const char *text)
{
  return bt_write_file(path, text, strlen(text));
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

BT_DECLARE_TEST(test_file_compare_helpers)
{
  char tmpdir[] = "/tmp/britetest_cmp_XXXXXX";
  char fp1[PATH_MAX];
  char fp2[PATH_MAX];
  char fp3[PATH_MAX];
  char fp4[PATH_MAX];
  char fp5[PATH_MAX];
  char fp6[PATH_MAX];
  const char *ignore_patterns[] = {"^generated:", "^timestamp:"};
  const char *masked_fields[] = {"id", "timestamp"};
  const size_t skip_offsets[] = {6};
  const size_t skip_lengths[] = {8};
  const bt_path_compare_options_t ignore_timestamp_options = {
    BT_FILECMP_IGNORE_TIMESTAMPS
  };
  const bt_path_metadata_compare_options_t defaubt_metadata_options = {
    BT_STATCMP_SIZE | BT_STATCMP_PERMS | BT_STATCMP_TYPE
  };
  const bt_path_metadata_compare_options_t metadata_with_mtime_options = {
    BT_STATCMP_SIZE | BT_STATCMP_PERMS | BT_STATCMP_TYPE | BT_STATCMP_MTIME
  };
  struct utimbuf t1;
  struct utimbuf t2;

  BT_INIT_TEST(test_file_compare_helpers, 1);

  BT_ASSERT(mkdtemp(tmpdir) != NULL, 0);

  BT_ASSERT(test_join_path(fp1, sizeof(fp1), tmpdir, "control_time.txt") == 0, 0);
  BT_ASSERT(test_join_path(fp2, sizeof(fp2), tmpdir, "actual_time.txt") == 0, 0);
  BT_ASSERT(test_join_path(fp3, sizeof(fp3), tmpdir, "control_generated.txt") == 0, 0);
  BT_ASSERT(test_join_path(fp4, sizeof(fp4), tmpdir, "actual_generated.txt") == 0, 0);
  BT_ASSERT(test_join_path(fp5, sizeof(fp5), tmpdir, "control_masked.bin") == 0, 0);
  BT_ASSERT(test_join_path(fp6, sizeof(fp6), tmpdir, "actual_masked.bin") == 0, 0);

  BT_ASSERT(test_write_text(fp1, "timestamp: 2026-06-14 10:11:12\nvalue: stable\n") == 0, 0);
  BT_ASSERT(test_write_text(fp2, "timestamp: 2027-01-01 01:02:03\nvalue: stable\n") == 0, 0);
  BT_ASSERT(bt_compare_paths_with_options(fp1, fp2, NULL) == BT_MISMATCH, 0);
  BT_ASSERT(bt_compare_paths_with_options(fp1, fp2, &ignore_timestamp_options) == BT_OK, 0);

  BT_ASSERT(test_write_text(fp3, "generated: build-100\npayload=alpha\n") == 0, 0);
  BT_ASSERT(test_write_text(fp4, "generated: build-999\npayload=alpha\n") == 0, 0);
  BT_ASSERT(bt_compare_paths_ignoring_patterns(fp3, fp4, ignore_patterns, 2) == BT_OK, 0);

  BT_ASSERT(test_write_text(fp3, "{\"id\": 100, \"timestamp\": \"2026-06-14T10:11:12Z\", \"payload\": \"same\"}\n") == 0, 0);
  BT_ASSERT(test_write_text(fp4, "{\"id\": 999, \"timestamp\": \"2027-01-01T01:02:03Z\", \"payload\": \"same\"}\n") == 0, 0);
  BT_ASSERT(bt_compare_paths_masking_fields(fp3, fp4, masked_fields, 2) == BT_OK, 0);

  BT_ASSERT(test_write_text(fp5, "HEADER20240614TAIL") == 0, 0);
  BT_ASSERT(test_write_text(fp6, "HEADER20250101TAIL") == 0, 0);
  BT_ASSERT(bt_compare_paths_masking_ranges(fp5, fp6, skip_offsets, skip_lengths, 1) == BT_OK, 0);
  BT_ASSERT(bt_compare_paths_masking_ranges(fp5, fp6, skip_offsets, skip_lengths, 0) == BT_MISMATCH, 0);

  BT_ASSERT(chmod(fp5, 0600) == 0, 0);
  BT_ASSERT(chmod(fp6, 0600) == 0, 0);
  t1.actime = 1700000000;
  t1.modtime = 1700000000;
  t2.actime = 1700000100;
  t2.modtime = 1700000100;
  BT_ASSERT(utime(fp5, &t1) == 0, 0);
  BT_ASSERT(utime(fp6, &t2) == 0, 0);
  BT_ASSERT(bt_compare_path_metadata(fp5, fp6, &defaubt_metadata_options) == BT_OK, 0);
  BT_ASSERT(bt_compare_path_metadata(fp5, fp6, &metadata_with_mtime_options) == BT_MISMATCH, 0);

  unlink(fp1);
  unlink(fp2);
  unlink(fp3);
  unlink(fp4);
  unlink(fp5);
  unlink(fp6);
  rmdir(tmpdir);

  BT_RETURN;
}