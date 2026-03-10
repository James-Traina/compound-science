#!/usr/bin/env bash
# Test Group 7: Functional hook simulation with test fixtures (20 tests)
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/fixtures.sh"

SCRIPT="$PLUGIN_DIR/hooks/session-start.sh"

group "SessionStart — Empty Project"

dir=$(fixture_empty)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)
data=$(echo "$result" | cut -f3)
pipe=$(echo "$result" | cut -f4)
output=$(echo "$result" | cut -f5-)

# 1-4
[ "$ptype" = "unknown" ] && pass "empty → type=unknown" || must_fix "empty → type=unknown" "got $ptype"
[ "$lang" = "none" ] && pass "empty → lang=none" || must_fix "empty → lang=none" "got $lang"
[ "$data" = "false" ] && pass "empty → data=false" || must_fix "empty → data=false" "got $data"
[ "$pipe" = "false" ] && pass "empty → pipeline=false" || must_fix "empty → pipeline=false" "got $pipe"

group "SessionStart — Language Detection"

# 5-6
dir=$(fixture_python_econometrics)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)
[ "$ptype" = "empirical" ] && pass "python → type=empirical" || must_fix "python → type=empirical" "got $ptype"
[ "$lang" = "python" ] && pass "python → lang=python" || must_fix "python → lang=python" "got $lang"

# 7-8
dir=$(fixture_r_project)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)
[ "$ptype" = "empirical" ] && pass "R → type=empirical" || must_fix "R → type=empirical" "got $ptype"
[ "$lang" = "R" ] && pass "R → lang=R" || must_fix "R → lang=R" "got $lang"

# 9-10
dir=$(fixture_stata)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)
[ "$ptype" = "empirical" ] && pass "stata → type=empirical" || must_fix "stata → type=empirical" "got $ptype"
[ "$lang" = "stata" ] && pass "stata → lang=stata" || must_fix "stata → lang=stata" "got $lang"

# 11-12
dir=$(fixture_julia)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)
[ "$ptype" = "empirical" ] && pass "julia → type=empirical" || must_fix "julia → type=empirical" "got $ptype"
[ "$lang" = "julia" ] && pass "julia → lang=julia" || must_fix "julia → lang=julia" "got $lang"

group "SessionStart — Project Type Detection"

# 13
dir=$(fixture_latex_paper)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
[ "$ptype" = "paper" ] && pass "latex → type=paper" || must_fix "latex → type=paper" "got $ptype"

# 14
dir=$(fixture_empirical_paper)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
[ "$ptype" = "empirical-paper" ] && pass "empirical-paper → type=empirical-paper" || must_fix "empirical-paper → type=empirical-paper" "got $ptype"

group "SessionStart — Data & Pipeline Detection"

# 15-16
dir=$(fixture_with_data)
result=$(run_session_init "$dir" "$SCRIPT")
data=$(echo "$result" | cut -f3)
[ "$data" = "true" ] && pass "data dir → data=true" || must_fix "data dir → data=true" "got $data"

dir=$(fixture_with_pipeline)
result=$(run_session_init "$dir" "$SCRIPT")
pipe=$(echo "$result" | cut -f4)
[ "$pipe" = "true" ] && pass "Makefile → pipeline=true" || must_fix "Makefile → pipeline=true" "got $pipe"

group "SessionStart — Full Project"

# 17-18
dir=$(fixture_full_project)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
output=$(echo "$result" | cut -f5-)
[ "$ptype" = "empirical-paper" ] && pass "full → type=empirical-paper" || must_fix "full → type=empirical-paper" "got $ptype"
echo "$output" | grep -q '/estimate' && pass "full → suggests /estimate" || must_fix "full → suggests /estimate" "missing"

group "SessionStart — Config & Output"

# 19
dir=$(fixture_with_local_config)
result=$(run_session_init "$dir" "$SCRIPT")
output=$(echo "$result" | cut -f5-)
echo "$output" | grep -q 'Settings loaded' && pass "local config → detected" || must_fix "local config → detected" "output: $output"

# 20: Full project suggests pipeline-validator
dir=$(fixture_full_project)
result=$(run_session_init "$dir" "$SCRIPT")
output=$(echo "$result" | cut -f5-)
echo "$output" | grep -q 'pipeline-validator' && pass "full → suggests pipeline-validator" || must_fix "full → suggests pipeline-validator" "missing"

# Cleanup
cleanup_fixtures
