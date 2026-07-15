#!/usr/bin/env bash

# Test script for bt_propagate_repository_history() helper
# Tests efficiency (SHA comparison), return codes, and behavior

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Source the helper
source "$SCRIPT_DIR/scripts/helpers/history_log.sh"

echo "=== Testing bt_propagate_repository_history() Helper ==="
echo ""

# Test 1: Basic functionality - currently on dev/release-v1.0.0
echo "Test 1: Propagate from current branch (dev/release-v1.0.0)"
echo "Current branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Calling: bt_propagate_repository_history"

if bt_propagate_repository_history; then
  exit_code=$?
else
  exit_code=$?
fi

case $exit_code in
  0)
    echo "✓ Result: Already up to date (no fetch needed, efficient!)"
    ;;
  1)
    echo "✓ Result: Updated from remote"
    ;;
  2)
    echo "⚠ Result: Offline, file not in repo, or error"
    ;;
esac
echo "Exit code: $exit_code"
echo ""

# Test 2: Check that repository_history.md exists locally
echo "Test 2: Verify repository_history.md exists"
if [[ -f "$REPO_ROOT/logs/repository_history.md" ]]; then
  echo "✓ File exists locally"
  echo "  File size: $(wc -c < "$REPO_ROOT/logs/repository_history.md") bytes"
  echo "  First 3 lines:"
  head -3 "$REPO_ROOT/logs/repository_history.md" | sed 's/^/    /'
else
  echo "✗ File not found locally"
fi
echo ""

# Test 3: Check remote connectivity
echo "Test 3: Remote connectivity"
if git ls-remote origin >/dev/null 2>&1; then
  echo "✓ Remote 'origin' is reachable"
  echo "  Remote URL: $(git config --get remote.origin.url)"
else
  echo "⚠ Remote 'origin' is not reachable (offline mode)"
fi
echo ""

# Test 4: Show SHA comparison logic (what the helper does internally)
echo "Test 4: SHA comparison (efficient check)"
if local_sha=$(git rev-parse HEAD:logs/repository_history.md 2>/dev/null); then
  echo "✓ Local SHA: $local_sha"
  
  if remote_sha=$(git rev-parse origin/HEAD:logs/repository_history.md 2>/dev/null); then
    echo "✓ Remote SHA: $remote_sha"
    
    if [[ "$local_sha" == "$remote_sha" ]]; then
      echo "✓ SHAs match → Already up to date (no fetch would occur)"
    else
      echo "⚠ SHAs differ → Would fetch from remote"
    fi
  else
    echo "⚠ Cannot get remote SHA (file may not exist in remote)"
  fi
else
  echo "⚠ File not in local repo yet"
fi
echo ""

# Test 5: Run helper multiple times (tests efficiency of SHA comparison)
echo "Test 5: Efficiency test (run twice, second should be instant)"
echo "First call:"
time bt_propagate_repository_history >/dev/null 2>&1
first_exit=$?

echo "Second call (should be instant if already current):"
time bt_propagate_repository_history >/dev/null 2>&1
second_exit=$?

if [[ $first_exit -eq 0 ]] && [[ $second_exit -eq 0 ]]; then
  echo "✓ Both calls returned 0 (already up to date)"
  echo "✓ Helper is efficient - SHAs matched on first call, no fetch needed"
fi
echo ""

echo "=== All Tests Complete ==="
