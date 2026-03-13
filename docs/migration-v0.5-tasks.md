# v0.5 Migration Plan

Architecture redesign: 59 → 48 components. Nesting: hooks detect → commands orchestrate → agents execute → skills inform.

Reference: `docs/architecture-redesign.md` (Rev 3).

## Migration strategy

The migration follows a **bottom-up, additive-first** sequence. We build landing zones (skills, reference files) before merging the agents that use them, merge agents before reducing the commands that reference them, and update hooks last because hook prompts name agents and commands that must exist first. Every phase is independently committable. No phase leaves the plugin in a broken state.

The critical invariant throughout: **the test suite never goes red between commits.** If a phase breaks tests, the phase is wrong — not the tests. Tests are updated within each phase to reflect the new structure, not deferred.

### Why this ordering

```
Phase 0  Baseline       ← measure everything before touching anything
Phase 1  Hook models    ← one-file change, highest immediate ROI (rate limits)
Phase 2  Skills         ← additive: create landing zones, delete nothing
Phase 3  Agent merges   ← reductive: merge/dissolve agents into prepared targets
Phase 4  Commands       ← reductive: remove commands that now point to merged agents + new skills
Phase 5  Hook prompts   ← update: references to agents/commands changed in Phases 3-4
Phase 6  Documentation  ← reflects all structural changes, version bump
Phase 7  Test suite     ← adapt hardcoded counts, add migration-specific assertions
Phase 8  Final gate     ← eval score ≥ baseline, word count ≤ baseline, tag v0.5.0
```

Each phase depends on the previous one's exit gate passing. If an eval surfaces a problem, fix it before advancing — never carry debt forward.

### What to watch for

- **Word count creep**: when merging agents, the temptation is to keep everything from both sources. Resist. The merged agent should be *shorter* than the sum of its parts, because overlap was the reason for the merge.
- **Phase-gate preservation**: the `/estimate` pipeline has explicit quality gates ("do not proceed to SE until convergence confirmed"). When migrating this to `references/estimation-pipeline.md`, the gates must survive. A flat checklist is a regression.
- **Hook char limits**: UserPromptSubmit is at 4,976/5,000 chars. When updating hook prompts in Phase 5, adding new agent names can push past the limit. Shorten elsewhere first.
- **Cross-reference cascades**: deleting an agent in Phase 3 can break references in hooks (Phase 5), CLAUDE.md (Phase 6), and tests (Phase 7). The Eval 3 dangling-reference check catches this early.

### Baselines (recorded in Phase 0, referenced by all later evals)

| Metric | v0.4.4 baseline | v0.5 target |
|---|---|---|
| Components | 59 | 47 (14 agents + 17 skills + 7 hooks + 7 commands + 2 wrappers; stubs are temporary) |
| Total words | 125,286 | ≤ 125,286 (must not grow) |
| Tests passing | 307/307 | ≥ 307 (may add tests) |
| Eval score | 49/50 (Grade A) | ≥ 49/50 |
| Agent max words | 2,618 (journal-referee) | ≤ 2,500 |
| SKILL.md max words | 4,089 (identification-proofs) | ≤ 2,000 |
| Hook max chars | 4,976 (UPS) | ≤ 5,000 |

---

## Phase 0 — Baseline capture

No code changes. Record numbers that every subsequent phase is measured against. These baselines are the standard of comparison for the entire migration — if we can't measure it, we can't prove the migration improved anything.

- [ ] **0.1** Run full test suite, record pass/fail/warn counts
  ```bash
  bash .tests/run-all.sh 2>&1 | tail -5
  ```
- [ ] **0.2** Run eval harness, record dimension scores and total
  ```bash
  python3 .evals/grade.py --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Total: {d[\"total\"]}/50'); [print(f'  {k}: {v}') for k,v in d['scores'].items()]"
  ```
- [ ] **0.3** Record component inventory baseline
  ```bash
  echo "Agents:   $(find agents/ -name '*.md' | wc -l | tr -d ' ')"
  echo "Commands: $(find commands/ -name '*.md' | wc -l | tr -d ' ')"
  echo "Skills:   $(find skills/ -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')"
  echo "Hooks:    $(python3 -c "import json; print(len(json.load(open('hooks/hooks.json'))['hooks']))")"
  echo "Total:    $(( $(find agents/ -name '*.md' | wc -l) + $(find commands/ -name '*.md' | wc -l) + $(find skills/ -maxdepth 1 -mindepth 1 -type d | wc -l) + $(python3 -c "import json; print(len(json.load(open('hooks/hooks.json'))['hooks']))") ))"
  ```
- [ ] **0.4** Record word counts by layer
  ```bash
  echo "Agents:   $(find agents/ -name '*.md' -exec cat {} + | wc -w | tr -d ' ') words"
  echo "Commands: $(find commands/ -name '*.md' -exec cat {} + | wc -w | tr -d ' ') words"
  echo "Skills:   $(find skills/ -name '*.md' -exec cat {} + | wc -w | tr -d ' ') words"
  echo "Hooks:    $(wc -w < hooks/hooks.json | tr -d ' ') words"
  echo "CLAUDE:   $(wc -w < CLAUDE.md | tr -d ' ') words"
  ```
- [ ] **0.5** Record hook prompt char counts
  ```bash
  python3 -c "
  import json
  d = json.load(open('hooks/hooks.json'))
  for e, ms in d['hooks'].items():
      for m in ms:
          for h in m['hooks']:
              if h.get('type') == 'prompt':
                  print(f'{e}: {len(h[\"prompt\"]):,} chars  ({\"OK\" if len(h[\"prompt\"]) <= 5000 else \"OVER\"})')
  "
  ```
- [ ] **0.6** Git tag `v0.4.4-pre-migration`

**Exit gate:** All numbers recorded. No code changed. Tag exists.

---

## Phase 1 — Hook model routing

**Why first:** This is the single highest-ROI change in the entire migration — one file (`hooks/hooks.json`), six fields added. Every subsequent session benefits from Haiku classification speed and preserved Opus rate limits. It's also fully reversible (delete the `model` fields to revert) and doesn't change any component structure, so the test suite passes without modification.

**What changes:** Add `"model": "claude-haiku-4-5-20251001"` to 5 classification hooks. Add `"model": "claude-sonnet-4-6"` to the Stop hook (judgment, not classification). SessionStart is a bash command hook — no model field needed.

**Risk:** Near zero. The `model` field is additive. If a model string is invalid, Claude Code falls back to the session model.

- [ ] **1.1** Add `"model": "claude-haiku-4-5-20251001"` to all 6 prompt hooks
- [ ] **1.2** Override Stop hook model to `"model": "claude-sonnet-4-6"` (judgment, not classification)

### Eval 1 — Hook model fields

```bash
# PASS: every prompt hook has an explicit model field
python3 -c "
import json, sys
d = json.load(open('hooks/hooks.json'))
ok = True
for e, ms in d['hooks'].items():
    for m in ms:
        for h in m['hooks']:
            if h.get('type') == 'prompt':
                model = h.get('model', 'MISSING')
                status = 'PASS' if model != 'MISSING' else 'FAIL'
                print(f'  [{status}] {e}: model={model}')
                if model == 'MISSING': ok = False
if not ok: sys.exit(1)
print('All prompt hooks have explicit model fields.')
"

# PASS: Stop uses sonnet, others use haiku
python3 -c "
import json, sys
d = json.load(open('hooks/hooks.json'))
for e, ms in d['hooks'].items():
    for m in ms:
        for h in m['hooks']:
            if h.get('type') != 'prompt': continue
            model = h.get('model','')
            if e == 'Stop':
                assert 'sonnet' in model, f'Stop should use sonnet, got {model}'
            else:
                assert 'haiku' in model, f'{e} should use haiku, got {model}'
print('PASS: model routing correct (Stop=sonnet, rest=haiku)')
"
```

```bash
# PASS: tests still pass (hook structure unchanged except model field)
bash .tests/run-all.sh 01 10 12
```

**Exit gate:** All 3 eval blocks green. Commit.

---

## Phase 2 — Skill preparation

**Why now:** Skills are the landing zones for content that will migrate out of commands (Phase 4) and into agents (Phase 3). Building them first means the agents and commands can reference real files, not placeholders. This phase is purely additive — we create new files and add sections to existing files. Nothing is deleted. The test suite should pass with zero modifications (new files don't break existing assertions).

**What changes:** Create `publication-output` skill (new). Add 3 reference files to `empirical-playbook` (from `/estimate`, `/diagnose`, `/stress-test`). Add 2 reference files to `publication-output` (from `/tabulate`, `/visualize`). Verify `replication-package.md` exists in `reproducible-pipelines`. Update `compound-catalog` with solution-search capability (from `solutions-archivist` dissolution in Phase 3).

**Risk:** The main risk is SKILL.md bloat. The estimation-pipeline reference must preserve phase-gate logic, not flatten into a checklist. Eval 2 checks this explicitly (grep for gate keywords). The SKILL.md files themselves must stay ≤2,000 words — they're indexes, not encyclopedias. The current `identification-proofs` SKILL.md is at 4,089 words, which already violates our target. This needs trimming in this phase (move excess to references/).

### 2A — Create `publication-output` skill

- [ ] **2A.1** Create `skills/publication-output/SKILL.md` (≤2,000 words) — output type routing index
- [ ] **2A.2** Create `skills/publication-output/references/table-generation.md` — migrate `/tabulate` procedural content
- [ ] **2A.3** Create `skills/publication-output/references/figure-generation.md` — migrate `/visualize` procedural content

### 2B — Extend `empirical-playbook` references

- [ ] **2B.1** Create `skills/empirical-playbook/references/estimation-pipeline.md` — migrate `/estimate` 5-phase gated pipeline. **Critical**: preserve phase-gate logic, not a flat checklist.
- [ ] **2B.2** Create `skills/empirical-playbook/references/diagnostic-battery.md` — migrate `/diagnose` battery
- [ ] **2B.3** Create `skills/empirical-playbook/references/sensitivity-analysis.md` — migrate `/stress-test` recipes

### 2C — Extend `reproducible-pipelines` references

- [ ] **2C.1** Verify `skills/reproducible-pipelines/references/replication-package.md` already exists (from v0.4.4 split). If not, create it from `/replicate` content.

### 2D — Update `compound-catalog` skill

- [ ] **2D.1** Add "Searching Past Solutions" section to compound-catalog SKILL.md with grep patterns and search instructions for `docs/solutions/`

### Eval 2 — Skill word counts and structure

```bash
# PASS: all SKILL.md files ≤ 2,000 words
find skills/ -name "SKILL.md" -exec sh -c '
  words=$(wc -w < "$1")
  name=$(echo "$1" | sed "s|skills/||;s|/SKILL.md||")
  if [ "$words" -gt 2000 ]; then
    echo "  [FAIL] $name: $words words (limit 2000)"
    exit 1
  else
    echo "  [PASS] $name: $words words"
  fi
' _ {} \;
echo ""

# PASS: new reference files exist
for f in \
  skills/publication-output/SKILL.md \
  skills/publication-output/references/table-generation.md \
  skills/publication-output/references/figure-generation.md \
  skills/empirical-playbook/references/estimation-pipeline.md \
  skills/empirical-playbook/references/diagnostic-battery.md \
  skills/empirical-playbook/references/sensitivity-analysis.md; do
  [ -f "$f" ] && echo "  [PASS] $f exists" || echo "  [FAIL] $f missing"
done
echo ""

# PASS: estimation-pipeline.md has phase gates (not flat checklist)
grep -c "do not proceed\|before proceeding\|gate\|checkpoint\|confirm.*before" \
  skills/empirical-playbook/references/estimation-pipeline.md | \
  xargs -I{} sh -c '[ {} -ge 3 ] && echo "  [PASS] estimation-pipeline has {} phase gates" || echo "  [FAIL] estimation-pipeline has only {} phase gates (need ≥3)"'

# PASS: skill count is now 17
count=$(find skills/ -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
[ "$count" -eq 17 ] && echo "  [PASS] skill count = $count" || echo "  [FAIL] skill count = $count (expected 17)"

# PASS: total SKILL.md word count did not grow by more than 2,000 words vs baseline
# (publication-output SKILL.md is new; others should not have grown)
```

```bash
# PASS: existing tests still pass (additive changes only)
bash .tests/run-all.sh
```

**Exit gate:** 17 skills. All SKILL.md ≤2,000 words. 6 new reference files exist. Estimation pipeline has ≥3 phase gates. Full suite passes. Commit.

---

## Phase 3 — Agent merges

**Why now:** With skill landing zones built (Phase 2), agents can be merged and assigned their new skill preloads. This is the most structurally complex phase — 6 merges and 1 dissolution, touching 14 of 20 agent files. The key discipline: merged agents must be **shorter than the sum of parts**. Overlap was the reason for the merge; the merged agent should eliminate the overlap, not concatenate it.

**What changes:** 20 agents → 14. Delete 8 agent files, create 2 new ones (reproducibility-auditor, workflow-coordinator), modify 2 existing ones (econometric-reviewer absorbs 2, methods-explorer absorbs 1). Dissolve solutions-archivist entirely (capability moved to compound-catalog skill in Phase 2).

**Risk:** The econometric-reviewer absorbs calibration-assessor AND specification-analyzer, making it the broadest agent. Its word count must stay ≤2,500. If it can't fit, the calibration checklist should migrate to a preloaded skill rather than staying in the agent prompt. Second risk: dangling references. Every hook prompt, CLAUDE.md line, and test file that mentions a deleted agent name will need updating (Phases 5-7). Eval 3 flags these early so they don't cascade.

### Merge order (dependency-safe):

1. **Independent merges** (no cross-dependencies, can parallelize):
   - 3A: calibration-assessor → econometric-reviewer
   - 3B: specification-analyzer → econometric-reviewer
   - 3C: benchmark-researcher → methods-explorer
   - 3D: solutions-archivist → compound-catalog skill (dissolution)
2. **Paired merges** (internal dependencies):
   - 3E: pipeline-validator + reproducibility-checker → reproducibility-auditor
   - 3F: research-coordinator + progress-tracker → workflow-coordinator

### 3A — Merge `calibration-assessor` into `econometric-reviewer`

- [ ] **3A.1** Integrate calibration-assessor's unique content (target selection, sensitivity to moments, calibration strategy review) into econometric-reviewer.md
- [ ] **3A.2** Add `skills:` frontmatter if not present: `[empirical-playbook, causal-inference]`
- [ ] **3A.3** Delete `agents/review/calibration-assessor.md`
- [ ] **3A.4** Verify econometric-reviewer.md ≤2,500 words

### 3B — Merge `specification-analyzer` into `econometric-reviewer`

- [ ] **3B.1** Integrate spec-flow tracing checklist (model → estimator → code) into econometric-reviewer.md
- [ ] **3B.2** Delete `agents/audit/specification-analyzer.md` (or `agents/workflow/` — check actual location)
- [ ] **3B.3** Verify econometric-reviewer.md still ≤2,500 words after both merges

### 3C — Merge `benchmark-researcher` into `methods-explorer`

- [ ] **3C.1** Integrate calibration-target hunting and empirical benchmark retrieval into methods-explorer.md
- [ ] **3C.2** Delete `agents/research/benchmark-researcher.md`
- [ ] **3C.3** Verify methods-explorer.md ≤2,500 words

### 3D — Dissolve `solutions-archivist`

- [ ] **3D.1** Verify compound-catalog SKILL.md has "Searching Past Solutions" section (from 2D.1)
- [ ] **3D.2** Delete `agents/research/solutions-archivist.md`
- [ ] **3D.3** Verify no other component hard-references `solutions-archivist` by name (grep all .md and .json files)

### 3E — Merge `pipeline-validator` + `reproducibility-checker` → `reproducibility-auditor`

- [ ] **3E.1** Create `agents/workflow/reproducibility-auditor.md` with two-phase structure: (1) structural audit, (2) functional verification
- [ ] **3E.2** Add `skills: [reproducible-pipelines]` to frontmatter
- [ ] **3E.3** Delete `agents/workflow/pipeline-validator.md` and `agents/workflow/reproducibility-checker.md`
- [ ] **3E.4** Verify reproducibility-auditor.md ≤2,500 words

### 3F — Merge `research-coordinator` + `progress-tracker` → `workflow-coordinator`

- [ ] **3F.1** Create `agents/workflow/workflow-coordinator.md` combining coordination + progress tracking
- [ ] **3F.2** Add `skills: [compound-catalog, swarm-orchestration, strategy-brainstorm]` to frontmatter
- [ ] **3F.3** Delete `agents/workflow/research-coordinator.md` and `agents/workflow/progress-tracker.md`
- [ ] **3F.4** Verify workflow-coordinator.md ≤2,500 words

### 3G — Trim over-budget existing agents

The baselines table shows journal-referee at 2,618 words (target ≤2,500). Merges are not the only source of bloat — existing agents that already exceed the budget need trimming too.

- [ ] **3G.1** Trim `agents/review/journal-referee.md` to ≤2,500 words. Cut repetitive checklist items or move procedural detail to a preloaded skill.
- [ ] **3G.2** Verify no other existing (non-merged) agent exceeds 2,500 words.

### Eval 3 — Agent inventory and quality

```bash
# PASS: exactly 14 agent files
count=$(find agents/ -name '*.md' | wc -l | tr -d ' ')
[ "$count" -eq 14 ] && echo "[PASS] agent count = $count" || echo "[FAIL] agent count = $count (expected 14)"

# PASS: all agents ≤ 2,500 words
find agents/ -name "*.md" -exec sh -c '
  words=$(wc -w < "$1")
  name=$(basename "$1" .md)
  if [ "$words" -gt 2500 ]; then
    echo "  [FAIL] $name: $words words (limit 2500)"
  else
    echo "  [PASS] $name: $words words"
  fi
' _ {} \;

# PASS: no agent loads more than 3 skills
python3 -c "
import re, glob, sys
ok = True
for f in sorted(glob.glob('agents/**/*.md', recursive=True)):
    text = open(f).read()
    m = re.search(r'^skills:\s*\[([^\]]*)\]', text, re.MULTILINE)
    if m:
        skills = [s.strip() for s in m.group(1).split(',') if s.strip()]
        name = f.split('/')[-1].replace('.md','')
        if len(skills) > 3:
            print(f'  [FAIL] {name}: {len(skills)} skills {skills}')
            ok = False
        else:
            print(f'  [PASS] {name}: {len(skills)} skills')
if not ok: sys.exit(1)
"

# PASS: no orphaned skills (every skill dir has ≥1 agent that preloads it OR is process/meta)
python3 -c "
import re, glob, os, sys
process_skills = {'compound-catalog','strategy-brainstorm','project-setup','swarm-orchestration','git-worktree'}
all_skills = {os.path.basename(d) for d in glob.glob('skills/*') if os.path.isdir(d)}
loaded = set()
for f in glob.glob('agents/**/*.md', recursive=True):
    m = re.search(r'^skills:\s*\[([^\]]*)\]', open(f).read(), re.MULTILINE)
    if m:
        for s in m.group(1).split(','):
            loaded.add(s.strip())
orphans = all_skills - loaded - process_skills
for s in sorted(all_skills):
    if s in orphans:
        print(f'  [WARN] {s}: not preloaded by any agent')
    else:
        print(f'  [PASS] {s}: loaded or process/meta')
"

# PASS: deleted agents are truly gone
for agent in calibration-assessor specification-analyzer benchmark-researcher \
             solutions-archivist pipeline-validator reproducibility-checker \
             research-coordinator progress-tracker; do
  found=$(find agents/ -name "$agent.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "$found" -eq 0 ] && echo "  [PASS] $agent deleted" || echo "  [FAIL] $agent still exists"
done

# PASS: new agents exist
for agent in reproducibility-auditor workflow-coordinator; do
  found=$(find agents/ -name "$agent.md" 2>/dev/null | wc -l | tr -d ' ')
  [ "$found" -eq 1 ] && echo "  [PASS] $agent exists" || echo "  [FAIL] $agent missing"
done

# PASS: total agent word count decreased (baseline: 38,980)
total=$(find agents/ -name '*.md' -exec cat {} + | wc -w | tr -d ' ')
echo "Agent words: $total (baseline: 38,980)"
[ "$total" -lt 38980 ] && echo "  [PASS] word count decreased" || echo "  [WARN] word count did not decrease"
```

```bash
# PASS: no dangling references to deleted agents in hook prompts
python3 -c "
import json
deleted = ['calibration-assessor','specification-analyzer','benchmark-researcher',
           'solutions-archivist','pipeline-validator','reproducibility-checker',
           'research-coordinator','progress-tracker']
d = json.load(open('hooks/hooks.json'))
for e, ms in d['hooks'].items():
    for m in ms:
        for h in m['hooks']:
            if h.get('type') == 'prompt':
                for name in deleted:
                    if name in h['prompt']:
                        print(f'  [FAIL] {e} still references deleted agent: {name}')
print('(check complete — FAIL lines above indicate dangling references)')
"
```

**Exit gate:** 14 agents. All ≤2,500 words. No >3 skills per agent. No orphaned skills. No dangling references to deleted agents. Commit.

---

## Phase 4 — Command reduction

**Why now:** Agents are merged (Phase 3), skills have reference files (Phase 2), so commands can now safely point to their new targets. This is the most user-visible change — the command surface drops from 16 to 7 canonical + 2 wrappers + 7 stubs. The stubs exist so that users who type `/diagnose` out of habit get a helpful redirect rather than a "command not found" error.

**What changes:** Delete 7 commands' substantive content (replace with short stubs). Create 2 thin wrappers (`/estimate` → `/workflows:work`, `/replicate` → `reproducibility-auditor`). Absorb `/deepen-plan` into `/workflows:plan`. The workflow commands (brainstorm, plan, work, review, compound) and chain commands (lfg, slfg) are untouched — they're the canonical layer.

**Risk:** The `/workflows:plan` absorption of `/deepen-plan` is the only canonical command modification. The plan command must integrate the parallel agent enrichment logic without bloating. The `/estimate` wrapper needs to route cleanly to `/workflows:work` with the right estimation context — if the routing is vague, the user gets a generic work session instead of a guided estimation pipeline.

### 4A — Absorb `/deepen-plan` into `/workflows:plan`

- [ ] **4A.1** Integrate parallel agent enrichment content from `commands/deepen-plan.md` into `commands/workflows/plan.md`
- [ ] **4A.2** Replace `commands/deepen-plan.md` with redirect stub → `/workflows:plan` (stub, not delete — users who type `/deepen-plan` should get a helpful redirect)

### 4B — Create thin wrappers

- [ ] **4B.1** Create `commands/estimate.md` as thin wrapper → routes to `/workflows:work` with estimation pipeline context. Must include `disable-model-invocation: true` in frontmatter if it delegates.
- [ ] **4B.2** Create `commands/replicate.md` as thin wrapper → routes to `reproducibility-auditor` agent.

### 4C — Create deprecated stubs for removed commands

- [ ] **4C.1** Replace `commands/simulate.md` with redirect stub → `simulation-designer` agent
- [ ] **4C.2** Replace `commands/identify.md` with redirect stub → `identification-critic` agent
- [ ] **4C.3** Replace `commands/diagnose.md` with redirect stub → `empirical-playbook` skill
- [ ] **4C.4** Replace `commands/tabulate.md` with redirect stub → `publication-output` skill
- [ ] **4C.5** Replace `commands/visualize.md` with redirect stub → `publication-output` skill
- [ ] **4C.6** Replace `commands/stress-test.md` with redirect stub → `empirical-playbook` skill

Note: deepen-plan's stub is created in 4A.2 (total: 7 stubs = 6 here + 1 in 4A).

Stub format (each ≤50 words):
```markdown
---
description: "[Deprecated v0.5] Use /workflows:work or the [agent/skill] directly."
---
/[command] has moved. [One sentence explaining where it went and how to access it now.]
```

### Eval 4 — Command inventory

```bash
# PASS: exactly 16 command files (7 canonical + 2 wrappers + 7 stubs = 16)
# 5 workflow + lfg + slfg + estimate + replicate
# + simulate + identify + diagnose + tabulate + visualize + stress-test + deepen-plan = 16
count=$(find commands/ -name '*.md' | wc -l | tr -d ' ')
echo "Command files: $count"

# PASS: canonical commands are not stubs (each > 200 words)
for cmd in commands/workflows/brainstorm.md commands/workflows/plan.md \
           commands/workflows/work.md commands/workflows/review.md \
           commands/workflows/compound.md commands/lfg.md commands/slfg.md; do
  words=$(wc -w < "$cmd" 2>/dev/null || echo 0)
  [ "$words" -gt 200 ] && echo "  [PASS] $(basename $cmd): $words words" \
                        || echo "  [FAIL] $(basename $cmd): $words words (too short for canonical)"
done

# PASS: stubs are short (each ≤ 100 words)
for cmd in simulate identify diagnose tabulate visualize stress-test deepen-plan; do
  words=$(wc -w < "commands/$cmd.md" 2>/dev/null || echo 0)
  [ "$words" -le 100 ] && echo "  [PASS] $cmd stub: $words words" \
                        || echo "  [FAIL] $cmd stub: $words words (should be ≤100)"
done

# PASS: stubs mention where the capability moved
for cmd in simulate identify diagnose tabulate visualize stress-test deepen-plan; do
  if grep -qi "moved\|replaced\|use.*instead\|deprecated" "commands/$cmd.md" 2>/dev/null; then
    echo "  [PASS] $cmd stub has redirect language"
  else
    echo "  [FAIL] $cmd stub missing redirect language"
  fi
done

# PASS: wrappers reference their targets
grep -q "workflows:work\|empirical-playbook" commands/estimate.md && \
  echo "  [PASS] /estimate wrapper references work+playbook" || \
  echo "  [FAIL] /estimate wrapper missing target reference"
grep -q "reproducibility-auditor" commands/replicate.md && \
  echo "  [PASS] /replicate wrapper references auditor" || \
  echo "  [FAIL] /replicate wrapper missing target reference"

# PASS: total command word count decreased (was 27,716)
total=$(find commands/ -name '*.md' -exec cat {} + | wc -w | tr -d ' ')
echo "Command words: $total (was 27,716)"
[ "$total" -lt 27716 ] && echo "  [PASS] word count decreased" || echo "  [WARN] word count did not decrease"
```

**Exit gate:** 7 canonical commands substantive. 7 stubs short with redirects (6 removed commands + deepen-plan → /workflows:plan). 2 wrappers reference targets. Total command words decreased. Commit.

---

## Phase 5 — Hook prompt refresh

**Why now:** Agents and commands have their final names and structure (Phases 3-4). Hook prompts reference agents and commands by name, so they must be updated last among the structural changes. This is also where the layered Stop design lands — moving domain-specific completeness checks from the global Stop hook into agent-scoped SubagentStop hooks defined in agent frontmatter.

**What changes:** Update all 6 prompt hooks to reference new agent names, remove defunct command references, and trim the Stop hook to cross-cutting conditions. Add `hooks:` frontmatter to 3 agents for scoped Stop hooks. The char budget is tight: UPS is at 4,976/5,000.

**Risk:** Char overflow on UserPromptSubmit. When replacing command names with agent names (often longer), the prompt can grow. Counter by removing any obsolete content first. Second risk: the agent-scoped hooks must use valid YAML in the frontmatter — test this with a YAML parser before committing.

### 5A — Update hook prompts

- [ ] **5A.1** UserPromptSubmit: replace references to defunct commands (/diagnose, /stress-test, etc.) with agent references. Keep char count ≤5,000.
- [ ] **5A.2** PostToolUse: update agent references (remove calibration-assessor, add econometric-reviewer for calibration contexts). Keep ≤5,000 chars.
- [ ] **5A.3** Stop: update to reference new agent names. Remove references to deleted agents. Consider: should blocking items reference agents or just state the condition?
- [ ] **5A.4** SubagentStop: update agent name list (14 agents, not 20). Update severity routing for merged agents.
- [ ] **5A.5** PreCompact: update if any category names changed.
- [ ] **5A.6** PreToolUse: likely unchanged (guards bash commands, not agent-specific).

### 5B — Layered Stop design

- [ ] **5B.1** Identify which of the 10 Stop conditions are domain-specific vs. cross-cutting:
  - **Domain-specific** (move to agent-scoped SubagentStop in agent frontmatter):
    - Missing SEs → econometric-reviewer Stop hook
    - Unseeded simulation → simulation-designer Stop hook
    - Unstated regularity conditions → mathematical-prover Stop hook
  - **Cross-cutting** (keep in global Stop):
    - Results not saved, no replication package, no sensitivity analysis, diagnostics undocumented, DiD without pre-trends, IV without first-stage F, unvalidated merge
- [ ] **5B.2** Add `hooks:` frontmatter to 3 agents (econometric-reviewer, simulation-designer, mathematical-prover) with scoped Stop hooks. These auto-convert to SubagentStop at runtime.
- [ ] **5B.3** Trim global Stop prompt to cross-cutting conditions only. Char count should decrease.

### Eval 5 — Hook integrity

```bash
# PASS: all hook prompts ≤ 5,000 chars
python3 -c "
import json, sys
d = json.load(open('hooks/hooks.json'))
ok = True
for e, ms in d['hooks'].items():
    for m in ms:
        for h in m['hooks']:
            if h.get('type') == 'prompt':
                chars = len(h['prompt'])
                status = 'PASS' if chars <= 5000 else 'FAIL'
                print(f'  [{status}] {e}: {chars} chars')
                if chars > 5000: ok = False
if not ok: sys.exit(1)
print('All hook prompts within 5,000-char limit.')
"

# PASS: no hook prompt references a deleted agent
python3 -c "
import json
deleted = ['calibration-assessor','specification-analyzer','benchmark-researcher',
           'solutions-archivist','pipeline-validator','reproducibility-checker',
           'research-coordinator','progress-tracker']
d = json.load(open('hooks/hooks.json'))
clean = True
for e, ms in d['hooks'].items():
    for m in ms:
        for h in m['hooks']:
            p = h.get('prompt', '')
            for name in deleted:
                if name in p:
                    print(f'  [FAIL] {e} references deleted: {name}')
                    clean = False
if clean: print('[PASS] No deleted agent references in hooks')
"

# PASS: no hook prompt references a removed command by old name
python3 -c "
import json
removed_cmds = ['/simulate', '/identify', '/diagnose', '/tabulate', '/visualize', '/stress-test', '/deepen-plan']
d = json.load(open('hooks/hooks.json'))
clean = True
for e, ms in d['hooks'].items():
    for m in ms:
        for h in m['hooks']:
            p = h.get('prompt', '')
            for cmd in removed_cmds:
                if cmd in p:
                    print(f'  [FAIL] {e} references removed command: {cmd}')
                    clean = False
if clean: print('[PASS] No removed command references in hooks')
"

# PASS: agents with scoped Stop hooks have valid hook structure
python3 -c "
import yaml, glob, sys
for f in glob.glob('agents/**/*.md', recursive=True):
    text = open(f).read()
    if '---' in text:
        parts = text.split('---', 2)
        if len(parts) >= 3:
            try:
                fm = yaml.safe_load(parts[1])
                if fm and 'hooks' in fm:
                    name = fm.get('name', f)
                    print(f'  [INFO] {name} has scoped hooks: {list(fm[\"hooks\"].keys())}')
            except: pass
print('(check complete)')
"

# PASS: hooks.json is still valid JSON
python3 -c "import json; json.load(open('hooks/hooks.json')); print('[PASS] hooks.json valid JSON')"
```

**Exit gate:** All prompts ≤5,000 chars. No references to deleted agents or removed commands. Agent-scoped hooks valid. Commit.

---

## Phase 6 — Documentation update

**Why now:** All structural changes are done. Documentation reflects the final state, not an intermediate one. The version bump signals to users that an update is available (`claude plugin update compound-science`).

**What changes:** Rewrite CLAUDE.md to reflect 14 agents, 17 skills, 7+2 commands. Add a ~20-line routing table as post-compaction backstop (domain signal → agent mapping). Update README with new command surface and architecture overview. Bump version to 0.5.0.

**Risk:** CLAUDE.md word count budget is 3,000 words. The current CLAUDE.md is 1,289 words, so there's headroom, but the routing table and expanded skill descriptions could push it. The routing table is cheap insurance against compaction — it should be concise (~20 lines), not exhaustive.

- [ ] **6.1** Update CLAUDE.md: new component listings (14 agents, 7+2 commands, 17 skills), updated agent categories, updated hook descriptions. Keep ≤3,000 words.
- [ ] **6.2** Add ~20-line routing table to CLAUDE.md as post-compaction backstop (domain signal → agent mapping)
- [ ] **6.3** Update README.md: new command list, updated agent sections, architecture overview
- [ ] **6.4** Bump version in `.claude-plugin/plugin.json` to `"0.5.0"`
- [ ] **6.5** Update CONTRIBUTING.md: migration notes, new gotchas

### Eval 6 — Documentation completeness

```bash
# PASS: CLAUDE.md ≤ 3,000 words
words=$(wc -w < CLAUDE.md | tr -d ' ')
echo "CLAUDE.md: $words words"
[ "$words" -le 3000 ] && echo "  [PASS]" || echo "  [FAIL] over budget"

# PASS: every agent mentioned in CLAUDE.md
for f in agents/**/*.md; do
  name=$(basename "$f" .md)
  grep -q "$name" CLAUDE.md && echo "  [PASS] $name in CLAUDE.md" \
                             || echo "  [FAIL] $name missing from CLAUDE.md"
done

# PASS: every skill mentioned in CLAUDE.md
for d in skills/*/; do
  name=$(basename "$d")
  grep -q "$name" CLAUDE.md && echo "  [PASS] $name in CLAUDE.md" \
                             || echo "  [FAIL] $name missing from CLAUDE.md"
done

# PASS: version is 0.5.0
version=$(python3 -c "import json; print(json.load(open('.claude-plugin/plugin.json'))['version'])")
[ "$version" = "0.5.0" ] && echo "[PASS] version = $version" || echo "[FAIL] version = $version (expected 0.5.0)"

# PASS: CLAUDE.md has routing table
grep -c "→\|-->" CLAUDE.md | xargs -I{} sh -c \
  '[ {} -ge 10 ] && echo "[PASS] routing table present ({} arrows)" || echo "[FAIL] routing table missing or sparse ({} arrows)"'
```

**Exit gate:** CLAUDE.md ≤3,000 words. All agents and skills documented. Version 0.5.0. Routing table present. Commit.

---

## Phase 7 — Test suite adaptation

**Why now:** All structural changes and documentation are final. Test hardcoded counts (agent=20, skills=16, etc.) need updating to match the new inventory. This phase is mechanical — find every hardcoded number and update it. The risk is missing one, which causes a false failure. The eval is simple: full suite green.

**What changes:** Update counts in 11+ test files. Update AGENT_NAMES arrays. Update SKILLS arrays. Add tests for migration-specific invariants (stubs have redirects, wrappers route correctly, no deleted agent names in non-test files). Update fixtures if needed.

**Risk:** The test suite has 14 groups and 502 assertions. Some assertions use hardcoded agent name lists (like AGENT_NAMES in test 12). Missing an update creates a false failure that looks like a real regression. The systematic approach: grep for every deleted agent name and every old count across all test files.

### 7A — Update hardcoded counts

- [ ] **7A.1** `02-file-existence.sh`: update AGENTS count to 14, SKILLS to 17, total accordingly
- [ ] **7A.2** `04-frontmatter.sh`: update if agent category counts changed
- [ ] **7A.3** `05-content-quality.sh`: update word count thresholds if baseline shifted
- [ ] **7A.4** `06-cross-references.sh`: update agent name lists, command references
- [ ] **7A.5** `08-agent-organization.sh`: update counts (8 review, 1 audit, 3 research, 2 workflow)
- [ ] **7A.6** `09-command-completeness.sh`: update for new command structure (7 canonical + 2 wrappers + 6 stubs)
- [ ] **7A.7** `10-hook-coverage.sh`: update for model fields, agent-scoped hooks
- [ ] **7A.8** `11-skill-depth.sh`: update SKILLS array to 17, add publication-output
- [ ] **7A.9** `12-hook-integration.sh`: update agent name references in hook tests
- [ ] **7A.10** `13-workflow-scenarios.sh`: update agent name references
- [ ] **7A.11** `14-skill-trigger-matching.sh`: update for new skill

### 7B — Update fixtures and libraries

- [ ] **7B.1** `lib/fixtures.sh`: update SKILLS array to 17 (add publication-output)
- [ ] **7B.2** Update AGENT_NAMES arrays wherever they appear in test files

### 7C — Add migration-specific tests

- [ ] **7C.1** Test: deprecated stubs contain redirect language
- [ ] **7C.2** Test: thin wrappers reference their routing targets
- [ ] **7C.3** Test: no cross-reference to deleted agent names anywhere in non-test plugin files
- [ ] **7C.4** Test: agent-scoped hooks (if implemented) have valid structure

### Eval 7 — Full suite green

```bash
# PASS: full test suite passes
bash .tests/run-all.sh

# PASS: test count is reasonable (should be near 237, adjusted for structural changes)
# If count drops below 200, something is wrong. If above 300, tests may be inflated.
```

**Exit gate:** Full suite passes. No regressions. Commit.

---

## Phase 8 — Final validation

**Why this is the real test:** Everything above could pass individual phase evals but still fail as a system. This phase runs the full eval harness (grade.py, 10 dimensions, max 50), checks cross-reference integrity comprehensively, and measures quality density (words/component, preload weight). The migration succeeds only if: eval score ≥ baseline, total words ≤ baseline, and all cross-references resolve. If any of these fail, the migration made the plugin worse — go back and fix it.

**What changes:** No code changes. Run evals, tag, update memory.

### Eval 8A — Component inventory matches architecture doc

```bash
python3 -c "
import os, json

agents = sorted([f.replace('.md','') for f in os.listdir('agents/review')] +
                [f.replace('.md','') for f in os.listdir('agents/research') if f.endswith('.md')] +
                [f.replace('.md','') for f in os.listdir('agents/workflow') if f.endswith('.md')] +
                [f.replace('.md','') for f in os.listdir('agents/audit') if f.endswith('.md')])
skills = sorted([d for d in os.listdir('skills') if os.path.isdir(f'skills/{d}')])
commands = sorted([f.replace('.md','') for f in os.listdir('commands') if f.endswith('.md')] +
                  [f'workflows:{f.replace(\".md\",\"\")}' for f in os.listdir('commands/workflows') if f.endswith('.md')])
hooks = len(json.load(open('hooks/hooks.json'))['hooks'])

print(f'Agents:   {len(agents)} (target: 14)')
print(f'Skills:   {len(skills)} (target: 17)')
print(f'Commands: {len(commands)} (target: 16 = 7 canonical + 2 wrappers + 7 stubs)')
print(f'Hooks:    {hooks} (target: 7)')
print(f'Total:    {len(agents) + len(skills) + len(commands) + hooks}')
print()
for a in agents: print(f'  agent: {a}')
print()
for s in skills: print(f'  skill: {s}')
print()
for c in commands: print(f'  command: {c}')
"
```

### Eval 8B — Word count budget compliance

```bash
python3 -c "
import os, glob

def count_words(path):
    return len(open(path).read().split())

print('=== AGENT WORD COUNTS (limit: 2,500) ===')
for f in sorted(glob.glob('agents/**/*.md', recursive=True)):
    w = count_words(f)
    status = 'PASS' if w <= 2500 else 'FAIL'
    print(f'  [{status}] {os.path.basename(f).replace(\".md\",\"\"):30s} {w:5d} words')

print()
print('=== SKILL.MD WORD COUNTS (limit: 2,000) ===')
for f in sorted(glob.glob('skills/*/SKILL.md')):
    w = count_words(f)
    status = 'PASS' if w <= 2000 else 'FAIL'
    name = f.split('/')[1]
    print(f'  [{status}] {name:30s} {w:5d} words')

print()
print('=== CLAUDE.MD (limit: 3,000) ===')
w = count_words('CLAUDE.md')
status = 'PASS' if w <= 3000 else 'FAIL'
print(f'  [{status}] CLAUDE.md: {w} words')
"
```

### Eval 8C — Quality density metrics

```bash
python3 -c "
import os, glob, json

# Total content words
total_words = sum(len(open(f).read().split()) for f in glob.glob('agents/**/*.md', recursive=True))
total_words += sum(len(open(f).read().split()) for f in glob.glob('skills/**/*.md', recursive=True))
total_words += sum(len(open(f).read().split()) for f in glob.glob('commands/**/*.md', recursive=True))
total_words += len(open('hooks/hooks.json').read().split())
total_words += len(open('CLAUDE.md').read().split())

# Component count
n_agents = len(glob.glob('agents/**/*.md', recursive=True))
n_skills = len([d for d in os.listdir('skills') if os.path.isdir(f'skills/{d}')])
n_commands = len(glob.glob('commands/**/*.md', recursive=True))
n_hooks = len(json.load(open('hooks/hooks.json'))['hooks'])
n_total = n_agents + n_skills + n_commands + n_hooks

# Preload weight (total SKILL.md words loaded per agent via skills: frontmatter)
import re
max_preload = 0
max_preload_agent = ''
for f in glob.glob('agents/**/*.md', recursive=True):
    text = open(f).read()
    m = re.search(r'^skills:\s*\[([^\]]*)\]', text, re.MULTILINE)
    if m:
        skill_names = [s.strip() for s in m.group(1).split(',') if s.strip()]
        preload = sum(len(open(f'skills/{s}/SKILL.md').read().split()) for s in skill_names if os.path.exists(f'skills/{s}/SKILL.md'))
        name = os.path.basename(f).replace('.md','')
        if preload > max_preload:
            max_preload = preload
            max_preload_agent = name

print('=== QUALITY DENSITY METRICS ===')
print(f'Total content:     {total_words:,} words (baseline: 125,382)')
print(f'Components:        {n_total} (baseline: 59)')
print(f'Words/component:   {total_words // n_total:,} (lower = denser)')
print(f'Max preload weight: {max_preload:,} words ({max_preload_agent})')
print()
delta_words = total_words - 125382
delta_components = n_total - 59
print(f'Word count delta:  {delta_words:+,} ({\"GOOD\" if delta_words <= 0 else \"WATCH\"})')
print(f'Component delta:   {delta_components:+,} ({\"GOOD\" if delta_components < 0 else \"WATCH\"})')
"
```

### Eval 8D — Eval harness score

```bash
# PASS: eval score ≥ baseline (recorded in Phase 0)
python3 .evals/grade.py
```

### Eval 8E — Cross-reference integrity (comprehensive)

```bash
python3 -c "
import os, glob, re, json

# Collect all valid component names
agents = {os.path.basename(f).replace('.md','') for f in glob.glob('agents/**/*.md', recursive=True)}
skills = {d for d in os.listdir('skills') if os.path.isdir(f'skills/{d}')}
commands = set()
for f in glob.glob('commands/**/*.md', recursive=True):
    name = os.path.basename(f).replace('.md','')
    if 'workflows' in f:
        commands.add(f'workflows:{name}')
    commands.add(name)

valid = agents | skills | commands
# Known non-components (config keys, etc.)
non_components = {'disable-model-invocation','set-e','no-verify','pre-migration'}

# Check CLAUDE.md backtick references
text = open('CLAUDE.md').read()
refs = set(re.findall(r'\x60([a-z]+-[a-z-]+)\x60', text))
unresolved = refs - valid - non_components
if unresolved:
    for u in sorted(unresolved):
        print(f'  [WARN] CLAUDE.md references unresolved: {u}')
else:
    print('[PASS] All CLAUDE.md backtick references resolve')

# Check hook prompts for agent references
d = json.load(open('hooks/hooks.json'))
for e, ms in d['hooks'].items():
    for m in ms:
        for h in m['hooks']:
            p = h.get('prompt', '')
            hook_refs = set(re.findall(r'\x60([a-z]+-[a-z-]+)\x60', p))
            bad = hook_refs - valid - non_components
            if bad:
                for b in bad:
                    print(f'  [WARN] {e} hook references unresolved: {b}')

print('[DONE] Cross-reference check complete')
"
```

- [ ] **8.1** All Eval 8A-8E pass
- [ ] **8.2** Git tag `v0.5.0`
- [ ] **8.3** Update memory (MEMORY.md) with new component counts and architecture

**Exit gate:** 14 agents, 17 skills, 7+2+7 commands, 7 hooks. All word budgets met. Eval score ≥ baseline. No dangling references. Total words ≤ baseline.

---

## Summary checklist

| Phase | Key metric | Target |
|---|---|---|
| 0 | Baseline recorded | All numbers captured |
| 1 | Hook models | 5 Haiku + 1 Sonnet + 1 bash |
| 2 | Skills | 17 dirs, all SKILL.md ≤2,000w, 6 new references |
| 3 | Agents | 14 files, all ≤2,500w, max 3 skills each |
| 4 | Commands | 7 canonical + 2 wrappers + 7 stubs (incl. deepen-plan redirect) |
| 5 | Hooks | All prompts ≤5,000 chars, no defunct references |
| 6 | Docs | CLAUDE.md ≤3,000w, version 0.5.0, routing table |
| 7 | Tests | Full suite green |
| 8 | Final | Eval score ≥ baseline, total words ≤ baseline |

**Total tasks:** 53
**Total eval checkpoints:** 8 (one per phase)
**Expected commits:** 8-12 (one per phase, some phases split)
