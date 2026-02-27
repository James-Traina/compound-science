#!/bin/bash
# Test Group 5: Content quality — no web dev terms, no placeholders, no leaks
source "$(dirname "$0")/../lib/assert.sh"

EXCLUDE="--exclude-dir=test --exclude-dir=.ralph --exclude-dir=.serena --exclude-dir=.git --exclude-dir=.claude"

group "Web Dev Terms"

WEB_DEV_TERMS="Rails|React|Angular|Vue\.js|Express\.js|Node\.js|webpack|npm run|yarn |DHH|Kieran|iOS app|Android app|Ruby on Rails|ActiveRecord|middleware|REST API|GraphQL|Redux|Next\.js|Nuxt"

hits=$(grep -rn $EXCLUDE -E "$WEB_DEV_TERMS" "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$hits" ]; then
  pass "zero web dev terms"
else
  count=$(echo "$hits" | wc -l | tr -d ' ')
  must_fix "zero web dev terms" "$count hit(s) — $(echo "$hits" | head -3)"
fi

group "Placeholder Markers"

real_todos=$(grep -rn $EXCLUDE -E '^\s*(#|//|<!--)\s*(TODO|FIXME|XXX|HACK|TBD)\b' "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$real_todos" ]; then
  pass "no TODO/FIXME/XXX/HACK/TBD comments"
else
  count=$(echo "$real_todos" | wc -l | tr -d ' ')
  must_fix "no TODO/FIXME/XXX/HACK/TBD comments" "$count found"
fi

stub_content=$(grep -rn $EXCLUDE -E 'PLACEHOLDER|<insert |<your |CHANGEME|FILL_IN' "$PLUGIN_DIR" 2>/dev/null || true)
if [ -z "$stub_content" ]; then
  pass "no stub/placeholder content"
else
  count=$(echo "$stub_content" | wc -l | tr -d ' ')
  must_fix "no stub/placeholder content" "$count found"
fi

group "Hardcoded Paths"

personal_paths=$(grep -rn $EXCLUDE '/Users/jat406\|/home/jat406' "$PLUGIN_DIR" --include="*.md" --include="*.sh" --include="*.json" 2>/dev/null | grep -v 'github.com/jat406' || true)
if [ -z "$personal_paths" ]; then
  pass "no hardcoded personal paths"
else
  count=$(echo "$personal_paths" | wc -l | tr -d ' ')
  must_fix "no hardcoded personal paths" "$count found"
fi
