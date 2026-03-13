#!/usr/bin/env bash
# Test Group 14: Skill description trigger matching (20 tests)
#
# Verifies that each skill's description contains keywords that align with
# the UserPromptSubmit categories and common user prompts. This ensures
# Claude Code can auto-match skills to user intent via description matching.

source "$(dirname "$0")/../lib/assert.sh"

SKILLS_DIR="$PLUGIN_DIR/skills"

# Helper: extract the description field from a SKILL.md's YAML frontmatter.
# Handles both single-line and >- multi-line descriptions.
skill_desc() {
  local skill="$1"
  python3 -c "
import re, sys
with open('$SKILLS_DIR/$skill/SKILL.md') as f:
    text = f.read()
# Multi-line >- description
m = re.search(r'description:\s*>-\s*\n(.*?)(?:\n---|\n[a-z])', text, re.DOTALL)
if m:
    print(m.group(1))
    sys.exit(0)
# Single-line description
m = re.search(r'description:\s*(.*)', text)
if m:
    print(m.group(1))
" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════
# Section A: Each skill description contains domain keywords
# that match common user prompts for that skill's domain
# ═══════════════════════════════════════════════════════════

group "Skill Description Keywords"

# 1: causal-inference — IV, DiD, RDD, or matching
desc=$(skill_desc "causal-inference")
echo "$desc" | grep -qiE 'IV|2SLS|DiD|RDD|synthetic control|matching' \
  && pass "causal-inference: domain keywords" \
  || must_fix "causal-inference" "missing IV/DiD/RDD/matching in description"

# 2: causal-ml — DML, causal forest, or GRF
desc=$(skill_desc "causal-ml")
echo "$desc" | grep -qiE 'double machine learning|causal forest|GRF|DR-Learner' \
  && pass "causal-ml: domain keywords" \
  || must_fix "causal-ml" "missing DML/causal forest keywords"

# 3: structural-modeling — BLP, NFXP, MPEC, or structural
desc=$(skill_desc "structural-modeling")
echo "$desc" | grep -qiE 'BLP|NFXP|MPEC|structural model|dynamic discrete choice' \
  && pass "structural-modeling: domain keywords" \
  || must_fix "structural-modeling" "missing BLP/NFXP/structural keywords"

# 4: game-theory — Nash, equilibrium, entry, or auction
desc=$(skill_desc "game-theory")
echo "$desc" | grep -qiE 'Nash|equilibrium|entry|auction|strategic' \
  && pass "game-theory: domain keywords" \
  || must_fix "game-theory" "missing Nash/equilibrium keywords"

# 5: bayesian-estimation — MCMC, Stan, PyMC, or posterior
desc=$(skill_desc "bayesian-estimation")
echo "$desc" | grep -qiE 'MCMC|Stan|PyMC|posterior|prior|Bayesian' \
  && pass "bayesian-estimation: domain keywords" \
  || must_fix "bayesian-estimation" "missing MCMC/Bayesian keywords"

# 6: identification-proofs — identification, rank condition, or regularity
desc=$(skill_desc "identification-proofs")
echo "$desc" | grep -qiE 'identification|rank condition|regularity|identified' \
  && pass "identification-proofs: domain keywords" \
  || must_fix "identification-proofs" "missing identification keywords"

# 7: empirical-playbook — method, empirical, diagnostics, or power
desc=$(skill_desc "empirical-playbook")
echo "$desc" | grep -qiE 'method|empirical|diagnostics|power|estimator' \
  && pass "empirical-playbook: domain keywords" \
  || must_fix "empirical-playbook" "missing empirical method keywords"

# 8: reproducible-pipelines — Makefile, Snakemake, DVC, or replication
desc=$(skill_desc "reproducible-pipelines")
echo "$desc" | grep -qiE 'Makefile|Snakemake|DVC|replication|pipeline' \
  && pass "reproducible-pipelines: domain keywords" \
  || must_fix "reproducible-pipelines" "missing pipeline keywords"

# 9: submission-guide — journal, submission, or formatting
desc=$(skill_desc "submission-guide")
echo "$desc" | grep -qiE 'journal|submission|formatting|referee' \
  && pass "submission-guide: domain keywords" \
  || must_fix "submission-guide" "missing journal/submission keywords"

# 10: referee-response — referee, R&R, or response
desc=$(skill_desc "referee-response")
echo "$desc" | grep -qiE 'referee|R&R|response|revision' \
  && pass "referee-response: domain keywords" \
  || must_fix "referee-response" "missing referee/R&R keywords"

# 11: data-acquisition — FRED, World Bank, or time series
desc=$(skill_desc "data-acquisition")
echo "$desc" | grep -qiE 'FRED|World Bank|time series|economic' \
  && pass "data-acquisition: domain keywords" \
  || must_fix "data-acquisition" "missing FRED/World Bank keywords"

# 12: compound-catalog — solution, documentation, or resolved
desc=$(skill_desc "compound-catalog")
echo "$desc" | grep -qiE 'solution|documentation|resolved|categorized' \
  && pass "compound-catalog: domain keywords" \
  || must_fix "compound-catalog" "missing solution/documentation keywords"

# 13: strategy-brainstorm — brainstorm, research, or methodological
desc=$(skill_desc "strategy-brainstorm")
echo "$desc" | grep -qiE 'brainstorm|research|methodological|estimation' \
  && pass "strategy-brainstorm: domain keywords" \
  || must_fix "strategy-brainstorm" "missing brainstorm keywords"

# 14: git-worktree — worktree, parallel, or concurrent
desc=$(skill_desc "git-worktree")
echo "$desc" | grep -qiE 'worktree|parallel|concurrent|isolated' \
  && pass "git-worktree: domain keywords" \
  || must_fix "git-worktree" "missing worktree/parallel keywords"

# 15: swarm-orchestration — multi-agent, parallel, or teammates
desc=$(skill_desc "swarm-orchestration")
echo "$desc" | grep -qiE 'multi-agent|parallel|teammate|orchestrat' \
  && pass "swarm-orchestration: domain keywords" \
  || must_fix "swarm-orchestration" "missing orchestration keywords"

# 16: project-setup — configure, setup, or local.md
desc=$(skill_desc "project-setup")
echo "$desc" | grep -qiE 'configure|setup|local.md|review agent' \
  && pass "project-setup: domain keywords" \
  || must_fix "project-setup" "missing setup/configure keywords"

# 16b: publication-output — table, figure, LaTeX, or stargazer
desc=$(skill_desc "publication-output")
echo "$desc" | grep -qiE 'table|figure|LaTeX|stargazer|publication' \
  && pass "publication-output: domain keywords" \
  || must_fix "publication-output" "missing table/figure/publication keywords"

# ═══════════════════════════════════════════════════════════
# Section B: Hook → Skill cross-references
# Verify that skills referenced by UserPromptSubmit actually exist
# ═══════════════════════════════════════════════════════════

group "Hook → Skill Cross-References"

# 17: causal-inference skill exists (referenced by UPS IDENTIFICATION)
[ -d "$SKILLS_DIR/causal-inference" ] \
  && pass "UPS → causal-inference skill exists" \
  || must_fix "UPS → causal-inference" "skill directory not found"

# 18: structural-modeling skill exists (referenced by UPS ESTIMATION/CONVERGENCE)
[ -d "$SKILLS_DIR/structural-modeling" ] \
  && pass "UPS → structural-modeling skill exists" \
  || must_fix "UPS → structural-modeling" "skill directory not found"

# 19: submission-guide skill exists (referenced by UPS SUBMISSION)
[ -d "$SKILLS_DIR/submission-guide" ] \
  && pass "UPS → submission-guide skill exists" \
  || must_fix "UPS → submission-guide" "skill directory not found"

# 20: bayesian-estimation skill exists (referenced by PTU Bayesian detection)
[ -d "$SKILLS_DIR/bayesian-estimation" ] \
  && pass "PTU → bayesian-estimation skill exists" \
  || must_fix "PTU → bayesian-estimation" "skill directory not found"
