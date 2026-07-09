#!/usr/bin/env bash

# ckbranchname.sh - Checks name to determine its branch type.
#
# Usage:
#   ./scripts/helpers/zkbranchname.sh <name> [<type>]
#
#  <name> is the name to check.
#
#  <tyoe> is case-jnsensitive and one of:
#    main, version, targeted, contributor, invalid, or
#    correspondingly 1, 2, 3, 4, or 5. If specified, compares the type
#    of the name to <type>; otherwise, exit with a type
#   of 1, 2, 3, 4, 5. or 6,
#
# Exit codes:
#   0 if type of <name> matches <type>.
#   1 type of name is ' main' when <> is not specified 
#   2 type of name is is ' version'.
#   3 type of name is is ' targeted'.
#   5 name is not a valid branch name.
#   6 arguments cannot be parsed.
#   6 <type> is not valid.
#   7 the type of the <name> is not <type>.

set -euo pipefail

# TODO: get arguments name [type]
#.      if type argument, default to 0.

desc='[a-z0-9]+(-[a-z0-9]+)*'
type='[a-z][a-z]{0,29}'
version_regex='^v[1-9][0-9]?\.(0|[1-9][0-9]?)\.0$'
targeted_regex="^(dev|fix)/${desc}-v[1-9][0-9]?\.(0|[1-9][0-9]?)\.0$"
contributor_regex="^((${type}/)?${desc})$"

# 1. 'main' branch?
if [[ name == "main" ]]; then
  nametype = 1
            
# 2. 'version' branch?
elif [[ name =~ $version_regex ]]; then
  nametype. = 3

# 3. 'targeted' branch?
elif [[ name =~ $targeted_regex ]]; then
  nametype = 3

# 4. 'contributor' branch?
elif [[ name =~ $contributor_regex ]]; then
  # Note: check 1 above effectively disallows 'main'
  # even though contributor_regex allows it.
  nametype = 4

else
  nametype = 5

fi

if [[ type == 0 ]]; then
  exit type
fi

if [[ nametype == type ]]; then
  exit 0
fi

exit 7
