#!/usr/bin/env bash
# Test Group 7: SessionStart prompt content validation (20 tests)
#
# Since SessionStart is a prompt-based hook (not a shell script), these tests
# validate that the prompt contains all necessary detection keywords for
# languages, project types, data signals, and output formatting.
source "$(dirname "$0")/../lib/assert.sh"

export HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

# Extract SessionStart prompt into a temp file
PROMPT_FILE=$(mktemp "${TMPDIR:-/tmp}/cs-session-prompt-XXXXXX")
python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
with open('$PROMPT_FILE', 'w') as f:
    for m in d['hooks']['SessionStart']:
        for h in m['hooks']:
            if h['type'] == 'prompt':
                f.write(h['prompt'])
"

group "SessionStart — Language Detection Keywords"

# 1: Python econometrics packages
grep -qiE 'statsmodels|linearmodels|pyblp' "$PROMPT_FILE" \
  && pass "python econometrics keywords present" \
  || must_fix "python econometrics keywords present" "missing statsmodels/linearmodels/pyblp"

# 2: R econometrics packages
grep -qiE 'fixest|lfe|AER|rdrobust' "$PROMPT_FILE" \
  && pass "R econometrics keywords present" \
  || must_fix "R econometrics keywords present" "missing fixest/lfe/AER"

# 3: Stata detection
grep -qiE 'stata|\.do|\.ado|regress|ivregress' "$PROMPT_FILE" \
  && pass "Stata detection keywords present" \
  || must_fix "Stata detection keywords present" "missing Stata references"

# 4: Julia detection
grep -qiE 'Julia|Project\.toml|Optim|JuMP' "$PROMPT_FILE" \
  && pass "Julia detection keywords present" \
  || must_fix "Julia detection keywords present" "missing Julia references"

group "SessionStart — Project Type Classification"

# 5: Empirical project type
grep -qiF 'empirical' "$PROMPT_FILE" \
  && pass "empirical project type defined" \
  || must_fix "empirical project type defined" "missing"

# 6: Paper project type
grep -qiF 'paper' "$PROMPT_FILE" \
  && pass "paper project type defined" \
  || must_fix "paper project type defined" "missing"

# 7: Empirical-paper combined type
grep -qiF 'empirical-paper' "$PROMPT_FILE" \
  && pass "empirical-paper project type defined" \
  || must_fix "empirical-paper project type defined" "missing"

# 8: Prompt explains classification logic
grep -qiE 'classify|Classify as' "$PROMPT_FILE" \
  && pass "classification logic explained" \
  || must_fix "classification logic explained" "missing classification instructions"

group "SessionStart — Data & Pipeline Detection"

# 9: Data file detection (csv/dta)
grep -qiE '\.csv|\.dta|data/' "$PROMPT_FILE" \
  && pass "data file detection keywords present" \
  || must_fix "data file detection keywords present" "missing .csv/.dta/data/"

# 10: Pipeline detection (Makefile/Snakemake/DVC)
grep -qiE 'Makefile|Snakefile|dvc\.yaml' "$PROMPT_FILE" \
  && pass "pipeline detection keywords present" \
  || must_fix "pipeline detection keywords present" "missing Makefile/Snakefile/dvc.yaml"

# 11: LaTeX detection
grep -qiE '\.tex|LaTeX' "$PROMPT_FILE" \
  && pass "LaTeX detection keywords present" \
  || must_fix "LaTeX detection keywords present" "missing .tex/LaTeX"

# 12: Pipeline active message
grep -qiE 'Pipeline|reproducibility' "$PROMPT_FILE" \
  && pass "pipeline active message defined" \
  || must_fix "pipeline active message defined" "missing pipeline message"

group "SessionStart — Output Formatting"

# 13: Returns systemMessage
grep -qiF 'systemMessage' "$PROMPT_FILE" \
  && pass "prompt instructs systemMessage return" \
  || must_fix "prompt instructs systemMessage return" "missing systemMessage instruction"

# 14: Mentions agents being active
grep -qiE 'agents are active|agents active' "$PROMPT_FILE" \
  && pass "prompt references active agents" \
  || must_fix "prompt references active agents" "missing"

# 15: Self-detection guard (don't detect plugin repo itself)
grep -qiE 'plugin repository|do not self-detect|compound-science plugin' "$PROMPT_FILE" \
  && pass "self-detection guard present" \
  || must_fix "self-detection guard present" "should skip plugin repo itself"

# 16: Return nothing when no signals
grep -qiE 'return nothing|If none detected' "$PROMPT_FILE" \
  && pass "no-signal fallback defined" \
  || must_fix "no-signal fallback defined" "missing fallback behavior"

group "SessionStart — Bayesian & Additional Detection"

# 17: Bayesian/probabilistic package detection
grep -qiE 'pymc|numpyro|cmdstanpy|brms|rstan' "$PROMPT_FILE" \
  && pass "Bayesian package keywords present" \
  || must_fix "Bayesian package keywords present" "missing pymc/numpyro/cmdstanpy"

# 18: R package detection
grep -qiE 'renv\.lock|DESCRIPTION' "$PROMPT_FILE" \
  && pass "R project file detection present" \
  || must_fix "R project file detection present" "missing renv.lock/DESCRIPTION"

# 19: Prompt has a model specified
py_eval "SessionStart has model specified" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['SessionStart']:
    for h in m['hooks']:
        assert 'model' in h, 'SessionStart hook missing model field'
" "missing model"

# 20: Prompt has a timeout specified
py_eval "SessionStart has timeout specified" "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
for m in d['hooks']['SessionStart']:
    for h in m['hooks']:
        assert h.get('timeout', 0) > 0, 'SessionStart hook missing timeout'
" "missing timeout"

# Cleanup
rm -f "$PROMPT_FILE"
