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

### Economics — Top 5

| Feature | AER | Econometrica | QJE | JPE | ReStud |
|---------|-----|-------------|-----|-----|--------|
| Spacing | 1.5 | Double | Double | Double | Double |
| Abstract limit | 100 words | 150 words | None stated | 100 words | 150 words |
| Page limit | None | None | None | None | None |
| Math notation | Standard LaTeX | Numbered theorems, proof environments required | Standard LaTeX | Standard LaTeX | Standard LaTeX |
| SE reporting | Parentheses | Parentheses | Parentheses or brackets | Parentheses | Parentheses |
| Stars convention | Standard 1/5/10% | Discouraged in some areas | Discouraged — report exact p-values | Standard 1/5/10% | Standard 1/5/10% |
| Figures format | PDF/EPS | PDF/EPS | PDF/EPS | PDF/EPS | PDF/EPS |
| Online appendix | Yes, separate | Yes, separate supplement | Yes, separate | Yes, separate | Yes, separate |
| Submission system | Editorial Express | Editorial Express | ScholarOne | ScholarOne | Editorial Express |
| Anonymized | Yes | Yes | Yes | Yes | Yes |
| Replication package | AEA Data Editor review, required at acceptance | Required at acceptance | Required at acceptance | Required at acceptance | Required at acceptance |

**AER specifics:**
- 1.5-line spacing (unusual — most journals want double).
- AEA journals (AER, AEJ: Applied, AEJ: Policy, AEJ: Macro, AEJ: Micro) share the same data and code availability policy. Replication packages are reviewed by the AEA Data Editor before final acceptance.
- Use `\documentclass[12pt]{article}` with `\usepackage{setspace}\onehalfspacing`.
- JEL codes required. Keywords optional.

**Econometrica specifics:**
- Formal proof environments required for theoretical results. Use `\begin{theorem}...\end{theorem}`, `\begin{proof}...\end{proof}`.
- Number all assumptions, theorems, lemmas, propositions, and corollaries consecutively.
- Regularity conditions must be stated explicitly, not buried in footnotes.
- Supplemental Material is the standard term (not "Online Appendix").
- Uses the Econometric Society's LaTeX class `ecta.cls` for final publication (not required for submission, but available).

**QJE specifics:**
- No significance stars preferred — report coefficients and standard errors; let readers judge significance.
- Tends to favor papers with clean natural experiments and policy relevance.
- No strict page limit, but papers over 60 pages are unusual.
- ScholarOne submission system.

**JPE specifics:**
- University of Chicago Press formatting for accepted papers.
- Relatively strict on exposition quality — clear, concise writing valued.
- ScholarOne submission system.
- Generally expects structural or quasi-experimental work with clear economic content.

**ReStud specifics:**
- Editorial Express submission.
- Known for long review times (6-12 months common).
- Strong emphasis on theoretical contribution even in empirical papers.

### Economics — AEJ Journals

| Feature | AEJ: Applied | AEJ: Policy | AEJ: Macro | AEJ: Micro |
|---------|-------------|-------------|------------|------------|
| Focus | Empirical applied micro | Policy evaluation | Macro empirical/theory | Micro theory + empirical |
| Spacing | 1.5 | 1.5 | 1.5 | 1.5 |
| Page limit | None | None | None | None |
| Replication | AEA Data Editor | AEA Data Editor | AEA Data Editor | AEA Data Editor |
| Turnaround | 3-6 months | 3-6 months | 3-6 months | 3-6 months |

All AEJ journals follow AEA-wide policies on data availability, formatting, and submission through Editorial Express.

### Economics — Field Journals

| Feature | JHR | JDE | JOLE | JUE | JEEA |
|---------|-----|-----|------|-----|------|
| Focus | Human resources, labor, education, health | Development economics | Labor economics | Urban economics | European economic research |
| Spacing | Double | Double | Double | Double | Double |
| Abstract limit | 100 words | 100 words | 150 words | 100 words | 100 words |
| Submission system | ScholarOne | Editorial Manager (Elsevier) | ScholarOne | Editorial Manager (Elsevier) | ScholarOne |
| Formatting | Standard LaTeX/Word | Elsevier template available | Standard LaTeX | Elsevier template available | Standard LaTeX |
| Special notes | JEL codes required | Requires IRB/ethics statement for field experiments | — | — | — |

### Finance — Top Journals

| Feature | JF | JFE | RFS |
|---------|-----|-----|-----|
| Focus | Broad finance | Corporate, asset pricing, financial institutions | Broad finance, slightly more theoretical |
| Spacing | Double | Double | Double |
| Abstract limit | 200 words | 200 words | 200 words |
| Submission system | ScholarOne | SSRN/Editorial Manager | ScholarOne |
| Special requirement | — | **Highlights**: 3-5 bullet points summarizing key findings (required at submission) | — |
| Internet appendix | Yes | Yes | Yes, called "Internet Appendix" |
| Stars convention | Standard 1/5/10% | Standard 1/5/10% | Standard 1/5/10% |

**JFE specifics:**
- Requires "Highlights" — 3-5 bullet point findings, each under 85 characters.
- Uses Elsevier Editorial Manager.
- Data availability statement required.
- Relatively fast turnaround (3-4 months for first decision).

**JF specifics:**
- American Finance Association journal.
- ScholarOne submission.
- Associate Editor system: the AE writes a recommendation letter that the Editor often follows closely.

**RFS specifics:**
- Dual submission with conferences (e.g., SFS Cavalcade) sometimes fast-tracked.
- Internet Appendix is the standard term for supplementary material.

### Political Science

| Feature | APSR | AJPS | JOP | Political Analysis |
|---------|------|------|-----|--------------------|
| Focus | Broad political science | Broad political science | Broad political science | Quantitative methods for polisci |
| Abstract format | **Structured**: separate sections for purpose, methods, results | **Structured** | Standard | Standard |
| Word limit | 12,000 words (including notes, excluding references) | 10,000 words | 10,000 words | 10,000 words |
| Anonymized | Yes | Yes | Yes | Yes |
| Replication | Dataverse deposit required at acceptance | Dataverse deposit | Dataverse deposit | Dataverse deposit |
| Submission system | ScholarOne | Editorial Manager | ScholarOne | ScholarOne |

**APSR/AJPS structured abstract:**
Both require a structured abstract with clearly labeled sections. Typical format:
```
Purpose: [What question does this paper address?]
Design/Methods: [What data and methods are used?]
Findings: [What are the main results?]
Value: [What is the contribution?]
```

**Political Analysis specifics:**
- Methods journal — emphasis on methodological innovation with political science application.
- Code and data must be deposited in the Political Analysis Dataverse.
- LaTeX or Word accepted, but LaTeX strongly preferred for mathematical content.

### Sociology

| Feature | ASR | AJS |
|---------|-----|-----|
| Focus | Broad sociology | Broad sociology, slightly more theoretical |
| Word limit | 11,000 words (text + notes) | 12,000-15,000 words |
| Abstract limit | 200 words | 200 words |
| Spacing | Double | Double |
| Anonymized | Yes | Yes |
| Submission system | ScholarOne | Editorial Manager |
| Formatting notes | ASA style (author-date citations) | Chicago style |

**Key differences from econ journals:**
- Sociology journals use author-date citation format (Smith 2020), not numbered references.
- Tables include descriptive statistics more prominently.
- Variable names in tables use plain English (not shorthand abbreviations).
- Discussion sections are longer and more interpretive.
- Word limits are strictly enforced.

### Marketing

| Feature | Marketing Science | JMR | JCR |
|---------|-------------------|-----|-----|
| Focus | Quantitative marketing, structural models | Broad marketing research | Consumer behavior |
| Spacing | Double | Double | Double |
| Submission system | ScholarOne | ScholarOne | ScholarOne |
| Special notes | Welcomes structural estimation, field experiments | Requires managerial implications section | Primarily behavioral/experimental |
| Replication | Code sharing encouraged | Code sharing encouraged | — |

**Marketing Science specifics:**
- Strong tradition of structural empirical modeling (BLP-style demand, dynamic models).
- Accepts longer papers than most econ journals.
- Requires a "managerial relevance" statement in many cases.
- Closely related to economics in methods but distinct in framing.

### Statistics

| Feature | JASA | Annals of Statistics | Biometrika | JRSS-B |
|---------|------|---------------------|------------|--------|
| Focus | Applied and theoretical statistics | Theoretical statistics | Statistical methodology | Statistical methodology |
| Spacing | Double | Double | Double | Double |
| Abstract limit | 200 words | 100 words | 200 words | 200 words |
| Page limit | ~30 pages (main), supplement OK | ~30 pages | ~20 pages | ~25 pages |
| Submission system | ScholarOne | IMS system | Editorial Manager | ScholarOne |
| Supplement | Yes | Yes | Yes | Yes |

**JASA specifics:**
- Two tracks: "Applications and Case Studies" (applied) and "Theory and Methods" (methodology).
- The applied track requires genuine data analysis, not just simulations.
- The theory track requires mathematical proofs.
- Supplementary materials can be extensive.

**Annals of Statistics specifics:**
- Purely theoretical — proofs are the core contribution.
- Very high bar for theoretical novelty.
- IMS (Institute of Mathematical Statistics) format.
- LaTeX required, use `imsart.cls`.

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

RESPONSE TO THE EDITOR
=======================

[If the editor raised specific points in the decision letter]

Thank you again for your guidance throughout this process.

Sincerely,
[Authors]
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
- The referee asks for better exposition or additional explanation
- The concern is shared by multiple referees (editor will weight this heavily)
- The requested analysis is standard for the method (e.g., pre-trends for DiD)

**Defend when:**
- Conceding would undermine the paper's core identification strategy
- The requested specification is econometrically inappropriate for the setting
- The referee misunderstands a key aspect of the method or data
- The requested data/analysis is genuinely impossible to obtain
- The suggestion would change the paper into a different paper entirely

**How to defend effectively:**
1. Acknowledge the concern as legitimate
2. Explain why the current approach is preferred, citing methodological literature
3. Provide partial accommodation (a robustness check, additional discussion, or sensitivity analysis)
4. Never leave a concern entirely unaddressed — even if you disagree, show you took it seriously

### Response Matrix

Track every referee comment in a spreadsheet or table:

| Ref | # | Comment Summary | Category | Action | Status | Location |
|-----|---|----------------|----------|--------|--------|----------|
| R1 | 1 | Exclusion restriction not credible | Major / Identification | New falsification test | Done | Table A3, p.15 |
| R1 | 2 | Sample period too short | Major / Data | Extended sample + robustness | Done | Section 3.2, Table 2 |
| R1 | 3 | Typo in equation 4 | Minor / Exposition | Fix | Done | p.8, eq.4 |
| R2 | 1 | Compare to [Smith 2019] | Major / Literature | Added discussion + comparison | Done | Section 2, pp.4-5 |
| R2 | 2 | Cluster at state level | Major / Inference | Added state-clustered SEs | Done | All tables |

Categories: Identification, Data, Inference, Exposition, Literature, Robustness, Other.
Status: Done, In Progress, Deferred (with justification), Declined (with explanation in letter).

**Rule: every cell in the Status column must be filled before resubmission.**

## Revision Management

### Track Changes Workflow

**LaTeX:**
```latex
% In preamble, use latexdiff or manual markup:
\usepackage{changes}
% Or use color markup:
\usepackage{xcolor}
\newcommand{\new}[1]{\textcolor{blue}{#1}}
\newcommand{\removed}[1]{\textcolor{red}{\sout{#1}}}

% Better approach: use latexdiff on the command line
% latexdiff old.tex new.tex > diff.tex
% pdflatex diff.tex
% This produces a PDF with additions in blue and deletions in red
```

**Best practices:**
- Generate the diff PDF from the previous submission vs the revision — editors expect this.
- In the response letter, reference page numbers from the **clean revised manuscript**, not the diff.
- Keep a copy of the exact submitted version for each round (tag in git: `v1-submitted`, `v1-revision`, `v2-submitted`).

### Version Control for Submissions

```bash
# Tag each submission
git tag -a v1-submitted -m "First submission to AER, 2024-01-15"
git tag -a v1-r1-response -m "R&R response to AER referees, 2024-07-20"
git tag -a v2-submitted -m "Revised submission to AER, 2024-07-22"

# Generate diff between submissions
latexdiff-git --git-path v1-submitted v2-submitted -- main.tex
```

### Multi-Round Revision Strategy

| Round | Focus | Response length |
|-------|-------|----------------|
| R1 (first R&R) | Address all major concerns thoroughly. Over-deliver on robustness. | Detailed, often 15-30 pages |
| R2 (second R&R) | Fine-tune remaining concerns. Show that R1 issues are fully resolved. | Concise, 5-15 pages |
| R3 (rare, conditional accept) | Minor copyediting, final clarifications only. | Very brief, 2-5 pages |

**After each round:**
1. Wait 24-48 hours before reading referee reports (emotional distance helps)
2. Read all reports once without taking notes
3. Read again, categorizing each comment (major/minor, type)
4. Build the response matrix
5. Prioritize major identification/methodology concerns
6. Draft responses to major comments first
7. Fill in minor comments
8. Co-authors review the response letter before finalizing
9. Generate diff PDF
10. Submit clean manuscript + response letter + diff PDF

## Common Referee Concerns by Method

### Instrumental Variables

| Concern | Typical Phrasing | Response Strategy |
|---------|-----------------|-------------------|
| Exclusion restriction | "The instrument may affect Y through channels other than X." | Provide institutional argument. Run reduced-form with controls for suspected channels. Show falsification tests (effect on placebo outcomes unaffected by X). |
| Weak instruments | "The first-stage F is only [N], raising weak instrument concerns." | Report Olea-Pflueger effective F. Show LIML results. Report Anderson-Rubin confidence sets. If F is truly low, consider alternate instruments. |
| LATE vs ATE | "The IV estimates a local effect for compliers, limiting external validity." | Characterize compliers (compare means of covariates for compliers vs always-takers). Discuss whether the complier subpopulation is policy-relevant. Bound ATE using complier share. |
| Endogenous instrument | "The instrument is correlated with [unobservable]." | This is the most dangerous critique. If the referee is right, the paper's identification fails. Provide maximum institutional detail. Run Conley et al. (2012) plausibly exogenous IV bounds. |
| Monotonicity | "There may be defiers in this setting." | Argue from institutional details why defiance is implausible. Test for heterogeneity in first stage across subgroups — monotonicity implies same-signed first stage everywhere. |

### Difference-in-Differences

| Concern | Typical Phrasing | Response Strategy |
|---------|-----------------|-------------------|
| Pre-trends | "Figure X shows concerning pre-trends." | Run formal pre-trend tests. Report Rambachan-Roth sensitivity analysis. If pre-trends exist, explore detrending or synthetic DiD. Show that results are robust to controlling for group-specific linear trends. |
| Parallel trends | "What justifies the parallel trends assumption?" | Plot raw outcomes for treated vs control. Report pre-treatment covariate balance. Discuss institutional reasons why trends should be similar. Run placebo treatment timing tests. |
| Staggered timing | "TWFE is biased with heterogeneous treatment effects and staggered adoption." | Switch to Callaway-Sant'Anna or Sun-Abraham. Report Bacon decomposition of TWFE estimate. Show results are similar (or explain differences). |
| Spillovers | "Treatment may spill over to control units." | Define control group more carefully (geographic distance, economic isolation). Test for treatment effects in "nearby control" units. Discuss direction of bias from spillovers. |
| Compositional changes | "The sample composition changes around the treatment date." | Show balanced panel results. Verify no differential attrition. Run on a fixed sample with no entry/exit. |
| Anticipation | "Agents may have anticipated the policy change." | Test for effects in pre-treatment periods. If anticipation is plausible, shift the treatment date earlier and re-estimate. Discuss institutional details about policy announcement vs implementation. |

### Structural Estimation

| Concern | Typical Phrasing | Response Strategy |
|---------|-----------------|-------------------|
| Functional form | "Results may be driven by functional form assumptions." | Report sensitivity to alternative functional forms (logit vs probit, parametric vs semiparametric). Show that key qualitative results survive flexible specifications. |
| Identification | "It is unclear what variation identifies the parameters." | Add a formal identification argument (preferably in the model section). Show which moments or data patterns pin down each parameter. Report identification-at-infinity or point-identification conditions. |
| Computational issues | "How do you know the solution is a global optimum?" | Report results from multiple starting values. Show the objective function surface. Report convergence diagnostics. For MPEC, report constraint violations. |
| Counterfactual validity | "The counterfactual is far from the data." | Report how far counterfactual parameters are from estimated values. Conduct sensitivity analysis around the counterfactual. Validate the model on out-of-sample data. |
| External validity | "The model is estimated on [specific context] and may not generalize." | Acknowledge the limitation. If possible, validate on a holdout sample or different context. Discuss which model features are context-specific vs general. |

### Regression Discontinuity

| Concern | Typical Phrasing | Response Strategy |
|---------|-----------------|-------------------|
| Manipulation | "Agents may manipulate the running variable to sort around the cutoff." | Report McCrary/Cattaneo-Jansson-Ma density test. Show histogram of running variable. If institutional rules prevent manipulation, explain them. Show covariate balance at the cutoff. |
| Bandwidth sensitivity | "Results are sensitive to bandwidth choice." | Report results at 0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x the optimal bandwidth. Show a coefficient plot across bandwidths. Report both MSE-optimal and CER-optimal bandwidths. |
| Local effect | "The effect is identified only at the cutoff and may not generalize." | Acknowledge this is inherent to RDD. If the cutoff is policy-relevant (e.g., eligibility threshold), emphasize this. Explore heterogeneity away from the cutoff cautiously (using extrapolation methods from Angrist-Rokkanen 2015). |
| Polynomial order | "Why use a linear specification? A quadratic might be more appropriate." | Local linear (p=1) is the standard recommendation (Gelman-Imbens 2019 argue against higher-order polynomials). Report robustness to local quadratic. Use rdrobust which selects optimal polynomial. |
| Discrete running variable | "The running variable takes few distinct values." | Use Cattaneo-Idrobo-Titiunik methods for discrete running variables. Report results with and without clustering on the running variable. Standard rdrobust may not be appropriate. |

### Matching / Selection on Observables

| Concern | Typical Phrasing | Response Strategy |
|---------|-----------------|-------------------|
| Unobservables | "The selection-on-observables assumption is strong. Unobserved confounders may bias results." | Report Oster (2019) bounds or Altonji-Elder-Taber (2005) sensitivity analysis. Show that results survive controlling for increasingly rich sets of observables. Report Rosenbaum bounds. |
| Common support | "There is limited overlap between treated and control propensity score distributions." | Show propensity score density plots by treatment status. Report the fraction of observations trimmed. Show results are robust to alternative trimming thresholds. |
| Model dependence | "Results may depend on the propensity score model specification." | Report results from multiple specifications (logit, probit, random forest). Use doubly robust estimator (AIPW). Show covariate balance under each specification. |
| Balance | "Standardized mean differences remain large after matching." | Report Love plot of SMDs before and after matching. Target SMD < 0.1 on all covariates. If balance is poor, consider a different matching method or add covariates. |

## Anti-Patterns

### Response Letter Anti-Patterns

| Anti-Pattern | Why It Fails | Better Approach |
|--------------|-------------|-----------------|
| Defensive or combative tone | Alienates referees and editors. Signals unwillingness to engage. | Thank the referee, acknowledge the concern, then explain your position with evidence. |
| Ignoring minor comments | Signals carelessness. Editors notice when comments are skipped. | Address every single comment, even if briefly ("Thank you, we have corrected this typo on p.7"). |
| Responding with only "Done" | Referee cannot verify the change without re-reading the entire paper. | Quote the specific change: "We have added the following sentence to Section 3 (p.12): '[quote]'." |
| Bulk-dismissing concerns | "We believe our original approach is correct" repeated for multiple points. | Each concern deserves an individual, substantive response. |
| Adding results not requested | Stuffing the paper with unrequested analyses dilutes the revision. | Focus on what was asked. Add unrequested improvements only if they directly strengthen the paper. |
| Not updating the literature review | Referees often suggest papers to cite. Ignoring these suggestions is noticed. | Add every reasonable citation suggestion. Explain how the paper relates to yours. |
| Submitting without the diff | Editor must manually compare versions, slowing the process. | Always include a latexdiff or tracked-changes version alongside the clean manuscript. |
| Waiting too long to resubmit | After 12+ months, referees may have forgotten the paper. Some journals revoke the R&R. | Aim to resubmit within 3-6 months. If you need more time, inform the editor. |

### Manuscript Anti-Patterns

| Anti-Pattern | Why It Fails | Better Approach |
|--------------|-------------|-----------------|
| Burying the contribution | Reader must wade through 10 pages before understanding what the paper does. | State the question, method, and main result in the first two paragraphs of the introduction. |
| Results without context | Coefficients without economic interpretation ("the coefficient is 0.043"). | Interpret magnitudes: "A one-standard-deviation increase in X increases Y by 4.3%, roughly equivalent to [meaningful comparison]." |
| Too many tables | 20+ tables signal data mining. Editors want focused results. | 4-6 main tables. Move the rest to an appendix. |
| Inconsistent notation | Using both beta and b for the same coefficient in different sections. | Define notation once and use it consistently throughout. |
| Claiming causality without identification | "Our results show that X causes Y" after running an OLS regression with no causal strategy. | Be precise: "conditional on controls, X is associated with Y" unless you have a valid identification strategy. |
| No robustness section | Single specification, no sensitivity analysis. Referees will question every choice. | Dedicate a section to alternative specifications, sample definitions, and estimation methods. |

## Editor Communication

### Decision Types

| Decision | Meaning | Typical Next Step |
|----------|---------|-------------------|
| Desk reject | Editor decided not to send to referees. | Submit elsewhere. Do not appeal unless there is a clear factual error in the editor's reasoning. |
| Reject after review | Referees recommended rejection and editor agreed. | Substantially revise and submit elsewhere, incorporating referee feedback. |
| Revise and resubmit (R&R) | Paper has potential but needs significant revision. | This is good news. Address all comments thoroughly. |
| Conditional accept | Minor revisions needed, paper will be accepted if addressed. | Make the requested changes precisely. Do not introduce new results. |
| Accept | Paper accepted for publication. | Celebrate. Then prepare camera-ready version and replication package. |

### When to Contact the Editor

- **Before submission**: Only if you have a genuine question about scope or formatting not answered by the guidelines.
- **During review**: Do not contact the editor to ask about the status before the stated expected turnaround (usually 3-6 months). After the expected turnaround, a brief polite inquiry is acceptable.
- **After R&R**: If you need an extension beyond the stated deadline (usually 6-12 months), contact the editor before the deadline expires.
- **After rejection**: A brief, factual appeal is appropriate only if the referee made a demonstrable factual error that affected the recommendation. "I disagree with the referee's assessment" is not grounds for an appeal.

## Submission Timing

| Factor | Guidance |
|--------|----------|
| Conference presentations | Submit after presenting at a major conference (NBER, AEA, EEA) — the paper benefits from feedback, and the presentation signals quality. |
| Working paper circulation | Post to SSRN/NBER before submission. Journals expect papers to circulate as working papers first. |
| Dual submission | Most economics and finance journals prohibit simultaneous submission to multiple journals. Confirm the journal's policy. |
| Semester timing | Avoid submitting in July-August (many editors and referees are on vacation, leading to slower turnaround). September-November and January-March tend to be faster. |
| Market timing | Junior scholars on the job market should have papers submitted and preferably under review by September of their market year. |
