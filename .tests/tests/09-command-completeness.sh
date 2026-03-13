#!/usr/bin/env bash
# Test Group 9: Command structure, completeness, and integration (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

group "Command Categories"

# 1: Workflow commands exist in subdirectory
workflow_count=$(find "$PLUGIN_DIR/commands/workflows" -name "*.md" | wc -l | tr -d ' ')
assert_count "workflow commands = 5" 5 "$workflow_count"

# 2: Root-level commands (domain + utility + chain)
root_count=$(find "$PLUGIN_DIR/commands" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
assert_count "root-level commands = 11" 11 "$root_count"

# 3: Total commands
total_count=$(find "$PLUGIN_DIR/commands" -name "*.md" | wc -l | tr -d ' ')
assert_count "total commands = 16" 16 "$total_count"

group "New Utility Commands Exist"

# 4-8: Each command exists (stubs/wrappers are allowed to be short; only full commands need depth)
# v0.5: 7 deprecated stubs + 2 thin wrappers are excluded from depth checks
STUB_COMMANDS="simulate identify diagnose tabulate visualize stress-test deepen-plan"
WRAPPER_COMMANDS="estimate replicate"
for cmd in diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    case "$STUB_COMMANDS" in
      *"$cmd"*)
        # Stub: just verify it exists and is short
        if [ "$lines" -le 20 ]; then
          pass "command $cmd exists as deprecated stub ($lines lines)"
        else
          should_fix "command $cmd is a stub" "$lines lines — expected <=20 for a stub"
        fi
        ;;
      *)
        case "$WRAPPER_COMMANDS" in
          *"$cmd"*)
            # Wrapper: verify it exists and is thin
            if [ "$lines" -le 30 ]; then
              pass "command $cmd exists as thin wrapper ($lines lines)"
            else
              should_fix "command $cmd is a wrapper" "$lines lines — expected <=30 for a wrapper"
            fi
            ;;
          *)
            # Full command: check for depth
            if [ "$lines" -ge 100 ]; then
              pass "command $cmd exists ($lines lines)"
            else
              must_fix "command $cmd has depth" "only $lines lines"
            fi
            ;;
        esac
        ;;
    esac
  else
    must_fix "command $cmd exists" "file not found"
  fi
done

group "Command Structure"

# 9: Full commands have Input Document section (stubs/wrappers excluded)
WRAPPER_COMMANDS="estimate replicate"
all_input=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  case "$STUB_COMMANDS $WRAPPER_COMMANDS" in *"$cmd"*) continue ;; esac
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ] && ! grep -qi 'Input Document\|input\|If no input' "$file"; then
    all_input=false
    must_fix "command $cmd has input handling" "missing input section"
  fi
done
if $all_input; then pass "all full commands handle input (stubs/wrappers excluded)"; fi

# 10: Full commands have multiple phases (stubs/wrappers excluded)
all_phases=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  case "$STUB_COMMANDS $WRAPPER_COMMANDS" in *"$cmd"*) continue ;; esac
  file="$PLUGIN_DIR/commands/$cmd.md"
  phase_count=$(grep -cE '### Phase|## Phase' "$file" 2>/dev/null) || phase_count=0
  if [ "$phase_count" -lt 3 ]; then
    all_phases=false
    must_fix "command $cmd has >=3 phases" "found $phase_count"
  fi
done
if $all_phases; then pass "all full commands have >=3 phases (stubs/wrappers excluded)"; fi

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

# 13: /estimate wrapper references a skill or /workflows:work
if grep -qE 'empirical-playbook|/workflows:work' "$PLUGIN_DIR/commands/estimate.md" 2>/dev/null; then
  pass "/estimate wrapper references empirical-playbook or /workflows:work"
else
  must_fix "/estimate wrapper references skill/workflow" "missing"
fi

# 14: /simulate stub references simulation-designer
if grep -q 'simulation-designer' "$PLUGIN_DIR/commands/simulate.md" 2>/dev/null; then
  pass "/simulate stub references simulation-designer"
else
  must_fix "/simulate stub references simulation-designer" "missing"
fi

# 15: /identify stub references identification-critic or identification-proofs
if grep -qE 'identification-critic|identification-proofs' "$PLUGIN_DIR/commands/identify.md" 2>/dev/null; then
  pass "/identify stub references identification component"
else
  must_fix "/identify stub references identification component" "missing"
fi

# 16: /diagnose stub references an agent or skill
if grep -qE 'econometric-reviewer|numerical-auditor|empirical-playbook' "$PLUGIN_DIR/commands/diagnose.md" 2>/dev/null; then
  pass "/diagnose stub references review component"
else
  should_fix "/diagnose stub references review component" "no agent/skill reference found"
fi

# 17: /replicate references reproducibility-auditor
if grep -qE 'reproducibility-auditor' "$PLUGIN_DIR/commands/replicate.md" 2>/dev/null; then
  pass "/replicate references workflow agents"
else
  must_fix "/replicate references workflow agents" "should reference reproducibility-auditor"
fi

# 18: /stress-test stub references an agent or skill
if grep -qE 'identification-critic|econometric-reviewer|empirical-playbook' "$PLUGIN_DIR/commands/stress-test.md" 2>/dev/null; then
  pass "/stress-test stub references review component"
else
  should_fix "/stress-test stub references review component" "no agent/skill reference found"
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
