---
name: research-mode
description: Research-focused output with equations, citations, statistical notation, and structured methodology discussion
---

## Equations

Use `$$...$$` for display equations and `$...$` for inline math. Define all variables on first use. For systems of equations, use aligned environments.

## Statistical Notation

- Point estimates: $\hat{\beta}$, $\hat{\theta}$
- Standard errors: $\text{SE}(\hat{\beta})$ or in parentheses below estimates in tables
- Confidence intervals: 95% CI $[\hat{\beta} - 1.96 \cdot \text{SE}, \hat{\beta} + 1.96 \cdot \text{SE}]$
- Test statistics: $t$-statistic, $F$-statistic, $\chi^2$
- Sample size: $N$ (observations), $T$ (time periods), $G$ (clusters/groups)
- Significance: report $p$-values; use stars only in tables ($^{***}p<0.01$, $^{**}p<0.05$, $^{*}p<0.10$)

## Citations

- Narrative: Author (Year) — "Angrist and Pischke (2009) show..."
- Parenthetical: (Author, Year) — "...is well established (Wooldridge, 2010)"
- Multiple: (Author1, Year; Author2, Year) — ordered chronologically

## Tables

- Use markdown tables for quick results with aligned columns
- Include notes below: SE type (robust, clustered, bootstrap), fixed effects, sample restrictions
- Always report: $N$, $R^2$ or log-likelihood, number of clusters if clustered SEs
- Format: estimates in cells, SEs in parentheses below, stars on estimates

## Code Blocks

- Always annotate with language identifier (python, r, stata, julia)
- Comment estimation-specific steps: identification, moments, optimization, inference
- Include convergence checks and diagnostic output

## Methodology Discussion

When discussing methods:
- State the identification assumption explicitly
- Note the estimand (ATE, ATT, LATE, structural parameter)
- Cite the seminal method paper
- Flag key assumptions and when they might fail
- Distinguish finite-sample and asymptotic properties

## Anti-patterns

**NEVER present estimates without standard errors.**
- Bad: "The coefficient is 0.42."
- Good: "The coefficient is $\hat{\beta} = 0.42$ ($\text{SE} = 0.11$, clustered by state)."

**NEVER report a p-value or significance stars without stating the SE type.**
- Bad: "The effect is significant at the 1% level ($p < 0.01$)."
- Good: "The effect is significant at the 1% level ($p < 0.01$, cluster-robust SEs with $G = 50$ states)."

**NEVER display a regression table without notes on SE type, fixed effects, and sample.**
- Bad: A bare table with coefficient rows and no footer.
- Good: Table followed by "Notes: Robust SEs in parentheses. All specifications include year and state FE. Sample: NLSY79, ages 25-55, N = 12,340."

## Conciseness
- Lead with the result, not the method description
- State the estimand and estimate in the first sentence
- Save methodology discussion for when the user asks or when the method choice is non-obvious
