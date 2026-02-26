#!/bin/bash
# Test Group 8: All 20 domain keywords present in documentation
source "$(dirname "$0")/../lib/assert.sh"

# The 20 canonical domain keywords
KEYWORDS=(
  "Academic Writing"
  "Applied Statistics"
  "Business Analytics"
  "Causal Inference"
  "Data Engineering"
  "Data Science"
  "Economic Research"
  "Empirical Methods"
  "Empirical Microdata"
  "Empirical Reasoning"
  "Equilibrium Reasoning"
  "Game Theory"
  "Identification Arguments"
  "Identification Proofs"
  "Mathematical Equilibrium"
  "Mathematical Modeling"
  "Reproducible Pipelines"
  "Structural Econometrics"
  "Structural Estimation"
  "Structural Modeling"
)

group "Keyword Coverage — CLAUDE.md"

for kw in "${KEYWORDS[@]}"; do
  if grep -qi "$kw" "$PLUGIN_DIR/CLAUDE.md"; then
    pass "CLAUDE.md: $kw"
  else
    must_fix "CLAUDE.md: $kw" "keyword missing"
  fi
done

group "Keyword Coverage — README.md"

for kw in "${KEYWORDS[@]}"; do
  if grep -qi "$kw" "$PLUGIN_DIR/README.md"; then
    pass "README.md: $kw"
  else
    must_fix "README.md: $kw" "keyword missing"
  fi
done

group "Keyword Coverage — plugin.json"

# plugin.json keywords (compact form)
pj_keywords=$(python3 -c "
import json
d = json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))
print(' '.join(d.get('keywords', [])))
" 2>/dev/null || echo "")

# plugin.json should have at least 8 keywords
kw_count=$(echo "$pj_keywords" | wc -w | tr -d ' ')
if [ "$kw_count" -ge 8 ]; then
  pass "plugin.json has $kw_count keywords (≥8)"
else
  should_fix "plugin.json has $kw_count keywords (≥8)" "consider adding more"
fi
