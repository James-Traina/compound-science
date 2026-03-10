---
name: tabulate
description: "Generate publication-ready tables from estimation results, summary statistics, or Monte Carlo output"
argument-hint: "<regression results, summary statistics, data file, or table specification>"
allowed-tools: Read, Write, Edit, Bash
---

# Publication Table Pipeline

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

Generate publication-ready tables from estimation results, summary statistics, Monte Carlo output, or raw data. Handles standard academic formats: stargazer-style regressions, descriptive statistics, simulation results, balance tables, transition matrices, and custom layouts. Produces LaTeX (default), markdown, HTML, or CSV output.

## Input Document

<input_document> #$ARGUMENTS </input_document>

**If no input:** Search for estimation results (model objects, regression output files), summary statistics code, or Monte Carlo results in the codebase. If found, use the most recently modified relevant file. If nothing found, state "No table content found. Provide regression results, a data file, or a description of the desired table." and stop.

## Execution Workflow

### Phase 1: Detect Content Type

Identify what kind of table is needed from the input.

1. **Scan input for content signals:**

   | Content type | Detection signals | Table format |
   |-------------|-------------------|-------------|
   | **Regression results** | Model objects, coefficient estimates, SEs, R², N | Stargazer-style coefficient table |
   | **Summary statistics** | `describe()`, `summary()`, mean/sd/min/max | Descriptive statistics panel |
   | **Monte Carlo output** | Bias, RMSE, coverage, replications | Simulation results table |
   | **Balance table** | Treatment/control means, difference, p-values | Balance / covariate comparison |
   | **Transition matrix** | State transitions, Markov chains, mobility | Matrix with row/column labels |
   | **First-stage results** | IV first stage, instrument coefficients, F-stats | First-stage regression table |
   | **Raw data** | DataFrame, CSV, panel data | Auto-detect appropriate table type |
   | **Custom specification** | User describes table layout | Build to specification |

2. **Extract table content:**
   - Parse model objects, result files, or data sources
   - Identify all variables, coefficients, standard errors, test statistics
   - Determine the number of columns (specifications, samples, methods)
   - Identify the number of panels (if multi-panel table needed)

3. **Confirm table dimensions:**

   | Dimension | Source |
   |-----------|--------|
   | **Rows** | Variables / parameters / statistics |
   | **Columns** | Specifications / samples / estimators |
   | **Panels** | Grouped sets of rows (e.g., Panel A: Means, Panel B: Regressions) |
   | **Footer rows** | N, R², F-stat, fixed effects indicators, controls |

### Phase 2: Format Selection

Choose the output format based on context and user preference.

1. **Format decision:**

   | Format | When to use | File extension |
   |--------|------------|---------------|
   | **LaTeX** | Default for academic papers; journal submission | `.tex` |
   | **Markdown** | README files, GitHub display, quick review | `.md` |
   | **HTML** | Web display, presentations, interactive docs | `.html` |
   | **CSV** | Data exchange, spreadsheet import, archival | `.csv` |

   - Default to LaTeX unless the project context suggests otherwise
   - If the project contains `.tex` files: use LaTeX
   - If the project is primarily markdown: use markdown
   - If the user specifies a format: use that format

2. **LaTeX configuration:**

   | Setting | Default | Notes |
   |---------|---------|-------|
   | **Document class** | Standalone table (no preamble) | Include `\usepackage` only if standalone |
   | **Table environment** | `table` with `tabular` | Use `longtable` if > 40 rows |
   | **Column alignment** | `l` for labels, `c` for numeric | Right-align if mixed-width numbers |
   | **Booktabs** | Yes (`\toprule`, `\midrule`, `\bottomrule`) | Never use `\hline` |
   | **Font size** | `\small` or `\footnotesize` | Adjust to fit page width |
   | **Float placement** | `[htbp]` | Standard float |
   | **Caption** | Include with `\label` | Label format: `tab:<name>` |

3. **Number formatting defaults:**

   | Content | Decimal places | Format |
   |---------|---------------|--------|
   | Coefficients | 3 | Plain number |
   | Standard errors | 3 | In parentheses |
   | t-statistics | 2 | In brackets (if shown) |
   | p-values | 3 | Plain or significance stars |
   | R² | 3 | Plain number |
   | N (sample size) | 0 | With comma separators |
   | Percentages | 1 | With % symbol |
   | Dollar amounts | 0-2 | With $ and commas |

### Phase 3: Table Generation

Build the table with standard academic formatting conventions.

1. **Regression table (stargazer-style):**

   ```
   Structure:
   - Header row: specification labels (1), (2), (3), ...
   - Dependent variable row (if varies across columns)
   - Coefficient rows: estimate with stars
   - SE rows: in parentheses, directly below coefficient
   - Separator line (midrule)
   - Footer: N, R², Adjusted R², F-statistic
   - Fixed effects indicators: Yes/No row for each FE dimension
   - Controls indicator: Yes/No
   - Clustering level
   - Significance note: * p<0.10, ** p<0.05, *** p<0.01
   ```

   Formatting rules:
   - Stars on coefficients, not on SEs
   - SEs in parentheses: `(0.287)`
   - Align decimal points across columns
   - Negative numbers: use minus sign, not parentheses (economics convention)
   - Omit coefficients for control variables if many (note "Controls: Yes" instead)
   - Fixed effects as Yes/No indicators, not as coefficient rows

2. **Summary statistics table:**

   ```
   Structure:
   - Variable names in first column
   - Statistics columns: Mean, SD, Min, P25, Median, P75, Max, N
   - Panel structure if multiple groups (e.g., Panel A: Full sample, Panel B: Treatment)
   ```

   Formatting rules:
   - Report mean and standard deviation for continuous variables
   - Report frequency and percentage for categorical variables
   - Include N (non-missing) for each variable if missingness varies
   - Order variables logically: outcome first, then treatment, then controls

3. **Monte Carlo results table:**

   ```
   Structure:
   - Rows: estimator × sample size combinations
   - Columns: Bias, RMSE, MAE, Coverage(95%), Coverage(90%), Size, Power
   - Panel by estimator or by DGP parameter variation
   - Footer: R (replications), base seed
   ```

   Formatting rules:
   - Bias: report sign explicitly (positive or negative)
   - Coverage: bold if outside [0.90, 0.98] for 95% CI
   - Size: bold if outside [0.03, 0.07] for 5% nominal level
   - RMSE: bold the lowest value in each N row (best estimator)

4. **Balance table:**

   ```
   Structure:
   - Variable names in first column
   - Treatment mean, Control mean, Difference, SE(Diff), p-value
   - Optionally: Normalized difference (Imbens & Rubin)
   - Footer: N (treatment), N (control)
   ```

   Formatting rules:
   - Stars on the difference column
   - Flag normalized differences > 0.25 (Imbens & Rubin threshold)
   - Include joint F-test for balance at the bottom

5. **Transition matrix:**

   ```
   Structure:
   - Row labels: origin states
   - Column labels: destination states
   - Cell values: transition probabilities or counts
   - Row totals (should sum to 1.0 for probabilities)
   ```

### Phase 4: Multi-Panel Assembly

Combine multiple table components into a single publication-ready table.

1. **Panel detection:**
   - If input contains multiple related result sets: assemble as panels
   - If comparing across samples, methods, or time periods: separate panels

2. **Panel organization:**

   | Pattern | Panel structure |
   |---------|---------------|
   | **Multiple outcomes** | Panel A: Outcome 1, Panel B: Outcome 2 |
   | **Multiple samples** | Panel A: Full sample, Panel B: Subsample 1, Panel C: Subsample 2 |
   | **Multiple methods** | Panel A: OLS, Panel B: IV, Panel C: GMM |
   | **Multiple time periods** | Panel A: Pre-period, Panel B: Post-period |
   | **Extensive + intensive margin** | Panel A: Participation, Panel B: Conditional on participation |

3. **Cross-specification alignment:**
   - Ensure variable names are consistent across panels
   - Align columns across panels (same specification in same column position)
   - Use consistent number formatting across all panels
   - Repeat column headers only at the top, not for each panel

4. **Companion tables:**
   - If the main table is a regression: generate a companion summary statistics table
   - If the main table is balance: generate a companion histogram or distribution comparison
   - Store companion tables as separate files but note the relationship

5. **Table sizing:**
   - If table exceeds standard page width: suggest landscape orientation or font reduction
   - If table exceeds one page: suggest splitting into separate tables or using longtable
   - Maximum recommended columns: 8-10 for letter/A4 paper
   - Maximum recommended rows before splitting: 40-50

### Phase 5: Output

Write table files and provide formatted code blocks.

1. **Generate output files:**

   | Format | File location | Contents |
   |--------|--------------|----------|
   | **LaTeX** | `tables/<name>.tex` | Standalone table (includable via `\input{}`) |
   | **Markdown** | `tables/<name>.md` | GitHub-compatible markdown table |
   | **HTML** | `tables/<name>.html` | Styled HTML table |
   | **CSV** | `tables/<name>.csv` | Plain CSV for data exchange |

   - Create `tables/` directory if it does not exist
   - Name files descriptively: `reg-main-results.tex`, `sumstats-full-sample.tex`, `mc-bias-coverage.tex`

2. **LaTeX integration code:**
   ```latex
   % Include in your paper:
   \input{tables/<name>.tex}

   % Or with figure environment:
   \begin{table}[htbp]
   \centering
   \caption{<caption text>}
   \label{tab:<label>}
   \input{tables/<name>.tex}
   \end{table}
   ```

3. **Provide inline code block** — display the full table in the output for immediate review

4. **Generate reproduction code** (in the project's language):
   - Python: pandas DataFrame formatting or `stargazer` package call
   - R: `stargazer()`, `modelsummary()`, or `kableExtra` call
   - Stata: `esttab` or `outreg2` command
   - Include the exact command to regenerate the table from the estimation objects

5. Before finalizing, consider dispatching `results-verifier` to verify that table numbers match the underlying code output.

6. **Quality checks before output:**

   | Check | Requirement |
   |-------|------------|
   | **Decimal alignment** | All numbers in a column align at the decimal point |
   | **Star placement** | Stars attached to coefficients, never to SEs |
   | **SE format** | Consistent parentheses or brackets throughout |
   | **N matches** | Sample sizes sum correctly across panels |
   | **Column labels** | Clear and concise, no abbreviation ambiguity |
   | **Significance note** | Present at bottom if stars used |
   | **Source note** | Include data source if relevant |
   | **Compiles** | LaTeX compiles without errors (check for special characters) |

## Output Format

**Success Output:**

```
## Table Generated: <table name>

### Table Preview
<formatted table displayed inline>

### Files Written
- Table: tables/<name>.<ext>
- [Companion table: tables/<companion>.<ext>]

### Integration
<LaTeX \input command or markdown include syntax>

### Reproduction Code
<code to regenerate the table from source data/results>

### Formatting Notes
- Format: <LaTeX / markdown / HTML / CSV>
- Panels: <count and description>
- Specifications: <column descriptions>
- Significance: * p<0.10, ** p<0.05, *** p<0.01
```

**Failure Output:**

```
## Table Generation Failed

### Issue
<description of why the table could not be generated>

### Available Data
- <what was found in the input>
- <what is missing>

### Suggested Fixes
1. <specific action to provide needed data>
2. <alternative table that could be generated>
```

## Routes To

- `/estimate` — run estimation to generate results for tabulation
- `/simulate` — run Monte Carlo study to generate simulation results
- `/diagnose` — run diagnostics on the estimation before tabulating
- `/workflows:compound` — capture table templates in knowledge base

## Standard Table Templates Reference

| Table type | Typical context | Key elements |
|-----------|-----------------|-------------|
| **Main regression** | Core paper results | 3-6 specs, baseline through full controls |
| **First stage** | IV papers | Instrument coefficients, F-stats, partial R² |
| **Summary statistics** | Descriptive section | Full sample + subsamples |
| **Balance table** | RCT or quasi-experimental | Treatment vs control, normalized differences |
| **Robustness** | Appendix | Alternative specs, samples, methods |
| **Heterogeneity** | Subgroup analysis | Interactions or split samples |
| **Monte Carlo** | Simulation section | Bias, RMSE, coverage by N and estimator |
| **Event study** | DiD papers | Pre/post coefficients and CIs |
| **Transition matrix** | Dynamic/Markov models | State-to-state probabilities |

## Key Packages Reference

| Language | Packages |
|----------|----------|
| Python | pandas, stargazer, statsmodels.iolib, tabulate, pylatex |
| R | stargazer, modelsummary, kableExtra, xtable, huxtable, gt |
| Julia | PrettyTables.jl, DataFrames.jl, Latexify.jl |
| Stata | esttab, outreg2, estout, tabstat, table |
