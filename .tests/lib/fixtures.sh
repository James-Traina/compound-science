#!/usr/bin/env bash
# Shared test fixtures and constants

set -euo pipefail

# Canonical skill list — shared by test files to prevent drift when skills are added
# v0.8: 10 domain knowledge + 6 workflow + 2 chain + 2 wrapper = 20 total
# 7 skills merged in v0.8: strategy-brainstorm→workflows-brainstorm, swarm-orchestration→slfg,
#   compound-catalog→workflows-compound, referee-response→submission-guide,
#   project-setup→workflows-review, git-worktree→workflows-work, data-acquisition→empirical-playbook
SKILLS=(
  # --- Domain knowledge skills (10) ---
  "causal-inference"
  "causal-ml"
  "game-theory"
  "identification-proofs"
  "bayesian-estimation"
  "reproducible-pipelines"
  "structural-modeling"
  "submission-guide"
  "empirical-playbook"
  "publication-output"
  # --- Workflow skills (6) ---
  "workflows-ideate"
  "workflows-brainstorm"
  "workflows-plan"
  "workflows-work"
  "workflows-review"
  "workflows-compound"
  # --- Chain skills (2) ---
  "lfg"
  "slfg"
  # --- Wrapper skills (2) ---
  "estimate"
  "replicate"
)

# --- Skill subsets for targeted testing ---

# Workflow skills — full depth, phases, Pipeline mode
WORKFLOW_SKILLS=("workflows-ideate" "workflows-brainstorm" "workflows-plan" "workflows-work" "workflows-review" "workflows-compound")

# Chain skills — must have disable-model-invocation: true
CHAIN_SKILLS=("lfg" "slfg")

# Wrapper skills — short redirects
WRAPPER_SKILLS=("estimate" "replicate")

# Original domain knowledge skills (10) — full depth/quality checks apply
ORIGINAL_SKILLS=(
  "causal-inference" "causal-ml" "game-theory"
  "identification-proofs" "bayesian-estimation" "reproducible-pipelines"
  "structural-modeling" "submission-guide" "empirical-playbook"
  "publication-output"
)
