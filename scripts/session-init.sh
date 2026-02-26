#!/bin/bash
# Compound-Science: SessionStart hook
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
if [ -f "$PROJECT_DIR/requirements.txt" ] || [ -f "$PROJECT_DIR/pyproject.toml" ] || [ -f "$PROJECT_DIR/setup.py" ]; then
  for f in "$PROJECT_DIR/requirements.txt" "$PROJECT_DIR/pyproject.toml" "$PROJECT_DIR/setup.py"; do
    if [ -f "$f" ] && grep -qiE "statsmodels|linearmodels|pyblp|econtools|doubleml|causalml|dowhy|scipy" "$f" 2>/dev/null; then
      ESTIMATION_LANG="python"
      PROJECT_TYPE="empirical"
      break
    fi
  done
fi

# R econometrics
if [ -f "$PROJECT_DIR/DESCRIPTION" ] || [ -f "$PROJECT_DIR/renv.lock" ] || ls "$PROJECT_DIR"/*.Rproj 1>/dev/null 2>&1; then
  ESTIMATION_LANG="R"
  PROJECT_TYPE="empirical"
fi

# Julia
if [ -f "$PROJECT_DIR/Project.toml" ]; then
  if grep -qiE "Optim|JuMP|Distributions|GLM|FixedEffectModels" "$PROJECT_DIR/Project.toml" 2>/dev/null; then
    ESTIMATION_LANG="julia"
    PROJECT_TYPE="empirical"
  fi
fi

# Stata
if ls "$PROJECT_DIR"/*.do 1>/dev/null 2>&1 || ls "$PROJECT_DIR"/*.ado 1>/dev/null 2>&1; then
  ESTIMATION_LANG="stata"
  PROJECT_TYPE="empirical"
fi

# LaTeX paper
if ls "$PROJECT_DIR"/*.tex 1>/dev/null 2>&1; then
  if [ "$PROJECT_TYPE" = "unknown" ]; then
    PROJECT_TYPE="paper"
  else
    PROJECT_TYPE="empirical-paper"
  fi
fi

# Data files
if ls "$PROJECT_DIR"/data 1>/dev/null 2>&1 || ls "$PROJECT_DIR"/*.csv 1>/dev/null 2>&1 || ls "$PROJECT_DIR"/*.dta 1>/dev/null 2>&1; then
  HAS_DATA=true
fi

# Pipeline
if [ -f "$PROJECT_DIR/Makefile" ] || [ -f "$PROJECT_DIR/Snakefile" ] || [ -f "$PROJECT_DIR/dvc.yaml" ]; then
  HAS_PIPELINE=true
fi

# --- Persist environment ---
echo "export CS_PROJECT_TYPE=$PROJECT_TYPE" >> "$ENV_FILE"
echo "export CS_ESTIMATION_LANG=$ESTIMATION_LANG" >> "$ENV_FILE"
echo "export CS_HAS_DATA=$HAS_DATA" >> "$ENV_FILE"
echo "export CS_HAS_PIPELINE=$HAS_PIPELINE" >> "$ENV_FILE"

# --- Build context message ---
MSG=""

if [ "$PROJECT_TYPE" != "unknown" ]; then
  MSG="Compound-Science detected: **$PROJECT_TYPE** project"
  [ "$ESTIMATION_LANG" != "none" ] && MSG="$MSG ($ESTIMATION_LANG)"
  MSG="$MSG."
fi

# Check for compound-science local config
if [ -f "$PROJECT_DIR/.claude/compound-science.local.md" ]; then
  MSG="$MSG Settings loaded from .claude/compound-science.local.md."
elif [ -f "$PROJECT_DIR/compound-science.local.md" ]; then
  MSG="$MSG Settings loaded from compound-science.local.md."
fi

# Suggest available tools based on project type
if [ "$PROJECT_TYPE" = "empirical" ] || [ "$PROJECT_TYPE" = "empirical-paper" ]; then
  MSG="$MSG Available: \`/estimate\`, \`/simulate\`, \`/identify\`, \`/workflows:plan\`."
fi

if [ "$HAS_PIPELINE" = true ]; then
  MSG="$MSG Pipeline detected — \`pipeline-validator\` and \`reproducibility-checker\` agents available."
fi

if [ -n "$MSG" ]; then
  echo "$MSG"
fi
