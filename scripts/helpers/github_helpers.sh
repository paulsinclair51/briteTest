#!/usr/bin/env bash

# Shared GitHub CLI helpers.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

bt_gh_find_pr_number_for_branch() {
  local branch="$1"
  local state="${2:-all}"

  gh pr list --head "$branch" --state "$state" --json number --jq '.[0].number' 2>/dev/null || echo ""
}
