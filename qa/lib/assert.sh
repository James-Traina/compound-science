#!/bin/bash
# QA assertion library for compound-science plugin testing
# Sources this file, then use: group, test_start, pass, must_fix, should_fix, skip, summary

set -euo pipefail

# --- State ---
_QA_TOTAL=0
_QA_PASSED=0
_QA_MUST_FIX=0
_QA_SHOULD_FIX=0
_QA_SKIPPED=0
_QA_GROUP=""
_QA_FAILURES=()
_QA_WARNINGS=()

# --- Paths ---
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PLUGIN_DIR="${PLUGIN_DIR:-$REPO_DIR}"
QA_DIR="${QA_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REPORT_DIR="$QA_DIR/reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/report-$(date +%Y%m%d-%H%M%S).log"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Functions ---

group() {
  _QA_GROUP="$1"
  _log ""
  _log "${BOLD}${CYAN}── $1 ──${RESET}"
}

pass() {
  local msg="$1"
  (( _QA_TOTAL++ )) || true
  (( _QA_PASSED++ )) || true
  _log "  ${GREEN}PASS${RESET}  $_QA_GROUP/$msg"
  _report "PASS" "$_QA_GROUP/$msg"
}

must_fix() {
  local msg="$1"
  local detail="${2:-}"
  (( _QA_TOTAL++ )) || true
  (( _QA_MUST_FIX++ )) || true
  _QA_FAILURES+=("$_QA_GROUP/$msg: $detail")
  _log "  ${RED}FAIL${RESET}  $_QA_GROUP/$msg"
  [ -n "$detail" ] && _log "        ${RED}→ $detail${RESET}"
  _report "FAIL" "$_QA_GROUP/$msg" "$detail"
}

should_fix() {
  local msg="$1"
  local detail="${2:-}"
  (( _QA_TOTAL++ )) || true
  (( _QA_SHOULD_FIX++ )) || true
  _QA_WARNINGS+=("$_QA_GROUP/$msg: $detail")
  _log "  ${YELLOW}WARN${RESET}  $_QA_GROUP/$msg"
  [ -n "$detail" ] && _log "        ${YELLOW}→ $detail${RESET}"
  _report "WARN" "$_QA_GROUP/$msg" "$detail"
}

skip() {
  local msg="$1"
  local reason="${2:-}"
  (( _QA_TOTAL++ )) || true
  (( _QA_SKIPPED++ )) || true
  _log "  ${CYAN}SKIP${RESET}  $_QA_GROUP/$msg${reason:+ ($reason)}"
  _report "SKIP" "$_QA_GROUP/$msg" "$reason"
}

# Assert a command exits 0
assert_ok() {
  local msg="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    pass "$msg"
  else
    must_fix "$msg" "command failed: $*"
  fi
}

# Assert a file exists
assert_file_exists() {
  local msg="$1"
  local path="$2"
  if [ -f "$path" ]; then
    pass "$msg"
  else
    must_fix "$msg" "file not found: $path"
  fi
}

# Assert a directory exists
assert_dir_exists() {
  local msg="$1"
  local path="$2"
  if [ -d "$path" ]; then
    pass "$msg"
  else
    must_fix "$msg" "directory not found: $path"
  fi
}

# Assert grep finds no matches (clean check)
assert_no_matches() {
  local msg="$1"
  local pattern="$2"
  local path="$3"
  local severity="${4:-must_fix}"
  local hits
  hits=$(grep -rn -E "$pattern" "$path" 2>/dev/null || true)
  if [ -z "$hits" ]; then
    pass "$msg"
  else
    local count
    count=$(echo "$hits" | wc -l | tr -d ' ')
    "$severity" "$msg" "$count match(es) found"
  fi
}

# Assert grep finds at least one match
assert_has_match() {
  local msg="$1"
  local pattern="$2"
  local path="$3"
  if grep -rq -E "$pattern" "$path" 2>/dev/null; then
    pass "$msg"
  else
    must_fix "$msg" "pattern not found: $pattern"
  fi
}

# Assert file count equals expected
assert_count() {
  local msg="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$msg ($actual)"
  else
    must_fix "$msg" "expected $expected, got $actual"
  fi
}

summary() {
  _log ""
  _log "${BOLD}═══════════════════════════════════════${RESET}"
  _log "${BOLD}  COMPOUND-SCIENCE QA REPORT${RESET}"
  _log "${BOLD}═══════════════════════════════════════${RESET}"
  _log ""
  _log "  Total:     $_QA_TOTAL"
  _log "  ${GREEN}Passed:    $_QA_PASSED${RESET}"
  [ "$_QA_MUST_FIX" -gt 0 ] && _log "  ${RED}Must-fix:  $_QA_MUST_FIX${RESET}" || _log "  Must-fix:  0"
  [ "$_QA_SHOULD_FIX" -gt 0 ] && _log "  ${YELLOW}Should-fix: $_QA_SHOULD_FIX${RESET}" || _log "  Should-fix: 0"
  [ "$_QA_SKIPPED" -gt 0 ] && _log "  ${CYAN}Skipped:   $_QA_SKIPPED${RESET}" || _log "  Skipped:   0"
  _log ""

  if [ ${#_QA_FAILURES[@]} -gt 0 ]; then
    _log "${RED}${BOLD}  MUST-FIX ISSUES:${RESET}"
    for f in "${_QA_FAILURES[@]}"; do
      _log "  ${RED}• $f${RESET}"
    done
    _log ""
  fi

  if [ ${#_QA_WARNINGS[@]} -gt 0 ]; then
    _log "${YELLOW}${BOLD}  SHOULD-FIX ISSUES:${RESET}"
    for w in "${_QA_WARNINGS[@]}"; do
      _log "  ${YELLOW}• $w${RESET}"
    done
    _log ""
  fi

  if [ "$_QA_MUST_FIX" -eq 0 ] && [ "$_QA_SHOULD_FIX" -eq 0 ]; then
    _log "  ${GREEN}${BOLD}✓ ALL CLEAR — ready to ship${RESET}"
  elif [ "$_QA_MUST_FIX" -eq 0 ]; then
    _log "  ${YELLOW}${BOLD}⚠ Shippable with warnings${RESET}"
  else
    _log "  ${RED}${BOLD}✗ BLOCKED — fix must-fix issues before release${RESET}"
  fi

  _log ""
  _log "  Report saved: $REPORT_FILE"
  _log "${BOLD}═══════════════════════════════════════${RESET}"

  # Write summary to report
  {
    echo ""
    echo "=== SUMMARY ==="
    echo "Total: $_QA_TOTAL | Passed: $_QA_PASSED | Must-fix: $_QA_MUST_FIX | Should-fix: $_QA_SHOULD_FIX | Skipped: $_QA_SKIPPED"
  } >> "$REPORT_FILE"

  # Exit code reflects status
  [ "$_QA_MUST_FIX" -eq 0 ]
}

# --- Internal ---

_log() {
  echo -e "$1"
}

_report() {
  local status="$1"
  local name="$2"
  local detail="${3:-}"
  echo "[$status] $name${detail:+ — $detail}" >> "$REPORT_FILE"
}
