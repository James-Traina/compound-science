#!/bin/bash
# Test fixture creation for hook simulation tests

set -euo pipefail

# Create a temp directory and return its path
fixture_dir() {
  local name="${1:-test}"
  local dir
  dir=$(mktemp -d "${TMPDIR:-/tmp}/cs-qa-${name}-XXXXXX")
  echo "$dir"
}

# Fixture: empty project
fixture_empty() {
  fixture_dir "empty"
}

# Fixture: Python econometrics project
fixture_python_econometrics() {
  local dir
  dir=$(fixture_dir "python-econ")
  echo "statsmodels>=0.14" > "$dir/requirements.txt"
  echo "$dir"
}

# Fixture: R econometrics project
fixture_r_project() {
  local dir
  dir=$(fixture_dir "r-project")
  printf 'Package: mypackage\nImports: fixest, dplyr\n' > "$dir/DESCRIPTION"
  echo "$dir"
}

# Fixture: Stata econometrics project
fixture_stata() {
  local dir
  dir=$(fixture_dir "stata")
  echo "regress y x1 x2, robust" > "$dir/analysis.do"
  echo "$dir"
}

# Fixture: Julia project
fixture_julia() {
  local dir
  dir=$(fixture_dir "julia")
  cat > "$dir/Project.toml" << 'TOML'
[deps]
Optim = "429524aa-4258-5aef-a3af-852621145aeb"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
TOML
  echo "$dir"
}

# Fixture: LaTeX paper only
fixture_latex_paper() {
  local dir
  dir=$(fixture_dir "paper")
  touch "$dir/manuscript.tex"
  echo "$dir"
}

# Fixture: empirical paper (Python + LaTeX)
fixture_empirical_paper() {
  local dir
  dir=$(fixture_dir "empirical-paper")
  echo "linearmodels>=5.0" > "$dir/requirements.txt"
  touch "$dir/paper.tex"
  echo "$dir"
}

# Fixture: project with data directory
fixture_with_data() {
  local dir
  dir=$(fixture_dir "with-data")
  mkdir -p "$dir/data"
  echo "$dir"
}

# Fixture: project with Makefile pipeline
fixture_with_pipeline() {
  local dir
  dir=$(fixture_dir "with-pipeline")
  echo "all: results" > "$dir/Makefile"
  echo "$dir"
}

# Fixture: full project (Python + LaTeX + data + pipeline)
fixture_full_project() {
  local dir
  dir=$(fixture_dir "full")
  echo "pyblp>=1.0" > "$dir/requirements.txt"
  touch "$dir/paper.tex"
  mkdir -p "$dir/data"
  echo "all: results" > "$dir/Makefile"
  echo "$dir"
}

# Fixture: project with .local.md config
fixture_with_local_config() {
  local dir
  dir=$(fixture_dir "local-config")
  mkdir -p "$dir/.claude"
  echo "# Local settings" > "$dir/.claude/compound-science.local.md"
  echo "$dir"
}

# Run session-init.sh against a fixture directory, capture env vars and output
run_session_init() {
  local project_dir="$1"
  local script="$2"
  local env_file
  env_file=$(mktemp "${TMPDIR:-/tmp}/cs-qa-env-XXXXXX")

  local output
  output=$(CLAUDE_PROJECT_DIR="$project_dir" CLAUDE_ENV_FILE="$env_file" bash "$script" 2>&1) || true

  # Parse env file
  local project_type estimation_lang has_data has_pipeline
  project_type=$(grep 'CS_PROJECT_TYPE=' "$env_file" 2>/dev/null | sed 's/.*=//' || echo "")
  estimation_lang=$(grep 'CS_ESTIMATION_LANG=' "$env_file" 2>/dev/null | sed 's/.*=//' || echo "")
  has_data=$(grep 'CS_HAS_DATA=' "$env_file" 2>/dev/null | sed 's/.*=//' || echo "")
  has_pipeline=$(grep 'CS_HAS_PIPELINE=' "$env_file" 2>/dev/null | sed 's/.*=//' || echo "")

  # Clean up
  rm -f "$env_file"

  # Return as tab-separated: project_type, estimation_lang, has_data, has_pipeline, output
  printf '%s\t%s\t%s\t%s\t%s' "$project_type" "$estimation_lang" "$has_data" "$has_pipeline" "$output"
}

# Clean up all fixture temp dirs
cleanup_fixtures() {
  rm -rf "${TMPDIR:-/tmp}"/cs-qa-*
}
