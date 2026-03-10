---
name: reproducible-pipelines
description: >-
  Guide for building reproducible research pipelines and replication packages. Use when the user is setting up a research project directory structure, configuring workflow managers (Make, Snakemake, DVC), managing computational environments, preparing replication packages for journal submission, or debugging reproducibility failures. Triggers on "reproducible", "replication package", "Makefile", "Snakemake", "DVC", "pipeline", "workflow manager", "data versioning", "conda environment", "Docker", "seed management", "AEA data editor", "replication", "project structure", or "submission checklist".
---

# Reproducible Pipelines

Reference for building reproducible research pipelines: from project directory structure to automated workflows to journal-ready replication packages. Every computational result should be regenerable from raw data by running a single command.

## When to Use This Skill

Use when the user is:
- Setting up a new empirical research project
- Building or debugging a Makefile/Snakemake/DVC pipeline
- Preparing a replication package for journal submission
- Managing computational environments (conda, Docker, renv)
- Tracking data provenance or versioning large datasets
- Debugging "works on my machine" reproducibility failures

Skip when:
- The task is about estimation methodology (use `causal-inference` or `structural-modeling` skill)
- The task is git workflow management (use `git-worktree` skill)
- The task is about orchestrating Claude agents (use `swarm-orchestration` skill)

## Where to Start
- **New project?** Start with Directory Structure below
- **Adding a workflow manager?** Jump to [Workflow Managers](#workflow-managers) (Make / Snakemake / DVC)
- **Preparing for submission?** Jump to [Pre-Submission Checklist](#pre-submission-checklist)

## Project Directory Structure

Use a standardized layout from the start. This is the structure expected by most replication reviewers:

```
project/
├── README.md                 # Master documentation (how to replicate)
├── Makefile                  # Or Snakefile — single entry point
├── environment.yml           # Conda environment (or requirements.txt)
├── data/
│   ├── raw/                  # Original, immutable data files
│   │   └── README.md         # Data sources, access instructions, citations
│   ├── intermediate/         # Cleaned/transformed data (gitignored, regenerable)
│   └── final/                # Analysis-ready datasets (gitignored, regenerable)
├── code/
│   ├── 01_clean.py           # Data cleaning
│   ├── 02_build.py           # Variable construction, merges
│   ├── 03_estimate.py        # Main estimation
│   ├── 04_robustness.py      # Robustness checks
│   └── 05_tables_figures.py  # Output generation
├── output/
│   ├── tables/               # LaTeX/CSV tables (gitignored, regenerable)
│   └── figures/              # PDF/PNG figures (gitignored, regenerable)
├── docs/
│   ├── brainstorms/          # Research brainstorming docs
│   ├── plans/                # Implementation plans
│   └── codebook.md           # Variable definitions
├── tests/                    # Validation tests
│   ├── test_clean.py
│   └── test_estimates.py
└── paper/
    └── manuscript.tex        # The paper itself
```

**Key principles:**
- `data/raw/` is **immutable** — never modify raw data files
- Everything in `intermediate/`, `final/`, `output/` is **regenerable** — gitignore it
- Number scripts to indicate execution order (or rely on the workflow manager)
- Keep `README.md` as the single entry point for replicators

### .gitignore for Research Projects

```gitignore
# Data (too large for git; document in README how to obtain)
data/raw/*.csv
data/raw/*.dta
data/raw/*.parquet
data/intermediate/
data/final/

# Generated output (reproducible from code)
output/tables/
output/figures/

# Environment
.conda/
__pycache__/
*.pyc
.ipynb_checkpoints/

# Large files managed by DVC
*.dvc

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
```

## Workflow Managers

### Make (Recommended Default)

Make is universally available, well-understood, and sufficient for most research pipelines. Use it unless you have a specific reason for something else.

```makefile
# Makefile — Top-level research pipeline

.PHONY: all clean tables figures

# Default target: reproduce everything
all: output/tables/main_results.tex output/figures/event_study.pdf

# === DATA CLEANING ===
data/intermediate/clean.parquet: data/raw/survey_2020.csv code/01_clean.py
	python code/01_clean.py

# === VARIABLE CONSTRUCTION ===
data/final/analysis.parquet: data/intermediate/clean.parquet code/02_build.py
	python code/02_build.py

# === ESTIMATION ===
output/estimates/main.pkl: data/final/analysis.parquet code/03_estimate.py
	python code/03_estimate.py

output/estimates/robustness.pkl: data/final/analysis.parquet code/04_robustness.py
	python code/04_robustness.py

# === TABLES AND FIGURES ===
output/tables/main_results.tex: output/estimates/main.pkl output/estimates/robustness.pkl code/05_tables_figures.py
	python code/05_tables_figures.py --tables

output/figures/event_study.pdf: output/estimates/main.pkl code/05_tables_figures.py
	python code/05_tables_figures.py --figures

# === UTILITIES ===
clean:
	rm -rf data/intermediate/ data/final/ output/

tables: output/tables/main_results.tex
figures: output/figures/event_study.pdf
```

**Make best practices:**
- Each target lists its **exact** dependencies (both data and code)
- Changing any dependency triggers recomputation of downstream targets
- `make -j4` runs independent targets in parallel (e.g., tables and figures simultaneously)
- `make -n` dry run shows what would be executed without running anything
- Use `.PHONY` for targets that don't correspond to files

### Snakemake (For Complex Pipelines)

Use Snakemake when the pipeline has many steps, parameter sweeps, or needs cluster execution.

```python
# Snakefile

configfile: "config.yaml"

rule all:
    input:
        "output/tables/main_results.tex",
        "output/figures/event_study.pdf"

rule clean_data:
    input:
        raw="data/raw/survey_2020.csv"
    output:
        clean="data/intermediate/clean.parquet"
    script:
        "code/01_clean.py"

rule build_analysis:
    input:
        clean="data/intermediate/clean.parquet"
    output:
        analysis="data/final/analysis.parquet"
    script:
        "code/02_build.py"

rule estimate:
    input:
        data="data/final/analysis.parquet"
    output:
        estimates="output/estimates/{spec}.pkl"
    params:
        seed=config["seed"]
    script:
        "code/03_estimate.py"

# Snakemake advantages over Make:
# - Python syntax (easier for researchers)
# - Built-in wildcards for parameter sweeps
# - Cluster execution (SLURM, SGE)
# - Conda environment per rule
# - Automatic DAG visualization: snakemake --dag | dot -Tpdf > dag.pdf
```

### DVC (Data Version Control)

Use DVC when you need to version large data files that don't fit in git.

```bash
# Initialize DVC in an existing git repo
dvc init

# Track a large data file
dvc add data/raw/survey_2020.csv
# Creates data/raw/survey_2020.csv.dvc (small metadata file, tracked by git)
# The actual data is in .dvc/cache

# Configure remote storage
dvc remote add -d myremote s3://my-bucket/dvc-cache

# Push data to remote
dvc push

# Collaborator pulls data
dvc pull
```

**DVC pipeline integration:**

```yaml
# dvc.yaml
stages:
  clean:
    cmd: python code/01_clean.py
    deps:
      - data/raw/survey_2020.csv
      - code/01_clean.py
    outs:
      - data/intermediate/clean.parquet

  estimate:
    cmd: python code/03_estimate.py
    deps:
      - data/final/analysis.parquet
      - code/03_estimate.py
    outs:
      - output/estimates/main.pkl
    params:
      - seed
      - n_bootstrap
```

**Enhanced DVC: remote storage and experiment tracking:**

```bash
# Remote storage options
dvc remote add -d s3remote s3://my-bucket/dvc-cache      # AWS S3
dvc remote add -d gcsremote gs://my-bucket/dvc-cache     # Google Cloud
dvc remote add -d sshremote ssh://server.edu/path/cache  # SSH server (common for university HPC)
dvc remote add -d localremote /data/shared/dvc-cache     # Shared NFS mount

# Visualize pipeline DAG
dvc dag                        # ASCII DAG in terminal
dvc dag --dot | dot -Tpdf > pipeline.pdf  # PDF visualization

# Parameter tracking and comparison
# params.yaml — centralize all tunable parameters
# DVC auto-tracks params files listed in dvc.yaml

dvc params diff HEAD~1         # Compare current params to last commit
dvc params diff main feature-branch  # Compare across branches

# Metrics: track experiment outcomes
# In dvc.yaml: add metrics: [output/metrics.json] to a stage
dvc metrics show               # Show all tracked metrics
dvc metrics diff HEAD~3        # Compare metrics across commits

# Partial pipeline execution
dvc repro estimate             # Run only the 'estimate' stage and its deps
dvc repro --force              # Re-run even if inputs haven't changed

# Pull only what you need (for large datasets)
dvc pull data/final/analysis.parquet.dvc  # Pull only one file
dvc fetch --run-cache          # Prefetch cached stage outputs
```

**DVC best practices for research:**
- Commit `dvc.lock` to git — it records the exact state of all outputs
- Use `params.yaml` for all tunable parameters (seeds, model specs, sample cutoffs); DVC tracks changes automatically
- On HPC clusters: configure SSH remote pointing at shared storage so collaborators don't re-run expensive stages
- `dvc metrics` is useful for tracking bias/RMSE across Monte Carlo runs; commit `metrics.json` to see history

### Which Workflow Manager to Use

| Factor | Make | Snakemake | DVC |
|--------|------|-----------|-----|
| Complexity | Simple pipelines (< 20 targets) | Complex pipelines, parameter sweeps | Data-heavy pipelines |
| Learning curve | Low (most researchers know it) | Medium (Python-like syntax) | Medium (git-like commands) |
| Cluster support | Manual (submit scripts) | Built-in (SLURM, SGE) | Via CML |
| Data versioning | No | No | Yes (core feature) |
| Availability | Everywhere | pip install | pip install |
| Reviewer familiarity | Very high | Medium | Lower |

**Recommendation:** Start with Make. Switch to Snakemake if you need cluster execution or parameter sweeps. Add DVC if data files are too large for git.

## Stata Projects

Stata pipelines have different conventions from Python/R. The core principle is the same — single entry point, numbered scripts, no manual steps — but the execution model (interactive GUI vs batch) requires extra care.

### Stata Project Structure

```
project/
├── master.do                  # Single entry point: runs the entire pipeline
├── code/
│   ├── 01_clean.do            # Data cleaning
│   ├── 02_build.do            # Variable construction
│   ├── 03_estimate.do         # Main estimation
│   ├── 04_robustness.do       # Robustness checks
│   └── 05_tables.do           # Table output
├── ado/                       # Custom ado-files (project-specific Stata programs)
├── data/
│   ├── raw/                   # Immutable raw data (.dta, .csv)
│   └── intermediate/          # Cleaned data (gitignored)
├── output/
│   ├── tables/                # Exported tables (.tex, .xlsx)
│   └── figures/               # Exported figures (.pdf, .eps)
└── logs/                      # Log files from do-file runs (gitignored)
```

### master.do — The Single Entry Point

```stata
* master.do — Run the entire pipeline
* Usage: stata -b do master.do  (batch mode, no GUI)

version 17.0          // Pin Stata version — critical for reproducibility

* === PATHS ===
* Use relative paths from project root
global root    "."
global code    "$root/code"
global data    "$root/data"
global output  "$root/output"
global logs    "$root/logs"

* === SETTINGS ===
set more off           // Never pause — required for batch mode
set matsize 11000      // Increase matrix size for large datasets
set linesize 120       // Wider output for tables

* === LOGGING ===
capture mkdir "$logs"
local logfile = "$logs/master_" + c(current_date) + ".log"
log using "`logfile'", replace text

* === PIPELINE ===
di "Starting pipeline: $S_DATE $S_TIME"

do "$code/01_clean.do"
do "$code/02_build.do"
do "$code/03_estimate.do"
do "$code/04_robustness.do"
do "$code/05_tables.do"

di "Pipeline complete: $S_DATE $S_TIME"
log close
```

### do-file Conventions

Each do-file should have a standard header and operate on global macros for paths:

```stata
* 03_estimate.do
* Purpose: Baseline DiD estimation with two-way FE
* Input:   $data/intermediate/panel_clean.dta
* Output:  $output/tables/table1_did.tex, $data/intermediate/estimates.dta
* Author:  [Name], [Date]
* Updated: [Date] — [change description]

version 17.0
set more off

* Load data
use "$data/intermediate/panel_clean.dta", clear

* Baseline DiD with reghdfe
reghdfe y treated##post controls, absorb(unit_fe time_fe) vce(cluster unit_id)

* Export table
estimates store main_did
esttab main_did using "$output/tables/table1_did.tex", ///
    replace label star(* 0.10 ** 0.05 *** 0.01) se ///
    title("Main DiD Results") booktabs
```

### Running Stata in Batch Mode (for reproducibility)

Never rely on interactive clicks. Always run via batch:

```bash
# Run full pipeline (no GUI)
stata -b do master.do

# Or stata-mp for parallel processing
stata-mp -b do master.do

# Check exit code
echo $?   # 0 = success, non-zero = error

# Integrate with Make
output/tables/table1_did.tex: code/03_estimate.do data/intermediate/panel_clean.dta
	stata -b do code/03_estimate.do
	@[ -f output/tables/table1_did.tex ] || (echo "Stata failed — check logs/" && exit 1)
```

### ado-file Versioning

Custom programs (ado-files) must be version-controlled and loaded before estimation:

```stata
* In master.do, before any do-files:
adopath + "$root/ado"   // Load project-specific ado-files first

* In your ado/ directory: myprog.ado, myprog.sthlp
* This ensures project ado-files take precedence over user-installed packages

* Document installed packages in a setup do-file:
* code/00_setup.do
ssc install reghdfe, replace
ssc install ftools, replace
ssc install estout, replace
ssc install rdrobust, replace
```

### Stata Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| No `version` statement | Results may change across Stata versions | Add `version 17.0` to every do-file |
| `set more on` (default) | Pipeline hangs waiting for keypress in batch | Always `set more off` in master.do |
| Absolute paths (`/Users/me/...`) | Breaks on collaborator machines | Use global macros from master.do |
| Interactive graph window (`graph display`) | Batch mode crashes | Use `graph export filename.pdf, replace` |
| Missing `log close` | Log file left open if error occurs | Add `cap log close` at top, `log close` at bottom |
| Point-and-click menu operations | Not reproducible | Everything in do-files |

## CROSS-LANGUAGE REPLICATION STANDARDS

### Tolerance Thresholds (Stata ↔ R ↔ Python)
When verifying results across languages, use these tolerance thresholds:

| Result type | Tolerance | Notes |
|-------------|-----------|-------|
| Integer counts | Exact match | Row counts, group sizes |
| Point estimates | \|diff\| < 0.01 (absolute) OR < 0.001% (relative) | Use stricter when estimates are small |
| Standard errors | \|diff\| < 0.05 OR < 0.01% relative | Different finite-sample corrections are acceptable if documented |
| P-values | Same significance conclusion at 1/5/10% | Exact p-values may differ across implementations |
| Confidence intervals | Overlap by >99% of interval width | Not just point equality |

### Stata-to-R Translation Trap Table
Known systematic differences that produce real numeric discrepancies:

| Issue | Stata behavior | R equivalent | Fix |
|-------|----------------|--------------|-----|
| Cluster SE df adjustment | Uses g-1 (groups minus 1) | `feols` uses g-1 by default; `lm_robust` varies | Use `feols` in R, not `lm_robust` with default |
| `areg` absorbed FE dof | Subtracts N_absorbed from residual df | `feols` handles automatically | Switch from `areg` to `reghdfe`/`feols` |
| Probit MFX | `margins, dydx(*)` = average marginal effect | `margins::margins()` or manual AME computation | Verify using AME, not marginal at mean |
| Multi-way clustering | `reghdfe` Cameron-Gelbach-Miller | `feols` multiway: `vcov = ~id+time` | Formulas differ; document which is used |
| Bootstrap sampling | `bsample` with `set seed` | `set.seed` before `boot()` or manual bootstrap | Seed must be set identically in both |
| Wild cluster bootstrap | `boottest` (Roodman) | `fwildclusterboot` (Fischer) | Different algorithms; expect SE-level (not exact) agreement |
| Time-series operators | `L.` / `D.` operators | `dplyr::lag()` with explicit group | Verify panel lag handles unbalanced panels identically |
| Balanced panel enforcement | `xtset` warns, `xtbalance` required | `is.pbalanced()` check | Unbalanced panels produce different within estimators |

### Anti-patterns
- 🔴 Manually editing generated tables (breaks automation trail)
- 🔴 `qui regress` without `eststo` in a loop (results not captured)
- 🔴 `save` without `compress` (file size; use `saveold` for v12 compatibility if needed)
- 🔴 `use data.dta, clear` at top of do-file without checking working directory first
- 🔴 Cross-language replication using the same base code (defeats the orthogonality purpose)

## Environment Management

### Conda (Recommended for Python/R Mixed Projects)

```yaml
# environment.yml
name: my-project
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.11.7        # Pin exact version
  - numpy=1.26.4
  - pandas=2.2.0
  - scipy=1.12.0
  - statsmodels=0.14.1
  - scikit-learn=1.4.0
  - matplotlib=3.8.3
  - pip:
    - linearmodels==6.0
    - pyblp==1.1.0
    - rdrobust==1.1.1
```

```bash
# Create environment
conda env create -f environment.yml

# Export exact versions (for reproducibility)
conda env export --no-builds > environment.lock.yml

# Recreate exact environment
conda env create -f environment.lock.yml
```

**Best practices:**
- Pin **exact** versions in the lock file (not `>=` or `~=`)
- Use `conda-forge` channel for most scientific packages
- Test on a clean machine (or CI) to verify the environment file is complete
- `environment.yml` is for human editing; `environment.lock.yml` is the machine-exact specification

### pip + venv (Lighter Weight)

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install and freeze
pip install numpy==1.26.4 pandas==2.2.0 statsmodels==0.14.1
pip freeze > requirements.txt

# Recreate
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### renv (For R Projects)

```r
# Initialize renv in project
renv::init()

# Install packages (recorded in renv.lock)
install.packages("fixest")
install.packages("did")

# Snapshot current state
renv::snapshot()

# Collaborator restores exact environment
renv::restore()
```

### Docker (Maximum Reproducibility)

Use Docker when the computational environment itself must be exactly reproducible (OS-level dependencies, system libraries).

```dockerfile
# Dockerfile
FROM continuumio/miniconda3:24.1.2-0

WORKDIR /project

# Copy environment specification first (for caching)
COPY environment.yml .
RUN conda env create -f environment.yml

# Activate environment in subsequent commands
SHELL ["conda", "run", "-n", "my-project", "/bin/bash", "-c"]

# Copy project files
COPY . .

# Default: run the full pipeline
CMD ["make", "all"]
```

```bash
# Build and run
docker build -t my-project .
docker run -v $(pwd)/output:/project/output my-project

# Or run interactively
docker run -it -v $(pwd):/project my-project bash
```

## Random Seed Management

Every stochastic operation must be seeded and logged.

```python
# config.py — Central seed management
import numpy as np
import random
import os

MASTER_SEED = 20240215  # Date-based seeds are easy to document

def set_all_seeds(seed=MASTER_SEED):
    """Set seeds for all random number generators."""
    np.random.seed(seed)
    random.seed(seed)
    os.environ['PYTHONHASHSEED'] = str(seed)

    # If using PyTorch
    try:
        import torch
        torch.manual_seed(seed)
        torch.cuda.manual_seed_all(seed)
        torch.backends.cudnn.deterministic = True
    except ImportError:
        pass

def get_rng(seed=None):
    """Create an independent RNG for a specific task.

    Use this instead of global np.random to avoid seed contamination
    between different parts of the pipeline.
    """
    if seed is None:
        seed = MASTER_SEED
    return np.random.default_rng(seed)
```

```python
# In estimation code
from config import get_rng, MASTER_SEED

# Each bootstrap/simulation gets a deterministic, independent seed
rng = get_rng(MASTER_SEED + 1)  # +1 for bootstrap, +2 for simulation, etc.

bootstrap_estimates = []
for b in range(n_bootstrap):
    idx = rng.choice(n, size=n, replace=True)
    # ... estimate on bootstrap sample
```

**Rules:**
1. **One master seed** defined in a config file, documented in README
2. **Derived seeds** for different pipeline stages (bootstrap, simulation, sample splits)
3. **Use `np.random.default_rng()`** not `np.random.seed()` — the new API creates independent generators that don't interfere with each other
4. **Log the seed** in output metadata: `results['seed'] = MASTER_SEED`
5. **Test reproducibility**: run the pipeline twice and diff the outputs

## Results Caching

Avoid re-running expensive computations during development.

```python
import pickle
import hashlib
from pathlib import Path

def cached_computation(func, cache_key, cache_dir="output/cache", **kwargs):
    """Cache expensive computations with dependency-aware keys."""
    cache_path = Path(cache_dir) / f"{cache_key}.pkl"
    cache_path.parent.mkdir(parents=True, exist_ok=True)

    if cache_path.exists():
        with open(cache_path, 'rb') as f:
            return pickle.load(f)

    result = func(**kwargs)

    with open(cache_path, 'wb') as f:
        pickle.dump(result, f)

    return result

# Usage
estimates = cached_computation(
    run_estimation,
    cache_key="main_2sls_v3",  # version the cache key when code changes
    data=df, instruments=['z1', 'z2']
)
```

**Important:** Caching is for development speed only. The final replication run must execute everything from scratch (`make clean && make all`).

## Replication Package Standards

### AEA Data Editor Requirements

The AEA (American Economic Association) has the most detailed replication requirements. Following these satisfies most other journals too.

**Required components:**

1. **README.md** — Must include:
   - Data availability statement (where to obtain each dataset)
   - Computational requirements (time, memory, software)
   - Instructions to reproduce all results
   - List of all tables and figures with the script that produces each

2. **Data citations** — Cite every dataset used, including:
   - Provider and access conditions
   - DOI or persistent URL
   - Date accessed
   - Any restrictions on redistribution

3. **Code** — Must produce every number in the paper:
   - Every table (including appendix tables)
   - Every figure
   - Every in-text statistic ("We find a 3.2% effect...")

4. **License** — Include a license file (typically MIT or CC-BY for code)

### README Template

```markdown
# Replication Package for "[Paper Title]"

## Authors
[Names and affiliations]

## Data Availability

| Dataset | Source | Access | Included |
|---------|--------|--------|----------|
| CPS March Supplement | IPUMS | Public (registration) | No — download from [URL] |
| State policy dates | Hand-collected | — | Yes (`data/raw/policy_dates.csv`) |

### Instructions for restricted data
[If any data requires DUA or restricted access, explain the process]

## Computational Requirements

- **Software:** Python 3.11, packages in `environment.yml`
- **Hardware:** [X] GB RAM, [Y] CPU hours
- **OS:** Tested on Ubuntu 22.04 and macOS 14

## Instructions

```bash
# 1. Set up environment
conda env create -f environment.yml
conda activate my-project

# 2. Obtain data
# Download CPS data from [URL] to data/raw/

# 3. Run full pipeline
make all

# Expected runtime: ~[X] hours on [hardware description]
```

## Output Map

| Output | Script | Table/Figure |
|--------|--------|-------------|
| `output/tables/main_results.tex` | `code/03_estimate.py` | Table 1 |
| `output/tables/robustness.tex` | `code/04_robustness.py` | Table 2 |
| `output/figures/event_study.pdf` | `code/05_tables_figures.py` | Figure 1 |
```

### Pre-Submission Checklist

Run this before submitting the replication package:

- [ ] **Clean build**: `make clean && make all` succeeds from scratch
- [ ] **Fresh environment**: Create environment from `environment.yml` on a clean machine; all packages install
- [ ] **Data documentation**: Every raw data file has source, access instructions, and citation
- [ ] **Output map**: Every table, figure, and in-text statistic mapped to a script
- [ ] **No absolute paths**: `grep -r '/Users\|/home\|C:\\' code/` returns nothing
- [ ] **No manual steps**: Every intermediate file is produced by code, not hand-edited
- [ ] **Seeds documented**: Master seed stated in README; all stochastic code is seeded
- [ ] **Runtime estimate**: README states expected runtime and hardware requirements
- [ ] **License**: LICENSE file included
- [ ] **Sensitive data**: No IRB-restricted or proprietary data included without authorization
- [ ] **Large files**: Data files either included (if small + redistributable) or documented (if large/restricted)
- [ ] **Version pinned**: `environment.yml` or `requirements.txt` has exact version numbers

## Common Anti-Patterns

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| Jupyter notebooks as the pipeline | Non-linear execution, hidden state, hard to automate | Use .py scripts orchestrated by Make; notebooks only for exploration |
| Absolute file paths (`/Users/me/data/...`) | Breaks on any other machine | Use relative paths from project root; configure data directory in a single config file |
| `pip install` without version pinning | Package updates break code silently months later | Pin exact versions: `pandas==2.2.0` |
| Modifying raw data files | Destroys provenance; can't rerun from original | `data/raw/` is immutable; all cleaning produces new files in `data/intermediate/` |
| Committing large data files to git | Bloats repository, slow clones | Use DVC, git-lfs, or document download instructions |
| Hardcoded random seeds scattered across files | Hard to find, easy to miss one | Centralize in config.py, derive all seeds from one master seed |
| "It works on my laptop" | Different OS, library versions, locale settings | Test in Docker or CI; provide `environment.yml` |
| Results tables copy-pasted into paper | Tables get stale when estimates change | Generate LaTeX tables directly from estimation code |
| Pipeline only tested by the author | Missing implicit dependencies | Have a co-author or RA run from scratch; or use CI |

The `pipeline-validator` agent can audit pipelines for these anti-patterns automatically, and the `reproducibility-checker` agent can verify replication packages before submission.
