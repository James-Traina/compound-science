---
name: submission-guide
description: >-
  Guide for academic journal submission, referee responses, and revision management. Use when the user is preparing a manuscript for submission, formatting for a specific journal, responding to referees, or managing revisions. Triggers on "submit", "referee", "revision", "R&R", "response letter", "journal", "formatting", "submission", "resubmit", "cover letter", "referee report", "revise and resubmit".
---

# Journal Submission

Reference for the full journal submission lifecycle: pre-submission preparation, journal-specific formatting, referee response strategy, and revision management. Covers conventions for top journals in economics, finance, political science, sociology, marketing, and statistics.

## When to Use This Skill

Use when the user is:
- Preparing a manuscript for first submission to an academic journal
- Formatting a paper to meet a specific journal's requirements
- Writing a response letter to referee reports after receiving an R&R
- Managing tracked changes and revision logistics
- Anticipating common referee objections for a particular empirical method
- Writing a cover letter to the editor

Skip when:
- The task is choosing an empirical method (use `causal-inference` or `empirical-playbook` skill)
- The task is structural estimation implementation (use `structural-modeling` skill)
- The task is setting up a replication package (use `reproducible-pipelines` skill)

## Pre-Submission Checklist

Complete every item before submitting. Missing any one of these is a common reason for desk rejection or delayed processing.

### Manuscript

- [ ] **Title**: Concise, informative, no unnecessary jargon. Under 15 words is ideal.
- [ ] **Abstract**: States the question, method, data, and main finding. Respects journal word limit (typically 100-150 words for econ journals).
- [ ] **JEL codes**: 2-4 codes, primary code first. Check https://www.aeaweb.org/econlit/jelCodes.php for current classification.
- [ ] **Keywords**: 3-6 terms not already in the title.
- [ ] **Introduction**: Clearly states contribution in first two paragraphs. Includes a "roadmap" paragraph at the end.
- [ ] **Literature review**: Positions paper relative to 3-5 closest papers. Explains what this paper does that they do not.
- [ ] **Identification section**: Formal statement of assumptions, not just prose. Numbered assumptions preferred.
- [ ] **Results**: Main results first, robustness second. Do not bury the lead.
- [ ] **Conclusion**: No new results. Discuss limitations honestly. Suggest future work briefly.
- [ ] **References**: Every citation in text appears in references and vice versa. Use a bibliography manager (BibTeX/BibLaTeX).
- [ ] **Anonymization**: Remove all author-identifying information. Check PDF metadata, acknowledgments, file paths in code, dataset names that reveal institution.
- [ ] **Page/word count**: Within journal limits. Many journals have strict limits (e.g., AER Papers & Proceedings: 5 pages).
- [ ] **Spell check and grammar**: Run a final pass. Typos in the abstract signal carelessness.
- [ ] **Agent review**: Run the `journal-referee` agent for an adversarial review and the `results-verifier` agent to audit tables against code output.

### Tables

- [ ] **Self-contained**: Each table has a descriptive title and notes explaining all variables, sample, and significance stars.
- [ ] **Significance stars**: Use journal convention. Most econ journals: `* p<0.10, ** p<0.05, *** p<0.01`. Some journals (QJE) discourage stars entirely.
- [ ] **Standard errors**: Report in parentheses below coefficients. State clustering level in notes.
- [ ] **Number of observations**: Report N for every regression. Report N by group for DiD/panel.
- [ ] **R-squared or fit measure**: Report adjusted R-squared, within R-squared for FE models, or pseudo R-squared for nonlinear models.
- [ ] **Decimal places**: 2-3 significant digits. Do not report 8 decimal places from Stata/R output.
- [ ] **Consistent formatting**: Same variable names across all tables. Same order of controls.
- [ ] **No vertical lines**: Use horizontal rules only (booktabs style in LaTeX).

### Figures

- [ ] **Vector format**: PDF or EPS for line plots and diagrams. High-resolution PNG (300+ DPI) only for heatmaps or photos.
- [ ] **Readable in grayscale**: Use shapes/patterns in addition to colors. At least 20% of readers print in black and white.
- [ ] **Axis labels**: Clear, with units. Font size readable when figure is scaled to journal column width.
- [ ] **No chartjunk**: Remove gridlines, unnecessary legends, 3D effects, excessive tick marks.
- [ ] **Consistent style**: All figures use the same font, color palette, and line weights.
- [ ] **Source note**: State data source and sample period below each figure.

### Appendix and Online Appendix

- [ ] **Appendix**: Proofs, additional tables referenced in the main text, variable definitions.
- [ ] **Online appendix**: Supplementary results that support but are not essential to the main argument.
- [ ] **Cross-references**: Every appendix item is referenced from the main text. No orphan appendix tables.
- [ ] **Separate file**: Some journals require the online appendix as a separate PDF. Check submission guidelines.

### Replication Package

- [ ] **Data**: All data files, or clear instructions for obtaining restricted-access data.
- [ ] **Code**: All scripts from raw data to final tables/figures. Master script that runs everything in order.
- [ ] **README**: Describes file structure, software requirements, runtime estimate, expected output.
- [ ] **Seeds**: All random number generator seeds set and documented.
- [ ] **Versions**: Software versions pinned (R/Python/Stata version, package versions).
- [ ] **License**: Data license and code license specified.
- [ ] **Tested**: Run the entire pipeline from scratch on a clean machine or container.

### Cover Letter

- [ ] **Editor name**: Address to the specific editor, not "Dear Editor." Check the journal website for the handling editor or co-editors by field.
- [ ] **One paragraph summary**: State the paper's question, method, and main result.
- [ ] **Contribution statement**: Why this paper is a good fit for this specific journal.
- [ ] **Conflicts of interest**: Disclose any relevant relationships.
- [ ] **Suggested referees**: 3-5 names with affiliations and emails. Choose experts who will understand the method but are not close collaborators. Avoid suggesting people who are known to be hostile to the approach.
- [ ] **Excluded referees**: Optional but available at most journals. Use sparingly and only for genuine conflicts.

## Journal-Specific Formatting

For per-journal tables covering spacing, abstract limits, stars conventions, submission systems, and special requirements across Economics (Top 5, AEJ, Field), Finance, Political Science, Sociology, Marketing, and Statistics journals, see: **`references/journal-profiles.md`**

Quick lookup:
- **AER**: 1.5-line spacing, 100-word abstract, Editorial Express
- **Econometrica**: Double spacing, numbered proof environments required, `ecta.cls`
- **QJE**: No significance stars — report exact p-values, ScholarOne
- **JPE**: University of Chicago Press style, ScholarOne
- **JFE**: Requires "Highlights" (3-5 bullets ≤ 85 chars each), Elsevier Editorial Manager
- **APSR/AJPS**: Structured abstract (Purpose / Methods / Findings / Value) required

## Referee Response Strategy

### Response Letter Structure

The response letter is the single most important document in the revision. A well-structured response dramatically increases the probability of acceptance.

**Template structure:**

```
Dear [Editor name],

Thank you for the opportunity to revise our manuscript "[Title]"
(Manuscript #XXXX). We are grateful to you and the referees for
constructive comments that have substantially improved the paper.

Below we provide a detailed point-by-point response. For convenience:
- Referee comments are in [italics / block quotes]
- Our responses are in regular text
- Page and line numbers refer to the revised manuscript
- Changes in the manuscript are highlighted in [blue / tracked changes]

[Summary of major changes — 1 paragraph, 3-5 sentences]

RESPONSE TO REFEREE 1
======================

Major Comments
--------------

1. [Referee comment, quoted verbatim or closely paraphrased]

   [Your response]

   [If applicable: "We have revised Section X (pp. Y-Z) to address
   this point. Specifically, we now..."]

Minor Comments
--------------

1. [Comment]

   [Response]

RESPONSE TO REFEREE 2
======================

[Same structure]
```

### Tone and Framing

| Principle | Good Example | Bad Example |
|-----------|-------------|-------------|
| Thank the referee | "This is an excellent point that led us to strengthen Section 4." | "We disagree with the referee's interpretation." |
| Be specific about changes | "We have added Table A3 (Online Appendix, p.15) showing results with alternative bandwidth." | "We have addressed this concern." |
| Concede gracefully | "The referee is correct that our original discussion was unclear. We have rewritten paragraphs 2-3 of Section 3 to..." | "We believe our original discussion was clear, but we have added a footnote." |
| Defend with evidence | "We respectfully maintain our baseline specification because: (1) the Hausman test does not reject (p=0.34, Table A5), (2) results are quantitatively similar with the referee's preferred specification (Table A6)." | "We disagree." |
| Never be dismissive | "Thank you for this suggestion. While our setting differs from [Paper] because [reason], we have added a discussion of this connection in footnote 12." | "This comment reflects a misunderstanding of our method." |

### What to Concede vs Defend

**Concede when:**
- The referee is factually correct about an error
- The suggestion improves the paper without changing the core contribution
- Adding a robustness check is low-cost and reassuring
- The concern is shared by multiple referees (editor will weight this heavily)
- The requested analysis is standard for the method (e.g., pre-trends for DiD)

**Defend when:**
- Conceding would undermine the paper's core identification strategy
- The requested specification is econometrically inappropriate for the setting
- The referee misunderstands a key aspect of the method or data
- The suggestion would change the paper into a different paper entirely

### Response Matrix

Track every referee comment in a spreadsheet or table:

| Ref | # | Comment Summary | Category | Action | Status | Location |
|-----|---|----------------|----------|--------|--------|----------|
| R1 | 1 | Exclusion restriction not credible | Major / Identification | New falsification test | Done | Table A3, p.15 |
| R1 | 2 | Sample period too short | Major / Data | Extended sample + robustness | Done | Section 3.2, Table 2 |
| R2 | 1 | Compare to [Smith 2019] | Major / Literature | Added discussion + comparison | Done | Section 2, pp.4-5 |
| R2 | 2 | Cluster at state level | Major / Inference | Added state-clustered SEs | Done | All tables |

Categories: Identification, Data, Inference, Exposition, Literature, Robustness, Other.
**Rule: every cell in the Status column must be filled before resubmission.**

### Method-Specific Referee Concerns

For per-method concern tables (IV, DiD, Structural Estimation, RDD, Matching), including typical phrasing and detailed response strategies, see: **`references/referee-tactics.md`**

## Revision Management

### Track Changes Workflow

```latex
% In preamble, use latexdiff or manual markup:
\usepackage{xcolor}
\newcommand{\new}[1]{\textcolor{blue}{#1}}

% Better: use latexdiff on the command line
% latexdiff old.tex new.tex > diff.tex
% pdflatex diff.tex
% Produces PDF with additions in blue and deletions in red
```

```bash
# Tag each submission
git tag -a v1-submitted -m "First submission to AER, 2024-01-15"
git tag -a v1-r1-response -m "R&R response to AER referees, 2024-07-20"
git tag -a v2-submitted -m "Revised submission to AER, 2024-07-22"

# Generate diff between submissions
latexdiff-git --git-path v1-submitted v2-submitted -- main.tex
```

**Best practices:**
- Generate the diff PDF from the previous submission vs the revision — editors expect this.
- Reference page numbers from the **clean revised manuscript**, not the diff.
- Keep a copy of the exact submitted version for each round (tag in git).

### Multi-Round Revision Strategy

| Round | Focus | Response length |
|-------|-------|----------------|
| R1 (first R&R) | Address all major concerns thoroughly. Over-deliver on robustness. | Detailed, often 15-30 pages |
| R2 (second R&R) | Fine-tune remaining concerns. Show that R1 issues are fully resolved. | Concise, 5-15 pages |
| R3 (rare, conditional accept) | Minor copyediting, final clarifications only. | Very brief, 2-5 pages |

**After each round:** wait 24-48 hours → read all reports → categorize (major/minor) → build response matrix → prioritize identification concerns → draft major responses → fill minor comments → co-author review → generate diff PDF → submit.

## Editor Communication

### Decision Types

| Decision | Meaning | Typical Next Step |
|----------|---------|-------------------|
| Desk reject | Editor decided not to send to referees. | Submit elsewhere. Do not appeal unless there is a clear factual error. |
| Reject after review | Referees recommended rejection. | Substantially revise and submit elsewhere, incorporating feedback. |
| Revise and resubmit (R&R) | Paper has potential but needs significant revision. | Address all comments thoroughly. |
| Conditional accept | Minor revisions needed. | Make the requested changes precisely. Do not introduce new results. |
| Accept | Paper accepted. | Prepare camera-ready version and replication package. |

### When to Contact the Editor

- **Before submission**: Only if you have a genuine question about scope or formatting not answered by the guidelines.
- **During review**: Do not ask about status before the stated expected turnaround (usually 3-6 months). A brief polite inquiry is acceptable after.
- **After R&R**: Contact before deadline if you need an extension.
- **After rejection**: Only if the referee made a demonstrable factual error. "I disagree" is not grounds for appeal.

## Submission Timing

| Factor | Guidance |
|--------|----------|
| Conference presentations | Submit after presenting at a major conference — the paper benefits from feedback, and the presentation signals quality. |
| Working paper circulation | Post to SSRN/NBER before submission. Journals expect papers to circulate as working papers first. |
| Dual submission | Most economics and finance journals prohibit simultaneous submission to multiple journals. Confirm the journal's policy. |
| Semester timing | Avoid July-August (editors and referees on vacation). September-November and January-March tend to be faster. |
| Market timing | Junior scholars should have papers submitted and preferably under review by September of their market year. |
