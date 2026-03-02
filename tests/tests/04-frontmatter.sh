#!/bin/bash
# Test Group 4: YAML frontmatter validation for all markdown components (20 tests)
source "$(dirname "$0")/../lib/assert.sh"

group "Frontmatter — Agents"

# 1: All agents have frontmatter
all_fm=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! head -1 "$file" | grep -q '^---'; then
    all_fm=false
    must_fix "agent $name has frontmatter" "must start with ---"
  fi
done
if $all_fm; then pass "all agents have frontmatter"; fi

# 2: All agents have description
all_desc=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q '^description:' "$file"; then
    all_desc=false
    must_fix "agent $name has description" "YAML needs description field"
  fi
done
if $all_desc; then pass "all agents have description"; fi

# 3: All agents have model: sonnet
all_model=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q '^model: sonnet' "$file"; then
    all_model=false
    must_fix "agent $name has model: sonnet" "missing or wrong model"
  fi
done
if $all_model; then pass "all agents have model: sonnet"; fi

# 4: All agents have tools listed
all_tools=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q '^tools:' "$file"; then
    all_tools=false
    must_fix "agent $name has tools" "missing tools field"
  fi
done
if $all_tools; then pass "all agents have tools listed"; fi

group "Frontmatter — Commands"

# 5: All commands have frontmatter
all_fm=true
for file in "$PLUGIN_DIR"/commands/*.md "$PLUGIN_DIR"/commands/workflows/*.md; do
  name=$(basename "$file" .md)
  if ! head -1 "$file" | grep -q '^---'; then
    all_fm=false
    must_fix "command $name has frontmatter" "must start with ---"
  fi
done
if $all_fm; then pass "all commands have frontmatter"; fi

# 6: All commands have description
all_desc=true
for file in "$PLUGIN_DIR"/commands/*.md "$PLUGIN_DIR"/commands/workflows/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q '^description:' "$file"; then
    all_desc=false
    must_fix "command $name has description" "YAML needs description field"
  fi
done
if $all_desc; then pass "all commands have description"; fi

# 7: Domain and utility commands have argument-hint
all_hints=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ] && ! grep -q '^argument-hint:' "$file"; then
    all_hints=false
    must_fix "command $cmd has argument-hint" "domain/utility commands need argument-hint"
  fi
done
if $all_hints; then pass "all domain/utility commands have argument-hint"; fi

group "Frontmatter — Chain Commands"

# 8-9
for chain in lfg slfg; do
  file="$PLUGIN_DIR/commands/$chain.md"
  if grep -q 'disable-model-invocation: true' "$file"; then
    pass "$chain has disable-model-invocation: true"
  else
    must_fix "$chain has disable-model-invocation: true" "chain commands must not invoke model directly"
  fi
done

group "Frontmatter — Skills"

# 10: All skills have frontmatter
all_fm=true
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  if [ -f "$file" ] && ! head -1 "$file" | grep -q '^---'; then
    all_fm=false
    must_fix "skill $name has frontmatter" "must start with ---"
  fi
done
if $all_fm; then pass "all skills have frontmatter"; fi

# 11: All skills have description with trigger keywords
all_desc=true
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  if [ -f "$file" ] && ! grep -q '^description:' "$file"; then
    all_desc=false
    must_fix "skill $name has description" "YAML needs description with triggers"
  fi
done
if $all_desc; then pass "all skills have description"; fi

group "Frontmatter — Name Consistency"

# 12: Agent name field matches filename
all_match=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  filename=$(basename "$file" .md)
  name_field=$(grep '^name:' "$file" | head -1 | sed 's/^name: *//')
  if [ "$filename" != "$name_field" ]; then
    all_match=false
    must_fix "agent name matches filename: $filename" "name field says '$name_field'"
  fi
done
if $all_match; then pass "all agent names match filenames"; fi

# 13: Command name field matches filename (or workflows: prefix)
all_match=true
for file in "$PLUGIN_DIR"/commands/*.md; do
  filename=$(basename "$file" .md)
  name_field=$(grep '^name:' "$file" | head -1 | sed 's/^name: *//')
  if [ "$filename" != "$name_field" ]; then
    all_match=false
    must_fix "command name matches filename: $filename" "name field says '$name_field'"
  fi
done
if $all_match; then pass "all root command names match filenames"; fi

# 14: Workflow command names have workflows: prefix
all_prefix=true
for file in "$PLUGIN_DIR"/commands/workflows/*.md; do
  name_field=$(grep '^name:' "$file" | head -1 | sed 's/^name: *//')
  if ! echo "$name_field" | grep -q '^workflows:'; then
    all_prefix=false
    must_fix "workflow $(basename $file .md) has workflows: prefix" "got: $name_field"
  fi
done
if $all_prefix; then pass "all workflow commands have workflows: prefix"; fi

group "Frontmatter — Content Depth"

# 15: Domain/utility commands have Pipeline mode statement
all_pipeline=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  if [ -f "$file" ] && ! grep -q 'Pipeline mode' "$file"; then
    all_pipeline=false
    must_fix "command $cmd has Pipeline mode statement" "missing pipeline mode"
  fi
done
if $all_pipeline; then pass "all domain/utility commands have Pipeline mode"; fi

# 16: Domain/utility commands have phases (Phase/### Phase)
all_phases=true
for cmd in estimate simulate identify diagnose tabulate replicate visualize stress-test; do
  file="$PLUGIN_DIR/commands/$cmd.md"
  phase_count=$(grep -c '### Phase\|## Phase\|Phase [0-9]' "$file" 2>/dev/null) || phase_count=0
  if [ "$phase_count" -lt 3 ]; then
    all_phases=false
    must_fix "command $cmd has >=3 phases" "found $phase_count"
  fi
done
if $all_phases; then pass "all domain/utility commands have >=3 phases"; fi

# 17: All agents have examples section
all_examples=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q '<examples>' "$file"; then
    all_examples=false
    must_fix "agent $name has examples section" "missing <examples> block"
  fi
done
if $all_examples; then pass "all agents have examples section"; fi

# 18: New skills have sufficient depth (>100 lines)
for skill in submission-guide empirical-playbook; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -ge 100 ]; then
      pass "skill $skill has depth ($lines lines)"
    else
      must_fix "skill $skill has depth" "only $lines lines, need >=100"
    fi
  fi
done

# 20: All skills have name field matching directory
all_match=true
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  if [ -f "$file" ]; then
    name_field=$(grep '^name:' "$file" | head -1 | sed 's/^name: *//')
    if [ "$name" != "$name_field" ]; then
      all_match=false
      must_fix "skill name matches dir: $name" "name field says '$name_field'"
    fi
  fi
done
if $all_match; then pass "all skill names match directory names"; fi
