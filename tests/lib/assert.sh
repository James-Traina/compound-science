#!/bin/bash
# Assertion library for compound-science plugin testing

set -euo pipefail

# --- State ---
_QA_TOTAL=0
_QA_PASSED=0
_QA_MUST_FIX=0
_QA_SHOULD_FIX=0
_QA_SKIPPED=0
_QA_GROUP=""

# --- Paths ---
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PLUGIN_DIR="${PLUGIN_DIR:-$REPO_DIR}"
QA_DIR="${QA_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REPORT_DIR="$QA_DIR/reports"
mkdir -p "$REPORT_DIR"

# Use shared report when run via run-all.sh, otherwise create own
if [ -n "${SHARED_REPORT:-}" ]; then
  REPORT_FILE="$SHARED_REPORT"
else
  REPORT_FILE="$REPORT_DIR/report-$(date +%Y%m%d-%H%M%S).log"
fi

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
  echo -e ""
  echo -e "${BOLD}${CYAN}── $1 ──${RESET}"
}

pass() {
  local msg="$1"
  (( _QA_TOTAL++ )) || true
  (( _QA_PASSED++ )) || true
  echo -e "  ${GREEN}PASS${RESET}  $_QA_GROUP/$msg"
  echo "[PASS] $_QA_GROUP/$msg" >> "$REPORT_FILE"
}

must_fix() {
  local msg="$1"
  local detail="${2:-}"
  (( _QA_TOTAL++ )) || true
  (( _QA_MUST_FIX++ )) || true
  echo -e "  ${RED}FAIL${RESET}  $_QA_GROUP/$msg"
  [ -n "$detail" ] && echo -e "        ${RED}→ $detail${RESET}"
  echo "[FAIL] $_QA_GROUP/$msg${detail:+ — $detail}" >> "$REPORT_FILE"
}

should_fix() {
  local msg="$1"
  local detail="${2:-}"
  (( _QA_TOTAL++ )) || true
  (( _QA_SHOULD_FIX++ )) || true
  echo -e "  ${YELLOW}WARN${RESET}  $_QA_GROUP/$msg"
  [ -n "$detail" ] && echo -e "        ${YELLOW}→ $detail${RESET}"
  echo "[WARN] $_QA_GROUP/$msg${detail:+ — $detail}" >> "$REPORT_FILE"
}

skip() {
  local msg="$1"
  local reason="${2:-}"
  (( _QA_TOTAL++ )) || true
  (( _QA_SKIPPED++ )) || true
  echo -e "  ${CYAN}SKIP${RESET}  $_QA_GROUP/$msg${reason:+ ($reason)}"
  echo "[SKIP] $_QA_GROUP/$msg${reason:+ — $reason}" >> "$REPORT_FILE"
}

# --- Helpers ---

assert_ok() {
  local msg="$1"; shift
  if "$@" >/dev/null 2>&1; then
    pass "$msg"
  else
    must_fix "$msg" "command failed: $*"
  fi
}

assert_file_exists() {
  local msg="$1" path="$2"
  if [ -f "$path" ]; then pass "$msg"; else must_fix "$msg" "file not found: $path"; fi
}

assert_dir_exists() {
  local msg="$1" path="$2"
  if [ -d "$path" ]; then pass "$msg"; else must_fix "$msg" "directory not found: $path"; fi
}

assert_count() {
  local msg="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$msg ($actual)"
  else
    must_fix "$msg" "expected $expected, got $actual"
  fi
}
