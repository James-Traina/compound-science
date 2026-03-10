---
name: deepen-plan
description: "Enrich an existing research plan by spawning parallel specialist agents — literature scout, identification critic, benchmark researcher, and methods explorer — and synthesizing their findings back into the plan as Research Insights subsections."
argument-hint: "[plan file or paste plan content]"
allowed-tools: Read, Grep, Glob, Bash, Agent
---

# Deepen Plan: Parallel Research Enrichment

You have been invoked after `/plan` has produced a research plan document. Your job is to enrich it by running parallel specialist research against the plan's key decisions and synthesizing the findings back.

## Phase 1: Parse the Plan

Read the plan (from argument, from `docs/plans/` directory, or from conversation context). Identify:
- The **identification strategy** (IV? DiD? RDD? Structural? Observational?)
- The **estimators** named (GMM? NFXP? BLP? Callaway-Sant'Anna? etc.)
- The **data sources** mentioned
- The **target parameters** (ATE, ATT, LATE, structural parameter?)
- Any **open questions** flagged by the plan author

## Phase 2: Spawn Parallel Agents

Launch all four agents simultaneously against the plan. Pass each agent the full plan text and a specific research question:

**Agent 1 — `literature-scout`**
> "Given this research plan, identify: (1) 3-5 papers this work should cite that may be missing; (2) any recent methods advances (post-2022) that supersede or complement the planned approach; (3) the 1-2 most important prior applications of this exact identification strategy."

**Agent 2 — `identification-critic`**
> "Given this research plan, identify: (1) the weakest link in the identification argument as written; (2) any unstated regularity conditions; (3) whether the planned estimator correctly targets the stated estimand; (4) one alternative identification strategy worth considering."

**Agent 3 — `benchmark-researcher`**
> "Given this research plan, identify: (1) calibration targets or stylized facts relevant to the structural parameters (if any); (2) what magnitudes from similar papers should the key estimates be compared against; (3) reference values for key parameters from the empirical literature."

**Agent 4 — `methods-explorer`**
> "Given this research plan, identify: (1) the best software implementation of the planned estimator (package, version, known bugs); (2) any computational considerations (convergence, dimensionality, initialization); (3) one alternative estimator that may be more robust or efficient given the stated data structure."

## Phase 3: Synthesize Findings

Wait for all four agents to complete. For each section of the plan that the agents commented on, add a `### Research Insights` subsection with:

```
### Research Insights
**Literature** (from literature-scout): [key finding]
**Identification** (from identification-critic): [key finding]
**Benchmarks** (from benchmark-researcher): [key finding, if applicable]
**Methods** (from methods-explorer): [key finding]
```

Keep each insight to 2-3 sentences. Flag items requiring immediate attention before estimation begins with `⚠️`.

## Phase 4: Output

Produce the enriched plan as a markdown document. Save to `docs/plans/plan-deepened-[date].md` if a plans directory exists.

End with a summary table:

```
| Agent | Key finding | Action required |
|-------|------------|-----------------|
| literature-scout | [finding] | [yes/no] |
| identification-critic | [finding] | [yes/no] |
| benchmark-researcher | [finding] | [yes/no] |
| methods-explorer | [finding] | [yes/no] |
```
