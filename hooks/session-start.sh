#!/usr/bin/env bash
# compound-science: SessionStart hook
# Detects project type and injects relevant context into the session.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
ENV_FILE="${CLAUDE_ENV_FILE:-/dev/null}"

# --- Detect project type ---
PROJECT_TYPE="unknown"
ESTIMATION_LANG="none"
HAS_DATA=false
HAS_PIPELINE=false

# Python econometrics
for f in "$PROJECT_DIR/requirements.txt" "$PROJECT_DIR/pyproject.toml" "$PROJECT_DIR/setup.py"; do
  if [ -f "$f" ] && grep -qiE "statsmodels|linearmodels|pyblp|econtools|doubleml|causalml|dowhy|pymc|numpyro|cmdstanpy" "$f" 2>/dev/null; then
    ESTIMATION_LANG="python"
    PROJECT_TYPE="empirical"
    break
  fi
done

# R econometrics (check dependency files for econometrics packages)
for f in "$PROJECT_DIR/DESCRIPTION" "$PROJECT_DIR/renv.lock"; do
  if [ -f "$f" ] && grep -qiE "fixest|lfe|AER|plm|ivreg|did|rdrobust|Synth|estimatr|sandwich|bacondecomp|brms|rstan|rstanarm" "$f" 2>/dev/null; then
    ESTIMATION_LANG="R"
    PROJECT_TYPE="empirical"
    break
  fi
done

# Julia
if [ -f "$PROJECT_DIR/Project.toml" ]; then
  if grep -qiE "Optim|JuMP|Distributions|GLM|FixedEffectModels" "$PROJECT_DIR/Project.toml" 2>/dev/null; then
    ESTIMATION_LANG="julia"
    PROJECT_TYPE="empirical"
  fi
fi

# Stata econometrics (check .do/.ado files for estimation commands)
if compgen -G "$PROJECT_DIR/*.do" > /dev/null 2>&1 || compgen -G "$PROJECT_DIR/*.ado" > /dev/null 2>&1; then
  for f in "$PROJECT_DIR"/*.do "$PROJECT_DIR"/*.ado; do
    if [ -f "$f" ] && grep -qiE "regress|ivregress|xtreg|xtabond|areg|didregress|rdrobust|gmm|mle|nl" "$f" 2>/dev/null; then
      ESTIMATION_LANG="stata"
      PROJECT_TYPE="empirical"
      break
    fi
  done
fi

# LaTeX paper
if compgen -G "$PROJECT_DIR/*.tex" > /dev/null 2>&1; then
  if [ "$PROJECT_TYPE" = "unknown" ]; then
    PROJECT_TYPE="paper"
  else
    PROJECT_TYPE="empirical-paper"
  fi
fi

# Data files
if [ -e "$PROJECT_DIR/data" ] || compgen -G "$PROJECT_DIR/*.csv" > /dev/null 2>&1 || compgen -G "$PROJECT_DIR/*.dta" > /dev/null 2>&1; then
  HAS_DATA=true
fi

# Pipeline
if [ -f "$PROJECT_DIR/Makefile" ] || [ -f "$PROJECT_DIR/Snakefile" ] || [ -f "$PROJECT_DIR/dvc.yaml" ]; then
  HAS_PIPELINE=true
fi

# --- Persist environment ---
{
  echo "export CS_PROJECT_TYPE=$PROJECT_TYPE"
  echo "export CS_ESTIMATION_LANG=$ESTIMATION_LANG"
  echo "export CS_HAS_DATA=$HAS_DATA"
  echo "export CS_HAS_PIPELINE=$HAS_PIPELINE"
} >> "$ENV_FILE"

# --- Build context message ---
MSG=""

if [ "$PROJECT_TYPE" != "unknown" ]; then
  MSG="compound-science detected: **$PROJECT_TYPE** project"
  [ "$ESTIMATION_LANG" != "none" ] && MSG="$MSG ($ESTIMATION_LANG)"
  MSG="$MSG."
fi

# Check for compound-science local config
if [ -f "$PROJECT_DIR/.claude/compound-science.local.md" ]; then
  MSG="$MSG Settings loaded from .claude/compound-science.local.md."
elif [ -f "$PROJECT_DIR/compound-science.local.md" ]; then
  MSG="$MSG Settings loaded from compound-science.local.md."
fi

# Describe what's active based on project type
if [ "$PROJECT_TYPE" = "empirical" ] || [ "$PROJECT_TYPE" = "empirical-paper" ]; then
  MSG="$MSG Econometric review, identification, and methodology agents are active."
elif [ "$PROJECT_TYPE" = "paper" ]; then
  MSG="$MSG Identification and methodology agents are active."
fi

if [ "$HAS_PIPELINE" = true ]; then
  MSG="$MSG Pipeline reproducibility checks are active."
fi

if [ -n "$MSG" ]; then
  echo "$MSG"
fi
