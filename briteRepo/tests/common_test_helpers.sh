#!/usr/bin/env bash

# Shared assertion and command-capture helpers for shell smoke tests.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, '<repo>/LICENSE'.

pass() {
  echo "PASS: $1"
}

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

run_capture() {
  local output_file="$1"
  shift
  set +e
  "$@" >"$output_file" 2>&1
  local status=$?
  set -e
  echo "$status"
}

assert_contains() {
  local text="$1"
  local file="$2"
  grep -Fq -- "$text" "$file" || fail "expected '$text' in $file"
}

assert_matches() {
  local regex="$1"
  local file="$2"
  grep -Eq -- "$regex" "$file" || fail "expected pattern '$regex' in $file"
}
