#!/bin/bash
# Test Group 4: YAML frontmatter validation for all markdown components
source "$(dirname "$0")/../lib/assert.sh"

group "Frontmatter — Agents"

for file in "$PLUGIN_DIR"/agents/*/*.md; do
  name=$(basename "$file" .md)
  if head -1 "$file" | grep -q '^---'; then
    pass "agent $name has frontmatter"
  else
    must_fix "agent $name has frontmatter" "must start with ---"
  fi

  if grep -q '^description:' "$file"; then
    pass "agent $name has description"
  else
    must_fix "agent $name has description" "YAML frontmatter needs description field"
  fi
done

group "Frontmatter — Commands"

for file in "$PLUGIN_DIR"/commands/*.md "$PLUGIN_DIR"/commands/workflows/*.md; do
  name=$(basename "$file" .md)
  if head -1 "$file" | grep -q '^---'; then
    pass "command $name has frontmatter"
  else
    must_fix "command $name has frontmatter" "must start with ---"
  fi

  if grep -q '^description:' "$file"; then
    pass "command $name has description"
  else
    must_fix "command $name has description" "YAML frontmatter needs description field"
  fi
done

group "Frontmatter — Chain Commands"

for chain in lfg slfg; do
  file="$PLUGIN_DIR/commands/$chain.md"
  if grep -q 'disable-model-invocation: true' "$file"; then
    pass "$chain has disable-model-invocation: true"
  else
    must_fix "$chain has disable-model-invocation: true" "chain commands must not invoke model directly"
  fi
done

group "Frontmatter — Skills"

for dir in "$PLUGIN_DIR"/skills/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  if [ -f "$file" ] && head -1 "$file" | grep -q '^---'; then
    pass "skill $name has frontmatter"
  elif [ -f "$file" ]; then
    # Skills may not require frontmatter — check if it has meaningful content
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -gt 20 ]; then
      pass "skill $name has content ($lines lines, no frontmatter)"
    else
      should_fix "skill $name has frontmatter" "only $lines lines and no frontmatter"
    fi
  fi
done
