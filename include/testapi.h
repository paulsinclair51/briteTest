 /**
 * @file /include/testapi.h
 *
 * @mainpage Test API Function Declarations
 *
 * This header declares test helper functions that can be used in
 * test expressions or by their underlying functions. The helpers focus
 * on process execution, waiting, file operations, simple text matching,
 * and scoped environment overrides.
 *
 * For an overview of the Test API, see the
 * README.md file in the repository root directory.
 * See src/testapi.c for the API definitions.
 *
 * @copyright Copyright (c) 2026 Paul Sinclair
 * SPDX-License-Identifier: MIT
 * For license details, see LICENSE in the repository root directory.
 */

/**
 * @section HeaderUsage Header Usage
 *
 * This header is included by source (.c) file for supporting esting, e.g., a feature,
 * API, or a project implementation.
 * It provides declarations, definitions (other than non-inline function definitions
 * provided by litetest_test.c in the repository src directory).
 *
 * See README.md in the repository root directory for an introduction to LiteTest.
 *
 * See LiteTest Docucmentation Guide for ,,,
 *
 * @note LiteTest requires POSIX.1-2001 (IEEE Std 1003.1-2001) compatibility and a
 *       C99-compliant compiler. Linux, macOS, and the BSD family natively meet these
 *       requirements. Windows requires a POSIX compatibility layer such as Cygwin,
 *       MSYS2, or WSL.
 *
 * @note LiteTest Runner has been exercised in a POSIX environment; however, users must
 *       confirm correct behavior in their own environment.
 */

/**
 * @name LT_TEST_VERSION
 *
 * @brief Version "M.m.p" for litetest_test.h which must be the same as
 *.       LT_TEST_VERSION_C for litetest_runner.c.
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
 * @note M is the same across all versioned entities in the Litetest repository..
 */
 
#define LT_TESt_VERSION "1.0.0"

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
 * @section LiteTestVersionMacros LiteTest Version Macros
 */

/**
 * @defgroup LiteTestVersionMacros LiteTest Version Macros
 *
 * @name LT_VERSION_MAJOR, LT_VERSION_MINOR, LT_VERSION_PATCH,
 *       LT_VERSION_NUM, LT_VERSION_HEX, 
 *       LT_VERSION_CMP
 *
 * @brief Version macros for LiteTest (litetest_runner.h and litetest_runner.c):
 * 
 * LT_MAJOR(v)
 *    Major version
 *    size_t, 1 or greater.
 * 
 * LT_MINOR(v)
 *    Minor version nunber
 *    size_t, e.g., 0, 22.
 * 
 * LT_PATCH(v)
 *    Patch version number
 *    size_t, e.g., 0, 12.
 * 
 * LT_VERSION_NUM(v)
 *    size_t, form MMmmpp for comparisons, e.g., 10000 for
 *    version 1.0.0, 10200 for version 1.2.0, or 11212 for version 1.12.12.
 * 
 * LT_VERSION_HEX(v)
 *    Hexadecimal form 0xMMmmpp for display/debugging, e.g.,
 *    0x010000 for version 1.0.0, 0x010200 for version 1.2.0,
 *    or 0x011212 for version 1.12.12.
 * 
 * LT_VERSION_CMP(v1, v2)
 *    1 v1 is greater than v2,
 *    0 v1 is equal to v2,
 *   -1 v1 is less than v2,
 *.  -2 v1 or v2 has invalid version formatting,
 *
 *    v1 and v2 are strings with the same format as LT_RUNNER_VERSION,
 *    LT_RUNNER_VERFSION_C, LT_TEST_VERSION, and LT_TEST_VERISON_C.
 *
 * @{
 */

#if !defined(LT_RUNNER_VERSION)

size_t litetest_get_test_major_internal(v);
#define LT_VERSION_MAJOR(v) litetest_get_test_major_internal()

size_t litetest_get_test_minor_internal(v);
#define LT_VERSION_MINOR(v) litetest_get_test_minor_internal((v))

size_t litetest_get_test_patch_internal(v);
#define LT_VERSION_PATCH(v) litetest_get_test_patch_internal((v))

// LiteTest version as an integer for comparisons.

size_t litetest_get_test_num_internal(v);
#define LT_VERSION_NUM(v) litetest_get_test_num_internal((v))

// LiteTest version encoded as 0xMMmmpp (major, minor, patch) for display/debug.

size_t litetest_get_test_hex_internal(v);
#define LT_VERSION_HEX(v) litetest_get_test_hex_internal((v))

// LiteTest version compared to specified version (1 if true, otherwie 0).

int litetest_test_cmp_internal
( comst char *v1, comst char *v2 );
#define LT_VERSION_CMP(v1, v2) litetest_test_cmp_internal((v1), (v2))

#endif

/** @} */ // End of Version Macros.

/* Structured error codes for test helper functions. */
typedef enum {
  LT_OK = 0,
  LT_FAIL = 1,
  LT_MISMATCH = 2,
  LT_TIMEOUT = 3,
  LT_EARG = -1,
  LT_ENOMEM = -2,
  LT_EIO = -3,
  LT_EPARSE = -4,
  LT_ESIZE = -5
} lt_error_t;

/* Allocator hook types for custom memory management. */
typedef void *(*lt_malloc_fn)(size_t size);
typedef void *(*lt_realloc_fn)(void *ptr, size_t size);
typedef void (*lt_free_fn)(void *ptr);

/* Get/set allocator hooks for custom memory management policy. */
void lt_set_allocator_hooks(lt_malloc_fn malloc_function,
                            lt_realloc_fn realloc_function,
                            lt_free_fn free_function);
void lt_get_allocator_hooks(lt_malloc_fn *malloc_function,
                            lt_realloc_fn *realloc_function,
                            lt_free_fn *free_function);

/**
 * @section TestHelperFunctions Test Helper Functions
 *
 * @note Some helpers allocate memory internally. Allocations are bounded by an
 * implementation cap to avoid unbounded growth. The current implementation cap
 * is 16 MiB per helper operation.
 *
 * @note Ownership rule: if a helper returns allocated memory through an output
 * pointer (for example, lt_read_file or lt_read_file_with_limit), the caller owns the
 * memory and must free it.
 *
 * @note Return conventions are grouped into three styles:
 * 1. Structured helpers return LT_OK, LT_MISMATCH, LT_TIMEOUT, or LT_E*.
 * 2. Predicate helpers return 1 for true/match, 0 for false/no-match, and -1 on error.
 * 3. Legacy process helpers return 0 for success, 1 for timeout/expected negative result,
 *    and -1 on invalid arguments or system failure.
 */

/**
 * @subsection TestHelperExecution Execution and Runtime Test Helper Functions
 */

/**
 * @name lt_execute_command
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
int lt_execute_command(const char *command_line,
                       int timeout_ms,
                       char *output_buffer,
                       size_t output_buffer_size,
                       int *exit_code);

/**
 * @name lt_wait_for_condition
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
int lt_wait_for_condition(int (*condition)(void *callback_context),
                          void *callback_context,
                          int timeout_ms,
                          int poll_interval_ms);

/**
 * @name lt_assert_completes_within
 *
 * @brief Run a callback and fail if it does not complete before the timeout.

 * @param callback Callback to run.
 * @param callback_context Callback context.
 * @param timeout_ms Timeout in milliseconds.
 *
 * @return 0 when the callback completed before the timeout, 1 when it timed out,
 * or -1 on invalid arguments or process/setup failure.
 */
int lt_assert_completes_within(int (*callback)(void *callback_context),
                               void *callback_context,
                               int timeout_ms);

/**
 * @name lt_capture_standard_error
 *
 * @brief Capture stderr output emitted by a callback.

 * @param callback Callback to run.
 * @param callback_context Callback context.
 * @param output_buffer Buffer receiving captured stderr output.
 * @param output_buffer_size Size of output_buffer.
 *
 * @return 0 when capture succeeded, or -1 on invalid arguments or pipe/process failure.
 */
int lt_capture_standard_error(int (*callback)(void *callback_context),
                              void *callback_context,
                              char *output_buffer,
                              size_t output_buffer_size);

/**
 * @subsection TestHelperFilesystem Filesystem and Path Test Helper Functions
 */

/**
 * @name lt_with_working_directory
 *
 * @brief Run a callback in a temporary working directory scope.

 * @param path Working directory path to use while the callback runs.
 * @param callback Callback to run.
 * @param callback_context Callback context.
 *
 * @return Callback result when setup and restore succeeded, or -1 on working-directory
 * setup/restore failure.
 */
int lt_with_working_directory(const char *path,
                              int (*callback)(void *callback_context),
                              void *callback_context);

/**
 * @name lt_copy_file
 *
 * @brief Copy a file from one path to another.
 *
 * @return 0 on success, -1 on error.
 */
int lt_copy_file(const char *source_path, const char *destination_path);

/**
 * @name lt_make_temp_dir
 *
 * @brief Create a unique temporary directory.
 *
 * @param prefix Prefix used in directory name.
 * @param out_path Buffer receiving created directory path.
 * @param out_path_size Size of out_path.
 *
 * @return 0 on success, -1 on error.
 */
int lt_make_temp_dir(const char *prefix, char *out_path, size_t out_path_size);

/**
 * @name lt_make_temp_file
 *
 * @brief Create a unique temporary file path.
 *
 * @return 0 on success, non-zero on error.
 */
int lt_make_temp_file(const char *prefix, char *out_path, size_t out_path_size);

/**
 * @name lt_make_dirs
 *
 * @brief Create a directory path recursively.
 *
 * @return 0 on success, non-zero on error.
 */
int lt_make_dirs(const char *path);

/**
 * @name lt_path_join
 *
 * @brief Join two path parts into one path.
 *
 * @return 0 on success, non-zero on error.
 */
int lt_path_join(const char *left_path_part,
                 const char *right_path_part,
                 char *output_path,
                 size_t output_path_size);

/**
 * @name lt_read_file
 *
 * @brief Read an entire file into a newly allocated buffer.
 *
 * @note On success, *content points to caller-owned memory that must be freed.
 *
 * @return LT_OK on success, LT_ENOMEM on size exceeded, LT_EIO on read error.
 */
int lt_read_file(const char *path, char **content, size_t *length);

/**
 * @name lt_read_file_with_limit
 *
 * @brief Read an entire file with explicit maximum size limit.
 *
 * @param path File path to read.
 * @param max_bytes Hard size limit (0 uses implementation default).
 * @param content Receives caller-owned memory (caller must free).
 * @param length Receives byte count read.
 *
 * @return LT_OK on success, LT_ESIZE if file exceeds max, LT_EIO on error.
 */
int lt_read_file_with_limit(const char *path,
                            size_t max_bytes,
                            char **content,
                            size_t *length);

/**
 * @name lt_read_file_into
 *
 * @brief Read a file into a caller-provided buffer (no allocation).
 *
 * @param path File path to read.
 * @param buffer Caller-provided buffer.
 * @param buffer_size Buffer size.
 * @param out_length Receives bytes actually read.
 *
 * @return LT_OK on success, LT_ESIZE if file exceeds buffer, LT_EIO on error.
 */
int lt_read_file_into(const char *path,
                      char *buffer,
                      size_t buffer_size,
                      size_t *out_length);

/**
 * @name lt_remove_tree
 *
 * @brief Remove a file or directory tree recursively.
 *
 * @return 0 on success, non-zero on error.
 */
int lt_remove_tree(const char *path);

/**
 * @name lt_stat_check
 *
 * @brief Validate basic file metadata constraints.
 *
 * @return 0 on success, non-zero on error.
 */
int lt_stat_check(const char *path, int must_exist, long minimum_size);

/**
 * @name lt_touch
 *
 * @brief Create a file if missing or update its modification time.
 *
 * @return 0 on success, non-zero on error.
 */
int lt_touch(const char *path);

/**
 * @name lt_write_file
 *
 * @brief Write a buffer to a file path.
 *
 * @return 0 on success, non-zero on error.
 */
int lt_write_file(const char *path, const void *buffer, size_t length);

/**
 * @subsection TestHelperComparison Comparison and Matching Test Helper Functions
 */

/**
 * @name lt_compare_dirs
 *
 * @brief Compare two directories.
 *
 * @return LT_OK when the selected directory content matches, LT_MISMATCH when it differs,
 * or LT_EIO on directory traversal or stat failure.
 */
int lt_compare_dirs(const char *left_path, const char *right_path, int recursive);

/**
 * @name lt_compare_files
 *
 * @brief Compare two open files byte-by-byte.
 *
 * @return 1 if equal, 0 if different, -1 on error.
 */
int lt_compare_files(FILE *left_file, FILE *right_file);

/**
 * @name lt_compare_file_to_path
 *
 * @brief Compare an open file with a file path.
 *
 * @return 1 if equal, 0 if different, -1 on error.
 */
int lt_compare_file_to_path(FILE *file, const char *path);

/**
 * @name lt_compare_paths
 *
 * @brief Compare two file paths byte-by-byte.
 *
 * @return 1 if equal, 0 if different, -1 on error.
 */
int lt_compare_paths(const char *left_path, const char *right_path);

/**
 * @name lt_compare_path_to_file
 *
 * @brief Compare a file path with an open file.
 *
 * @return 1 if equal, 0 if different, -1 on error.
 */
int lt_compare_path_to_file(const char *path, FILE *file);

enum {
  LT_FILECMP_IGNORE_TRAILING_WHITESPACE = 1 << 0,
  LT_FILECMP_IGNORE_EMPTY_LINES = 1 << 1,
  LT_FILECMP_IGNORE_TIMESTAMPS = 1 << 2,
  LT_FILECMP_IGNORE_LINE_ENDINGS = 1 << 3,
  LT_FILECMP_CASE_INSENSITIVE = 1 << 4
};

typedef struct {
  int flags;
} lt_path_compare_options_t;

#define LT_PATH_COMPARE_OPTIONS_INIT {0}

/**
 * @name lt_compare_paths_with_options
 *
 * @brief Compare two file paths with named comparison options.
 *
 * @param left_path First file path.
 * @param right_path Second file path.
 * @param options Optional comparison options. Pass NULL or LT_PATH_COMPARE_OPTIONS_INIT
 * for the default byte-for-byte comparison. options->flags uses LT_FILECMP_* values.
 *
 * @return LT_OK if equivalent, LT_MISMATCH if different, LT_EIO on error.
 */
int lt_compare_paths_with_options(const char *left_path,
                                  const char *right_path,
                                  const lt_path_compare_options_t *options);

/**
 * @name lt_compare_paths_ignoring_patterns
 *
 * @brief Compare two file paths while skipping lines that match regex patterns.
 *
 * @param left_path First file path.
 * @param right_path Second file path.
 * @param ignore_patterns POSIX extended regex patterns to skip.
 * @param pattern_count Number of patterns.
 *
 * @return LT_OK if equivalent, LT_MISMATCH if different, LT_EPARSE/LT_EIO on error.
 */
int lt_compare_paths_ignoring_patterns(const char *left_path,
                                       const char *right_path,
                               const char **ignore_patterns,
                               size_t pattern_count);

/**
 * @name lt_compare_paths_masking_fields
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
 * @return LT_OK if equivalent, LT_MISMATCH if different, LT_EIO on error.
 */
int lt_compare_paths_masking_fields(const char *left_path,
                                    const char *right_path,
                           const char **field_names,
                           size_t field_count);

/**
 * @name lt_compare_paths_masking_ranges
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
 * @return LT_OK if equivalent, LT_MISMATCH if different, LT_EIO on error.
 */
int lt_compare_paths_masking_ranges(const char *left_path,
                                    const char *right_path,
                           const size_t *skip_offsets,
                           const size_t *skip_lengths,
                           size_t range_count);

enum {
  LT_STATCMP_SIZE = 1 << 0,
  LT_STATCMP_PERMS = 1 << 1,
  LT_STATCMP_MTIME = 1 << 2,
  LT_STATCMP_OWNER = 1 << 3,
  LT_STATCMP_TYPE = 1 << 4
};

typedef struct {
  int flags;
} lt_path_metadata_compare_options_t;

#define LT_PATH_METADATA_COMPARE_OPTIONS_INIT {0}

/**
 * @name lt_compare_path_metadata
 *
 * @brief Compare selected filesystem metadata for two paths.
 *
 * @param left_path First path.
 * @param right_path Second path.
 * @param options Optional metadata comparison options. Pass NULL or
 * LT_PATH_METADATA_COMPARE_OPTIONS_INIT to compare size, permissions, and type.
 * options->flags uses LT_STATCMP_* values.
 *
 * @return LT_OK if selected metadata matches, LT_MISMATCH if different, LT_EIO on error.
 */
int lt_compare_path_metadata(const char *left_path,
                             const char *right_path,
                             const lt_path_metadata_compare_options_t *options);

/**
 * @name lt_hexdump_diff
 *
 * @brief Compare two byte buffers and emit context-friendly diff details.
 *
 * @return LT_OK when the buffers match, LT_MISMATCH when they differ, or LT_EARG
 * on invalid input.
 */
int lt_hexdump_diff(const void *a, const void *b, size_t n, size_t context);

/**
 * @name lt_compare_json
 *
 * @brief Compare JSON documents with default strict semantics.
 *
 * @note This convenience form is strict: object key order is significant and the
 * default allocation limit applies.
 *
 * @return LT_OK if equivalent, LT_MISMATCH if different, or LT_EPARSE on invalid JSON.
 */
int lt_compare_json(const char *expected_json, const char *actual_json);

typedef struct {
  size_t max_bytes;
  int ignore_key_order;
} lt_json_compare_options_t;

#define LT_JSON_COMPARE_OPTIONS_INIT {0, 0}

/**
 * @name lt_compare_json_with_limit
 *
 * @brief Compare JSON documents with named normalization and size options.
 *
 * @param expected_json Expected JSON string.
 * @param actual_json Actual JSON string.
 * @param options Optional JSON compare options. Pass NULL or
 * LT_JSON_COMPARE_OPTIONS_INIT to use the default size limit and strict key order.
 * Set options->ignore_key_order non-zero to normalize object key order. Set
 * options->max_bytes to apply a smaller explicit size limit.
 *
 * @return LT_OK if equivalent, LT_MISMATCH if different, LT_ESIZE/LT_EPARSE on error.
 */
int lt_compare_json_with_limit(const char *expected_json,
                               const char *actual_json,
                               const lt_json_compare_options_t *options);

/**
 * @name lt_match
 *
 * @brief Match text against a wildcard pattern.
 *
 * Supported wildcards:
 *   * matches zero or more characters
 *   ? matches exactly one character
 *
 * @return 1 on match, 0 on no match, -1 on invalid arguments.
 */
int lt_match(const char *text, const char *pattern);

/**
 * @name lt_compare_memory_detail
 *
 * @brief Compare two byte buffers and return first differing index.
 *
 * @return LT_OK when the buffers match, LT_MISMATCH when they differ, or LT_EARG
 * on invalid input.
 */
int lt_compare_memory_detail(const void *left_buffer,
                             const void *right_buffer,
                             size_t length,
                             size_t *first_difference);

typedef struct {
  int ignore_whitespace;
  int ignore_line_endings;
} lt_text_compare_options_t;

#define LT_TEXT_COMPARE_OPTIONS_INIT {0, 0}

/**
 * @name lt_compare_text_normalized
 *
 * @brief Compare text with named normalization options.
 *
 * @param left_text First text string.
 * @param right_text Second text string.
 * @param options Optional normalization options. Pass NULL or
 * LT_TEXT_COMPARE_OPTIONS_INIT for a literal text comparison.
 *
 * @return LT_OK when the texts match, LT_MISMATCH when they differ, or LT_EARG
 * on invalid input.
 */
int lt_compare_text_normalized(const char *left_text,
                               const char *right_text,
                               const lt_text_compare_options_t *options);

/**
 * @subsection TestHelperEnvironment Environment Test Helper Functions
 */

/**
 * @name lt_with_environment_variable
 *
 * @brief Temporarily set an environment variable for callback execution.
 *
 * @param variable_name Environment variable name.
 * @param temporary_value Value to assign while callback executes.
 * @param callback Callback to run.
 * @param callback_context Callback context.
 *
 * @return Callback result when setup and restore succeeded, or LT_EARG/LT_EIO if
 * the temporary environment override could not be applied or restored.
 */
int lt_with_environment_variable(const char *variable_name,
                                 const char *temporary_value,
                                 int (*callback)(void *callback_context),
                                 void *callback_context);

/**
 * @subsection TestHelperProcessResult Process Exit Code Test Helper Functions
 */

/**
 * @name lt_get_command_exit_code
 *
 * @brief Execute command and retrieve exit code.
 *
 * @param command_line Shell command to execute.
 * @param exit_code Receives process exit code.
 *
 * @return LT_OK on success, LT_EIO on exec error.
 */
int lt_get_command_exit_code(const char *command_line, int *exit_code);

/**
 * @name lt_assert_command_exit_code
 *
 * @brief Execute command and verify it exits with expected code.
 *
 * @param command_line Shell command to execute.
 * @param expected_code Expected exit code.
 *
 * @return LT_OK if code matches, LT_MISMATCH if different, LT_EIO on error.
 */
int lt_assert_command_exit_code(const char *command_line, int expected_code);

/**
 * @subsection TestHelperFilesystemPredicates Filesystem Predicate Test Helper Functions
 */

/**
 * @name lt_exists
 *
 * @brief Check if path exists (file or directory).
 *
 * @return 1 if exists, 0 if not, -1 on error.
 */
int lt_exists(const char *path);

/**
 * @name lt_is_file
 *
 * @brief Check if path is a regular file.
 *
 * @return 1 if regular file, 0 if not, -1 on error.
 */
int lt_is_file(const char *path);

/**
 * @name lt_is_directory
 *
 * @brief Check if path is a directory.
 *
 * @return 1 if directory, 0 if not, -1 on error.
 */
int lt_is_directory(const char *path);

/**
 * @name lt_get_size
 *
 * @brief Get file size in bytes.
 *
 * @param path File path.
 * @param size Receives file size.
 *
 * @return LT_OK on success, LT_EARG on invalid input, or LT_EIO on stat failure.
 */
int lt_get_size(const char *path, size_t *size_bytes);

/**
 * @name lt_file_age
 *
 * @brief Get file age in seconds since last modification.
 *
 * @param path File path.
 * @param age_seconds Receives age in seconds.
 *
 * @return LT_OK on success, LT_EARG on invalid input, or LT_EIO on stat failure.
 */
int lt_file_age(const char *path, time_t *age_seconds);

/**
 * @name lt_path_has_extension
 *
 * @brief Check if path has specified extension.
 *
 * @param path File path.
 * @param extension Extension string (e.g., ".txt").
 *
 * @return 1 if matches, 0 if not, -1 on invalid args.
 */
int lt_path_has_extension(const char *path, const char *extension);

/**
 * @subsection TestHelperStringText String and Text Test Helper Functions
 */

/**
 * @name lt_string_contains
 *
 * @brief Search for substring in text.
 *
 * @param text Haystack string.
 * @param substring Needle substring.
 * @param position Receives position of first match (optional).
 *
 * @return 1 if found, 0 if not, -1 on invalid args.
 */
int lt_string_contains(const char *text, const char *substring, size_t *position);

/**
 * @name lt_string_starts_with
 *
 * @brief Check if text starts with prefix.
 *
 * @return 1 if yes, 0 if no, -1 on invalid args.
 */
int lt_string_starts_with(const char *text, const char *prefix);

/**
 * @name lt_string_ends_with
 *
 * @brief Check if text ends with suffix.
 *
 * @return 1 if yes, 0 if no, -1 on invalid args.
 */
int lt_string_ends_with(const char *text, const char *suffix);

/**
 * @name lt_match_regex
 *
 * @brief Match text against POSIX extended regex pattern.
 *
 * @param text Text to match.
 * @param pattern Extended regex pattern.
 *
 * @return 1 on match, 0 on no match, or -1 on invalid input or regex compilation failure.
 */
int lt_match_regex(const char *text, const char *pattern);

/**
 * @name lt_compare_file_lines
 *
 * @brief Compare two files line-by-line.
 *
 * @param file1 First file path.
 * @param file2 Second file path.
 *
 * @return LT_OK if identical, LT_MISMATCH if different, LT_EIO on error.
 */
int lt_compare_file_lines(const char *left_path, const char *right_path);

/**
 * @subsection TestHelperFileOps Extended File Operation Test Helper Functions
 */

/**
 * @name lt_append_file
 *
 * @brief Append content to a file.
 *
 * @param path File path.
 * @param content Data to append.
 * @param length Byte count to append.
 *
 * @return LT_OK on success, LT_EIO on error.
 */
int lt_append_file(const char *path, const char *content, size_t length);

/**
 * @name lt_rename_file
 *
 * @brief Rename or move a file.
 *
 * @param old_path Current path.
 * @param new_path New path.
 *
 * @return LT_OK on success, LT_EIO on error.
 */
int lt_rename_file(const char *old_path, const char *new_path);

/**
 * @name lt_symlink
 *
 * @brief Create a symbolic link.
 *
 * @param target Link target path.
 * @param link_path Path for new symlink.
 *
 * @return LT_OK on success, LT_EIO on error.
 */
int lt_symlink(const char *target, const char *link_path);

/**
 * @subsection TestHelperJsonData JSON Data Extraction Test Helper Functions
 */

/**
 * @name lt_json_extract
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
 * @return LT_OK on success, LT_EARG on invalid input, LT_EPARSE if the path is not
 * found or cannot be parsed, or LT_ESIZE if extraction exceeds bounded storage.
 */
int lt_json_extract(const char *json_text, const char *path, char **out_value);

/**
 * @name lt_json_has_path
 *
 * @brief Check if JSON path exists.
 *
 * @param json_text JSON document.
 * @param path Path to check (e.g., "obj.key[0]").
 *
 * @return 1 if the path exists, 0 if it does not, or -1 when the input is invalid
 * or the JSON cannot be parsed.
 */
int lt_json_has_path(const char *json_text, const char *path);

/**
 * @subsection TestHelperResourceMgmt Resource Management Test Helper Functions
 */

/**
 * @name lt_cleanup_register
 *
 * @brief Register cleanup callback to run at test end.
 *
 * Cleanup functions run in LIFO order (last registered, first run).
 *
 * @param cleanup_callback Callback to run.
 * @param cleanup_context Context passed to cleanup.
 *
 * @return LT_OK on success, LT_ENOMEM on limit reached.
 */
int lt_cleanup_register(void (*cleanup_callback)(void *cleanup_context),
                        void *cleanup_context);

/**
 * @name lt_temp_file_auto
 *
 * @brief Create temporary file with auto-cleanup.
 *
 * File is automatically deleted at test end.
 *
 * @param suffix File suffix (e.g., ".txt").
 * @param outpath Buffer receiving file path.
 * @param outpathsz Size of outpath.
 *
 * @return LT_OK on success, LT_EIO on error.
 */
int lt_temp_file_auto(const char *suffix, char *outpath, size_t outpathsz);

#if defined(__cplusplus)
}
#endif
