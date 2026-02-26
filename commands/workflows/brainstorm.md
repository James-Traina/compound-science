---
name: workflows:brainstorm
description: Explore methodological approaches through structured analysis before planning implementation
argument-hint: "<research question or methodological problem>"
---

# Brainstorm a Research Approach or Methodological Decision

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

**Note: The current year is 2026.** Use this when dating brainstorm documents.

Brainstorming helps answer **WHAT** approach to take through structured analysis. It precedes `/workflows:plan`, which answers **HOW** to implement it.

**Process knowledge:** Load the `brainstorming` skill for detailed question techniques, approach exploration patterns, and parsimony principles.

## Research Question

<feature_description> #$ARGUMENTS </feature_description>

**If the research question above is empty:** Infer the question from recent context — open files, recent conversation, or the project's estimation code. If no context is available, state "No research question provided" and stop.

## Execution Flow

### Phase 0: Assess Scope

Evaluate whether brainstorming is needed based on the research question.

**Clear requirements indicators:**
- Specific estimator or method already chosen
- Referenced existing implementation to follow
- Described exact identification strategy
- Constrained, well-defined methodological scope

**If requirements are already clear:**
Skip brainstorming and note: "Requirements are detailed enough to proceed directly to planning. Run `/workflows:plan` to continue." Then stop.

**If requirements need exploration:** Proceed to Phase 1.

### Phase 1: Understand the Problem

#### 1.1 Codebase and Literature Research

Run a targeted scan to understand existing patterns and related methods:

- Task methods-researcher("Understand existing methodological patterns and approaches related to: <research_question>")

Focus on: existing estimation code, identification strategies used in this project, methodology documented in papers or notes.

#### 1.2 Problem Decomposition

Analyze the research question systematically without user interaction:

1. **Core question**: What is the fundamental methodological decision being made?
2. **Constraints**: What data limitations, computational budgets, or identification requirements constrain the choice?
3. **Prior art**: What has this project already done that's similar? What methods are established in the literature?
4. **Success criteria**: What would a good solution look like? (e.g., consistent estimation, reasonable computational cost, testable identification)

Document findings from the research agent and decomposition. If the question is ambiguous, pick the most natural interpretation given the project context and note the assumption.

### Phase 2: Compare Approaches

Propose **2-3 concrete methodological approaches** based on research and analysis.

For each approach, provide:

| Criterion | Approach A | Approach B | Approach C |
|-----------|-----------|-----------|-----------|
| **Description** | 2-3 sentence summary | 2-3 sentence summary | 2-3 sentence summary |
| **Theoretical properties** | Consistency, efficiency, robustness to misspecification | ... | ... |
| **Identification requirements** | What assumptions are needed? How testable are they? | ... | ... |
| **Computational cost** | Estimation time, convergence difficulty, parallelizability | ... | ... |
| **Data requirements** | Sample size needs, variable availability, panel structure | ... | ... |
| **Software availability** | Packages (Python/R/Julia), maturity, documentation | ... | ... |
| **Monte Carlo evidence** | Finite-sample performance from methodology literature | ... | ... |

**Recommendation:** Select the simplest approach that satisfies the identification requirements. Apply parsimony — prefer well-understood methods with established software implementations over novel approaches unless the research question specifically demands novelty.

Document why the recommended approach was chosen and what conditions would favor the alternatives.

### Phase 3: Capture the Analysis

Write a brainstorm document to `docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md`.

Ensure `docs/brainstorms/` directory exists before writing.

**Document structure:**

```markdown
---
title: [Brainstorm Topic]
date: YYYY-MM-DD
status: complete
recommended-approach: [Name of recommended approach]
---

# [Brainstorm Topic]

## Research Question
[The question being explored]

## Problem Decomposition
- Core question: [...]
- Key constraints: [...]
- Prior art in this project: [...]
- Success criteria: [...]

## Approaches Compared

### Approach A: [Name]
- **Description:** [...]
- **Theoretical properties:** [...]
- **Identification requirements:** [...]
- **Computational cost:** [...]
- **Data requirements:** [...]
- **Software:** [...]
- **Monte Carlo evidence:** [...]
- **Verdict:** [...]

### Approach B: [Name]
[Same structure]

### Approach C: [Name] (if applicable)
[Same structure]

## Recommendation
**Selected: [Approach Name]**

[Why this approach. What conditions would favor alternatives. Key tradeoffs accepted.]

## Key Decisions
- [Decision 1 and rationale]
- [Decision 2 and rationale]

## Assumptions Made
- [Any assumptions made during autonomous analysis]

## Open Questions
- [Questions that should be resolved during planning or implementation]

## References
- [Methodological papers cited]
- [Software documentation referenced]
```

### Phase 4: Summary and Handoff

Display summary and suggest next steps:

```
Brainstorm complete!

Document: docs/brainstorms/YYYY-MM-DD-<topic>-brainstorm.md

Recommended approach: [Approach Name]
Key rationale: [One-line summary]

Alternatives documented:
- [Alternative 1]: [When to prefer]
- [Alternative 2]: [When to prefer]

Next: Run `/workflows:plan` to create an implementation plan.
```

Automatically proceed to `/workflows:plan` if invoked from `/lfg` or `/slfg`.

## Important Guidelines

- **Stay focused on WHAT approach, not HOW to implement** — implementation details belong in the plan
- **Apply parsimony** — prefer simpler, well-understood methods unless complexity is justified
- **Be specific about tradeoffs** — "more efficient but requires stronger assumptions" not "has pros and cons"
- **Ground in real methods** — cite actual estimators (2SLS, GMM, MPEC), packages (statsmodels, fixest, PyBLP), and papers
- **Keep outputs concise** — 200-300 words per section max

NEVER CODE! Just explore and document methodological decisions.
