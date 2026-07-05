#!/usr/bin/env bash

# Shared text output and branch-detection helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# High-Level Flow:
# - Provides shared output helpers for info/success/warn messaging.
# - Provides a common error-exit helper and branch-detection utility.
# - Maintains consistent lightweight shell behavior across scripts/bin tools.

bt_info() {
  echo "$1"
}

bt_success() {
  echo "$1"
}

bt_warn() {
  echo "$1"
}

bt_error_exit() {
  local code="$1"
  local message="$2"

  echo "Error: $message" >&2
  exit "$code"
}

bt_get_current_branch_or_empty() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || true
}
