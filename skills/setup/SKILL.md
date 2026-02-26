---
name: setup
description: Configure which review agents run for your project. Auto-detects research stack and writes compound-science.local.md. Use when setting up compound-science for a new project, reconfiguring agents, changing estimation language, or adjusting project settings. Triggers on "setup compound", "configure agents", "set up project", "change review agents", "switch to R", "set estimation language", or when /workflows:work reads project configuration.
---

# Compound-Science Setup

Configure `compound-science.local.md` — controls which agents run during `/workflows:review`, `/workflows:work`, and `/workflows:compound`, and sets project-wide defaults for estimation language, project type, and data handling.

## Quick Start (Under 2 Minutes)

For most projects, auto-detection handles everything:

```bash
# The plugin auto-detects your project. To verify:
cat compound-science.local.md
```

If no config file exists, the setup skill creates one automatically. Here's the fastest path:

1. The skill detects your project type and estimation language from files in the repo
2. It writes `compound-science.local.md` with sensible defaults
3. You edit the "Research Context" section if you want agent-specific guidance

**That's it.** The workflow commands read this file automatically.

---

## How It Works

### Step 1: Check Existing Config

Read `compound-science.local.md` in the project root.

- **If exists:** Display current settings. Decide based on context:
  - If the user asked to reconfigure → proceed to Step 2 (overwrite)
  - If the user asked to view → display the file, then stop
  - Otherwise → use existing config (no changes needed)
- **If missing:** Proceed to Step 2 (create new)

### Step 2: Detect Project Type and Language

Auto-detect from file patterns in the repository:

```bash
# Estimation language detection (priority order)
if ls *.py src/**/*.py scripts/**/*.py 2>/dev/null | head -1 | grep -q .; then
  # Check for estimation packages
  grep -rl "statsmodels\|linearmodels\|pyblp\|scipy.optimize" *.py src/**/*.py 2>/dev/null && LANG="python"
fi
if ls *.R R/**/*.R scripts/**/*.R 2>/dev/null | head -1 | grep -q .; then
  grep -rl "fixest\|lfe\|AER\|estimatr\|rdrobust" *.R R/**/*.R 2>/dev/null && LANG="r"
fi
if ls *.jl src/**/*.jl 2>/dev/null | head -1 | grep -q .; then
  grep -rl "GLM\|FixedEffectModels\|Optim\." *.jl src/**/*.jl 2>/dev/null && LANG="julia"
fi
if ls *.do *.ado 2>/dev/null | head -1 | grep -q .; then
  LANG="stata"
fi

# Project type detection
HAS_DATA=$(test -d data || test -d raw_data || ls *.csv *.dta *.parquet 2>/dev/null | head -1 | grep -q . && echo "true" || echo "false")
HAS_PAPER=$(test -f paper.tex || test -f manuscript.tex || ls *.tex 2>/dev/null | head -1 | grep -q . && echo "true" || echo "false")
HAS_PIPELINE=$(test -f Makefile || test -f Snakefile || test -f dvc.yaml && echo "true" || echo "false")
HAS_PACKAGE=$(test -f setup.py || test -f pyproject.toml || test -f DESCRIPTION && echo "true" || echo "false")

# Classify
if [ "$HAS_DATA" = "true" ] && [ "$HAS_PAPER" = "true" ]; then
  PROJECT_TYPE="empirical-paper"
elif [ "$HAS_DATA" = "true" ]; then
  PROJECT_TYPE="empirical"
elif [ "$HAS_PAPER" = "true" ]; then
  PROJECT_TYPE="methodology-paper"
elif [ "$HAS_PACKAGE" = "true" ]; then
  PROJECT_TYPE="software-package"
else
  PROJECT_TYPE="general"
fi
```

### Step 3: Select Agent Configuration

Based on detected project type, auto-select the review agents:

**Empirical paper** (default — most common):
```yaml
review_agents:
  - econometrician
  - numerical-auditor
  - identification-critic
  - pipeline-validator
plan_review_agents:
  - econometrician
  - identification-critic
```

**Methodology paper:**
```yaml
review_agents:
  - mathematical-prover
  - identification-critic
  - referee
  - numerical-auditor
plan_review_agents:
  - mathematical-prover
  - identification-critic
```

**Empirical (data analysis without paper):**
```yaml
review_agents:
  - econometrician
  - numerical-auditor
  - data-detective
plan_review_agents:
  - econometrician
```

**Software package** (estimation library, simulation toolkit):
```yaml
review_agents:
  - numerical-auditor
  - econometrician
plan_review_agents:
  - numerical-auditor
```

**General** (fallback):
```yaml
review_agents:
  - econometrician
  - numerical-auditor
plan_review_agents:
  - econometrician
```

### Step 4: Write Config File

Write `compound-science.local.md` with the detected settings:

```markdown
---
# Compound-Science Configuration
# Auto-detected on [date]. Edit to customize.

# Review agents run during /workflows:review
review_agents:
  - econometrician
  - numerical-auditor
  - identification-critic
  - pipeline-validator

# Agents for /workflows:plan review phase
plan_review_agents:
  - econometrician
  - identification-critic

# Estimation language (auto-detected)
estimation_language: python

# Project type: empirical-paper | methodology-paper | empirical | software-package | general
project_type: empirical-paper

# Data sensitivity: public | restricted | confidential
data_sensitivity: public

# Additional agents to include in /workflows:review (beyond defaults)
# extra_review_agents:
#   - referee
#   - mathematical-prover

# Agents to exclude from default review set
# exclude_review_agents:
#   - pipeline-validator
---

# Research Context

Add project-specific instructions here. These notes are passed to all review agents during /workflows:review and /workflows:work.

Examples:
- "We exploit variation in minimum wage changes across states — check parallel trends carefully"
- "Panel data with N=500 firms, T=20 years — cluster at firm level"
- "BLP demand estimation — convergence is the main concern, use tight tolerance"
- "Replication package for AEA submission — strict reproducibility requirements"
```

### Step 5: Confirm

Output the configuration summary:

```
Saved to compound-science.local.md

Project type:     empirical-paper
Est. language:    python
Data sensitivity: public
Review agents:    4 configured
                  econometrician
                  numerical-auditor
                  identification-critic
                  pipeline-validator
Plan agents:      2 configured
                  econometrician
                  identification-critic

Tip: Edit the "Research Context" section to add project-specific
     review instructions. Re-run setup anytime to reconfigure.
```

---

## Configuration Reference

### All Configuration Options

| Field | Type | Default | Valid Values | Description |
|---|---|---|---|---|
| `review_agents` | list | (per project type) | Any agent name from compound-science | Agents run during `/workflows:review` |
| `plan_review_agents` | list | (per project type) | Any agent name | Agents that review plans in `/workflows:plan` |
| `estimation_language` | string | (auto-detected) | `python`, `r`, `julia`, `stata` | Default language for code generation |
| `project_type` | string | (auto-detected) | `empirical-paper`, `methodology-paper`, `empirical`, `software-package`, `general` | Controls which agents are most relevant |
| `data_sensitivity` | string | `public` | `public`, `restricted`, `confidential` | Affects data handling suggestions |
| `extra_review_agents` | list | `[]` | Any agent name | Added on top of defaults |
| `exclude_review_agents` | list | `[]` | Any agent name | Removed from defaults |

### Available Agents

All agents that can be configured in `review_agents` or `plan_review_agents`:

**Review agents:**
| Agent | Role | Best for |
|---|---|---|
| `econometrician` | Checks identification, endogeneity, standard errors, instrument validity | Empirical estimation code |
| `mathematical-prover` | Verifies proof steps, regularity conditions, existence/uniqueness | Theoretical derivations |
| `numerical-auditor` | Checks floating-point stability, convergence, matrix conditioning | Numerical computation |
| `identification-critic` | Evaluates completeness of identification arguments | Identification strategies |
| `referee` | Adversarial journal referee simulation | Written artifacts, papers |

**Research agents:**
| Agent | Role | Best for |
|---|---|---|
| `literature-scout` | Finds related methods, papers, prior applications | Literature review |
| `methods-researcher` | Deep-dives into specific methods, compares alternatives | Method selection |
| `data-detective` | Profiles data, checks quality, validates merges | Data preparation |
| `learnings-researcher` | Searches past solutions in `docs/solutions/` | Recurring problems |

**Workflow agents:**
| Agent | Role | Best for |
|---|---|---|
| `pipeline-validator` | Validates reproducible pipelines (seeds, paths, deps) | Pipeline code |
| `reproducibility-checker` | Pre-submission reproducibility verification | Replication packages |

### Project Type Behavior

Each project type adjusts default behavior across all workflow commands:

**empirical-paper:**
- Review emphasizes identification, standard errors, and reproducibility
- Stop hook checks for: clustered SEs, convergence diagnostics, seed documentation
- Compound command uses all 6 solution categories

**methodology-paper:**
- Review emphasizes proof correctness and mathematical rigor
- Stop hook checks for: regularity conditions, proof completeness
- Referee agent included by default (evaluates contribution and exposition)

**empirical:**
- Review emphasizes data quality and estimation correctness
- Lighter pipeline requirements (no replication package needed)
- Data-detective agent included by default

**software-package:**
- Review emphasizes numerical correctness and edge cases
- Stop hook checks for: test coverage, docstrings, numerical precision
- Lighter on identification/methodology concerns

### Data Sensitivity Levels

| Level | Behavior |
|---|---|
| `public` | No restrictions. Data paths can be logged, shared in docs |
| `restricted` | Data paths are noted but actual data values are never included in solution docs or commit messages |
| `confidential` | Solution docs reference data structure only (never variable names from restricted datasets). Pipeline suggestions use synthetic data for testing |

---

## Advanced Configuration

### Per-Command Agent Overrides

Override agents for specific commands by adding command-specific sections:

```yaml
---
review_agents:
  - econometrician
  - numerical-auditor

# Override for /workflows:review only
review_override:
  - econometrician
  - numerical-auditor
  - identification-critic
  - referee
  - pipeline-validator

# Override for /estimate only
estimate_override:
  - econometrician
  - numerical-auditor
---
```

### Conditional Agents

Add agents that only run when certain conditions are met:

```yaml
---
review_agents:
  - econometrician
  - numerical-auditor

conditional_agents:
  referee:
    when: "*.tex files exist or docs/paper/ directory exists"
  pipeline-validator:
    when: "Makefile or Snakefile or dvc.yaml exists"
  mathematical-prover:
    when: "proof or derivation files detected"
---
```

### Multi-Language Projects

For projects using multiple estimation languages:

```yaml
---
estimation_language: python
secondary_languages:
  - r        # For robustness checks in fixest
  - stata    # For legacy code comparison
---
```

The primary `estimation_language` is used for new code generation. Secondary languages are recognized in review and compound workflows.

---

## How Config Is Read

Workflow commands read `compound-science.local.md` at startup:

1. **`/workflows:review`** — reads `review_agents` to decide which agents to launch in parallel
2. **`/workflows:plan`** — reads `plan_review_agents` for the plan review phase
3. **`/workflows:work`** — reads `estimation_language` for code generation defaults
4. **`/workflows:compound`** — reads all settings for solution documentation routing
5. **`/estimate`** — reads `estimation_language` and any `estimate_override` agents
6. **`/simulate`** — reads `estimation_language` for simulation code generation
7. **SessionStart hook** — reads `project_type` to set environment context

If no `compound-science.local.md` exists, commands use defaults for `empirical-paper` with `python`.

---

## Anti-Patterns

- **Over-configuring** — the defaults work for most projects; only customize if you have specific needs
- **Excluding core agents** — removing `econometrician` from an empirical project means estimation code gets no domain review
- **Wrong project type** — if you have data AND a paper, use `empirical-paper`, not just `empirical`
- **Forgetting Research Context** — the free-text section is where project-specific guidance goes; agents read it during review
- **Manual agent lists in commands** — don't hardcode agent names in workflow commands; always read from config so changes propagate
