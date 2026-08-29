#!/usr/bin/env bash

# ckbranchname.sh - Checks name to determine its branch type.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.
#
# Usage:
#   ./briteRepo/helpers/ckbranchname.sh <name> [<type>]
#
#  <name> is the name to check.
#
#  <type> is case-insensitive and one of:
#    main, version, targeted, contributor, invalid, or
#    correspondingly 1, 2, 3, 4, or 5. If specified, compares the type
#    of the name to <type>; otherwise, exit with the type code
#    (1, 2, 3, 4, or 5).
#
# Exit codes:
#   0 type of <name> matches <type> (when <type> is specified).
#   1 type of name is 'main'.
#   2 type of name is 'version'.
#   3 type of name is 'targeted'.
#   4 type of name is 'contributor'.
#   5 name is not a valid branch name.
#   6 arguments cannot be parsed or <type> is not valid.
#   7 the type of the <name> is not <type> (when <type> is specified).

set -euo pipefail

# Parse arguments: name [type]
if [[ $# -lt 1 || $# -gt 2 ]]; then
  exit 6
fi

name="$1"
check_type="${2:-0}"

# Validate and normalize check_type
case "${check_type,,}" in
  0)
    check_type=0
    ;;
  main|1)
    check_type=1
    ;;
  version|2)
    check_type=2
    ;;
  targeted|3)
    check_type=3
    ;;
  contributor|4)
    check_type=4
    ;;
  invalid|5)
    check_type=5
    ;;
  *)
    exit 6
    ;;
esac

# Define regex patterns
desc='[a-z0-9]+(-[a-z0-9]+)*'
type='[a-z][a-z]{0,29}'
version_regex='^v[1-9][0-9]?\.(0|[1-9][0-9]?)\.0$'
targeted_regex="^(dev|fix)/${desc}-v[1-9][0-9]?\.(0|[1-9][0-9]?)\.0$"
contributor_regex="^((${type}/)?${desc})$"

# Determine the type of the branch name
nametype=0

# 1. 'main' branch?
if [[ "$name" == "main" ]]; then
  nametype=1
  
# 2. 'version' branch?
elif [[ "$name" =~ $version_regex ]]; then
  nametype=2

# 3. 'targeted' branch?
elif [[ "$name" =~ $targeted_regex ]]; then
  nametype=3

# 4. 'contributor' branch?
elif [[ "$name" =~ $contributor_regex ]]; then
  # Note: check 1 above effectively disallows 'main'
  # even though contributor_regex allows it.
  nametype=4

else
  nametype=5

fi

# Return result
if [[ $check_type -eq 0 ]]; then
  # No type specified; return the determined type
  exit "$nametype"
fi

if [[ $nametype -eq $check_type ]]; then
  # Type matches
  exit 0
fi

# Type does not match
exit 7
