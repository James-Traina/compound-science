---
name: visualize
description: "Generate publication-quality research visualization code: event studies, RD plots, coefficient plots, power curves, densities"
argument-hint: "<visualization type, estimation results, or data to plot>"
---

# Research Visualization Pipeline

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

Generate publication-quality visualization code for standard research plots. Detects the visualization need from the input, selects the appropriate plotting framework, generates code with clean academic defaults (no gridlines, serif fonts, grayscale-friendly palettes), and produces standard research plots: event studies with confidence bands, RD plots with local polynomial fits, coefficient plots, power curves, density comparisons, and more.

## Input Document

<input_document> #$ARGUMENTS </input_document>

**If no input:** Search for estimation results, regression output, or data files that suggest a natural visualization. If event study coefficients are found, generate an event study plot. If RD data is found, generate an RD plot. If multiple specifications exist, generate a coefficient comparison plot. If nothing relevant is found, state "No visualization target found. Provide estimation results, a data file, or describe the desired plot (e.g., 'event study', 'RD plot', 'coefficient plot')." and stop.

## Execution Workflow

### Phase 1: Detect Visualization Need

Identify which plot type is appropriate from the input context.

1. **Classify the visualization:**

   | Plot type | Detection signals | Typical context |
   |----------|-------------------|----------------|
   | **Event study** | Time-relative coefficients, leads and lags, pre/post indicators | DiD, staggered treatment |
   | **RD plot** | Running variable, cutoff value, treatment assignment | Regression discontinuity |
   | **Coefficient plot** | Multiple estimates with CIs, specification comparison | Robustness, heterogeneity |
   | **Power curve** | Sample sizes, effect sizes, rejection rates | Study design, grant proposals |
   | **Density / distribution** | Continuous variable, treatment/control groups | Balance, McCrary test |
   | **Binned scatter** | Two continuous variables, conditional means | Nonlinear relationships |
   | **Kaplan-Meier / survival** | Duration data, hazard rates, censoring | Duration models |
   | **Heat map / matrix** | Correlation matrix, transition probabilities | Descriptive, model diagnostics |
   | **Time series** | Variable over time, multiple series | Trends, structural breaks |
   | **Geographic / map** | Spatial data, regional variation | Spatial analysis |

2. **Extract plot inputs:**

   | Input type | What to extract |
   |-----------|----------------|
   | **Estimation results** | Point estimates, SEs, CIs, variable names |
   | **Data file** | Variable names, data types, sample size |
   | **Simulation output** | Metrics by parameter grid, performance curves |
   | **User description** | Desired plot type, customization requests |

3. **Determine plot count:**
   - Single plot: one visualization requested or naturally implied
   - Multi-panel: related plots that should appear together (e.g., event study + pre-trend test)
   - Figure series: multiple independent plots (e.g., RD plots for each outcome)

### Phase 2: Select Framework

Choose the plotting framework based on the project's language and existing code.

1. **Framework selection logic:**

   | Project language | Default framework | Alternative |
   |-----------------|-------------------|-------------|
   | **Python** | matplotlib + seaborn | plotly (interactive) |
   | **R** | ggplot2 | base R, plotly |
   | **Julia** | Plots.jl (GR backend) | Makie.jl |
   | **Stata** | twoway / graph | coefplot |

   - If the project already uses a plotting library: use that library for consistency
   - If no existing plots: use the default for the project's primary language
   - If the user specifies a framework: use that framework

2. **Publication defaults** (applied to all frameworks):

   | Setting | Value | Rationale |
   |---------|-------|----------|
   | **Font family** | Computer Modern / Times / serif | Matches LaTeX documents |
   | **Font size (axis labels)** | 11-12pt | Readable at journal print size |
   | **Font size (tick labels)** | 9-10pt | Smaller than axis labels |
   | **Font size (title)** | 12-14pt | Largest element (or omit for papers) |
   | **Figure size** | 6.5" × 4.5" (single column) | Fits standard journal column |
   | **Figure size** | 13" × 4.5" (full width, two panels) | Fits full page width |
   | **DPI** | 300 (raster), vector preferred | Publication print quality |
   | **Background** | White, no gray background | Clean academic look |
   | **Grid lines** | None (or very light gray if data is dense) | Reduce visual clutter |
   | **Axis lines** | Bottom and left only (no top/right box) | Tufte-style minimalism |
   | **Color palette** | Grayscale-friendly with markers | Readable in B&W print |
   | **Line styles** | Vary line dash patterns + markers | Distinguishable without color |
   | **Legend** | Inside plot area or below, no box border | Minimal chrome |
   | **File format** | PDF (vector) primary, PNG (300 DPI) secondary | Vector for papers, raster for slides |

3. **Color palette specification:**

   | Use case | Palette |
   |----------|---------|
   | **2 groups** | Black + medium gray | Distinguishable and printable |
   | **3-5 groups** | Black, dark gray, medium gray, light gray, white with border | Grayscale range |
   | **Sequential** | Single-hue gradient (e.g., light blue to dark blue) | Ordered data |
   | **Diverging** | Blue-white-red (colorblind-safe) | Deviations from center |
   | **Qualitative (if color)** | Okabe-Ito or ColorBrewer Set2 | Colorblind accessible |

### Phase 3: Generate Code

Write complete, runnable plotting code for the detected visualization type.

1. **Event study plot:**

   ```
   Components:
   - X-axis: time relative to treatment (periods -K to +L)
   - Y-axis: coefficient estimates
   - Point estimates: markers at each period
   - Confidence intervals: vertical bars or shaded bands (95% default)
   - Reference line: horizontal at zero
   - Reference line: vertical at period -1 (last pre-treatment)
   - Pre-trend test p-value: annotated on plot or in caption
   ```

   Key decisions:
   - Normalize to period -1 (coefficient = 0, omitted category)
   - Show 95% CI (default) and optionally 90% CI in lighter shade
   - If staggered treatment: use Callaway-Sant'Anna or Sun-Abraham aggregation
   - Include pre-trend test result as annotation or caption note
   - X-axis label: "Periods relative to treatment"
   - Y-axis label: "Estimated effect" or parameter-specific label

2. **RD plot:**

   ```
   Components:
   - X-axis: running variable (centered at cutoff)
   - Y-axis: outcome variable
   - Binned scatter: local means within bins on each side
   - Local polynomial fit: separate curves on each side of cutoff
   - Confidence band: shaded 95% CI around each local polynomial
   - Cutoff line: vertical dashed line at threshold
   - Treatment effect: annotated jump at cutoff
   ```

   Key decisions:
   - Bin width: use IMSE-optimal (Calonico, Cattaneo, Titiunik) or evenly spaced
   - Polynomial order: local linear (default) or local quadratic
   - Bandwidth: IMSE-optimal or MSE-optimal (report the bandwidth used)
   - Use `rdplot` (R) or `rdrobust` conventions for standard presentation
   - Include manipulation test (McCrary/Cattaneo-Jansson-Ma) as companion density plot

3. **Coefficient plot:**

   ```
   Components:
   - Y-axis: variable names or specification labels
   - X-axis: coefficient values
   - Point estimates: markers
   - Confidence intervals: horizontal lines (95% and 90%)
   - Reference line: vertical at zero
   - Grouping: panel or color by category if many coefficients
   ```

   Key decisions:
   - Horizontal layout (coefficients on x-axis) is standard for many variables
   - Vertical layout for comparing few coefficients across many specifications
   - Order variables by magnitude or logical grouping (not alphabetically)
   - Use different marker shapes for different specifications
   - Thick line for 90% CI, thin line for 95% CI (or vice versa)

4. **Power curve:**

   ```
   Components:
   - X-axis: sample size (N) or minimum detectable effect (MDE)
   - Y-axis: power (probability of rejecting H0)
   - Curves: one per significance level or effect size
   - Reference line: horizontal at 0.80 (conventional power threshold)
   - Reference line: horizontal at nominal significance level
   ```

   Key decisions:
   - Log scale for x-axis if sample size range is large
   - Show curves for α = 0.05 (primary) and α = 0.01 (secondary)
   - Annotate the sample size needed for 80% power
   - If multiple effect sizes: use line dash patterns to distinguish

5. **Density / distribution plot:**

   ```
   Components:
   - X-axis: variable values
   - Y-axis: density (kernel density estimate)
   - Curves: one per group (treatment/control, pre/post)
   - Vertical lines: means for each group (dashed)
   - Legend: group labels
   ```

   Key decisions:
   - Kernel: Gaussian (default), Epanechnikov for bounded support
   - Bandwidth: Silverman's rule or Sheather-Jones
   - For McCrary test: use bin counts with local polynomial fit at cutoff
   - Normalize densities if group sizes differ substantially
   - Rug plot along x-axis for small samples (N < 200)

6. **Binned scatter plot:**

   ```
   Components:
   - X-axis: binned values of X variable (equal-sized bins)
   - Y-axis: mean of Y within each bin
   - Points: bin means
   - Fit line: linear or polynomial (residualized if controls)
   - Confidence band: around fit line
   ```

   Key decisions:
   - Number of bins: 20 (default), adjust for sample size
   - Equal-sized bins (same number of observations) vs equal-width bins
   - If residualizing: partial out controls before binning (Cattaneo et al., 2024)
   - Report the number of bins and binning method

### Phase 4: Standard Research Plots

Apply research-field-specific conventions and compile multi-panel figures.

1. **Pre-trend test visualization** (companion to event study):
   - Plot cumulative pre-treatment coefficients with joint confidence band
   - Or: plot F-statistic for joint pre-trend test across different pre-periods
   - Include as a sub-panel or companion figure

2. **Specification curve** (companion to robustness):
   - Top panel: sorted point estimates with CIs across all specifications
   - Bottom panel: indicator matrix showing which specification choices are active
   - Highlight the baseline specification
   - Shade the median and interquartile range of estimates

3. **Multi-panel figure assembly:**

   | Layout | When to use |
   |--------|------------|
   | **Side-by-side (1×2)** | Two related outcomes or before/after |
   | **Stacked (2×1)** | Event study + pre-trend test |
   | **Grid (2×2)** | Four related subgroup analyses |
   | **Grid (2×3 or 3×2)** | Six robustness variants |

   - Use consistent axis scales across panels when comparing
   - Label panels as (a), (b), (c) or Panel A, Panel B, Panel C
   - Share legends across panels when categories are the same
   - Ensure font sizes are readable at the final print size

4. **LaTeX figure environment:**
   ```latex
   \begin{figure}[htbp]
   \centering
   \includegraphics[width=\textwidth]{figures/<filename>.pdf}
   \caption{<Descriptive caption with data source and sample information>}
   \label{fig:<label>}
   \begin{figurenotes}
   Notes: <Methodological notes, confidence level, sample restrictions>
   \end{figurenotes}
   \end{figure}
   ```

5. **Accessibility checks:**
   - All information encoded in color is also encoded in shape or line style
   - Sufficient contrast between elements (WCAG AA minimum)
   - Alt text provided for HTML output
   - Legend labels are descriptive (not just "Series 1", "Series 2")

### Phase 5: Output

Write code files, generate figures, and provide LaTeX integration.

1. **Write visualization code:**
   - Save to `code/figures/<figure-name>.<ext>` or project-appropriate location
   - Include all necessary imports at the top
   - Include data loading (from the project's data files)
   - Include all plot customization (no external style files required)
   - Include `savefig()` / `ggsave()` / equivalent at the end
   - Code should be runnable as a standalone script

2. **Generate figure files:**

   | Format | File | Use |
   |--------|------|-----|
   | **PDF** | `figures/<name>.pdf` | Paper inclusion (vector, scalable) |
   | **PNG** | `figures/<name>.png` | Slides, web, README (300 DPI) |
   | **EPS** | `figures/<name>.eps` | Some journal submission systems |

   - Create `figures/` directory if it does not exist
   - Always produce PDF as primary output
   - Produce PNG as secondary for preview

3. **Provide inline preview:**
   - Display the key parameters of the generated plot
   - Show the code block for immediate review
   - Note any data dependencies for running the code

4. **LaTeX integration:**
   - Provide the complete `\begin{figure}...\end{figure}` environment
   - Include a draft caption with placeholder for researcher refinement
   - Include `\label{fig:...}` for cross-referencing
   - Note the required `\usepackage{graphicx}` (and booktabs, caption, etc.)

5. **Quality checklist before output:**

   | Check | Requirement |
   |-------|------------|
   | **Axis labels present** | Both axes have descriptive labels with units |
   | **No default title** | Remove auto-generated titles (titles go in captions) |
   | **Legend readable** | Legend entries are descriptive, legend is positioned clearly |
   | **Font consistent** | All text elements use the same font family |
   | **Grayscale readable** | Plot is interpretable in black and white |
   | **No chart junk** | No unnecessary gridlines, borders, or decorations |
   | **Aspect ratio** | Width:height ratio appropriate for the data |
   | **Resolution** | Vector (PDF) or >= 300 DPI (PNG) |
   | **File size** | Reasonable for the content (<5 MB for vector) |

## Output Format

**Success Output:**

```
## Visualization Generated: <plot type>

### Plot Description
- Type: <event study / RD / coefficient plot / ...>
- Framework: <matplotlib / ggplot2 / Plots.jl>
- Panels: <count and layout>

### Code
<full code block for generating the figure>

### Files Written
- Code: code/figures/<name>.<ext>
- Figure: figures/<name>.pdf
- Figure: figures/<name>.png

### LaTeX Integration
\begin{figure}[htbp]
...
\end{figure}

### Customization Notes
- <how to adjust colors, labels, axis limits>
- <how to add/remove panels>
- <data requirements for regeneration>
```

**Failure Output:**

```
## Visualization Failed

### Issue
<description of why the plot could not be generated>

### Available Data
- <what was found>
- <what is missing for the requested plot>

### Suggested Alternatives
1. <alternative plot type that could be generated>
2. <data needed to produce the requested plot>
```

## Routes To

- `/tabulate` — generate companion tables for the figures
- `/estimate` — run estimation to generate plottable results
- `/sensitivity` — generate specification curve visualization
- `/workflows:compound` — capture visualization templates in knowledge base

## Common Plot Types Reference

| Plot | Field | Key reference |
|------|-------|--------------|
| Event study | DiD / policy evaluation | Freyaldenhoven et al. (2019) |
| RD plot | Regression discontinuity | Cattaneo, Idrobo & Titiunik (2020) |
| Coefficient plot | Robustness / heterogeneity | Jann (2014) |
| Specification curve | Robustness | Simonsohn et al. (2020) |
| Binned scatter | Nonlinear relationships | Cattaneo et al. (2024) |
| McCrary density | RD manipulation test | McCrary (2008) |
| Power curve | Study design | Cohen (1988) |
| Survival curve | Duration analysis | Kaplan & Meier (1958) |
| Funnel plot | Meta-analysis | Egger et al. (1997) |

## Key Packages Reference

| Language | Packages |
|----------|----------|
| Python | matplotlib, seaborn, plotly, statsmodels.graphics, rdrobust |
| R | ggplot2, rdrobust, rdplot, coefplot, fixest::coefplot, survminer, binsreg |
| Julia | Plots.jl, Makie.jl, StatsPlots.jl |
| Stata | twoway, coefplot, rdplot, binscatter |
