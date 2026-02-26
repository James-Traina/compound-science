#!/bin/bash
# Compound-Science QA Suite
# Run all tests and generate a consolidated report.
#
# Usage:
#   ./qa/run-all.sh              # Run all tests
#   ./qa/run-all.sh 05 07        # Run specific test groups
#   ./qa/run-all.sh --list       # List available tests

set -euo pipefail

QA_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$QA_DIR/.." && pwd)"
PLUGIN_DIR="$REPO_DIR"
REPORT_DIR="$QA_DIR/reports"
mkdir -p "$REPORT_DIR"

# Shared report file for all tests in this run
SHARED_REPORT="$REPORT_DIR/report-$(date +%Y%m%d-%H%M%S).log"

export QA_DIR REPO_DIR PLUGIN_DIR REPORT_DIR SHARED_REPORT

# --- Parse args ---

if [ "${1:-}" = "--list" ]; then
  echo "Available test groups:"
  for test_file in "$QA_DIR"/tests/*.sh; do
    name=$(basename "$test_file" .sh)
    desc=$(head -2 "$test_file" | grep '^#' | tail -1 | sed 's/^# *//')
    printf "  %-30s %s\n" "$name" "$desc"
  done
  exit 0
fi

# --- Header ---

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║     COMPOUND-SCIENCE QA TEST SUITE        ║"
echo "║     $(date +%Y-%m-%d\ %H:%M:%S)                      ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# --- Collect tests ---

tests=()
if [ $# -gt 0 ]; then
  for arg in "$@"; do
    while IFS= read -r f; do tests+=("$f"); done < <(find "$QA_DIR/tests" -name "${arg}*.sh" 2>/dev/null | sort)
  done
else
  while IFS= read -r f; do tests+=("$f"); done < <(find "$QA_DIR/tests" -name "*.sh" | sort)
fi

# --- Run tests ---

for test_file in "${tests[@]}"; do
  bash "$test_file" 2>&1 || true
done

# --- Consolidated report ---

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║           CONSOLIDATED RESULTS            ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# Aggregate across ALL report files from this run (each test creates one)
all_reports=("$REPORT_DIR"/report-*.log)

total_pass=0
total_fail=0
total_warn=0
total_skip=0

for rpt in "${all_reports[@]}"; do
  [ -f "$rpt" ] || continue
  p=$(grep -c '^\[PASS\]' "$rpt" 2>/dev/null) || p=0
  f=$(grep -c '^\[FAIL\]' "$rpt" 2>/dev/null) || f=0
  w=$(grep -c '^\[WARN\]' "$rpt" 2>/dev/null) || w=0
  s=$(grep -c '^\[SKIP\]' "$rpt" 2>/dev/null) || s=0
  total_pass=$((total_pass + p))
  total_fail=$((total_fail + f))
  total_warn=$((total_warn + w))
  total_skip=$((total_skip + s))
done

total_all=$((total_pass + total_fail + total_warn + total_skip))

echo "  Total:      $total_all"
echo "  Passed:     $total_pass"
echo "  Must-fix:   $total_fail"
echo "  Should-fix: $total_warn"
echo "  Skipped:    $total_skip"
echo ""

if [ "$total_fail" -gt 0 ]; then
  echo "  MUST-FIX:"
  for rpt in "${all_reports[@]}"; do
    [ -f "$rpt" ] || continue
    grep '^\[FAIL\]' "$rpt" 2>/dev/null | while read -r line; do
      echo "    $line"
    done
  done
  echo ""
fi

if [ "$total_warn" -gt 0 ]; then
  echo "  SHOULD-FIX:"
  for rpt in "${all_reports[@]}"; do
    [ -f "$rpt" ] || continue
    grep '^\[WARN\]' "$rpt" 2>/dev/null | while read -r line; do
      echo "    $line"
    done
  done
  echo ""
fi

if [ "$total_fail" -eq 0 ] && [ "$total_warn" -eq 0 ]; then
  echo "  ✓ ALL CLEAR — ready to ship"
elif [ "$total_fail" -eq 0 ]; then
  echo "  ⚠ Shippable with warnings"
else
  echo "  ✗ BLOCKED — fix must-fix issues before release"
fi

echo ""

# Clean up old reports (keep only latest)
latest=$(ls -t "$REPORT_DIR"/report-*.log 2>/dev/null | head -1)
for rpt in "$REPORT_DIR"/report-*.log; do
  [ "$rpt" != "$latest" ] && rm -f "$rpt"
done

echo "  Report: $latest"
echo ""

# Exit with failure if must-fix issues exist
[ "$total_fail" -eq 0 ]
