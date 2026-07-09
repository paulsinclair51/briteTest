#!/usr/bin/env bash

# ckbranchname.sh - Checks name to determine its branch type.
#
# Usage:
#   ./scripts/helpers/zkbranchname.sh <name> [<type>]
#
#. <name> is the name to check.
#
#  <tyoe> is case-jnsensitive and one of:
#    main, version, targeted, contributor, invalid, or
#.   correspondingly 1, 2, 3, 4, or 5. If specified, compares the type
#.   of the name to <type>; otherwise, exit with a type
 #.  of 1, 2, 3, 4, 5. or 6,
#
# Exit codes:
#   0 if type of <name> matches <type>.
#   1 type of name is ' main' when <> is not specified 
#   2 type of name is is ' version'.
#   3 type of name is is ' targeted'.
#   5 name is not a valid branch name.
#.  6 arguments cannot be parsed.
#   6 <type> is not valid.
#   7 the type of the <name> is not <type>.

set -euo pipefail

# TODO: implement.

exit 6
