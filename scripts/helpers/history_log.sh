#!/usr/bin/env bash

# Shared helpers for writing branch history markdown logs.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

bt_init_history_log() {
  local log_file="$1"

  mkdir -p "$(dirname "$log_file")"

  if [[ ! -f "$log_file" ]]; then
    cat > "$log_file" <<'HEADER'
# Branch History Log

HEADER
  fi
}

bt_append_history_log() {
  local log_file="$1"
  local message="$2"
  local comment="${3:-}"
  local timestamp

  bt_init_history_log "$log_file"

  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  if [[ -n "$comment" ]]; then
    cat >> "$log_file" <<EOF

**$timestamp**: $message
  $comment
EOF
  else
    cat >> "$log_file" <<EOF

**$timestamp**: $message
EOF
  fi
}
