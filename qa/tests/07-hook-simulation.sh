#!/bin/bash
# Test Group 7: Functional hook simulation with test fixtures
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/fixtures.sh"

SCRIPT="$PLUGIN_DIR/scripts/session-init.sh"

group "SessionStart — Empty Project"

dir=$(fixture_empty)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)
data=$(echo "$result" | cut -f3)
pipe=$(echo "$result" | cut -f4)
output=$(echo "$result" | cut -f5-)

[ "$ptype" = "unknown" ] && pass "empty → type=unknown" || must_fix "empty → type=unknown" "got $ptype"
[ "$lang" = "none" ] && pass "empty → lang=none" || must_fix "empty → lang=none" "got $lang"
[ "$data" = "false" ] && pass "empty → data=false" || must_fix "empty → data=false" "got $data"
[ "$pipe" = "false" ] && pass "empty → pipeline=false" || must_fix "empty → pipeline=false" "got $pipe"
[ -z "$output" ] && pass "empty → no output" || should_fix "empty → no output" "got: $output"

group "SessionStart — Python Econometrics"

dir=$(fixture_python_econometrics)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)

[ "$ptype" = "empirical" ] && pass "python → type=empirical" || must_fix "python → type=empirical" "got $ptype"
[ "$lang" = "python" ] && pass "python → lang=python" || must_fix "python → lang=python" "got $lang"

group "SessionStart — R Project"

dir=$(fixture_r_project)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)

[ "$ptype" = "empirical" ] && pass "R → type=empirical" || must_fix "R → type=empirical" "got $ptype"
[ "$lang" = "R" ] && pass "R → lang=R" || must_fix "R → lang=R" "got $lang"

group "SessionStart — Stata Project"

dir=$(fixture_stata)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)

[ "$ptype" = "empirical" ] && pass "stata → type=empirical" || must_fix "stata → type=empirical" "got $ptype"
[ "$lang" = "stata" ] && pass "stata → lang=stata" || must_fix "stata → lang=stata" "got $lang"

group "SessionStart — Julia Project"

dir=$(fixture_julia)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)

[ "$ptype" = "empirical" ] && pass "julia → type=empirical" || must_fix "julia → type=empirical" "got $ptype"
[ "$lang" = "julia" ] && pass "julia → lang=julia" || must_fix "julia → lang=julia" "got $lang"

group "SessionStart — LaTeX Paper Only"

dir=$(fixture_latex_paper)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)

[ "$ptype" = "paper" ] && pass "latex → type=paper" || must_fix "latex → type=paper" "got $ptype"

group "SessionStart — Empirical Paper"

dir=$(fixture_empirical_paper)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)

[ "$ptype" = "empirical-paper" ] && pass "empirical-paper → type=empirical-paper" || must_fix "empirical-paper → type=empirical-paper" "got $ptype"
[ "$lang" = "python" ] && pass "empirical-paper → lang=python" || must_fix "empirical-paper → lang=python" "got $lang"

group "SessionStart — Data & Pipeline Detection"

dir=$(fixture_with_data)
result=$(run_session_init "$dir" "$SCRIPT")
data=$(echo "$result" | cut -f3)
[ "$data" = "true" ] && pass "data dir → data=true" || must_fix "data dir → data=true" "got $data"

dir=$(fixture_with_pipeline)
result=$(run_session_init "$dir" "$SCRIPT")
pipe=$(echo "$result" | cut -f4)
[ "$pipe" = "true" ] && pass "Makefile → pipeline=true" || must_fix "Makefile → pipeline=true" "got $pipe"

group "SessionStart — Full Project"

dir=$(fixture_full_project)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
data=$(echo "$result" | cut -f3)
pipe=$(echo "$result" | cut -f4)
output=$(echo "$result" | cut -f5-)

[ "$ptype" = "empirical-paper" ] && pass "full → type=empirical-paper" || must_fix "full → type=empirical-paper" "got $ptype"
[ "$data" = "true" ] && pass "full → data=true" || must_fix "full → data=true" "got $data"
[ "$pipe" = "true" ] && pass "full → pipeline=true" || must_fix "full → pipeline=true" "got $pipe"
echo "$output" | grep -q '/estimate' && pass "full → suggests /estimate" || must_fix "full → suggests /estimate" "missing from output"
echo "$output" | grep -q 'pipeline-validator' && pass "full → suggests pipeline-validator" || must_fix "full → suggests pipeline-validator" "missing from output"

group "SessionStart — Local Config Detection"

dir=$(fixture_with_local_config)
result=$(run_session_init "$dir" "$SCRIPT")
output=$(echo "$result" | cut -f5-)
echo "$output" | grep -q 'Settings loaded' && pass "local config → detected" || must_fix "local config → detected" "output: $output"

# Cleanup
cleanup_fixtures
