#!/usr/bin/env bash
# Test Group 13: Workflow scenario trigger coverage (32 tests)
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

export HOOKS_FILE="$PLUGIN_DIR/hooks/hooks.json"

# ── Extract hook prompts into temp files (one Python call) ──

TMPD=$(mktemp -d "${TMPDIR:-/tmp}/cs-qa-wf-XXXXXX")

python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
tmp = '$TMPD'
for event in ['UserPromptSubmit', 'Stop', 'SubagentStop']:
    with open(f'{tmp}/{event}.txt', 'w') as f:
        for m in d['hooks'].get(event, []):
            for h in m['hooks']:
                if h['type'] == 'prompt':
                    f.write(h['prompt'])
"

UPS="$TMPD/UserPromptSubmit.txt"
STP="$TMPD/Stop.txt"

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
# Section C: Stop hook — all 10 completeness conditions
# ═══════════════════════════════════════════════════════════

group "Stop — Completeness Conditions"

# 26: v0.5.1: SEs moved to SubagentStop — check Stop covers sensitivity/robustness instead
grep -qiE 'sensitiv|robustness' "$STP" \
  && pass "condition 1 sensitivity/robustness check" \
  || must_fix "condition 1 sensitivity/robustness" "missing keyword"

# 27: v0.5.1: Seeds moved to SubagentStop — check Stop covers reproducible location
grep -qiE 'reproducible|saved|replication' "$STP" \
  && pass "condition 2 results reproducibility" \
  || must_fix "condition 2 results reproducibility" "missing keyword"

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
# Section E: SessionStart prompt — pipeline & Bayesian coverage
# ═══════════════════════════════════════════════════════════

# Extract SessionStart prompt for keyword checks
SS_PROMPT=$(mktemp "${TMPDIR:-/tmp}/cs-ss-prompt-XXXXXX")
python3 -c "
import json, os
d = json.load(open(os.environ['HOOKS_FILE']))
with open('$SS_PROMPT', 'w') as f:
    for m in d['hooks']['SessionStart']:
        for h in m['hooks']:
            if h['type'] == 'prompt':
                f.write(h['prompt'])
"

group "Session-Start — Pipeline & Bayesian Detection"

# 41: SessionStart prompt covers Snakefile for pipeline detection
grep -qiF 'Snakefile' "$SS_PROMPT" \
  && pass "python+snakemake → type=empirical" \
  || must_fix "python+snakemake → type=empirical" "missing Snakefile keyword"

# 42: SessionStart prompt covers pipeline classification
grep -qiE 'Pipeline|pipeline' "$SS_PROMPT" \
  && pass "python+snakemake → pipeline=true" \
  || must_fix "python+snakemake → pipeline=true" "missing pipeline classification"

# 43: SessionStart prompt covers Bayesian packages
grep -qiE 'pymc|numpyro|cmdstanpy' "$SS_PROMPT" \
  && pass "bayesian → type=empirical" \
  || must_fix "bayesian → type=empirical" "missing Bayesian package keywords"

# 44: Bayesian packages listed under Python section (not R or Julia)
grep -qiE 'Python.*pymc|Python.*numpyro|pymc.*numpyro.*cmdstanpy' "$SS_PROMPT" \
  && pass "bayesian → lang=python" \
  || must_fix "bayesian → lang=python" "Bayesian packages should be under Python section"

rm -f "$SS_PROMPT"

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

# 47: UPS SIMULATION → references numerical-auditor (v0.8: simulation-designer merged into numerical-auditor)
grep -qF 'numerical-auditor' "$UPS" \
  && pass "SIMULATION → numerical-auditor agent" \
  || must_fix "SIMULATION → numerical-auditor" "not referenced"

# 48: Stop → references a diagnostic/review component (v0.5: /diagnose removed, replaced by agents/skills)
grep -qiE 'empirical-playbook|econometric-reviewer|data-detective|diagnostic' "$STP" \
  && pass "Stop → references diagnostic component" \
  || must_fix "Stop → diagnostic component" "not referenced"

# ── Cleanup ──
rm -rf "$TMPD"
