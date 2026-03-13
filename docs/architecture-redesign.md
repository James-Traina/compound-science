# compound-science Architecture Redesign

## For External Review — March 2026 (Rev 3, incorporating two reviewer rounds)

This document describes a proposed restructuring of the compound-science Claude Code plugin. Rev 3 incorporates feedback from two external architecture reviews and verified platform documentation. Resolved decisions are marked; remaining open questions are at the end.

---

## 1. What compound-science does

compound-science is a Claude Code plugin for quantitative social science research: structural econometrics, causal inference, game theory, and reproducible pipelines. It provides AI-powered review, automation, and workflow orchestration for researchers doing estimation, simulation, identification arguments, and paper preparation.

The plugin uses four component types provided by Claude Code's plugin system:

- **Hooks** — fire automatically on lifecycle events (user submits a prompt, a file is edited, the model stops, context is compacted). They inject context or block actions.
- **Commands** — user-invocable via `/command-name`. Markdown files that instruct the model what to do.
- **Agents** — spawnable subagents with focused expertise. Each agent is a markdown file defining a role, perspective, and set of tools.
- **Skills** — reference knowledge that agents or the main model can load. Markdown files with domain-specific patterns, recipes, and decision trees.

---

## 2. The problem with the current architecture

The plugin grew organically to **59 components**: 7 hooks, 16 commands, 20 agents, and 16 skills. Three problems emerged.

### 2.1 Flat structure with unclear nesting

All four component types coexist at the same level. There's no clear hierarchy of responsibility. For example:

- `/identify` (command) and `identification-critic` (agent) both handle identification arguments. When should the user invoke the command vs. when should the hook surface the agent?
- `/replicate` (command) duplicates what `pipeline-validator` + `reproducibility-checker` (agents) already do.
- `/simulate` (command) is essentially "spawn `simulation-designer` and `process-architect` agents."

The user has to navigate 16 commands, many of which are thin wrappers around agent capabilities. This creates choice paralysis and redundancy.

### 2.2 Hook cost overhead

The plugin has 6 prompt-type hooks that fire on every user message, every file edit, and every model stop event. These hooks were running on the **session model** (typically Claude Opus), consuming the user's subscription allocation for simple classification tasks like "is this prompt about estimation?" and "is this file a research artifact?"

On a subscription plan, this doesn't cost extra dollars, but it burns through rate limits and adds latency.

### 2.3 Component overlap

Several components cover similar ground:

- `pipeline-validator` (structural audit) and `reproducibility-checker` (functional audit) both review replication packages
- `research-coordinator` (sequencing) and `progress-tracker` (inventory) both manage workflow state
- `process-architect` (theory → DGP) and `simulation-designer` (DGP → Monte Carlo) operate on adjacent steps of the same pipeline
- `benchmark-researcher` (find calibration targets) and `solutions-archivist` (search past solutions) are narrow retrieval functions that could be capabilities of broader agents or skills
- `specification-analyzer` (model → estimator → code tracing) overlaps substantially with `econometric-reviewer`'s code review scope

---

## 3. Design principles for the restructuring

### 3.1 Each layer has one job

Claude Code's plugin system has a natural hierarchy. We assign each layer a primary responsibility:

```
Hooks       → detect and advise
Commands    → orchestrate multi-phase workflows
Agents      → execute domain tasks autonomously
Skills      → provide reference knowledge
```

A component belongs in whichever layer matches its primary function. A command earns its place by requiring the **main model as a stateful coordinator** across multiple phases or interactions — whether that means spawning multiple agents, managing multi-turn dialogue with structured phases, or sequencing steps that depend on each other's output. A command that says "spawn one agent and follow this recipe" is really just a skill that the agent should load.

### 3.2 Commands exist only for genuine orchestration

By this criterion, `/workflows:brainstorm` qualifies despite not spawning agents — it manages a multi-turn structured dialogue. `/estimate` does not qualify — it's a sequential recipe that an agent can follow from a skill. The test is not "does it spawn agents?" but "does it need the main model as a stateful coordinator?"

### 3.3 Agents are leaf-level executors

Claude Code enforces this: **subagents cannot spawn other subagents** (one level deep only). This means agents are always the final execution layer. They can load skills for reference knowledge, but they can't delegate to other agents. All multi-agent coordination must happen from the main model context (i.e., from commands or the main conversation).

### 3.4 In this plugin, skills provide reference knowledge

Claude Code's skill system is prompt-based and flexible — skills can technically contain action instructions, spawn subagents, and use tools. However, **in compound-science**, we use skills as reference documents: recipes, decision trees, checklists, and domain patterns. Skills follow three-level progressive disclosure: metadata (description) → SKILL.md (overview + routing) → references/ (full procedures).

This is a project convention, not a platform limitation. We chose it because it keeps the layer separation clean: agents execute, skills inform. If a skill needs to take action, it belongs in an agent definition instead.

### 3.5 In this plugin, hooks detect and advise

Claude Code supports four hook types: **command** (shell scripts), **HTTP** (POST to endpoints), **prompt** (single-turn LLM evaluation), and **agent** (spawns a subagent with tools for multi-turn verification). All matching hooks run in parallel, and identical handlers are deduplicated automatically.

In compound-science, we use hooks primarily for **detection and guardrails**, not orchestration. Hooks can inject context (`additionalContext`, `systemMessage`), block actions (`decision: "block"`), and surface relevant capabilities. But they cannot trigger commands or spawn agents in the main conversation directly — the main model reads the hook's output and decides whether to act.

One exception: the **Stop hook** can block the model from stopping. When it blocks with a reason, the model almost always follows because it has no other directive. This makes Stop hooks effectively deterministic for completeness checks.

**Why prompt hooks, not agent hooks, for most events:** Agent hooks (which spawn subagents with tool access for multi-turn verification) are more powerful but slower and more expensive. Our classification tasks ("is this about estimation?", "does this file use statsmodels?") are single-turn pattern matching — prompt hooks handle them in ~200ms. We reserve the agent hook type as a potential upgrade path for the Stop hook, where multi-turn verification (reading files, checking outputs) would improve completeness judgments. See §5.4.

### 3.6 Use the cheapest model that works — and preserve rate limits

The primary argument for routing hooks to cheaper models is **latency and rate-limit preservation**, not cost. On a Pro subscription, every Opus call from a hook competes with the user's main conversation for the same rate-limit bucket. Although hooks run in parallel (so latency is the slowest matching hook, not the sum), Opus hooks still consume rate-limit capacity that the main conversation needs. This is the difference between "the plugin slows you down" and "the plugin is invisible."

Claude Code's prompt and agent hooks default to a fast model. We specify the model explicitly for two reasons: (1) to pin a specific version (`claude-haiku-4-5-20251001`) for stability, and (2) to override the default for the Stop hook, which uses a stronger model for judgment calls about research substance. See §5.4.

### 3.7 Plugin CLAUDE.md is awareness; hooks are temporal precision

An alternative approach (suggested by early reviewers) is to skip hooks entirely and put all auto-invocation rules in CLAUDE.md: "when you see estimation code, suggest the econometric-reviewer agent." Since plugins include their own CLAUDE.md that Claude reads when the plugin is active, this is technically feasible.

We rejected this as the primary mechanism for three reasons:

1. **Compaction degrades static instructions.** After context compaction (which happens routinely in long research sessions), CLAUDE.md instructions get summarized and may lose specificity. A hook fires fresh context at the exact moment it's needed — post-compaction or not. Our PreCompact hook exists precisely because CLAUDE.md instructions alone don't survive long sessions reliably.

2. **Plugin CLAUDE.md competes for attention.** A user may have 10+ plugins installed, each with its own CLAUDE.md, plus their global and project-level CLAUDE.md files. That's 12+ instruction sources. A hook's `systemMessage` arrives as a targeted injection at the relevant lifecycle moment, not as one paragraph among hundreds.

3. **Hooks can block deterministically.** CLAUDE.md can say "don't forget standard errors" but the model can ignore advisory text. A Stop hook returning `decision: "block"` is enforced by the Claude Code runtime regardless of model judgment.

The correct split: **CLAUDE.md provides awareness** (what agents exist, what skills do, domain vocabulary) while **hooks provide temporal precision** (detecting research context at prompt time, guarding tool use, checking completeness at stop). Each mechanism handles the failure mode of the other. As a backstop, the plugin CLAUDE.md carries a condensed (~20-line) routing table mapping domain signals to agents, providing post-compaction fallback.

### 3.8 Word-count budgets prevent bloat migration

Reducing component count doesn't help if the absorbed content makes surviving components too large for agent context windows. Claude Code injects the **full content** of preloaded skills into subagent context at startup. This means a bloated skill taxes every agent that loads it, every time it's spawned.

Explicit targets per layer:

| Layer | Target | Rationale |
|---|---|---|
| Agent prompts | ≤ 2,500 words each | Fits comfortably in subagent context alongside skill content |
| SKILL.md bodies | ≤ 2,000 words each | Overview + decision tree + routing to references/ |
| references/ files | Unlimited | Full procedures, loaded on demand by keyword from SKILL.md |
| Hook prompts | ≤ 5,000 chars each | Existing test-suite bloat guard (test 12-20) |
| Plugin CLAUDE.md | ≤ 3,000 words | Awareness only; no procedural recipes |

The 9 removed commands total ~20K words of procedural content. All of it migrates to `references/` files within skills — never into SKILL.md bodies or agent prompts. SKILL.md files serve as method-selection indexes that route to the right reference, not as repositories of procedural content.

---

## 4. The new architecture

### 4.1 Nesting model

```
Hooks (7: 5 Haiku, 1 Sonnet/agent, 1 bash)  ← detect context, surface agents + commands
  ↓ advise
Compound Commands (7 + 2 wrappers)            ← orchestrate multi-phase workflows only
  ↓ spawn
Agents (14)                                    ← execute domain tasks with preloaded skills
  ↓ preload
Skills (17)                                    ← provide reference knowledge (SKILL.md + references/)

Escape hatches:
  • Hooks surface agents directly when no workflow is needed
  • Main model spawns agents ad hoc based on conversation context
  • Skills loaded by any agent or the main model on demand
```

The nesting is conceptual and organizational, not enforced by the platform. The main model (Opus) is always the hub — every layer talks to it, and it orchestrates everything. But the hierarchy gives each component a clear role and reduces the surface area users need to navigate.

### 4.2 The compound loop

The plugin's core workflow is a loop:

```
Plan → Work → Review → Compound → Repeat
```

Each step is a command. The commands are the only user-facing orchestration interface. Everything else (agents, skills) operates behind the scenes, surfaced by hooks or spawned by commands.

Users can enter the loop at any point (`/workflows:plan`, `/workflows:work`, etc.) or run it end-to-end (`/lfg` for sequential, `/slfg` for parallel).

The key insight: **the compound loop is the only workflow that needs commands.** Domain tasks (estimation, simulation, identification, diagnostics, sensitivity analysis, table generation, replication) are things that happen *within* the loop — during the Work phase, Review phase, or Compound phase. They don't need their own top-level commands.

### 4.3 Ambient detection via hooks

The plugin detects research context automatically through 7 hooks:

1. **SessionStart** (bash command) — detects project type from file system signals
2. **UserPromptSubmit** (prompt, Haiku) — classifies user prompts into 14 research categories, surfaces relevant agents
3. **PostToolUse** (prompt, Haiku) — detects research file types when code is written/edited, surfaces relevant agents
4. **PreToolUse** (prompt, Haiku) — guards bash commands for reproducibility issues (seeds, paths, versions)
5. **Stop** (prompt or agent, Sonnet) — checks completeness conditions before the model finishes; uses a stronger model because it makes judgment calls about research substance. See §5.4 for the layered Stop design.
6. **PreCompact** (prompt, Haiku) — preserves research state before context compression
7. **SubagentStop** (prompt, Haiku) — severity-routes agent findings and suggests next steps

Hooks reference **agents** as the primary suggestion and mention the **compound loop** as the comprehensive alternative. Pattern: *"The `econometric-reviewer` agent can review this estimation code. For a full multi-agent review, use `/workflows:review`."*

---

## 5. Specific changes

### 5.1 Commands: 16 → 7 canonical + 2 wrappers

**Retained (7 canonical):**

| Command | Why it survives |
|---|---|
| `/workflows:brainstorm` | Multi-turn structured dialogue — requires main model as stateful coordinator |
| `/workflows:plan` | Spawns 4 research agents in parallel, synthesizes findings (absorbs `/deepen-plan`) |
| `/workflows:work` | Execution framework with quality gates — loads skills as needed |
| `/workflows:review` | Spawns 4-8 review agents dynamically in parallel — core multi-agent orchestration |
| `/workflows:compound` | Spawns parallel analysis agents, synthesizes solution documentation |
| `/lfg` | Sequential chain: plan → work → review → compound |
| `/slfg` | Parallel swarm chain |

**Thin routing wrappers (2, deprecated in v0.5, removed in v0.6):**

| Wrapper | Routes to | Rationale |
|---|---|---|
| `/estimate` | `/workflows:work` with estimation pipeline context | Estimation is how users think — this is an unusually natural intent that deserves a bridge. Routes into the work phase with `empirical-playbook` estimation recipe preloaded. |
| `/replicate` | `reproducibility-auditor` agent | Replication package assembly is a standalone task with strong user-facing semantics. Routes to the merged agent directly. |

These wrappers preserve discoverability during the transition without compromising the new architecture. They are thin routing layers, not full orchestration commands.

**Removed (7, no wrapper):**

| Former command | Where it went | Rationale |
|---|---|---|
| `/simulate` | `simulation-designer` agent | The command was essentially "spawn simulation-designer." Now the agent handles the full Monte Carlo design pipeline. |
| `/identify` | `identification-critic` agent | The command was a structured interview. The agent already does this; pipeline steps become part of its instructions + identification-proofs skill. |
| `/diagnose` | `empirical-playbook` skill (`references/diagnostic-battery.md`) | Sequential diagnostic battery. Pure recipe knowledge. |
| `/stress-test` | `empirical-playbook` skill (`references/sensitivity-analysis.md`) | Sequential sensitivity battery. Pure recipe knowledge. |
| `/tabulate` | `publication-output` skill (`references/table-generation.md`) | Table generation recipes. Loaded by `results-verifier` agent. |
| `/visualize` | `publication-output` skill (`references/figure-generation.md`) | Figure generation recipes. Loaded by `results-verifier` agent. |
| `/deepen-plan` | Merged into `/workflows:plan` | Plan enrichment IS planning. No reason for a separate command. |

**Migration path (decided):** Ship v0.5 with the 2 thin wrappers above plus deprecated stubs for the 7 removed commands. Stubs print a one-line redirect (e.g., *"/diagnose has moved to the diagnostic battery in the empirical-playbook skill. Use /workflows:work or ask the econometric-reviewer agent directly."*). Remove all stubs and wrappers in v0.6.

### 5.2 Agents: 20 → 14

**Six merges:**

| Merge | Result | Rationale |
|---|---|---|
| `benchmark-researcher` → `methods-explorer` | `methods-explorer` | Finding calibration targets and empirical benchmarks is a research task. The explorer already analyzes methods; benchmarks are a natural extension of "what does the literature say about this?" |
| `pipeline-validator` + `reproducibility-checker` → | `reproducibility-auditor` | Both audit the same artifact (replication package) at different levels. Becomes a two-phase agent: (1) structural audit, (2) functional verification. |
| `research-coordinator` + `progress-tracker` → | `workflow-coordinator` | "Where are we?" and "what's next?" are two sides of the same coordination function. |
| `calibration-assessor` → `econometric-reviewer` | `econometric-reviewer` | Calibration review is a specialized form of estimation review. The econometric-reviewer already covers moment conditions and instrument validity; calibration strategy (target selection, sensitivity to moments) is a natural extension. *Note: Reviewer 2 urged caution here. We proceed because in our specific domain, calibration review IS a subroutine of estimation review, not a distinct adversarial perspective.* |
| `specification-analyzer` → `econometric-reviewer` | `econometric-reviewer` | Tracing the model → estimator → code flow is exactly what the econometric-reviewer does during code review. The systematic checklist becomes part of the econometric-reviewer's instructions. *Both reviewers agreed this merge is correct.* |
| `solutions-archivist` → `compound-catalog` skill | (dissolved) | Searching `docs/solutions/` is a retrieval operation on local files — a skill capability, not an agent perspective. The `compound-catalog` skill gains a "Searching Past Solutions" section with grep patterns and search instructions. Any agent that loads the skill can search past solutions. |

**Merge NOT made (revised from original proposal):** `process-architect` → `simulation-designer` was rejected by both reviewers. DGP formalization from structural primitives is a **theory task** requiring understanding of economic models, equilibrium conditions, and data-generating assumptions. Monte Carlo experimental design is an **applied statistics task** — choosing sample sizes, replication counts, metrics, seed management. These require different skill preloads and different cognitive approaches. Merging them would require 4+ skills in one agent, violating the "no agent loads more than 3 skills" constraint. Both agents survive separately.

**Agent categories (14 agents):**

| Category | Count | Agents |
|---|---|---|
| Review | 8 | econometric-reviewer, mathematical-prover, numerical-auditor, identification-critic, journal-referee, simulation-designer, process-architect, equilibrium-analyst |
| Audit | 1 | results-verifier |
| Research | 3 | literature-scout, methods-explorer, data-detective |
| Workflow | 2 | reproducibility-auditor, workflow-coordinator |

Review agents have genuinely distinct adversarial **perspectives** — a referee thinks differently from an identification critic, and both think differently from a numerical auditor. Perspective diversity is the point of multi-agent review. Below 14 agents, perspective diversity starts to erode.

**Agent → skill assignments:**

| Agent | Preloaded skills (max 3) |
|---|---|
| econometric-reviewer | empirical-playbook, causal-inference |
| mathematical-prover | identification-proofs, game-theory |
| numerical-auditor | bayesian-estimation, structural-modeling |
| identification-critic | identification-proofs, causal-inference |
| journal-referee | submission-guide, empirical-playbook |
| simulation-designer | empirical-playbook, causal-ml |
| process-architect | structural-modeling, game-theory, identification-proofs |
| equilibrium-analyst | game-theory, structural-modeling |
| results-verifier | publication-output, empirical-playbook |
| literature-scout | (none — uses web search) |
| methods-explorer | (loaded contextually per task) |
| data-detective | data-acquisition, empirical-playbook |
| reproducibility-auditor | reproducible-pipelines |
| workflow-coordinator | compound-catalog, swarm-orchestration, strategy-brainstorm |

No agent loads more than 3 skills. No skill is orphaned without an agent that uses it.

### 5.3 Skills: 16 → 17

**Method domain skills (6) — unchanged:**

structural-modeling, causal-inference, causal-ml, game-theory, identification-proofs, bayesian-estimation

Eight of these have progressive disclosure: lean SKILL.md (250-350 lines) with detailed `references/` subdirectories (21 existing files total).

**Applied procedure skills (7):**

| Skill | Changes |
|---|---|
| `empirical-playbook` | **Absorbs** `/estimate`, `/diagnose`, `/stress-test` procedural content. SKILL.md stays as a **method-selection decision tree** (~2,000 words) that routes to three new reference files. |
| `reproducible-pipelines` | **Absorbs** `/replicate` replication package recipe (into `references/`). |
| `submission-guide` | Unchanged. |
| `referee-response` | Unchanged. |
| `data-acquisition` | Unchanged. |
| `publication-output` | **NEW.** SKILL.md provides overview of publication-quality output patterns. Two reference files carry the procedural recipes. |
| `git-worktree` | Unchanged. Parallel branch management for concurrent estimation runs. |

**Progressive disclosure for absorbed commands:**

```
skills/empirical-playbook/
  SKILL.md                           ≤2,000 words — method selection decision tree
  references/
    estimation-pipeline.md           5-phase gated pipeline (from /estimate)
    diagnostic-battery.md            Specification tests + residual analysis (from /diagnose)
    sensitivity-analysis.md          Oster bounds + specification curve (from /stress-test)
    (existing reference files)

skills/publication-output/
  SKILL.md                           ≤2,000 words — output type routing
  references/
    table-generation.md              Publication-ready tables (from /tabulate)
    figure-generation.md             Research visualizations (from /visualize)

skills/reproducible-pipelines/
  references/
    replication-package.md           AEA-compliant replication (from /replicate)
    (existing reference files)
```

The estimation-pipeline reference preserves **phase-gate logic** from the original `/estimate` command: explicit quality gates between phases ("do not proceed to standard errors until convergence is confirmed"), not a flat checklist. This is the highest-risk migration — if the reference reads as a flat checklist rather than a gated pipeline, the quality-gate behavior will degrade. The `econometric-reviewer` agent's prompt must explicitly preserve phase sequencing when following this recipe during `/workflows:work`.

**Process/meta skills (4):**

| Skill | Changes |
|---|---|
| `compound-catalog` | **Absorbs** `solutions-archivist` retrieval capability. Gains a "Searching Past Solutions" section with grep patterns and search instructions for `docs/solutions/`. Any agent that loads this skill can search past solutions. |
| `strategy-brainstorm` | Unchanged. |
| `project-setup` | Unchanged. |
| `swarm-orchestration` | Unchanged. |

### 5.4 Hooks: 7 → 7 (with layered Stop design)

Structure unchanged. Four modifications:

**1. Five classification hooks specify `"model": "claude-haiku-4-5-20251001"`.**

These hooks handle pattern-matching tasks: "does this prompt mention estimation?", "is this file a .do file?", "does this bash command have a seed?" Claude Code's prompt hooks already default to a fast model; we specify explicitly to pin the version for stability.

**2. Stop hook uses a stronger model and potentially a different hook type.**

The Stop hook makes judgment calls about research completeness: "were standard errors appropriate for the clustering structure?", "was the identification design validated before magnitudes were interpreted?" This requires understanding the *substance* of what happened in the session.

Two options under consideration:

- **Option A (prompt hook, Sonnet):** Simple. One Sonnet prompt call per session end evaluates 10 completeness conditions against a summary of what happened. Cost: one Sonnet call per session — negligible. Limitation: the hook sees only the prompt text and event metadata, not the full session.

- **Option B (agent hook):** More powerful. Claude Code's `type: "agent"` hook spawns a subagent with tool access (Read, Grep, Glob). The agent could read output files, check for seed configuration in scripts, and verify standard error computation — not just classify keywords. Limitation: slower (spawns a full subagent context), more expensive, and adds ~5-10 seconds to session end.

Both reviewers agree the Stop hook should not use Haiku. The choice between Sonnet prompt and agent hook depends on whether the completeness checks require file-level verification (favoring agent) or conversation-level judgment (favoring prompt). See open question §9.1.

**3. Domain-specific completeness via agent-scoped hooks.**

Claude Code supports hooks defined in agent frontmatter. Stop hooks in agent frontmatter auto-convert to SubagentStop events. This enables a **layered Stop architecture**:

- **Agent-scoped hooks** check domain-specific completeness when each agent finishes (e.g., econometric-reviewer's SubagentStop verifies standard errors were addressed; simulation-designer's SubagentStop verifies seeds were set).
- **Global Stop hook** checks only cross-cutting conditions (results saved, replication package suggested, no unseeded simulations in the session).

This distributes the 10 completeness conditions across the agents best positioned to evaluate them, rather than centralizing everything in one global hook. The global Stop hook becomes leaner and more reliable.

**4. Hook prompts reference agents as primary suggestion, compound loop as alternative.**

Pattern: *"The `econometric-reviewer` agent can review this estimation code. For a full multi-agent review, use `/workflows:review`."* This gives users both the surgical option (spawn one agent) and the workflow option (run the loop).

---

## 6. What the user experiences

### Before (v0.4.x)

The user sees 16 slash commands and must decide which to invoke:

```
/estimate, /simulate, /identify, /diagnose, /tabulate,
/replicate, /visualize, /stress-test, /deepen-plan,
/workflows:brainstorm, /workflows:plan, /workflows:work,
/workflows:review, /workflows:compound, /lfg, /slfg
```

Many of these overlap ("should I run `/diagnose` or `/stress-test`?"). The user must also understand when to use commands vs. when agents fire automatically.

### After (v0.5)

The user sees 7 canonical commands — all part of one workflow — plus 2 familiar wrappers:

```
/workflows:brainstorm → /workflows:plan → /workflows:work →
/workflows:review → /workflows:compound
/lfg (run all sequentially)
/slfg (run all in parallel)

/estimate (routes to /workflows:work with estimation context)
/replicate (routes to reproducibility-auditor agent)
```

Everything else happens automatically. The hooks detect context and surface the right agents. The user focuses on their research; the plugin handles the tooling.

For power users who want explicit control, the agents are still spawnable by name ("spawn the `identification-critic` agent to review my exclusion restriction"). But no one needs to memorize 16 commands.

### After (v0.6)

The 2 wrappers and all deprecated stubs are removed. 7 commands remain.

---

## 7. Trade-offs

### 7.1 Gained

- **Simpler mental model**: 7 canonical commands instead of 16. One workflow loop.
- **Cleaner nesting**: every component has one role in the hierarchy.
- **Rate-limit preservation**: Haiku/Sonnet hooks instead of Opus hooks. Hooks run in parallel (latency = slowest hook, not sum), and classification hooks don't compete with the user's main conversation for Opus rate limits.
- **Less overlap**: 6 agent merges and 1 dissolution eliminate redundant perspectives while preserving adversarial diversity.
- **Better discoverability**: hooks surface the right agent at the right moment with a compound-loop fallback.
- **Controlled content migration**: word-count budgets (§3.8) and progressive disclosure prevent absorbed command content from bloating agent prompts or SKILL.md bodies.
- **Layered completeness checking**: domain-specific checks move to agent-scoped hooks; global Stop becomes leaner and more reliable.

### 7.2 Lost

- **Explicit invocation of domain tasks**: Users can no longer type `/diagnose` or `/stress-test` directly. They must either (a) let hooks surface the capability, (b) spawn the agent by name, or (c) run `/workflows:review`. The `/estimate` and `/replicate` wrappers bridge the two strongest intents.

- **Granular command control**: `/estimate` gave users a guided 5-step pipeline they could invoke at will. Now that pipeline is a skill reference loaded by agents during `/workflows:work`. The wrapper routes to the right context, but the v0.6 removal means users must eventually learn the new model.

- **Agent specialization breadth**: `econometric-reviewer` absorbs calibration-assessor and specification-analyzer responsibilities, making it the broadest agent. The word-count budget (≤2,500 words) constrains this risk. If the agent loses focus, the calibration checklist can migrate to a skill it preloads.

### 7.3 Mitigated risks

- **Hook reliability**: Hooks advise, they don't command (in this plugin). The main model might ignore a hook's suggestion. Mitigation: the Stop hook can block, which is deterministic. For UserPromptSubmit and PostToolUse, Opus reliably follows system-injected suggestions in practice.

- **Subagent nesting limit**: Agents can't spawn other agents. Mitigation: all multi-agent coordination happens from commands (main context). The nesting model respects this constraint by design.

- **Migration disruption**: Thin wrappers for `/estimate` and `/replicate` plus deprecated stubs for other commands provide a bridge. Clean removal in v0.6.

- **Empirical-playbook scope**: All procedural content goes to `references/` files. The SKILL.md stays as a 2,000-word method-selection index. Since skills inject full SKILL.md content at startup, this keeps agent context lean.

- **Stop hook accuracy**: Stop uses a stronger model (Sonnet or agent hook) for judgment calls. Classification hooks use Haiku. Agent-scoped SubagentStop hooks distribute domain-specific checks to the agents best positioned to evaluate them.

---

## 8. Resolved decisions

These questions were raised in Rev 1 and resolved through two rounds of external review:

| # | Question | Decision | Reviewer consensus |
|---|---|---|---|
| 1 | Is 7 commands the right number? | **7 canonical + 2 wrappers.** Keep `/estimate` and `/replicate` as thin routing wrappers for v0.5 (strong user intents that deserve a bridge). Remove in v0.6. | R1: commit to 7. R2: keep 2 wrappers. Adopted R2's pragmatic approach. |
| 2 | Are the agent merges correct? | **Revised.** Keep process-architect separate (theory ≠ applied stats; both reviewers agreed). Merge calibration-assessor + specification-analyzer into econometric-reviewer. Solutions-archivist dissolved into compound-catalog skill. Net: 14 agents. | R1: merge calibration-assessor. R2: be cautious. We proceed — calibration IS a subroutine of estimation review in our domain. |
| 3 | Is empirical-playbook absorbing too much? | **No, with progressive disclosure.** SKILL.md is a 2,000-word decision tree. Three absorbed recipes go to `references/` files. Phase-gate logic preserved in estimation-pipeline.md. | Both reviewers agreed: index + references is correct. |
| 4 | Should hooks reference commands or agents? | **Both.** Agents as primary suggestion, compound loop as alternative. Plugin CLAUDE.md carries a condensed routing table as post-compaction backstop. | Both reviewers agreed on hybrid approach. |
| 5 | Is Haiku appropriate for the Stop hook? | **No.** Stop uses Sonnet (prompt) or spawns an agent hook for multi-turn verification. Other 5 classification hooks use Haiku. | Both reviewers agreed: Stop requires judgment, not just classification. |
| 6 | What's the migration path? | **Thin wrappers + stubs.** `/estimate` and `/replicate` route to the right workflow/agent. Other 7 removed commands print redirect messages. All removed in v0.6. | R1: deprecated stubs. R2: functional wrappers for strong intents. Combined approach. |
| 7 | Are 14 agents too many? | **14 is the right number.** Below this, adversarial perspective diversity erodes. Each surviving review agent has a genuinely distinct stance. | R1: 14 is the floor. R2: target 13 (merge spec-analyzer). We merged spec-analyzer AND calibration-assessor, arriving at 14. |
| 8 | Should methods-explorer absorb three functions? | **Two, not three.** Absorbs benchmark-researcher (coherent — both survey literature). Solutions-archivist becomes a compound-catalog skill capability. | Both reviewers agreed: solution search is a skill capability, not an agent responsibility. |

## 9. Remaining open questions

1. **Should the Stop hook use a Sonnet prompt or an agent hook?** Agent hooks spawn a subagent with tool access (Read, Grep, Glob) for multi-turn verification. This enables file-level checks (did the script actually set a seed? did the output include standard errors?) but adds ~5-10 seconds. Sonnet prompt hooks are faster but limited to conversational judgment. Which completeness checks actually require file-level verification?

2. **How should domain-specific completeness checks distribute across agent-scoped SubagentStop hooks vs. the global Stop hook?** Candidate distribution: agent-scoped hooks handle method-specific checks (SEs after estimation, seeds after simulation, regularity conditions after proofs), global Stop handles cross-cutting checks (results saved, replication package). How granular should agent-scoped hooks be?

3. **Should the econometric-reviewer's expanded scope be split across instructions vs. skills?** It now covers estimation review (original), calibration strategy (from calibration-assessor), and specification flow tracing (from specification-analyzer). Should the calibration and spec-flow checklists live in the agent prompt, or in a skill it preloads? If calibration review proves to be a distinct perspective in practice, it can be re-extracted.

4. **How should the deprecated wrappers handle arguments?** If a user types `/estimate --method gmm`, should the wrapper (a) ignore arguments and just route to `/workflows:work`, or (b) translate to a natural-language instruction for the agent?

5. **Should the plugin CLAUDE.md routing table be auto-generated from hooks.json?** This would ensure the backstop stays in sync with hook behavior. But it adds a build step to what is currently a zero-build-step plugin.

---

## Appendix A: Full component inventory (45 canonical + 2 wrappers = 47)

### Commands (7 canonical + 2 wrappers)

```
commands/
  workflows/
    brainstorm.md      Multi-turn structured research exploration
    plan.md            Implementation planning (+ parallel agent enrichment)
    work.md            Plan execution with quality gates
    review.md          Multi-agent parallel review (4-8 agents)
    compound.md        Solution extraction to docs/
  lfg.md               Sequential chain: plan → work → review → compound
  slfg.md              Parallel swarm chain
  estimate.md          [WRAPPER v0.5 only] Routes to /workflows:work + estimation
  replicate.md         [WRAPPER v0.5 only] Routes to reproducibility-auditor agent
```

### Agents (14)

```
agents/
  review/
    econometric-reviewer.md     Identification, inference, SE, calibration, spec-flow review
    mathematical-prover.md      Proof verification, logical completeness
    numerical-auditor.md        Floating-point stability, convergence, RNG
    identification-critic.md    Adversarial identification scrutiny (+ /identify pipeline)
    journal-referee.md          Top-5 referee simulation
    simulation-designer.md      Monte Carlo experimental design (sample sizes, metrics, seeds)
    process-architect.md        Theory → DGP formalization from structural primitives
    equilibrium-analyst.md      Equilibrium existence/uniqueness/stability
  audit/
    results-verifier.md         Code → tables → manuscript tracing
  research/
    literature-scout.md         Systematic literature surveys
    methods-explorer.md         Estimator analysis + benchmarks (absorbed benchmark-researcher)
    data-detective.md           Data quality profiling
  workflow/
    reproducibility-auditor.md  Pipeline structure + end-to-end replication
    workflow-coordinator.md     Research coordination + progress tracking
```

### Skills (17)

```
skills/
  structural-modeling/         NFXP, MPEC, BLP, dynamic discrete choice, auctions
  causal-inference/            IV/2SLS, DiD, RDD, synthetic control, matching
  causal-ml/                   Double ML, causal forests, DR-Learner, post-LASSO
  game-theory/                 Nash/SPE/BNE, entry models, conduct, bargaining
  identification-proofs/       Formal identification arguments (+ /identify recipe)
  bayesian-estimation/         MCMC, Stan/PyMC/Numpyro, prior elicitation, diagnostics
  empirical-playbook/          Method selection decision tree + 3 procedure references
    references/
      estimation-pipeline.md   5-phase gated estimation (from /estimate)
      diagnostic-battery.md    Specification tests + residual analysis (from /diagnose)
      sensitivity-analysis.md  Oster bounds + spec curve (from /stress-test)
  reproducible-pipelines/      Make/Snakemake/DVC, environments, replication
    references/
      replication-package.md   AEA-compliant replication (from /replicate)
  submission-guide/            Journal formatting, referee response, revision strategy
  referee-response/            Structured author response protocol
  data-acquisition/            FRED and World Bank API access
  publication-output/          Publication-quality output patterns
    references/
      table-generation.md     Tables: regression, summary stats, MC output (from /tabulate)
      figure-generation.md    Figures: event study, RD, coefficient, power (from /visualize)
  git-worktree/                Parallel branches for concurrent estimation runs
  compound-catalog/            Solution documentation + past-solutions search (absorbed archivist)
  strategy-brainstorm/         Structured brainstorming techniques
  project-setup/               Project-specific configuration
  swarm-orchestration/         Multi-agent parallel execution patterns
```

### Hooks (7)

```
hooks/
  hooks.json                   All hook definitions
  session-start.sh             Project type detection (SessionStart)

  SessionStart        bash command           Project detection
  UserPromptSubmit    prompt (Haiku, pinned)  14-category domain detector
  PostToolUse         prompt (Haiku, pinned)  11-category file type detector
  PreToolUse          prompt (Haiku, pinned)  5-rule reproducibility guard
  Stop                prompt/agent (Sonnet)   Completeness checker (cross-cutting)
  PreCompact          prompt (Haiku, pinned)  10-category state preservation
  SubagentStop        prompt (Haiku, pinned)  Severity-routed next-step advisor
```

## Appendix B: Migration map

| v0.4.x component | v0.5 component | Type change |
|---|---|---|
| `/estimate` command | `/estimate` wrapper → `/workflows:work` + estimation | command → thin wrapper (v0.5), removed v0.6 |
| `/simulate` command | `simulation-designer` agent | command → agent |
| `/identify` command | `identification-critic` agent | command → agent |
| `/diagnose` command | `empirical-playbook` skill `references/diagnostic-battery.md` | command → skill reference (stub in v0.5) |
| `/stress-test` command | `empirical-playbook` skill `references/sensitivity-analysis.md` | command → skill reference (stub in v0.5) |
| `/tabulate` command | `publication-output` skill `references/table-generation.md` | command → skill reference (stub in v0.5) |
| `/visualize` command | `publication-output` skill `references/figure-generation.md` | command → skill reference (stub in v0.5) |
| `/replicate` command | `/replicate` wrapper → `reproducibility-auditor` agent | command → thin wrapper (v0.5), removed v0.6 |
| `/deepen-plan` command | `/workflows:plan` command | command → command (absorbed, stub in v0.5) |
| `process-architect` agent | `process-architect` agent | (unchanged — merge rejected by both reviewers) |
| `benchmark-researcher` agent | `methods-explorer` agent | agent → agent (MERGED) |
| `solutions-archivist` agent | `compound-catalog` skill | agent → skill capability (DISSOLVED) |
| `pipeline-validator` agent | `reproducibility-auditor` agent | agent → agent (MERGED) |
| `reproducibility-checker` agent | `reproducibility-auditor` agent | agent → agent (MERGED) |
| `research-coordinator` agent | `workflow-coordinator` agent | agent → agent (MERGED) |
| `progress-tracker` agent | `workflow-coordinator` agent | agent → agent (MERGED) |
| `calibration-assessor` agent | `econometric-reviewer` agent | agent → agent (MERGED) |
| `specification-analyzer` agent | `econometric-reviewer` agent | agent → agent (MERGED) |
