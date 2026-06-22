/**
 * @file /paulsinclair51/include/britetest_test.h
 *
 * @brief BriteTest Test API declarations.
 *
 * This header declares test helper functions that can be used in
 * test expressions or by their underlying functions. The helpers focus
 * on process execution, waiting, file operations, simple text matching,
 * and scoped environment overrides.
 *
 * Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * See LICENSE in the repository root for details.
 */

/**
 * @section HeaderUsage Header Usage
 *
 * This header is included by source (.c) file for supporting esting, e.g., a feature,
 * API, or a project implementation.
 * It provides declarations, definitions (other than non-inline function definitions
 * provided by britetest_test.c in the repository src directory).
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
 * @name BT_TEST_VERSION
 *
 * @brief Version "M.m.p" for britetest_test.h which must be the same as
 *.       BT_TEST_VERSION_C for britetest_runner.c.
 *
 * M, m, and p are 1 or 2 digits (e.g., O, 00, 1, 01, 24):
 +
 * - M: Major version for major additions or incompatible API changes.
 * - m: Minor version for backward-compatible additions.
 * - p: Patch version for bug fixes or internal improvements.
 *
 * @note Incompatible API changes: The naming conventions, error semantics,
 *       and safety guarantees are part of the documented and stable API
 *       and will not change without a major version increment.
 *
 * @note M is the same across all versioned entities in the BriteTest repository..
 */
 
#define BT_TESt_VERSION "1.0.0"

/**
 * @section ChangeHistory Change History
 *
 * 2026/09/27 Initial version "1.0.0.".
 *
 **/
 */

#pragma once

#include <stddef.h>
#include <stdio.h>
#include <time.h>

#if defined(__cplusplus)
extern "C" {
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
 * 
 * BT_MAJOR(v)
 *    Major version
 *    size_t, 1 or greater.
 * 
 * BT_MINOR(v)
 *    Minor version nunber
 *    size_t, e.g., 0, 22.
 * 
 * BT_PATCH(v)
 *    Patch version number
 *    size_t, e.g., 0, 12.
 * 
 * BT_VERSION_NUM(v)
 *    size_t, form MMmmpp for comparisons, e.g., 10000 for
 *    version 1.0.0, 10200 for version 1.2.0, or 11212 for version 1.12.12.
 * 
 * BT_VERSION_HEX(v)
 *    Hexadecimal form 0xMMmmpp for display/debugging, e.g.,
 *    0x010000 for version 1.0.0, 0x010200 for version 1.2.0,
 *    or 0x011212 for version 1.12.12.
 * 
 * BT_VERSION_CMP(v1, v2)
 *    1 v1 is greater than v2,
 *    0 v1 is equal to v2,
 *   -1 v1 is less than v2,
 *.  -2 v1 or v2 has invalid version formatting,
 *
 *    v1 and v2 are strings with the same format as BT_RUNNER_VERSION,
 *    BT_RUNNER_VERFSION_C, BT_TEST_VERSION, and BT_TEST_VERISON_C.
 *
 * @{
 */

#if !defined(BT_RUNNER_VERSION)

size_t britetest_get_test_major_internal(v);
#define BT_VERSION_MAJOR(v) britetest_get_test_major_internal()

size_t britetest_get_test_minor_internal(v);
#define BT_VERSION_MINOR(v) britetest_get_test_minor_internal((v))

size_t britetest_get_test_patch_internal(v);
#define BT_VERSION_PATCH(v) britetest_get_test_patch_internal((v))

// BriteTest version as an integer for comparisons.

size_t britetest_get_test_num_internal(v);
#define BT_VERSION_NUM(v) britetest_get_test_num_internal((v))

// BriteTest version encoded as 0xMMmmpp (major, minor, patch) for display/debug.

size_t britetest_get_test_hex_internal(v);
#define BT_VERSION_HEX(v) britetest_get_test_hex_internal((v))

// BriteTest version compared to specified version (1 if true, otherwie 0).

int britetest_test_cmp_internal
( comst char *v1, comst char *v2 );
#define BT_VERSION_CMP(v1, v2) britetest_test_cmp_internal((v1), (v2))

#endif

/** @} */ // End of Version Macros.

/* Structured error codes for test helper functions. */
typedef enum {
  BT_OK = 0,
  BT_FAIL = 1,
  BT_MISMATCH = 2,
  BT_TIMEOUT = 3,
  BT_EARG = -1,
  BT_ENOMEM = -2,
  BT_EIO = -3,
  BT_EPARSE = -4,
  BT_ESIZE = -5
} bt_error_t;

/* Allocator hook types for custom memory management. */
typedef void *(*bt_malloc_fn)(size_t size);
typedef void *(*bt_realloc_fn)(void *ptr, size_t size);
typedef void (*bt_free_fn)(void *ptr);

/* Get/set allocator hooks for custom memory management policy. */
void bt_set_allocator_hooks(bt_malloc_fn malloc_function,
                            bt_realloc_fn realloc_function,
                            bt_free_fn free_function);
void bt_get_allocator_hooks(bt_malloc_fn *malloc_function,
                            bt_realloc_fn *realloc_function,
                            bt_free_fn *free_function);

/**
 * @section TestHelperFunctions Test Helper Functions
 *
 * @note Some helpers allocate memory internally. Allocations are bounded by an
 * implementation cap to avoid unbounded growth. The current implementation cap
 * is 16 MiB per helper operation.
 *
 * @note Ownership rule: if a helper returns allocated memory through an output
 * pointer (for example, bt_read_file or bt_read_file_with_limit), the caller owns the
 * memory and must free it.
 *
 * @note Return conventions are grouped into three styles:
 * 1. Structured helpers return BT_OK, BT_MISMATCH, BT_TIMEOUT, or BT_E*.
 * 2. Predicate helpers return 1 for true/match, 0 for false/no-match, and -1 on error.
 * 3. Legacy process helpers return 0 for success, 1 for timeout/expected negative result,
 *    and -1 on invalid arguments or system failure.
 */

/**
 * @subsection TestHelperExecution Execution and Runtime Test Helper Functions
 */

/**
 * @name bt_execute_command
 *
 * @brief Execute a shell command and capture combined stdout/stderr.
 *
 * @param command_line Shell command to execute.
 * @param timeout_ms Timeout in milliseconds. 0 means no timeout.
 * @param output_buffer Output buffer for captured text (optional).
 * @param output_buffer_size Size of output_buffer.
 * @param exit_code Receives process exit code if available (optional).
 *
 * @return 0 when the command completed, 1 when the timeout expired, or -1 on invalid
 * arguments or process/setup failure.
 */
int bt_execute_command(const char *command_line,
                       int timeout_ms,
                       char *output_buffer,
                       size_t output_buffer_size,
                       int *exit_code);

/**
 * @name bt_wait_for_condition
 *
 * @brief Poll a predicate until true or timeout expires.
 *
 * @param condition Callback that returns non-zero when the condition is met.
 * @param callback_context User context passed to condition.
 * @param timeout_ms Timeout in milliseconds. 0 means single predicate check.
 * @param poll_interval_ms Poll interval in milliseconds (minimum 1).
 *
 * @return 1 when the condition becomes true, 0 when the timeout expires first,
 * or -1 on invalid arguments.
 */
int bt_wait_for_condition(int (*condition)(void *callback_context),
                          void *callback_context,
                          int timeout_ms,
                          int poll_interval_ms);

/**
 * @name bt_assert_completes_within
 *
 * @brief Run a callback and fail if it does not complete before the timeout.

 * @param callback Callback to run.
 * @param callback_context Callback context.
 * @param timeout_ms Timeout in milliseconds.
 *
 * @return 0 when the callback completed before the timeout, 1 when it timed out,
 * or -1 on invalid arguments or process/setup failure.
 */
int bt_assert_completes_within(int (*callback)(void *callback_context),
                               void *callback_context,
                               int timeout_ms);

/**
 * @name bt_capture_standard_error
 *
 * @brief Capture stderr output emitted by a callback.

 * @param callback Callback to run.
 * @param callback_context Callback context.
 * @param output_buffer Buffer receiving captured stderr output.
 * @param output_buffer_size Size of output_buffer.
 *
 * @return 0 when capture succeeded, or -1 on invalid arguments or pipe/process failure.
 */
int bt_capture_standard_error(int (*callback)(void *callback_context),
                              void *callback_context,
                              char *output_buffer,
                              size_t output_buffer_size);

/**
 * @subsection TestHelperFilesystem Filesystem and Path Test Helper Functions
 */

/**
 * @name bt_with_working_directory
 *
 * @brief Run a callback in a temporary working directory scope.

 * @param path Working directory path to use while the callback runs.
 * @param callback Callback to run.
 * @param callback_context Callback context.
 *
 * @return Callback result when setup and restore succeeded, or -1 on working-directory
 * setup/restore failure.
 */
int bt_with_working_directory(const char *path,
                              int (*callback)(void *callback_context),
                              void *callback_context);

/**
 * @name bt_copy_file
 *
 * @brief Copy a file from one path to another.
 *
 * @return 0 on success, -1 on error.
 */
int bt_copy_file(const char *source_path, const char *destination_path);

/**
 * @name bt_make_temp_dir
 *
 * @brief Create a unique temporary directory.
 *
 * @param prefix Prefix used in directory name.
 * @param out_path Buffer receiving created directory path.
 * @param out_path_size Size of out_path.
 *
 * @return 0 on success, -1 on error.
 */
int bt_make_temp_dir(const char *prefix, char *out_path, size_t out_path_size);

/**
 * @name bt_make_temp_file
 *
 * @brief Create a unique temporary file path.
 *
 * @return 0 on success, non-zero on error.
 */
int bt_make_temp_file(const char *prefix, char *out_path, size_t out_path_size);

/**
 * @name bt_make_dirs
 *
 * @brief Create a directory path recursively.
 *
 * @return 0 on success, non-zero on error.
 */
int bt_make_dirs(const char *path);

/**
 * @name bt_path_join
 *
 * @brief Join two path parts into one path.
 *
 * @return 0 on success, non-zero on error.
 */
int bt_path_join(const char *left_path_part,
                 const char *right_path_part,
                 char *output_path,
                 size_t output_path_size);

/**
 * @name bt_read_file
 *
 * @brief Read an entire file into a newly allocated buffer.
 *
 * @note On success, *content points to caller-owned memory that must be freed.
 *
 * @return BT_OK on success, BT_ENOMEM on size exceeded, BT_EIO on read error.
 */
int bt_read_file(const char *path, char **content, size_t *length);

/**
 * @name bt_read_file_with_limit
 *
 * @brief Read an entire file with explicit maximum size limit.
 *
 * @param path File path to read.
 * @param max_bytes Hard size limit (0 uses implementation default).
 * @param content Receives caller-owned memory (caller must free).
 * @param length Receives byte count read.
 *
 * @return BT_OK on success, BT_ESIZE if file exceeds max, BT_EIO on error.
 */
int bt_read_file_with_limit(const char *path,
                            size_t max_bytes,
                            char **content,
                            size_t *length);

/**
 * @name bt_read_file_into
 *
 * @brief Read a file into a caller-provided buffer (no allocation).
 *
 * @param path File path to read.
 * @param buffer Caller-provided buffer.
 * @param buffer_size Buffer size.
 * @param out_length Receives bytes actually read.
 *
 * @return BT_OK on success, BT_ESIZE if file exceeds buffer, BT_EIO on error.
 */
int bt_read_file_into(const char *path,
                      char *buffer,
                      size_t buffer_size,
                      size_t *out_length);

/**
 * @name bt_remove_tree
 *
 * @brief Remove a file or directory tree recursively.
 *
 * @return 0 on success, non-zero on error.
 */
int bt_remove_tree(const char *path);

/**
 * @name bt_stat_check
 *
 * @brief Validate basic file metadata constraints.
 *
 * @return 0 on success, non-zero on error.
 */
int bt_stat_check(const char *path, int must_exist, long minimum_size);

/**
 * @name bt_touch
 *
 * @brief Create a file if missing or update its modification time.
 *
 * @return 0 on success, non-zero on error.
 */
int bt_touch(const char *path);

/**
 * @name bt_write_file
 *
 * @brief Write a buffer to a file path.
 *
 * @return 0 on success, non-zero on error.
 */
int bt_write_file(const char *path, const void *buffer, size_t length);

/**
 * @subsection TestHelperComparison Comparison and Matching Test Helper Functions
 */

/**
 * @name bt_compare_dirs
 *
 * @brief Compare two directories.
 *
 * @return BT_OK when the selected directory content matches, BT_MISMATCH when it differs,
 * or BT_EIO on directory traversal or stat failure.
 */
int bt_compare_dirs(const char *left_path, const char *right_path, int recursive);

/**
 * @name bt_compare_files
 *
 * @brief Compare two open files byte-by-byte.
 *
 * @return 1 if equal, 0 if different, -1 on error.
 */
int bt_compare_files(FILE *left_file, FILE *right_file);

/**
 * @name bt_compare_file_to_path
 *
 * @brief Compare an open file with a file path.
 *
 * @return 1 if equal, 0 if different, -1 on error.
 */
int bt_compare_file_to_path(FILE *file, const char *path);

/**
 * @name bt_compare_paths
 *
 * @brief Compare two file paths byte-by-byte.
 *
 * @return 1 if equal, 0 if different, -1 on error.
 */
int bt_compare_paths(const char *left_path, const char *right_path);

/**
 * @name bt_compare_path_to_file
 *
 * @brief Compare a file path with an open file.
 *
 * @return 1 if equal, 0 if different, -1 on error.
 */
int bt_compare_path_to_file(const char *path, FILE *file);

enum {
  BT_FILECMP_IGNORE_TRAILING_WHITESPACE = 1 << 0,
  BT_FILECMP_IGNORE_EMPTY_LINES = 1 << 1,
  BT_FILECMP_IGNORE_TIMESTAMPS = 1 << 2,
  BT_FILECMP_IGNORE_LINE_ENDINGS = 1 << 3,
  BT_FILECMP_CASE_INSENSITIVE = 1 << 4
};

typedef struct {
  int flags;
} bt_path_compare_options_t;

#define BT_PATH_COMPARE_OPTIONS_INIT {0}

/**
 * @name bt_compare_paths_with_options
 *
 * @brief Compare two file paths with named comparison options.
 *
 * @param left_path First file path.
 * @param right_path Second file path.
 * @param options Optional comparison options. Pass NULL or BT_PATH_COMPARE_OPTIONS_INIT
 * for the default byte-for-byte comparison. options->flags uses BT_FILECMP_* values.
 *
 * @return BT_OK if equivalent, BT_MISMATCH if different, BT_EIO on error.
 */
int bt_compare_paths_with_options(const char *left_path,
                                  const char *right_path,
                                  const bt_path_compare_options_t *options);

/**
 * @name bt_compare_paths_ignoring_patterns
 *
 * @brief Compare two file paths while skipping lines that match regex patterns.
 *
 * @param left_path First file path.
 * @param right_path Second file path.
 * @param ignore_patterns POSIX extended regex patterns to skip.
 * @param pattern_count Number of patterns.
 *
 * @return BT_OK if equivalent, BT_MISMATCH if different, BT_EPARSE/BT_EIO on error.
 */
int bt_compare_paths_ignoring_patterns(const char *left_path,
                                       const char *right_path,
                               const char **ignore_patterns,
                               size_t pattern_count);

/**
 * @name bt_compare_paths_masking_fields
 *
 * @brief Compare structured text files while masking named field values.
 *
 * Supports JSON-style keys ("field": value) and line-oriented key/value text
 * (field=value, field: value). Field names are matched literally.
 *
 * @param left_path First file path.
 * @param right_path Second file path.
 * @param field_names Field names whose values should be ignored.
 * @param field_count Number of field names.
 *
 * @return BT_OK if equivalent, BT_MISMATCH if different, BT_EIO on error.
 */
int bt_compare_paths_masking_fields(const char *left_path,
                                    const char *right_path,
                           const char **field_names,
                           size_t field_count);

/**
 * @name bt_compare_paths_masking_ranges
 *
 * @brief Compare two file paths while ignoring specific byte ranges.
 *
 * Each offset/length pair describes a byte range to ignore in both files.
 * Ranges are interpreted against the same absolute offsets in each file.
 *
 * @param left_path First file path.
 * @param right_path Second file path.
 * @param skip_offsets Byte offsets to ignore.
 * @param skip_lengths Byte counts for each ignored range.
 * @param range_count Number of ignored ranges.
 *
 * @return BT_OK if equivalent, BT_MISMATCH if different, BT_EIO on error.
 */
int bt_compare_paths_masking_ranges(const char *left_path,
                                    const char *right_path,
                           const size_t *skip_offsets,
                           const size_t *skip_lengths,
                           size_t range_count);

enum {
  BT_STATCMP_SIZE = 1 << 0,
  BT_STATCMP_PERMS = 1 << 1,
  BT_STATCMP_MTIME = 1 << 2,
  BT_STATCMP_OWNER = 1 << 3,
  BT_STATCMP_TYPE = 1 << 4
};

typedef struct {
  int flags;
} bt_path_metadata_compare_options_t;

#define BT_PATH_METADATA_COMPARE_OPTIONS_INIT {0}

/**
 * @name bt_compare_path_metadata
 *
 * @brief Compare selected filesystem metadata for two paths.
 *
 * @param left_path First path.
 * @param right_path Second path.
 * @param options Optional metadata comparison options. Pass NULL or
 * BT_PATH_METADATA_COMPARE_OPTIONS_INIT to compare size, permissions, and type.
 * options->flags uses BT_STATCMP_* values.
 *
 * @return BT_OK if selected metadata matches, BT_MISMATCH if different, BT_EIO on error.
 */
int bt_compare_path_metadata(const char *left_path,
                             const char *right_path,
                             const bt_path_metadata_compare_options_t *options);

/**
 * @name bt_hexdump_diff
 *
 * @brief Compare two byte buffers and emit context-friendly diff details.
 *
 * @return BT_OK when the buffers match, BT_MISMATCH when they differ, or BT_EARG
 * on invalid input.
 */
int bt_hexdump_diff(const void *a, const void *b, size_t n, size_t context);

/**
 * @name bt_compare_json
 *
 * @brief Compare JSON documents with default strict semantics.
 *
 * @note This convenience form is strict: object key order is significant and the
 * default allocation limit applies.
 *
 * @return BT_OK if equivalent, BT_MISMATCH if different, or BT_EPARSE on invalid JSON.
 */
int bt_compare_json(const char *expected_json, const char *actual_json);

typedef struct {
  size_t max_bytes;
  int ignore_key_order;
} bt_json_compare_options_t;

#define BT_JSON_COMPARE_OPTIONS_INIT {0, 0}

/**
 * @name bt_compare_json_with_limit
 *
 * @brief Compare JSON documents with named normalization and size options.
 *
 * @param expected_json Expected JSON string.
 * @param actual_json Actual JSON string.
 * @param options Optional JSON compare options. Pass NULL or
 * BT_JSON_COMPARE_OPTIONS_INIT to use the default size limit and strict key order.
 * Set options->ignore_key_order non-zero to normalize object key order. Set
 * options->max_bytes to apply a smaller explicit size limit.
 *
 * @return BT_OK if equivalent, BT_MISMATCH if different, BT_ESIZE/BT_EPARSE on error.
 */
int bt_compare_json_with_limit(const char *expected_json,
                               const char *actual_json,
                               const bt_json_compare_options_t *options);

/**
 * @name bt_match
 *
 * @brief Match text against a wildcard pattern.
 *
 * Supported wildcards:
 *   * matches zero or more characters
 *   ? matches exactly one character
 *
 * @return 1 on match, 0 on no match, -1 on invalid arguments.
 */
int bt_match(const char *text, const char *pattern);

/**
 * @name bt_compare_memory_detail
 *
 * @brief Compare two byte buffers and return first differing index.
 *
 * @return BT_OK when the buffers match, BT_MISMATCH when they differ, or BT_EARG
 * on invalid input.
 */
int bt_compare_memory_detail(const void *left_buffer,
                             const void *right_buffer,
                             size_t length,
                             size_t *first_difference);

typedef struct {
  int ignore_whitespace;
  int ignore_line_endings;
} bt_text_compare_options_t;

#define BT_TEXT_COMPARE_OPTIONS_INIT {0, 0}

/**
 * @name bt_compare_text_normalized
 *
 * @brief Compare text with named normalization options.
 *
 * @param left_text First text string.
 * @param right_text Second text string.
 * @param options Optional normalization options. Pass NULL or
 * BT_TEXT_COMPARE_OPTIONS_INIT for a literal text comparison.
 *
 * @return BT_OK when the texts match, BT_MISMATCH when they differ, or BT_EARG
 * on invalid input.
 */
int bt_compare_text_normalized(const char *left_text,
                               const char *right_text,
                               const bt_text_compare_options_t *options);

/**
 * @subsection TestHelperEnvironment Environment Test Helper Functions
 */

/**
 * @name bt_with_environment_variable
 *
 * @brief Temporarily set an environment variable for callback execution.
 *
 * @param variable_name Environment variable name.
 * @param temporary_value Value to assign while callback executes.
 * @param callback Callback to run.
 * @param callback_context Callback context.
 *
 * @return Callback result when setup and restore succeeded, or BT_EARG/BT_EIO if
 * the temporary environment override could not be applied or restored.
 */
int bt_with_environment_variable(const char *variable_name,
                                 const char *temporary_value,
                                 int (*callback)(void *callback_context),
                                 void *callback_context);

/**
 * @subsection TestHelperProcessResult Process Exit Code Test Helper Functions
 */

/**
 * @name bt_get_command_exit_code
 *
 * @brief Execute command and retrieve exit code.
 *
 * @param command_line Shell command to execute.
 * @param exit_code Receives process exit code.
 *
 * @return BT_OK on success, BT_EIO on exec error.
 */
int bt_get_command_exit_code(const char *command_line, int *exit_code);

/**
 * @name bt_assert_command_exit_code
 *
 * @brief Execute command and verify it exits with expected code.
 *
 * @param command_line Shell command to execute.
 * @param expected_code Expected exit code.
 *
 * @return BT_OK if code matches, BT_MISMATCH if different, BT_EIO on error.
 */
int bt_assert_command_exit_code(const char *command_line, int expected_code);

/**
 * @subsection TestHelperFilesystemPredicates Filesystem Predicate Test Helper Functions
 */

/**
 * @name bt_exists
 *
 * @brief Check if path exists (file or directory).
 *
 * @return 1 if exists, 0 if not, -1 on error.
 */
int bt_exists(const char *path);

/**
 * @name bt_is_file
 *
 * @brief Check if path is a regular file.
 *
 * @return 1 if regular file, 0 if not, -1 on error.
 */
int bt_is_file(const char *path);

/**
 * @name bt_is_directory
 *
 * @brief Check if path is a directory.
 *
 * @return 1 if directory, 0 if not, -1 on error.
 */
int bt_is_directory(const char *path);

/**
 * @name bt_get_size
 *
 * @brief Get file size in bytes.
 *
 * @param path File path.
 * @param size Receives file size.
 *
 * @return BT_OK on success, BT_EARG on invalid input, or BT_EIO on stat failure.
 */
int bt_get_size(const char *path, size_t *size_bytes);

/**
 * @name bt_file_age
 *
 * @brief Get file age in seconds since last modification.
 *
 * @param path File path.
 * @param age_seconds Receives age in seconds.
 *
 * @return BT_OK on success, BT_EARG on invalid input, or BT_EIO on stat failure.
 */
int bt_file_age(const char *path, time_t *age_seconds);

/**
 * @name bt_path_has_extension
 *
 * @brief Check if path has specified extension.
 *
 * @param path File path.
 * @param extension Extension string (e.g., ".txt").
 *
 * @return 1 if matches, 0 if not, -1 on invalid args.
 */
int bt_path_has_extension(const char *path, const char *extension);

/**
 * @subsection TestHelperStringText String and Text Test Helper Functions
 */

/**
 * @name bt_string_contains
 *
 * @brief Search for substring in text.
 *
 * @param text Haystack string.
 * @param substring Needle substring.
 * @param position Receives position of first match (optional).
 *
 * @return 1 if found, 0 if not, -1 on invalid args.
 */
int bt_string_contains(const char *text, const char *substring, size_t *position);

/**
 * @name bt_string_starts_with
 *
 * @brief Check if text starts with prefix.
 *
 * @return 1 if yes, 0 if no, -1 on invalid args.
 */
int bt_string_starts_with(const char *text, const char *prefix);

/**
 * @name bt_string_ends_with
 *
 * @brief Check if text ends with suffix.
 *
 * @return 1 if yes, 0 if no, -1 on invalid args.
 */
int bt_string_ends_with(const char *text, const char *suffix);

/**
 * @name bt_match_regex
 *
 * @brief Match text against POSIX extended regex pattern.
 *
 * @param text Text to match.
 * @param pattern Extended regex pattern.
 *
 * @return 1 on match, 0 on no match, or -1 on invalid input or regex compilation failure.
 */
int bt_match_regex(const char *text, const char *pattern);

/**
 * @name bt_compare_file_lines
 *
 * @brief Compare two files line-by-line.
 *
 * @param file1 First file path.
 * @param file2 Second file path.
 *
 * @return BT_OK if identical, BT_MISMATCH if different, BT_EIO on error.
 */
int bt_compare_file_lines(const char *left_path, const char *right_path);

/**
 * @subsection TestHelperFileOps Extended File Operation Test Helper Functions
 */

/**
 * @name bt_append_file
 *
 * @brief Append content to a file.
 *
 * @param path File path.
 * @param content Data to append.
 * @param length Byte count to append.
 *
 * @return BT_OK on success, BT_EIO on error.
 */
int bt_append_file(const char *path, const char *content, size_t length);

/**
 * @name bt_rename_file
 *
 * @brief Rename or move a file.
 *
 * @param old_path Current path.
 * @param new_path New path.
 *
 * @return BT_OK on success, BT_EIO on error.
 */
int bt_rename_file(const char *old_path, const char *new_path);

/**
 * @name bt_symlink
 *
 * @brief Create a symbolic link.
 *
 * @param target Link target path.
 * @param link_path Path for new symlink.
 *
 * @return BT_OK on success, BT_EIO on error.
 */
int bt_symlink(const char *target, const char *link_path);

/**
 * @subsection TestHelperJsonData JSON Data Extraction Test Helper Functions
 */

/**
 * @name bt_json_extract
 *
 * @brief Extract value from JSON document using path notation.
 *
 * Path notation supports: "obj.key", "arr[0]", "obj.arr[1].key", etc.
 * Caller owns returned string.
 *
 * @param json_text JSON document.
 * @param path Path to extract (e.g., "response.data[0].id").
 * @param out_value Receives extracted value string (caller frees).
 *
 * @return BT_OK on success, BT_EARG on invalid input, BT_EPARSE if the path is not
 * found or cannot be parsed, or BT_ESIZE if extraction exceeds bounded storage.
 */
int bt_json_extract(const char *json_text, const char *path, char **out_value);

/**
 * @name bt_json_has_path
 *
 * @brief Check if JSON path exists.
 *
 * @param json_text JSON document.
 * @param path Path to check (e.g., "obj.key[0]").
 *
 * @return 1 if the path exists, 0 if it does not, or -1 when the input is invalid
 * or the JSON cannot be parsed.
 */
int bt_json_has_path(const char *json_text, const char *path);

/**
 * @subsection TestHelperResourceMgmt Resource Management Test Helper Functions
 */

/**
 * @name bt_cleanup_register
 *
 * @brief Register cleanup callback to run at test end.
 *
 * Cleanup functions run in LIFO order (last registered, first run).
 *
 * @param cleanup_callback Callback to run.
 * @param cleanup_context Context passed to cleanup.
 *
 * @return BT_OK on success, BT_ENOMEM on limit reached.
 */
int bt_cleanup_register(void (*cleanup_callback)(void *cleanup_context),
                        void *cleanup_context);

/**
 * @name bt_temp_file_auto
 *
 * @brief Create temporary file with auto-cleanup.
 *
 * File is automatically deleted at test end.
 *
 * @param suffix File suffix (e.g., ".txt").
 * @param outpath Buffer receiving file path.
 * @param outpathsz Size of outpath.
 *
 * @return BT_OK on success, BT_EIO on error.
 */
int bt_temp_file_auto(const char *suffix, char *outpath, size_t outpathsz);

#if defined(__cplusplus)
}
#endif
