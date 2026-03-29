#!/usr/bin/env bash
# Test Group 4: YAML frontmatter validation for all markdown components (13 tests)
# v0.6: commands/ removed; former commands are now skills
source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/fixtures.sh"

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

# 5: Review agents have disallowedTools (read-only enforcement)
all_have=true
for file in "$PLUGIN_DIR"/agents/review/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q 'disallowedTools' "$file"; then
    all_have=false
    must_fix "agent $name has disallowedTools" "missing — review agents must be read-only"
  fi
done
if $all_have; then pass "all review agents have disallowedTools"; fi

group "Frontmatter — Skills"

# 5: All skills have frontmatter
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

# 6: All skills have description with trigger keywords
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

# 7: Workflow skills have argument-hint (stubs/wrappers/chains excluded)
all_hints=true
for skill in "${WORKFLOW_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ] && ! grep -q '^argument-hint:' "$file"; then
    all_hints=false
    must_fix "skill $skill has argument-hint" "workflow skills need argument-hint"
  fi
done
if $all_hints; then pass "all workflow skills have argument-hint (stubs/wrappers/chains excluded)"; fi

group "Frontmatter — Chain Skills"

# 8-9: Chain skills have disable-model-invocation: true
for chain in "${CHAIN_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$chain/SKILL.md"
  if [ -f "$file" ]; then
    if grep -q 'disable-model-invocation: true' "$file"; then
      pass "$chain has disable-model-invocation: true"
    else
      must_fix "$chain has disable-model-invocation: true" "chain skills must not invoke model directly"
    fi
  else
    must_fix "$chain exists" "file not found: skills/$chain/SKILL.md"
  fi
done

group "Frontmatter — Name Consistency"

# 10: Agent name field matches filename
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

# 11: All skill names match directory names
all_match=true
for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  if [ -f "$file" ]; then
    name_field=$(grep '^name:' "$file" | head -1 | sed 's/^name: *//')
    # Normalize colon to hyphen for comparison (workflows:brainstorm → workflows-brainstorm)
    name_field_normalized=$(echo "$name_field" | sed 's/:/-/g')
    if [ "$name" != "$name_field" ] && [ "$name" != "$name_field_normalized" ]; then
      all_match=false
      must_fix "skill name matches dir: $name" "name field says '$name_field'"
    fi
  fi
done
if $all_match; then pass "all skill names match directory names"; fi

# Workflow skills have allowed-tools
all_tools=true
for skill in "${WORKFLOW_SKILLS[@]}"; do
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ] && ! grep -q 'allowed-tools' "$file"; then
    all_tools=false
    should_fix "skill $skill has allowed-tools" "missing tool restrictions"
  fi
done
if $all_tools; then pass "all workflow skills have allowed-tools"; fi

group "Frontmatter — Content Depth"

# 12: Workflow skills have Pipeline mode statement (ideate excluded — divergent phase)
all_pipeline=true
for skill in "${WORKFLOW_SKILLS[@]}"; do
  [ "$skill" = "workflows-ideate" ] && continue
  file="$PLUGIN_DIR/skills/$skill/SKILL.md"
  if [ -f "$file" ] && ! grep -q 'Pipeline mode' "$file"; then
    all_pipeline=false
    must_fix "skill $skill has Pipeline mode statement" "missing pipeline mode"
  fi
done
if $all_pipeline; then pass "all workflow skills have Pipeline mode (ideate excluded)"; fi

# 13: All agents have examples section
all_examples=true
for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if ! grep -q '<examples>' "$file"; then
    all_examples=false
    must_fix "agent $name has examples section" "missing <examples> block"
  fi
done
if $all_examples; then pass "all agents have examples section"; fi
