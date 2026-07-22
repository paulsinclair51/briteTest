#!/usr/bin/env bash

# Shared helpers for synchronizing reports between local and remote.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

# Copy reports to remote repository (untracked sync, not via git push).
# Supports SSH and file:// remote URLs.
bt_report_copy_to_remote() {
  local repo_root="$1"
  local reports_dir="$2"
  local report_pattern="${3:-commit*.md}"
  local remote_url
  local remote_host
  local remote_path

  [[ -d "$reports_dir" ]] || return 0

  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  [[ -n "$remote_url" ]] || return 0

  # Extract host and path from SSH URL (git@host:path)
  if [[ "$remote_url" =~ ^git@([^:]+):(.+)(.git)?$ ]]; then
    remote_host="${BASH_REMATCH[1]}"
    remote_path="${BASH_REMATCH[2]}"
    [[ "$remote_path" == *.git ]] && remote_path="${remote_path%.git}"

    # Copy reports to remote bare repo
    if ! scp -q "$reports_dir"/$report_pattern "git@${remote_host}:${remote_path}/reports/branch/" 2>/dev/null; then
      return 1
    fi
    return 0
  fi

  # Extract path from file:// URL
  if [[ "$remote_url" =~ ^file://(.+) ]]; then
    remote_path="${BASH_REMATCH[1]}"
    if [[ -d "$remote_path/reports/branch" ]]; then
      cp -f "$reports_dir"/$report_pattern "$remote_path/reports/branch/" 2>/dev/null || return 1
      return 0
    fi
  fi

  return 1
}

# Copy reports from remote repository to local (untracked sync).
# Supports SSH and file:// remote URLs.
bt_report_copy_from_remote() {
  local repo_root="$1"
  local reports_dir="$2"
  local report_pattern="${3:-commit*.md}"
  local remote_url
  local remote_host
  local remote_path

  [[ -d "$reports_dir" ]] || return 0

  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  [[ -n "$remote_url" ]] || return 0

  # Extract host and path from SSH URL (git@host:path)
  if [[ "$remote_url" =~ ^git@([^:]+):(.+)(.git)?$ ]]; then
    remote_host="${BASH_REMATCH[1]}"
    remote_path="${BASH_REMATCH[2]}"
    [[ "$remote_path" == *.git ]] && remote_path="${remote_path%.git}"

    # Copy reports from remote bare repo
    if ! scp -q "git@${remote_host}:${remote_path}/reports/branch"/$report_pattern "$reports_dir/" 2>/dev/null; then
      return 1
    fi
    return 0
  fi

  # Extract path from file:// URL
  if [[ "$remote_url" =~ ^file://(.+) ]]; then
    remote_path="${BASH_REMATCH[1]}"
    if [[ -d "$remote_path/reports/branch" ]]; then
      cp -f "$remote_path/reports/branch"/$report_pattern "$reports_dir/" 2>/dev/null || return 1
      return 0
    fi
  fi

  return 1
}

# Sync reports between local and remote: copy from remote first, then copy local to remote.
# This ensures both local and remote have the union of both sets.
bt_report_sync_bidirectional() {
  local repo_root="$1"
  local reports_dir="$2"
  local report_pattern="${3:-commit*.md}"

  [[ -d "$reports_dir" ]] || return 0

  # First, copy from remote to fill in any missing reports locally
  bt_report_copy_from_remote "$repo_root" "$reports_dir" "$report_pattern" 2>/dev/null || true

  # Then, copy local reports to remote to ensure remote has all local reports
  bt_report_copy_to_remote "$repo_root" "$reports_dir" "$report_pattern" 2>/dev/null || true

  return 0
}
