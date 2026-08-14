#!/usr/bin/env bash

# test_fixlocal.sh - orchestrator for fixlocal smoke test groups.
#
# Copyright (c) 2026 Paul Sinclair
# SPDX-License-Identifier: MIT
# For license details, see LICENSE in the repository root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/test_fixlocal_core.sh"
bash "$SCRIPT_DIR/test_fixlocal_remote.sh"
bash "$SCRIPT_DIR/test_fixlocal_retention.sh"

echo "All fixlocal grouped smoke tests passed."
