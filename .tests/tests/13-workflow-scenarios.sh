#!/usr/bin/env bash
# Test Group 13: Workflow scenario trigger coverage (50 tests)
#
# Verifies that the hook infrastructure supports 20 common research workflows.
# Each workflow triggers multiple plugin components automatically.
#
# Workflows tested:
#  W1  IV estimation in Python           W11 Publication-ready tables
#  W2  Staggered DiD in R                W12 Journal submission (AER)
#  W3  BLP convergence failure           W13 Referee response after R&R
#  W4  Monte Carlo simulation            W14 Julia structural estimation
#  W5  Formal identification proof       W15 Diagnostic battery
#  W6  Nash equilibrium entry game       W16 RDD with bandwidth sensitivity
#  W7  Stata panel merge + FE            W17 DVC pipeline + pip install
#  W8  Snakemake pipeline                W18 Design before results
#  W9  Bayesian MCMC diagnostics         W19 Causal forest + DML
#  W10 Oster bounds sensitivity          W20 Replication package audit

source "$(dirname "$0")/../lib/assert.sh"
source "$(dirname "$0")/../lib/fixtures.sh"

export HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"
SCRIPT="$PLUGIN_DIR/hooks/session-start.sh"

# ── Extract hook prompts into temp files (one Python call) ──

TMPD=$(mktemp -d "${TMPDIR:-/tmp}/cs-qa-wf-XXXXXX")

python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
tmp = '$TMPD'
for event in ['UserPromptSubmit', 'PostToolUse', 'Stop', 'PreToolUse', 'SubagentStop']:
    with open(f'{tmp}/{event}.txt', 'w') as f:
        for m in d['hooks'].get(event, []):
            for h in m['hooks']:
                if h['type'] == 'prompt':
                    f.write(h['prompt'])
"

UPS="$TMPD/UserPromptSubmit.txt"
PTU="$TMPD/PostToolUse.txt"
STP="$TMPD/Stop.txt"
PRE="$TMPD/PreToolUse.txt"

# ═══════════════════════════════════════════════════════════
# Section A: UserPromptSubmit — all 14 categories have trigger words
# Workflows: W1-W20 depend on correct category detection
# ═══════════════════════════════════════════════════════════

group "UserPromptSubmit — Category Trigger Words"

# 1: IDENTIFICATION (W1, W5, W6, W18)
grep -qiE 'exclusion restriction|instrument|endogeneity|exogeneity' "$UPS" \
  && pass "cat 1 IDENTIFICATION: trigger words" \
  || must_fix "cat 1 IDENTIFICATION" "missing trigger words"

# 2: ESTIMATION (W1, W3, W6, W7, W9, W14, W16, W19)
grep -qiE 'estimate|MLE|maximum likelihood|standard error|bootstrap' "$UPS" \
  && pass "cat 2 ESTIMATION: trigger words" \
  || must_fix "cat 2 ESTIMATION" "missing trigger words"

# 3: SIMULATION (W4, W19)
grep -qiE 'Monte Carlo|DGP|data generating process|RMSE|bias' "$UPS" \
  && pass "cat 3 SIMULATION: trigger words" \
  || must_fix "cat 3 SIMULATION" "missing trigger words"

# 4: PROOF (W5)
grep -qiE 'theorem|lemma|proposition|regularity condition' "$UPS" \
  && pass "cat 4 PROOF: trigger words" \
  || must_fix "cat 4 PROOF" "missing trigger words"

# 5: EQUILIBRIUM (W6)
grep -qiE 'Nash|equilibrium|best response|auction|entry' "$UPS" \
  && pass "cat 5 EQUILIBRIUM: trigger words" \
  || must_fix "cat 5 EQUILIBRIUM" "missing trigger words"

# 6: PIPELINE (W8, W17)
grep -qiE 'Makefile|snakemake|DVC|replication package|pipeline' "$UPS" \
  && pass "cat 6 PIPELINE: trigger words" \
  || must_fix "cat 6 PIPELINE" "missing trigger words"

# 7: DATA (W7)
grep -qiE 'merge|panel|cross-section|cleaning|imputation|missing' "$UPS" \
  && pass "cat 7 DATA: trigger words" \
  || must_fix "cat 7 DATA" "missing trigger words"

# 8: DIAGNOSTICS (W15)
grep -qiE 'Hausman|RESET|heteroskedasticity|misspecification' "$UPS" \
  && pass "cat 8 DIAGNOSTICS: trigger words" \
  || must_fix "cat 8 DIAGNOSTICS" "missing trigger words"

# 9: TABLES (W11)
grep -qiE 'tabulate|stargazer|publication-ready|LaTeX table' "$UPS" \
  && pass "cat 9 TABLES: trigger words" \
  || must_fix "cat 9 TABLES" "missing trigger words"

# 10: REPLICATION (W12, W20)
grep -qiE 'replication|AEA|reproducibility|submission package' "$UPS" \
  && pass "cat 10 REPLICATION: trigger words" \
  || must_fix "cat 10 REPLICATION" "missing trigger words"

# 11: SENSITIVITY (W10, W16)
grep -qiE 'Oster|specification curve|breakdown|omitted variable' "$UPS" \
  && pass "cat 11 SENSITIVITY: trigger words" \
  || must_fix "cat 11 SENSITIVITY" "missing trigger words"

# 12: SUBMISSION (W12, W13)
grep -qiE 'journal|referee|R&R|revision|response letter' "$UPS" \
  && pass "cat 12 SUBMISSION: trigger words" \
  || must_fix "cat 12 SUBMISSION" "missing trigger words"

# 13: CONVERGENCE (W3, W9, W14)
grep -qiE 'BFGS|Nelder-Mead|tolerance|starting value|Hessian' "$UPS" \
  && pass "cat 13 CONVERGENCE: trigger words" \
  || must_fix "cat 13 CONVERGENCE" "missing trigger words"

# 14: DESIGN BEFORE RESULTS (W18)
grep -qiE 'identification design|interpreting magnitudes|confirm.*identification' "$UPS" \
  && pass "cat 14 DESIGN BEFORE RESULTS: trigger words" \
  || must_fix "cat 14 DESIGN BEFORE RESULTS" "missing trigger words"

# ═══════════════════════════════════════════════════════════
# Section B: PostToolUse — all 11 file types detected
# ═══════════════════════════════════════════════════════════

group "PostToolUse — File Type Detection"

# 15: Python estimation code (W1, W3, W6, W10, W19)
grep -qiE 'statsmodels|pyblp|scipy.optimize|linearmodels' "$PTU" \
  && pass "file type 1 Python estimation" \
  || must_fix "file type 1 Python estimation" "missing detection keywords"

# 16: R estimation code (W2, W16)
grep -qiE 'fixest|lfe|rdrobust|did|ivreg' "$PTU" \
  && pass "file type 2 R estimation" \
  || must_fix "file type 2 R estimation" "missing detection keywords"

# 17: Stata estimation code (W7)
grep -qiE 'regress|ivregress|xtreg|reghdfe' "$PTU" \
  && pass "file type 3 Stata estimation" \
  || must_fix "file type 3 Stata estimation" "missing detection keywords"

# 18: Julia estimation code (W14)
grep -qiE 'Optim|NLsolve|ForwardDiff' "$PTU" \
  && pass "file type 4 Julia estimation" \
  || must_fix "file type 4 Julia estimation" "missing detection keywords"

# 19: Simulation/Monte Carlo (W4, W19)
grep -qiE 'replication|bias|RMSE|coverage' "$PTU" \
  && pass "file type 5 simulation/MC" \
  || must_fix "file type 5 simulation/MC" "missing detection keywords"

# 20: LaTeX proof/derivation (W5)
grep -qiE 'theorem|proof|lemma' "$PTU" \
  && pass "file type 6 LaTeX proof" \
  || must_fix "file type 6 LaTeX proof" "missing detection keywords"

# 21: Data pipeline (W8, W17, W20)
grep -qiE 'Makefile|Snakefile|dvc.yaml' "$PTU" \
  && pass "file type 7 data pipeline" \
  || must_fix "file type 7 data pipeline" "missing detection keywords"

# 22: Bibliography/manuscript (W11, W12, W13)
grep -qF '\cite' "$PTU" \
  && pass "file type 8 bibliography" \
  || must_fix "file type 8 bibliography" "missing \\cite detection"

# 23: Results tables (W11)
grep -qF '\begin{table}' "$PTU" \
  && pass "file type 9 results tables" \
  || must_fix "file type 9 results tables" "missing \\begin{table} detection"

# 24: Specification/methodology (W13)
grep -qiE 'specification|methodology' "$PTU" \
  && pass "file type 10 specification/methodology" \
  || must_fix "file type 10 specification/methodology" "missing detection keywords"

# 25: Bayesian/probabilistic code (W9)
grep -qiE 'pymc|numpyro|cmdstanpy|brms|arviz' "$PTU" \
  && pass "file type 11 Bayesian code" \
  || must_fix "file type 11 Bayesian code" "missing detection keywords"

# ═══════════════════════════════════════════════════════════
# Section C: Stop hook — all 10 completeness conditions
# ═══════════════════════════════════════════════════════════

group "Stop — Completeness Conditions"

# 26: Missing SEs (W1, W3, W6, W9, W14, W16, W19)
grep -qiE 'standard error' "$STP" \
  && pass "condition 1 missing SEs" \
  || must_fix "condition 1 missing SEs" "missing keyword"

# 27: Unseeded simulation (W4, W19)
grep -qiE 'seed.*reproducibility|reproducibility.*seed' "$STP" \
  && pass "condition 2 unseeded simulation" \
  || must_fix "condition 2 unseeded simulation" "missing keyword"

# 28: Unstated regularity conditions (W5)
grep -qiE 'regularity' "$STP" \
  && pass "condition 3 unstated regularity" \
  || must_fix "condition 3 unstated regularity" "missing keyword"

# 29: Unvalidated merge (W7, W17)
grep -qiE 'merge.*duplicate|duplicate.*merge' "$STP" \
  && pass "condition 4 unvalidated merge" \
  || must_fix "condition 4 unvalidated merge" "missing keyword"

# 30: Results not saved (W8, W11, W12, W20)
grep -qiE 'reproducible location|saved' "$STP" \
  && pass "condition 5 results not saved" \
  || must_fix "condition 5 results not saved" "missing keyword"

# 31: No sensitivity analysis (W2, W16)
grep -qiE 'robustness|sensitivity' "$STP" \
  && pass "condition 6 no sensitivity" \
  || must_fix "condition 6 no sensitivity" "missing keyword"

# 32: No replication package (W11, W12, W20)
grep -qiF 'replication package' "$STP" \
  && pass "condition 7 no replication package" \
  || must_fix "condition 7 no replication package" "missing keyword"

# 33: Diagnostics not documented (W15)
grep -qiE 'diagnostic' "$STP" \
  && pass "condition 8 diagnostics undocumented" \
  || must_fix "condition 8 diagnostics undocumented" "missing keyword"

# 34: DiD without pre-trends (W2)
grep -qiE 'pre-trend|parallel trend|event-study' "$STP" \
  && pass "condition 9 DiD without pre-trends" \
  || must_fix "condition 9 DiD without pre-trends" "missing keyword"

# 35: IV without first-stage F (W1, W18)
grep -qiE 'first-stage|effective F' "$STP" \
  && pass "condition 10 IV without first-stage F" \
  || must_fix "condition 10 IV without first-stage F" "missing keyword"

# ═══════════════════════════════════════════════════════════
# Section D: PreToolUse — all 5 guards
# ═══════════════════════════════════════════════════════════

group "PreToolUse — Guard Keywords"

# 36: Missing seed guard (W1, W2, W4, W9, W14, W16, W19)
grep -qiE 'seed|random' "$PRE" \
  && pass "guard 1 missing seed" \
  || must_fix "guard 1 missing seed" "missing keyword"

# 37: Absolute paths guard (W7, W20)
grep -qiE 'absolute path|relative path|home directory' "$PRE" \
  && pass "guard 2 absolute paths" \
  || must_fix "guard 2 absolute paths" "missing keyword"

# 38: Unversioned pip guard (W17)
grep -qiE 'version.*pin|pin.*version|==version' "$PRE" \
  && pass "guard 3 unversioned pip" \
  || must_fix "guard 3 unversioned pip" "missing keyword"

# 39: No output capture guard (W4, W10, W19, W20)
grep -qiE 'redirect|--output|tee' "$PRE" \
  && pass "guard 4 no output capture" \
  || must_fix "guard 4 no output capture" "missing keyword"

# 40: Pipeline without seed guard (W8, W17)
grep -qiE 'dvc repro|snakemake' "$PRE" \
  && pass "guard 5 pipeline without seed" \
  || must_fix "guard 5 pipeline without seed" "missing keyword"

# ═══════════════════════════════════════════════════════════
# Section E: Session-Start — additional project types
# ═══════════════════════════════════════════════════════════

group "Session-Start — Pipeline & Bayesian Detection"

# 41-42: Python + Snakemake → empirical + pipeline
dir=$(fixture_python_pipeline)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
pipe=$(echo "$result" | cut -f4)
[ "$ptype" = "empirical" ] && pass "python+snakemake → type=empirical" || must_fix "python+snakemake → type=empirical" "got $ptype"
[ "$pipe" = "true" ] && pass "python+snakemake → pipeline=true" || must_fix "python+snakemake → pipeline=true" "got $pipe"

# 43-44: Bayesian project → empirical (python)
dir=$(fixture_bayesian_project)
result=$(run_session_init "$dir" "$SCRIPT")
ptype=$(echo "$result" | cut -f1)
lang=$(echo "$result" | cut -f2)
[ "$ptype" = "empirical" ] && pass "bayesian → type=empirical" || must_fix "bayesian → type=empirical" "got $ptype"
[ "$lang" = "python" ] && pass "bayesian → lang=python" || must_fix "bayesian → lang=python" "got $lang"

# ═══════════════════════════════════════════════════════════
# Section F: Workflow cross-references (hooks → components)
# ═══════════════════════════════════════════════════════════

group "Workflow Cross-References"

# 45: UPS IDENTIFICATION → references identification-critic
grep -qF 'identification-critic' "$UPS" \
  && pass "IDENTIFICATION → identification-critic agent" \
  || must_fix "IDENTIFICATION → identification-critic" "not referenced"

# 46: UPS ESTIMATION → references econometric-reviewer
grep -qF 'econometric-reviewer' "$UPS" \
  && pass "ESTIMATION → econometric-reviewer agent" \
  || must_fix "ESTIMATION → econometric-reviewer" "not referenced"

# 47: UPS SIMULATION → references simulation-designer
grep -qF 'simulation-designer' "$UPS" \
  && pass "SIMULATION → simulation-designer agent" \
  || must_fix "SIMULATION → simulation-designer" "not referenced"

# 48: PTU Bayesian → references numerical-auditor
grep -qF 'numerical-auditor' "$PTU" \
  && pass "PTU Bayesian → numerical-auditor agent" \
  || must_fix "PTU Bayesian → numerical-auditor" "not referenced"

# 49: PTU Bayesian → references calibration-assessor
grep -qF 'calibration-assessor' "$PTU" \
  && pass "PTU Bayesian → calibration-assessor agent" \
  || must_fix "PTU Bayesian → calibration-assessor" "not referenced"

# 50: Stop → references /diagnose
grep -qF '/diagnose' "$STP" \
  && pass "Stop → references /diagnose command" \
  || must_fix "Stop → /diagnose" "not referenced"

# ── Cleanup ──
rm -rf "$TMPD"
cleanup_fixtures
