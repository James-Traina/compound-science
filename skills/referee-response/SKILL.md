---
name: referee-response
description: >-
  Guide for drafting structured author responses to peer review. Use when the user has received referee reports and needs to draft a response letter or revise a paper. Triggers on "referee report", "revise and resubmit", "R&R", "referee comments", "reviewer says", "respond to referee", "referee response", "point-by-point response", "author response", "revision letter", "second round", "desk reject appeal", or "editor decision".
---

# Referee Response: Structured Author Response Protocol

## Response Architecture

Every referee response consists of three documents:
1. **Cover letter** (1 page): Summary of changes, gratitude, overall framing
2. **Point-by-point response** (bulk): Each comment addressed in order
3. **Marked-up manuscript** (optional but recommended): Changes highlighted

---

## Comment Classification

Before drafting, classify each referee comment:

| Type | Definition | Response strategy |
|------|-----------|-------------------|
| **Factual error** | Referee misread the paper | Politely correct with specific page reference |
| **Legitimate concern** | Valid critique requiring real change | Concede, describe change, quote revised text |
| **Scope extension** | Wants a different paper | Explain what this paper does; add robustness if reasonable |
| **Identification challenge** | Questions causal validity | Treat seriously; add robustness, clarify assumptions |
| **Robustness request** | Wants additional specification | Add if reasonable; justify omission if not |
| **Presentation issue** | Clarity, notation, organization | Fix it; brief acknowledgment |
| **Citation request** | "You should cite X" | Add if relevant; briefly explain if not |

NEVER argue that a legitimate concern is wrong without making a change — revise first, then explain.
ALWAYS implement at least a partial accommodation of each concern, even if you disagree.

---

## Point-by-Point Format

```
**Referee 1, Comment 3:** [Quote the exact comment here]

**Response:** [Your response — one of three forms:]

Form A (Accept): We thank the referee for this observation. We have revised [Section X]
to address this concern. Specifically, [describe change]. The revised text now reads:
> "[Quote the new text verbatim]"

Form B (Partial accept): We agree with the spirit of this comment. We have added [X]
but do not [Y] because [brief justification focused on the paper's scope].
The revised text reads: > "[Quote new text]"

Form C (Polite decline): We appreciate the referee's suggestion. As the paper focuses
on [specific question], adding [Y] would take us [beyond scope / require different data].
We have clarified this in [Section X]: > "[Quote clarifying text]"
```

---

## Identification Challenges: High-Stakes Responses

When a referee challenges the identification strategy, use this framework:

1. **Do not concede identification failure unless the critique is decisive.** An incomplete argument is not an invalid one.
2. **Restate the identification assumption clearly and precisely** — often this alone resolves the concern.
3. **Add targeted robustness**: if the concern is "X could confound your result", add a specification that controls for X or a falsification test.
4. **Invoke the relevant literature**: if the exclusion restriction is standard in the field (e.g., distance-to-college IV for education), cite the papers that defend it.

### Standard robustness additions for identification challenges

| Challenge | Standard robustness addition |
|-----------|------------------------------|
| "Parallel trends may be violated" | Pre-trends test + Rambachan-Roth (2023) sensitivity; add covariates to DiD; Sant'Anna-Zhao (2020) doubly robust |
| "Instrument is weak" | Report Montiel Olea-Pflueger effective F; Anderson-Rubin CI; LIML vs. 2SLS comparison |
| "Instrument is not excludable" | Conley-Hansen-Rossi plausibly exogenous bounds; partial identification with Roy-Tchetgen bounds |
| "Omitted variable bias" | Oster (2019) bounds (delta and Rmax); coefficient stability table across specifications |
| "Selection into sample" | Heckman selection correction; Lee (2009) bounds; attrition test |
| "Bunching at cutoff" | Formal McCrary/rddensity test; donut RDD |
| "Wrong functional form" | Nonparametric local polynomial; Robinson partial linear model |

---

## Journal-Specific Tone Calibration

| Journal | Appropriate tone | Key emphasis |
|---------|-----------------|--------------|
| **AER/ECMA/JPE/QJE** | Formal, thorough, no shortcuts | Every comment gets a full response; no dismissals |
| **REStud/JME/JPubE** | Professional, can be more direct | Depth on methodological comments |
| **JHR/AEJ-Applied** | Practical, policy-focused framing | Emphasize empirical validity and policy implications |
| **Field journals** | Collegial, can acknowledge scope tradeoffs | Reviewer likely knows the data; acknowledge domain expertise |
| **Top theory** (ECMA/TE) | Formal, precise, mathematical | Proofs must be complete; no handwaving |

---

## Cover Letter Template

```
Dear Editor [Name],

We are pleased to submit the revised version of "[Paper Title]" (MS #XXXX).
We thank the editor and referees for their careful reading and constructive suggestions,
which have substantially improved the paper.

[2-3 sentences summarizing the main changes:]
The most significant revisions include: (i) [Main change addressing Referee 1's central concern];
(ii) [Main change addressing Referee 2's concern]; and (iii) [any other major revision].

[If identification was challenged:] We have strengthened the identification section by [X],
which directly addresses the concerns raised by Referee [N] about [specific issue].

The paper is [shorter/longer] by approximately [N] pages. We believe these revisions
fully address the referees' concerns and hope you find the revised manuscript suitable
for publication.

We look forward to your decision.

Sincerely,
[Authors]
```

---

## Tracking Revisions Across Rounds

Organize revision correspondence as:
```
correspondence/
  round1/
    referee1_report.md
    referee2_report.md
    response_letter.md
    changes_summary.md   # What changed and where (for round 2 reference)
  round2/
    ...
```

Use `changes_summary.md` to track:
- Which referee comments led to which changes
- What robustness was added vs. what was declined
- Page/section numbers of all changes

This becomes the foundation for a round-2 response letter that can say "as discussed in our previous response, [X] is addressed in [Section Y]."

---

## Scope

Use this skill when preparing responses to referee reports. For simulating what referees will say before submission, use the `journal-referee` agent. For pre-submission stress-testing of robustness, use `/stress-test`.
