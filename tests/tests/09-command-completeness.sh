#!/bin/bash
# Test Group 9: Command structure, completeness, and integration (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

group "Command Categories"

# 1: Workflow commands exist in subdirectory
workflow_count=$(find "$PLUGIN_DIR/commands/workflows" -name "*.md" | wc -l | tr -d ' ')
assert_count "workflow commands = 5" 5 "$workflow_count"

# 2: Root-level commands (domain + utility + chain)
root_count=$(find "$PLUGIN_DIR/commands" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
assert_count "root-level commands = 10" 10 "$root_count"

# 3: Total commands
total_count=$(find "$PLUGIN_DIR/commands" -name "*.md" | wc -l | tr -d ' ')
assert_count "total commands = 15" 15 "$total_count"

group "New Utility Commands Exist"

# 4-8: Each new command exists and has content
for cmd in diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -ge 100 ]; then
      pass "command $cmd exists ($lines lines)"
    else
      must_fix "command $cmd has depth" "only $lines lines"
    fi
  else
    must_fix "command $cmd exists" "file not found"
  fi
done

group "Command Structure"

# 9: All domain/utility commands have Input Document section
all_input=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ] && ! grep -qi 'Input Document\|input\|If no input' "$file"; then
    all_input=false
    must_fix "command $cmd has input handling" "missing input section"
  fi
done
if $all_input; then pass "all domain/utility commands handle input"; fi

# 10: All domain/utility commands have multiple phases
all_phases=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  phase_count=$(grep -cE '### Phase|## Phase' "$file" 2>/dev/null) || phase_count=0
  if [ "$phase_count" -lt 3 ]; then
    all_phases=false
    must_fix "command $cmd has >=3 phases" "found $phase_count"
  fi
done
if $all_phases; then pass "all domain/utility commands have >=3 phases"; fi

# 11: Chain commands are minimal (delegate only)
for chain in lfg slfg; do
  file="$PLUGIN_DIR/commands/$chain.md"
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -lt 50 ]; then
    pass "chain $chain is minimal ($lines lines)"
  else
    should_fix "chain $chain is minimal" "$lines lines seems too long for a delegator"
  fi
done

group "Command Agent References"

# 13: /estimate references econometric-reviewer
if grep -q 'econometric-reviewer' "$PLUGIN_DIR/commands/estimate.md" 2>/dev/null; then
  pass "/estimate references econometric-reviewer"
else
  must_fix "/estimate references econometric-reviewer" "missing"
fi

# 14: /simulate references simulation-designer
if grep -q 'simulation-designer' "$PLUGIN_DIR/commands/simulate.md" 2>/dev/null; then
  pass "/simulate references simulation-designer"
else
  must_fix "/simulate references simulation-designer" "missing"
fi

# 15: /identify references identification-critic
if grep -q 'identification-critic' "$PLUGIN_DIR/commands/identify.md" 2>/dev/null; then
  pass "/identify references identification-critic"
else
  must_fix "/identify references identification-critic" "missing"
fi

# 16: /diagnose references econometric-reviewer or numerical-auditor
if grep -qE 'econometric-reviewer|numerical-auditor' "$PLUGIN_DIR/commands/diagnose.md" 2>/dev/null; then
  pass "/diagnose references review agents"
else
  must_fix "/diagnose references review agents" "should reference econometric-reviewer or numerical-auditor"
fi

# 17: /replicate references pipeline-validator or reproducibility-checker
if grep -qE 'pipeline-validator|reproducibility-checker' "$PLUGIN_DIR/commands/replicate.md" 2>/dev/null; then
  pass "/replicate references workflow agents"
else
  must_fix "/replicate references workflow agents" "should reference pipeline-validator or reproducibility-checker"
fi

# 18: /stress-test references identification-critic
if grep -qE 'identification-critic|econometric-reviewer' "$PLUGIN_DIR/commands/stress-test.md" 2>/dev/null; then
  pass "/stress-test references review agents"
else
  must_fix "/stress-test references review agents" "should reference identification-critic or econometric-reviewer"
fi

group "Command Naming"

# 19: All command filenames use kebab-case or single word
all_valid=true
for file in "$PLUGIN_DIR"/commands/*.md "$PLUGIN_DIR"/commands/workflows/*.md; do
  name=$(basename "$file" .md)
  if ! echo "$name" | grep -qE '^[a-z]+(-[a-z]+)*$'; then
    all_valid=false
    must_fix "command $name uses valid naming" "invalid name format"
  fi
done
if $all_valid; then pass "all command filenames use valid naming"; fi

# 20: Workflow commands reference other commands or agents
workflow_refs=true
for file in "$PLUGIN_DIR"/commands/workflows/*.md; do
  name=$(basename "$file" .md)
  if ! grep -qE '/workflows:|`[a-z]+-[a-z-]+`|Task tool|Agent tool' "$file"; then
    workflow_refs=false
    should_fix "workflow $name references commands/agents" "no references found"
  fi
done
if $workflow_refs; then pass "all workflow commands reference other components"; fi
