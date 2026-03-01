---
name: replicate
description: "Build and verify AEA-compliant replication packages with dependency audit, pipeline verification, and data documentation"
argument-hint: "<project directory, paper draft, or replication package to verify>"
---

# Replication Package Pipeline

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

Build and verify a complete, AEA-compliant replication package. Scans the project for code, data, and outputs; generates a README following the AEA Data Editor's template; audits dependencies; verifies the pipeline produces reproducible results from a clean state; documents data sources with citations and access instructions; and assembles everything into a submission-ready structure.

## Input Document

<input_document> #$ARGUMENTS </input_document>

**If no input:** Scan the current project for code files (`.py`, `.R`, `.jl`, `.do`, `.m`), data files (`.csv`, `.dta`, `.parquet`, `.rds`), output files (`.tex`, `.pdf`, `.png`), and build systems (`Makefile`, `Snakefile`, `dvc.yaml`). If a project structure is detected, proceed with the full inventory. If the directory appears empty or non-research, state "No research project found. Provide a project directory or paper draft to build a replication package for." and stop.

## Execution Workflow

### Phase 1: Project Inventory

Scan the entire project to catalog all components needed for replication.

1. **Code inventory:**

   | Category | File types | What to record |
   |----------|-----------|---------------|
   | **Estimation code** | `.py`, `.R`, `.jl`, `.do`, `.m` | Language, dependencies, execution order |
   | **Data cleaning** | Same as above | Input/output file paths, transformations |
   | **Table/figure generation** | Same + `.tex`, `.Rmd` | Which outputs each script produces |
   | **Utility/helper code** | Same | Functions called by main scripts |
   | **Build system** | `Makefile`, `Snakefile`, `dvc.yaml`, `.sh` | Pipeline DAG, execution order |
   | **Configuration** | `.yaml`, `.json`, `.toml`, `.cfg` | Parameters, paths, settings |

   For each code file:
   - Record the file path, language, approximate purpose
   - Extract import/library statements to build dependency list
   - Identify input files read and output files written
   - Note any hardcoded paths (flag for portability)

2. **Data inventory:**

   | Category | File types | What to record |
   |----------|-----------|---------------|
   | **Raw data** | `.csv`, `.dta`, `.parquet`, `.rds`, `.xlsx` | Source, size, row/column counts |
   | **Intermediate data** | Same | Which script produces it, which consumes it |
   | **Final analysis data** | Same | The dataset used for estimation |
   | **Restricted/confidential** | Any | Access requirements, cannot be included |

   For each data file:
   - Record file path, size, format, dimensions (rows × columns)
   - Classify as raw, intermediate, or final
   - Check if the file should be included or excluded from the package
   - Note any files that exceed reasonable size for distribution (>100MB)

3. **Output inventory:**

   | Category | File types | What to record |
   |----------|-----------|---------------|
   | **Tables** | `.tex`, `.csv`, `.html` | Which script produces each |
   | **Figures** | `.pdf`, `.png`, `.eps`, `.svg` | Which script produces each |
   | **Logs** | `.log`, `.txt` | Estimation logs, build logs |
   | **Paper** | `.tex`, `.pdf` | Main manuscript, appendix |

4. **Build dependency graph:**
   - Map: raw data → cleaning code → analysis data → estimation code → results → tables/figures
   - Identify any gaps (output files with no code that produces them)
   - Identify any orphans (code files not part of the pipeline)
   - Flag any circular dependencies

5. **Inventory summary table:**

   ```
   ┌──────────────────┬───────┬────────────────────────────────┐
   │ Category         │ Count │ Details                        │
   ├──────────────────┼───────┼────────────────────────────────┤
   │ Code files       │ ...   │ Python: N, R: N, Stata: N      │
   │ Data files       │ ...   │ Raw: N, Intermediate: N        │
   │ Output files     │ ...   │ Tables: N, Figures: N          │
   │ Config files     │ ...   │ ...                            │
   │ Build system     │ ...   │ Makefile / Snakefile / None     │
   │ Total size       │ ...   │ Code: X MB, Data: Y MB         │
   └──────────────────┴───────┴────────────────────────────────┘
   ```

### Phase 2: README Generation

Generate a README following the AEA Data Editor's template (Vilhuber, 2020).

1. **README structure** (AEA template sections):

   ```markdown
   # Data Availability and Provenance Statements

   ## Dataset 1: <name>
   - **Source:** <provider, URL, citation>
   - **Access:** <how to obtain, any restrictions>
   - **License/terms:** <redistribution rights>
   - **Provided:** Yes / No (with access instructions if No)

   ## Dataset 2: <name>
   ...

   # Computational Requirements

   ## Software Requirements
   - <Language> <version> (e.g., Python 3.11, R 4.3.2, Stata 17)
   - Package list with versions (see requirements.txt / renv.lock)

   ## Hardware Requirements
   - Approximate time: <X minutes/hours on standard hardware>
   - Memory: <peak RAM usage>
   - Storage: <disk space needed>
   - Special requirements: <GPU, cluster, etc.>

   ## Description of Programs

   ### Data Preparation
   - `code/01_clean_data.py`: Reads <input>, produces <output>
   - `code/02_merge_data.py`: Reads <input>, produces <output>

   ### Analysis
   - `code/03_estimate.py`: Reads <input>, produces Tables 1-3
   - `code/04_figures.py`: Reads <input>, produces Figures 1-4

   ### Tables and Figures
   | Table/Figure | Program | Input | Output |
   |-------------|---------|-------|--------|
   | Table 1 | code/03_estimate.py | data/analysis.csv | tables/tab1.tex |
   | Figure 1 | code/04_figures.py | data/analysis.csv | figures/fig1.pdf |
   ...

   # Instructions for Replication

   ## Step 1: Install dependencies
   <exact commands>

   ## Step 2: Obtain data
   <instructions for any data not included>

   ## Step 3: Run pipeline
   <exact command to reproduce all results>

   ## Step 4: Verify
   <how to confirm outputs match>
   ```

2. **Auto-populate fields:**
   - Fill in all sections using information from Phase 1 inventory
   - Detect language versions from environment files or shebang lines
   - Estimate runtime from code complexity and data size
   - Map every table and figure to its generating script

3. **Flag incomplete sections:**
   - Mark any section that could not be auto-populated as `[TODO: ...]`
   - List all TODOs at the bottom for researcher attention

### Phase 3: Dependency Audit

Verify all dependencies are pinned and environments are reproducible.

1. **Check for environment specification files:**

   | Language | Expected file | Lockfile |
   |---------|--------------|---------|
   | **Python** | `requirements.txt` or `pyproject.toml` | `requirements.txt` with `==` pins |
   | **R** | `DESCRIPTION` or package list | `renv.lock` |
   | **Julia** | `Project.toml` | `Manifest.toml` |
   | **Stata** | Version note in README | N/A (note Stata version) |

2. **Dependency audit checklist:**

   | Check | Pass criteria | Flag if... |
   |-------|-------------|------------|
   | **Environment file exists** | At least one present | No environment specification found |
   | **Versions pinned** | All packages have exact versions | Any package uses `>=` or no version |
   | **Language version specified** | Exact version documented | Only major version or missing |
   | **System dependencies** | Documented if any | Undocumented system libraries needed |
   | **No unpinned git dependencies** | All git refs are commit hashes | Branch references used |

3. **Generate missing environment files:**
   - If `requirements.txt` missing for Python: scan imports and generate with current versions
   - If `renv.lock` missing for R: scan `library()` calls and generate package list
   - If `Manifest.toml` missing for Julia: note and flag

4. **Cross-check dependencies:**
   - Verify every imported package appears in the environment file
   - Flag any package in the environment file that is not imported (unnecessary dependency)
   - Check for known compatibility issues between pinned versions

5. **Dispatch `pipeline-validator` agent** (via Task tool):
   - Validate the dependency specification is complete
   - Check for reproducibility anti-patterns (unpinned versions, system-dependent paths)
   - Assess whether the environment can be recreated from the specification alone

### Phase 4: Pipeline Verification

Test that the pipeline produces reproducible results from a clean state.

1. **Pre-verification checks:**

   | Check | Requirement |
   |-------|------------|
   | **No manual steps** | Every step has code; no "open Excel and..." instructions |
   | **No hardcoded paths** | Paths are relative or configured; no `/Users/john/...` |
   | **Seeds set** | All random processes have explicit seeds |
   | **Output directories exist** | Scripts create output dirs or they exist in repo |
   | **Data available** | All required input data is present or documented |

2. **Clean build test** (if build system exists):
   - Delete all intermediate and output files (in a temporary copy)
   - Run the build system from scratch: `make clean && make all` or equivalent
   - Verify all expected outputs are regenerated
   - Compare regenerated outputs to originals (should match exactly or within floating-point tolerance)

3. **Script-by-script verification** (if no build system):
   - Execute scripts in documented order
   - Verify each script runs without error
   - Verify each script produces its expected outputs
   - Check that outputs match expectations (file exists, non-empty, reasonable size)

4. **Reproducibility checks:**

   | Check | Method | Pass criteria |
   |-------|--------|-------------|
   | **Deterministic output** | Run pipeline twice with same seeds | Byte-identical outputs |
   | **Seed sensitivity** | Change seed, run pipeline | Results change (confirms randomness is seeded) |
   | **Cross-platform** | Note platform-dependent code | Flag platform-specific calls |
   | **Path portability** | Check for absolute paths | All paths relative |

5. **Dispatch `reproducibility-checker` agent** (via Task tool):
   - Verify the pipeline can be replicated by an independent researcher
   - Check for hidden state dependencies (cached files, environment variables)
   - Assess the replication package against AEA Data Editor standards

6. **Verification results:**

   ```
   ┌──────────────────────────┬──────────┬────────────────────┐
   │ Check                    │ Result   │ Notes              │
   ├──────────────────────────┼──────────┼────────────────────┤
   │ All scripts run          │ Pass/Fail│ [error details]    │
   │ All outputs produced     │ Pass/Fail│ [missing outputs]  │
   │ Outputs match originals  │ Pass/Fail│ [differences]      │
   │ No hardcoded paths       │ Pass/Fail│ [flagged lines]    │
   │ Seeds documented         │ Pass/Fail│ [unseeded code]    │
   │ No manual steps          │ Pass/Fail│ [manual steps]     │
   └──────────────────────────┴──────────┴────────────────────┘
   ```

### Phase 5: Data Documentation

Document every data source with citations, access instructions, and redistribution rights.

1. **For each dataset, complete the data availability statement:**

   | Field | Required content |
   |-------|-----------------|
   | **Full citation** | Author, title, year, publisher, DOI/URL |
   | **Provider** | Organization or repository hosting the data |
   | **Access method** | Direct download, application required, purchase, API |
   | **Time period** | Date range of the data |
   | **Geographic scope** | Country, region, or level of geographic detail |
   | **Unit of observation** | Individual, firm, county, country-year, etc. |
   | **Key variables used** | List of variables extracted from this source |
   | **Redistribution rights** | Can the data be included in the package? |
   | **Access date** | When the data was downloaded/accessed |

2. **Classify data availability:**

   | Classification | Meaning | Package action |
   |---------------|---------|---------------|
   | **Public, redistributable** | Freely available, can include | Include in package |
   | **Public, not redistributable** | Freely available but terms prohibit redistribution | Provide download instructions |
   | **Restricted access** | Application required (FSRDC, WRDS, etc.) | Document access procedure |
   | **Proprietary / purchased** | Commercial data | Document source and terms |
   | **Generated** | Simulated or derived from other included data | Include generation code |

3. **Data citation format** (AEA standard):
   ```
   Author(s). Year. "Dataset Title." Publisher/Repository. DOI or URL.
   Accessed: YYYY-MM-DD.
   ```

4. **Verify completeness:**
   - Every data file used in the analysis has a documented source
   - Every restricted dataset has access instructions
   - Every citation includes a persistent identifier (DOI preferred)
   - No data file is both excluded from the package AND lacks access instructions

### Phase 6: Package Assembly

Organize all components into a submission-ready directory structure.

1. **Standard directory structure:**

   ```
   replication-package/
   ├── README.md                    # AEA-template README
   ├── LICENSE                      # Code license (MIT, BSD, etc.)
   ├── code/
   │   ├── 01_clean_data.<ext>      # Data preparation scripts
   │   ├── 02_analysis.<ext>        # Main estimation scripts
   │   ├── 03_tables.<ext>          # Table generation
   │   ├── 04_figures.<ext>         # Figure generation
   │   └── utils/                   # Helper functions
   ├── data/
   │   ├── raw/                     # Raw data (if redistributable)
   │   └── derived/                 # Intermediate/analysis datasets
   ├── output/
   │   ├── tables/                  # Generated tables
   │   └── figures/                 # Generated figures
   ├── docs/
   │   └── codebook.md              # Variable definitions
   ├── Makefile                     # Build system (or equivalent)
   └── requirements.txt             # Dependencies (language-specific)
   ```

2. **File organization rules:**

   | Rule | Rationale |
   |------|----------|
   | Number scripts by execution order | Clear pipeline sequence |
   | Separate raw from derived data | Reproducibility clarity |
   | Separate code from output | Clean rebuild possible |
   | Include only necessary files | No editor configs, caches, or temp files |
   | Use relative paths everywhere | Portability across machines |

3. **Exclusion checklist** (do NOT include):

   | Exclude | Why |
   |---------|-----|
   | `.git/` directory | Version control metadata |
   | Editor configs (`.vscode/`, `.idea/`) | IDE-specific |
   | Cache files (`__pycache__/`, `.Rhistory`) | Ephemeral |
   | Credential files (`.env`, API keys) | Security |
   | Large intermediate files (>100MB) | Size; regenerable from code |
   | Restricted data without redistribution rights | Legal |

4. **Generate build command:**
   - If `Makefile` exists: verify `make all` reproduces everything
   - If no build system: create a master script (`run_all.sh` or `run_all.py`) that executes all steps in order
   - The single-command reproduction requirement: one command must produce all outputs

5. **Final assembly checks:**

   | Check | Requirement |
   |-------|------------|
   | README complete | All sections filled, no remaining TODOs |
   | All code included | Every script in the pipeline is present |
   | All data included (or documented) | Redistributable data present; restricted data documented |
   | All outputs included | Tables and figures for comparison |
   | Dependencies specified | Exact versions pinned |
   | License included | Open-source license for code |
   | No sensitive files | No credentials, personal paths, or restricted data |

6. **Package size report:**

   ```
   ┌──────────────┬──────────┬───────┐
   │ Component    │ Files    │ Size  │
   ├──────────────┼──────────┼───────┤
   │ Code         │ N files  │ X MB  │
   │ Data (raw)   │ N files  │ X MB  │
   │ Data (derived)│ N files │ X MB  │
   │ Output       │ N files  │ X MB  │
   │ Documentation│ N files  │ X MB  │
   ├──────────────┼──────────┼───────┤
   │ TOTAL        │ N files  │ X MB  │
   └──────────────┴──────────┴───────┘
   ```

## Output Format

**Success Output:**

```
## Replication Package: <project name>

### Package Summary
- Structure: <directory layout>
- Code: <N files, languages>
- Data: <N files, X MB included, Y files restricted>
- Outputs: <N tables, M figures>

### Verification Status
| Check | Status |
|-------|--------|
| All scripts run | Pass / Fail |
| All outputs produced | Pass / Fail |
| Outputs reproducible | Pass / Fail |
| Dependencies pinned | Pass / Fail |
| No hardcoded paths | Pass / Fail |
| README complete | Pass / Fail |

### Data Availability
| Dataset | Classification | Included | Citation |
|---------|---------------|----------|----------|
| ... | Public / Restricted | Yes / No | ... |

### Agent Reviews
- pipeline-validator: [key findings]
- reproducibility-checker: [key findings]

### Files
- Package: replication-package/
- README: replication-package/README.md
- Build command: `make all` or `bash run_all.sh`

### Remaining TODOs (if any)
1. [items requiring researcher attention]
```

**Failure Output:**

```
## Replication Package Incomplete

### Blocking Issues
1. <critical issue preventing package completion>
2. <missing component>

### Completed Components
- [what was successfully assembled]

### Required Actions
1. <specific action to resolve blocking issue>
2. <what the researcher needs to provide>
```

## Routes To

- `/estimate` — run estimation to generate reproducible results
- `/tabulate` — generate publication-ready tables for the package
- `/diagnose` — run diagnostics to include in the package
- `/workflows:compound` — capture reproducibility patterns in knowledge base

## AEA Compliance Checklist Reference

| Requirement | Source | Status |
|------------|--------|--------|
| Data Availability Statement | AEA Policy (2019) | Required |
| Computational Requirements | AEA Template | Required |
| Program descriptions | AEA Template | Required |
| Instructions for replication | AEA Template | Required |
| Data citations | AEA Policy | Required |
| Code license | Best practice | Recommended |
| Single-command replication | AEA Data Editor | Strongly recommended |
| Expected runtime | AEA Template | Required |
| Software versions | AEA Template | Required |

## Key Packages Reference

| Language | Environment tools |
|----------|-----------------|
| Python | pip + requirements.txt, conda + environment.yml, poetry + pyproject.toml |
| R | renv + renv.lock, packrat, DESCRIPTION + NAMESPACE |
| Julia | Pkg + Project.toml + Manifest.toml |
| Stata | `version` command, `ssc install` list |
| Multi-language | Docker, Singularity, Nix, Make + language-specific envs |
