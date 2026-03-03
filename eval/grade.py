#!/usr/bin/env python3
"""
Compound-Science Plugin Quality Evaluator
==========================================
Scores 10 quality dimensions (1–5 each) → max 50 points.

Usage:
    python3 eval/grade.py [--root DIR] [--json] [--run-tests]

Flags:
    --root DIR    Plugin root directory  (default: current directory)
    --json        Emit raw JSON results to stdout
    --run-tests   Execute the test suite non-interactively; factors into D01

Exit codes: 0 if total == 50, else 1.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

# ── Types ──────────────────────────────────────────────────────────────────────

@dataclass
class R:
    dim: int
    name: str
    score: int          # 1–5
    notes: list[str] = field(default_factory=list)

    @property
    def full(self) -> bool:
        return self.score == 5

    def __str__(self) -> str:
        bar = "█" * self.score + "░" * (5 - self.score)
        icon = "✓" if self.full else "✗"
        note = f"  ← {self.notes[0]}" if self.notes else ""
        return f"  D{self.dim:02d} {icon} [{bar}] {self.score}/5  {self.name}{note}"


# ── Global state (set in main) ─────────────────────────────────────────────────
ROOT: Path = Path(".")
_CACHE: dict[str, str] = {}  # keyed by path-glob combo; cleared on ROOT change


# ── File helpers ───────────────────────────────────────────────────────────────

def find(*globs: str) -> list[Path]:
    return sorted({p for g in globs for p in ROOT.glob(g)})


def texts(paths: list[Path]) -> list[tuple[Path, str]]:
    out = []
    for p in paths:
        try:
            out.append((p, p.read_text("utf-8", errors="replace")))
        except OSError as exc:
            print(f"WARNING: could not read {p}: {exc}", file=sys.stderr)
    return out


def concat(paths: list[Path]) -> str:
    return "\n".join(t for _, t in texts(paths))


def n(pattern: str, text: str, flags: int = re.IGNORECASE) -> int:
    """Count non-overlapping regex matches."""
    return len(re.findall(pattern, text, flags))


def exists(*parts: str) -> bool:
    return (ROOT / Path(*parts)).exists()


# ── Inventory shortcuts ────────────────────────────────────────────────────────

def agents() -> list[Path]:
    return find("agents/**/*.md", "agents/**/*.yaml")


def commands() -> list[Path]:
    return find("commands/**/*.md", "commands/**/*.yaml")


def skills() -> list[Path]:
    return find("skills/**/SKILL.md", "skills/**/*.md")


def test_scripts() -> list[Path]:
    return find("tests/tests/*.sh", "tests/*.sh")


def hooks_text() -> str:
    """Raw JSON text — use for structural checks (presence of ${CLAUDE_PLUGIN_ROOT}, etc.)."""
    p = ROOT / "hooks" / "hooks.json"
    if not p.exists():
        p = ROOT / "hooks.json"
    if not p.exists():
        return ""
    try:
        return p.read_text("utf-8", errors="replace")
    except OSError as exc:
        print(f"WARNING: could not read {p}: {exc}", file=sys.stderr)
        return ""


def hooks_prompts() -> str:
    """All hook prompt strings concatenated — JSON-parsed so \\n becomes real newlines."""
    p = ROOT / "hooks" / "hooks.json"
    if not p.exists():
        p = ROOT / "hooks.json"
    if not p.exists():
        return ""
    try:
        data = json.loads(p.read_text("utf-8", errors="replace"))
        hook_map = data.get("hooks", data)
        parts: list[str] = []
        for event_entries in hook_map.values():
            for entry in event_entries:
                for hook in entry.get("hooks", []):
                    if hook.get("type") == "prompt":
                        parts.append(hook.get("prompt", ""))
                    elif hook.get("type") == "command":
                        parts.append(hook.get("command", ""))
        return "\n".join(parts)
    except json.JSONDecodeError as exc:
        print(f"WARNING: hooks.json is not valid JSON: {exc}", file=sys.stderr)
        return ""


def agent_named(name: str) -> bool:
    return any(p.stem == name for p in agents())


def command_named(name: str) -> bool:
    return any(name in p.stem or name == p.stem for p in commands())


def _cached(key: str, fn) -> str:  # noqa: ANN001
    """Return cached concat result, computing once per ROOT."""
    if key not in _CACHE:
        _CACHE[key] = fn()
    return _CACHE[key]


def agent_text() -> str:
    return _cached("agents", lambda: concat(agents()))


def command_text() -> str:
    return _cached("commands", lambda: concat(commands()))


def components_text() -> str:
    return _cached("all", lambda: concat(agents() + commands() + skills()))


# ── Scoring helpers ────────────────────────────────────────────────────────────

def penalize(penalty: int) -> int:
    """0→5, 1→4, 2–3→3, 4–6→2, 7+→1"""
    if penalty == 0:
        return 5
    if penalty == 1:
        return 4
    if penalty <= 3:
        return 3
    if penalty <= 6:
        return 2
    return 1


def checklist(checks: list[tuple[str, bool]], notes: list[str]) -> int:
    """Record each check result into notes; return score = number of passes (max 5, min 1)."""
    hits = 0
    for label, passed in checks:
        if passed:
            hits += 1
            notes.append(f"✓ {label}")
        else:
            notes.append(f"✗ {label}")
    return max(1, hits)


# ══════════════════════════════════════════════════════════════════════════════
# D01  Autonomous — zero-touch, non-interactive
# ══════════════════════════════════════════════════════════════════════════════

def d01_autonomous(run_tests: bool) -> R:
    notes, penalty = [], 0

    # 1. Bare `read VAR` (interactive) in test scripts — excludes `read -r` pipe reads
    for path, text in texts(test_scripts()):
        matches = re.findall(r"^\s*read\s+(?!-[rp\d])(\w+)", text, re.MULTILINE)
        if matches:
            penalty += len(matches)
            notes.append(f"{path.name}: interactive read({', '.join(matches)})")

    # 2. Blocking patterns in hooks
    h = hooks_text()
    for pat in [r"press\s+enter", r"await\s+input", r"confirm\?", r"type\s+yes"]:
        if re.search(pat, h, re.IGNORECASE):
            penalty += 2
            notes.append(f"hooks.json: blocking pattern '{pat}'")

    # 3. Optional: run test suite with stdin closed
    if run_tests:
        runner = ROOT / "tests" / "run-all.sh"
        if runner.exists():
            try:
                r = subprocess.run(
                    ["bash", str(runner)],
                    stdin=subprocess.DEVNULL,
                    capture_output=True,
                    timeout=300,
                    cwd=ROOT,
                )
                if r.returncode != 0:
                    penalty += 3
                    notes.append(f"Test suite failed non-interactively (exit {r.returncode})")
                else:
                    notes.append("Test suite passes with stdin=DEVNULL ✓")
            except subprocess.TimeoutExpired:
                penalty += 5
                notes.append("Test suite timed out — likely stdin-blocking")

    if not notes:
        notes.append("No interactive reads; hooks are non-blocking")
    return R(1, "Autonomous", penalize(penalty), notes)


# ══════════════════════════════════════════════════════════════════════════════
# D02  Minimal — lean, surgical, zero overengineering
# ══════════════════════════════════════════════════════════════════════════════

def d02_minimal(run_tests: bool) -> R:
    notes, penalty = [], 0

    # 1. TODO / FIXME / HACK / PLACEHOLDER / XXX in any component
    all_comp = components_text()
    todo_count = n(r"\b(TODO|FIXME|PLACEHOLDER|HACK|XXX)\b", all_comp, 0)
    if todo_count:
        penalty += todo_count
        notes.append(f"{todo_count} TODO/FIXME/PLACEHOLDER/HACK found in components")

    # 2. Average agent word count (target ≤ 700)
    agent_pairs = texts(agents())
    if agent_pairs:
        avg_words = sum(len(t.split()) for _, t in agent_pairs) / len(agent_pairs)
        if avg_words > 1200:
            penalty += 3
            notes.append(f"Avg agent size: {avg_words:.0f} words (>1200)")
        elif avg_words > 800:
            penalty += 1
            notes.append(f"Avg agent size: {avg_words:.0f} words (>800)")
        else:
            notes.append(f"Avg agent size: {avg_words:.0f} words ✓")

    # 3. Purpose-word duplication: same high-content word claimed by >4 agents
    desc_words = []
    for _, text in agent_pairs:
        m = re.search(r"description:\s*[\"']?(.+)", text)
        if m:
            desc_words.extend(w.lower() for w in m.group(1).split() if len(w) > 6)
    overlap = sum(1 for _, c in Counter(desc_words).items() if c > 4)
    if overlap > 3:
        penalty += 1
        notes.append(f"{overlap} purpose-words shared by >4 agents (possible overlap)")

    if not notes:
        notes.append("Lean components, no overengineering markers")
    return R(2, "Minimal", penalize(penalty), notes)


# ══════════════════════════════════════════════════════════════════════════════
# D03  Modular — one job per component, flat concerns
# ══════════════════════════════════════════════════════════════════════════════

def d03_modular(run_tests: bool) -> R:
    notes, penalty = [], 0

    # 1. Agent description 'and'-conjunction overloading (>3 'and' = multi-purpose)
    for path, text in texts(agents()):
        m = re.search(r"description:\s*[\"']?(.+)", text)
        if m:
            ands = m.group(1).lower().count(" and ")
            if ands > 3:
                penalty += 1
                notes.append(f"{path.name}: {ands} 'and' in description (unfocused)")

    # 2. No duplicate agent stems
    stems = [p.stem for p in agents()]
    dupes = [s for s, c in Counter(stems).items() if c > 1]
    if dupes:
        penalty += len(dupes) * 2
        notes.append(f"Duplicate agent names: {dupes}")

    # 3. Cross-subdomain references in agent descriptions (research agent mentioning review task)
    research_names = {p.stem for p in find("agents/research/*.md")}
    review_names = {p.stem for p in find("agents/review/*.md")}
    for path, text in texts(find("agents/research/*.md")):
        for rname in review_names:
            if rname in text and path.stem != rname:
                # Shallow check: if review agent name appears in research agent description
                m = re.search(r"description:.*" + re.escape(rname), text)
                if m:
                    penalty += 1
                    notes.append(f"{path.stem}: references review-agent '{rname}' in description")

    # 4. Plugin structure is flat: agents must be at agents/<type>/<name>.md (depth exactly 2)
    #    agents/<type>/<subdir>/<name>.md (depth 3+) is too deep
    agents_root = ROOT / "agents"
    deep = [
        p for p in agents()
        if agents_root in p.parents and len(p.relative_to(agents_root).parts) > 2
    ]
    if deep:
        penalty += len(deep)
        notes.append(f"{len(deep)} agent(s) nested >2 levels under agents/")

    if not notes:
        notes.append("Components are modular and non-overlapping")
    return R(3, "Modular", penalize(penalty), notes)


# ══════════════════════════════════════════════════════════════════════════════
# D04  Parallel — discrete parallelizable tasks and architecture
# ══════════════════════════════════════════════════════════════════════════════

def d04_parallel(run_tests: bool) -> R:
    notes = []
    cmd_text = command_text()
    at = agent_text()

    checks = [
        (
            "/slfg chain command exists",
            command_named("slfg"),
        ),
        (
            "disable-model-invocation:true on ≥2 chain commands",
            n(r"disable-model-invocation:\s*true", cmd_text) >= 2,
        ),
        (
            "Parallel/swarm/concurrent language in commands (≥4 hits)",
            n(r"\b(parallel|swarm|concurrent|simultaneously|in\s+parallel)\b", cmd_text) >= 4,
        ),
        (
            "Multi-agent brainstorm dispatches multiple agents",
            n(r"\b(methods.?explorer|literature.?scout|brainstorm)\b", cmd_text) >= 3,
        ),
        (
            "Agents are stateless (no shared-mutable-state refs)",
            n(r"\b(global\s+state|shared\s+memory|mutable\s+global)\b", at) == 0,
        ),
    ]
    score = checklist(checks, notes)
    return R(4, "Parallel", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D05  Robust — hardened against edge cases and silent failures
# ══════════════════════════════════════════════════════════════════════════════

def d05_robust(run_tests: bool) -> R:
    notes, penalty = [], 0

    # 1. Shellcheck on test scripts
    sh_files = test_scripts()
    try:
        sc_ok = subprocess.run(["which", "shellcheck"], capture_output=True, timeout=5).returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        sc_ok = False
    if sc_ok and sh_files:
        try:
            r = subprocess.run(
                ["shellcheck", "--severity=error"] + [str(f) for f in sh_files],
                capture_output=True, text=True, timeout=60,
            )
            # shellcheck outputs one line per error; count non-empty lines in stdout
            errors = len([l for l in r.stdout.splitlines() if l.strip()])
            if errors:
                penalty += min(errors // 3 + 1, 4)
                notes.append(f"shellcheck: {errors} error line(s) in test scripts")
            else:
                notes.append("shellcheck: 0 errors ✓")
        except subprocess.TimeoutExpired:
            penalty += 2
            notes.append("shellcheck timed out after 60s — skipping")
        except FileNotFoundError:
            notes.append("shellcheck binary not found — skipping")
    elif not sc_ok:
        notes.append("shellcheck not available (install for full D05)")

    # 2. Unquoted $VAR in hooks (not inside quotes or ${...})
    h = hooks_text()
    unquoted = n(r'(?<!["\'{])\$(?![{("])[A-Za-z_]\w*', h)
    if unquoted > 5:
        penalty += unquoted // 5
        notes.append(f"hooks.json: ~{unquoted} potentially unquoted $VAR expansions")

    # 3. Null / empty guards in hook scripts
    null_guards = n(r"\[\s*-[nz]\s+", h) + n(r"\$\{[^}]+:-", h)
    if null_guards < 2 and h:
        penalty += 1
        notes.append("hooks.json: few/no -n/-z null guards or ${VAR:-default} fallbacks")

    # 4. Test coverage: are there tests covering both agents and hooks?
    ts_text = concat(test_scripts())
    if not n(r"\bagent\b", ts_text):
        penalty += 1
        notes.append("No agent-focused tests detected in tests/tests/")
    if not n(r"\bhook\b", ts_text):
        penalty += 1
        notes.append("No hook-focused tests detected in tests/tests/")

    if not notes:
        notes.append("Scripts are guarded; test coverage spans agents and hooks")
    return R(5, "Robust", penalize(penalty), notes)


# ══════════════════════════════════════════════════════════════════════════════
# D06  Genuine — strict truthfulness, zero false completion claims
# ══════════════════════════════════════════════════════════════════════════════

def d06_genuine(run_tests: bool) -> R:
    notes, penalty = [], 0

    FALSE_DONE = re.compile(
        r"(task\s+(is\s+)?(complete|done|finished)|"
        r"(i\s+have|i've)\s+(successfully\s+)?(completed|done|verified)\b|"
        r"all\s+(checks?\s+pass|issues?\s+are\s+fixed))",
        re.IGNORECASE,
    )

    # 1. False completion claims in agent prompts
    for path, text in texts(agents()):
        hits = FALSE_DONE.findall(text)
        if hits:
            penalty += len(hits)
            notes.append(f"{path.stem}: {len(hits)} false-completion phrase(s)")

    # 2. Stop hook: count distinct blocking/suggestion conditions
    #    Use hooks_prompts() (JSON-parsed) so \n escapes become real newlines
    h = hooks_prompts()
    stop_items = n(r"^\s*\d+\.\s+\*\*", h, re.MULTILINE)
    if stop_items < 6:
        penalty += max(0, 6 - stop_items)
        notes.append(f"Stop hook: {stop_items} numbered conditions (want ≥6)")
    else:
        notes.append(f"Stop hook: {stop_items} numbered conditions ✓")

    # 3. Anti-hallucination guardrails in research agents
    for path, text in texts(find("agents/research/*.md")):
        if not n(r"(do\s+not\s+fabricate|no\s+hallucin|cannot\s+verify|"
                 r"do\s+not\s+invent|only.*cited|guardrail)", text):
            penalty += 1
            notes.append(f"{path.stem}: missing anti-hallucination guardrail")

    if not notes:
        notes.append("No false completions; blocking rules intact; guardrails present")
    return R(6, "Genuine", penalize(penalty), notes)


# ══════════════════════════════════════════════════════════════════════════════
# D07  Deterministic — anti-flaky, seeded, repeatable
# ══════════════════════════════════════════════════════════════════════════════

def d07_deterministic(run_tests: bool) -> R:
    notes = []
    h = hooks_text()
    comp_text = command_text() + agent_text()

    checks = [
        (
            "PreToolUse warns on missing seed for estimation/simulation scripts",
            # Hook warns on python/Rscript commands where seed is absent;
            # may describe it in prose rather than matching literal `python X.py --seed`
            n(r"--seed", h) >= 1
            or n(r"(missing\s+seed|no\s+.*seed|seed.*not|without.*seed)", h) >= 1,
        ),
        (
            "Stop hook flags unseeded simulations",
            n(r"(unseeded|without\s+.*seed|seed.*missing|set.*seed)", h) >= 1,
        ),
        (
            "No unguarded datetime.now() / uuid4() in components",
            n(r"\b(datetime\.now\(\)|uuid\.uuid4\(\)|time\.time\(\))\b", comp_text, 0) == 0,
        ),
        (
            "Test suite references seeds or idempotency",
            n(r"\b(seed|idempotent|deterministic|reproducib)\b", concat(test_scripts())) >= 2,
        ),
        (
            "No bare random() without seed in documentation examples",
            n(r"random\(\)(?!.*seed)", comp_text, 0) == 0,
        ),
    ]
    score = checklist(checks, notes)
    return R(7, "Deterministic", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D08  Reproducible — portable, environment-agnostic, pinned
# ══════════════════════════════════════════════════════════════════════════════

def d08_reproducible(run_tests: bool) -> R:
    notes, penalty = [], 0
    h = hooks_text()
    comp_text = concat(agents() + commands() + skills())

    # 1. Absolute paths in hooks — require /Users/<user>/<subpath>; exclude .../... placeholders
    _ABS_PAT = re.compile(r"/(?:Users|home|root|var|tmp)/\w[\w.-]+/[^\s'\"\\]+")
    abs_in_hooks = [p for p in _ABS_PAT.findall(h) if "..." not in p]
    if abs_in_hooks:
        penalty += len(abs_in_hooks) * 2
        notes.append(f"hooks.json: {len(abs_in_hooks)} absolute path(s): {abs_in_hooks[:2]}")

    # 2. Absolute paths in components — same pattern; excludes /Users/me/data/... examples
    abs_in_comp = [p for p in _ABS_PAT.findall(comp_text) if "..." not in p]
    if abs_in_comp:
        penalty += len(abs_in_comp)
        notes.append(f"Components: {len(abs_in_comp)} hardcoded absolute path(s)")

    # 3. Hardcoded usernames — only from real paths (not .../... placeholder examples)
    _all = h + comp_text
    _real = [p for p in _ABS_PAT.findall(_all) if "..." not in p]
    usernames = [m.group(1) for raw in _real for m in [re.search(r"/(?:Users|home)/(\w+)/", raw)] if m]
    unique_users = set(usernames)
    if unique_users:
        penalty += len(unique_users)
        notes.append(f"Hardcoded username(s): {sorted(unique_users)}")

    # 4. ${CLAUDE_PLUGIN_ROOT} used in hook commands (good: portable)
    uses_plugin_root = n(r"\$\{CLAUDE_PLUGIN_ROOT\}", h) >= 1
    if not uses_plugin_root and h:
        penalty += 1
        notes.append("hooks.json: no ${CLAUDE_PLUGIN_ROOT} usage — paths may be fragile")
    else:
        notes.append("${CLAUDE_PLUGIN_ROOT} used in hook commands ✓")

    # 5. Non-portable shebangs in shell scripts
    sh_text = concat(test_scripts() + find("scripts/*.sh"))
    bad = n(r"#!/usr/bin/python3|#!/usr/bin/bash\b", sh_text, 0)
    if bad:
        penalty += 1
        notes.append(f"{bad} non-portable shebang(s) (use #!/usr/bin/env)")

    if not notes:
        notes.append("No absolute paths; portable shebangs; ${CLAUDE_PLUGIN_ROOT} used")
    return R(8, "Reproducible", penalize(penalty), notes)


# ══════════════════════════════════════════════════════════════════════════════
# D09  Calibrated — honest about LLM limits, confidence-discounted
# ══════════════════════════════════════════════════════════════════════════════

def d09_calibrated(run_tests: bool) -> R:
    notes = []
    at = agent_text()

    HEDGE = re.compile(
        r"\b(may|might|consider|verify|check|suggest|typically|often|"
        r"can\s+be|possible|likely|examine|evaluate|assess|investigate|"
        r"if\s+applicable|where\s+appropriate)\b",
        re.IGNORECASE,
    )
    OVERCONF = re.compile(
        r"\b(always|never|guaranteed|definitely|certainly|will\s+always|"
        r"must\s+be|is\s+definitely|provably|conclusively|infallibly)\b",
        re.IGNORECASE,
    )
    UNCERTAINTY = re.compile(
        r"\b(cannot\s+verify|limited\s+to|cannot\s+confirm|"
        r"do\s+not\s+fabricate|do\s+not\s+invent|hallucin|fabricat|"
        r"uncertainty|caveats?|disclaimer|may\s+be\s+incorrect)\b",
        re.IGNORECASE,
    )

    hedge_n = len(HEDGE.findall(at))
    overconf_n = len(OVERCONF.findall(at))
    uncertainty_n = len(UNCERTAINTY.findall(at))

    ratio = hedge_n / (hedge_n + overconf_n) if (hedge_n + overconf_n) > 0 else 0.5

    base = (
        5 if ratio >= 0.85 else
        4 if ratio >= 0.70 else
        3 if ratio >= 0.55 else
        2 if ratio >= 0.40 else 1
    )
    # Explicit uncertainty markers bonus
    score = min(5, base + (1 if uncertainty_n >= 5 else 0))

    notes.append(
        f"Hedge: {hedge_n} | Overconfident: {overconf_n} | "
        f"Uncertainty markers: {uncertainty_n} | ratio: {ratio:.2f} → {score}/5"
    )
    return R(9, "Calibrated", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D10  Precise — curated high-signal findings, precision > recall
# ══════════════════════════════════════════════════════════════════════════════

def d10_precise(run_tests: bool) -> R:
    notes = []
    at = agent_text()
    h = hooks_text()

    checks = [
        (
            "'Top N' or 'most important N' constraints in agents (≥3)",
            n(r"\btop[- ]\d+|\bmost\s+important\s+\d+|\bhighest[-\s]\d+", at) >= 3,
        ),
        (
            "Anti-verbosity instructions (≥2 hits)",
            n(
                r"\b(do\s+not\s+(list|enumerate)\s+all|avoid\s+verbose|"
                r"prioritize\s+signal|curated|high[-\s]signal)\b",
                at,
            ) >= 2,
        ),
        (
            "Precision-over-recall framing",
            n(
                r"\b(precision\s*over\s*recall|signal.*noise|"
                r"quality\s+over\s+quantity|avoid\s+noise)\b",
                at,
            ) >= 1,
        ),
        (
            "Explicit output constraints: 'no more than' / 'at most' / 'limit to' (≥3)",
            n(r"\b(no\s+more\s+than|at\s+most|limit\s+to|focus\s+on\s+the\s+\d+)\b", at) >= 3,
        ),
        (
            "SubagentStop severity routing: critical / important / minor (≥6 hits)",
            n(r"\b(critical|important|minor)\b", h) >= 6,
        ),
    ]
    score = checklist(checks, notes)
    return R(10, "Precise", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D11  Iterative — repeated loops, convergence monitoring
# ══════════════════════════════════════════════════════════════════════════════

def d11_iterative(run_tests: bool) -> R:
    notes = []
    cmd_text = concat(commands())

    checks = [
        (
            "Convergence / loop / iteration in work command (≥3)",
            n(r"\b(convergence|converge|monitor|iteration|loop\s+until)\b", cmd_text) >= 3,
        ),
        (
            "Phase / step markers in workflow commands (≥5)",
            n(r"\b(phase\s+\d|step\s+\d|round\s+\d|pass\s+\d|\d+\.\s+\*\*)", cmd_text) >= 5,
        ),
        (
            "Feedback loop language (≥3 hits)",
            n(r"\b(feedback|re-?run|repeat|revisit|refine|next\s+iteration)\b", cmd_text) >= 3,
        ),
        (
            "Termination / until criteria defined (≥2)",
            n(r"\b(until|stop\s+when|terminate\s+if|converge\s+when|exit\s+when)\b", cmd_text) >= 2,
        ),
        (
            "Multi-pass workflow language (first pass / second pass)",
            n(r"\b(first\s+pass|second\s+pass|initial\s+pass|final\s+pass)\b", cmd_text) >= 2,
        ),
    ]
    score = checklist(checks, notes)
    return R(11, "Iterative", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D12  Compounding — archives solutions, builds on itself
# ══════════════════════════════════════════════════════════════════════════════

def d12_compounding(run_tests: bool) -> R:
    notes = []
    solutions_dir = ROOT / "docs" / "solutions"
    solution_files = list(solutions_dir.glob("**/*.md")) if solutions_dir.exists() else []
    solution_subdirs = [d for d in solutions_dir.iterdir() if d.is_dir()] if solutions_dir.exists() else []

    checks = [
        (
            "docs/solutions/ directory exists",
            solutions_dir.exists(),
        ),
        (
            "docs/solutions/ contains ≥1 .md solution files",
            len(solution_files) >= 1,
        ),
        (
            "docs/solutions/ has ≥3 category subdirectories",
            len(solution_subdirs) >= 3,
        ),
        (
            "solutions-archivist agent exists",
            agent_named("solutions-archivist"),
        ),
        (
            "/workflows:compound command exists",
            command_named("compound"),
        ),
    ]
    score = checklist(checks, notes)
    return R(12, "Compounding", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D13  Systematic — structured multi-step workflows, explicit dispatch
# ══════════════════════════════════════════════════════════════════════════════

def d13_systematic(run_tests: bool) -> R:
    notes = []
    cmd_text = command_text()
    all_comp = agent_text() + cmd_text

    coordinator = find("agents/workflow/research-coordinator.md")
    coord_text = concat(coordinator)

    checks = [
        (
            "Numbered list steps across commands (≥10 total)",
            n(r"^\s*\d+\.\s+\S", cmd_text, re.MULTILINE) >= 10,
        ),
        (
            "research-coordinator has explicit dispatch algorithm",
            n(r"\b(dispatch|algorithm|procedure|step\s+\d)", coord_text) >= 3,
        ),
        (
            "Checklist items [ ] or [x] across components (≥5)",
            n(r"\[\s*[xX ]?\s*\]", all_comp) >= 5,
        ),
        (
            "Phase markers: 'Phase N' / 'Step N' (≥4 in commands)",
            n(r"\bphase\s+\d+\b|\bstep\s+\d+\b", cmd_text) >= 4,
        ),
        (
            "Sequential connector language in commands (≥8 hits)",
            n(r"\b(then|next|subsequently|afterward|following\s+this)\b", cmd_text) >= 8,
        ),
    ]
    score = checklist(checks, notes)
    return R(13, "Systematic", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D14  Adversarial — deliberate stress-testing, self-challenging
# ══════════════════════════════════════════════════════════════════════════════

def d14_adversarial(run_tests: bool) -> R:
    notes = []
    adversarial_agents = find(
        "agents/review/identification-critic.md",
        "agents/review/journal-referee.md",
    )
    adv_text = concat(adversarial_agents)
    stress_text = concat(find("commands/stress-test.md"))

    checks = [
        (
            "identification-critic agent exists",
            agent_named("identification-critic"),
        ),
        (
            "journal-referee agent exists",
            agent_named("journal-referee"),
        ),
        (
            "/stress-test command exists",
            command_named("stress-test"),
        ),
        (
            "Adversarial vocabulary in critic/referee agents (≥5 hits)",
            n(
                r"\b(challenge|reject|flaw|invalidate|stress|adversarial|"
                r"critique|weakness|failure\s+mode|where\s+does\s+this\s+break)\b",
                adv_text,
            ) >= 5,
        ),
        (
            "Oster bounds / breakdown frontier in stress-test command",
            n(r"\b(oster|breakdown\s+frontier|robustness|sensitivity\s+analysis)\b", stress_text) >= 2,
        ),
    ]
    score = checklist(checks, notes)
    return R(14, "Adversarial", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D15  Rigorous — held to mathematical and academic standards
# ══════════════════════════════════════════════════════════════════════════════

def d15_rigorous(run_tests: bool) -> R:
    notes = []
    econ_rev = concat(find("agents/review/econometric-reviewer.md"))

    checks = [
        (
            "mathematical-prover agent exists",
            agent_named("mathematical-prover"),
        ),
        (
            "Regularity conditions in econometric-reviewer",
            n(r"regularity\s+condition", econ_rev) >= 1,
        ),
        (
            "Formal proof logic: iff / QED / therefore / contradiction (≥3 hits)",
            n(
                r"\b(iff|Q\.?E\.?D\.?|therefore|which\s+contradicts|"
                r"by\s+contradiction|sufficiency|necessity)\b",
                agent_text(),
            ) >= 3,
        ),
        (
            "Compactness / Lipschitz / contraction / fixed-point language",
            n(
                r"\b(lipschitz|compact(ness)?|measurability|differentiab|"
                r"contraction|fixed[- ]point|banach)\b",
                agent_text(),
            ) >= 2,
        ),
        (
            "CAS / symbolic computation / formal verification mentioned",
            n(
                r"\b(CAS|sympy|mathematica|formal\s+verif|"
                r"computer\s+algebra|symbolic\s+computation)\b",
                agent_text() + command_text(),
            ) >= 1,
        ),
    ]
    score = checklist(checks, notes)
    return R(15, "Rigorous", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D16  Actionable — concrete fixes (file:line), not vague complaints
# ══════════════════════════════════════════════════════════════════════════════

def d16_actionable(run_tests: bool) -> R:
    notes = []
    at = agent_text()
    h = hooks_text()

    checks = [
        (
            "file:line / line-number format in agent output instructions (≥2)",
            n(r"\bfile\s*:\s*line\b|\bline\s+number|\bat\s+line\s+\d", at) >= 2,
        ),
        (
            "'Exact/specific/precise location' in fix instructions (≥3)",
            n(
                r"\b(exact\s+(fix|change|correction|command)|"
                r"specific\s+(file|line|location|path)|"
                r"precise\s+(location|error|step))\b",
                at,
            ) >= 3,
        ),
        (
            "Anti-vague instructions: 'do not say / avoid vague / be specific' (≥2)",
            n(
                r"\b(do\s+not\s+say|avoid\s+vague|no\s+vague|"
                r"be\s+specific|must\s+include|include\s+the\s+exact)\b",
                at,
            ) >= 2,
        ),
        (
            "SubagentStop uses [agent]: [finding] → [action] format",
            n(r"\[agent\].*\[finding\]|\[\w[\w-]+\].*→\s*\[", h) >= 1,
        ),
        (
            "Severity routing: critical → immediate action in hooks (≥2 hits)",
            n(r"(critical.*immediate|immediate.*action|blocking.*fix|must\s+fix)", h) >= 2,
        ),
    ]
    score = checklist(checks, notes)
    return R(16, "Actionable", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D17  Interrogative — asks questions, does not make blind assertions
# ══════════════════════════════════════════════════════════════════════════════

def d17_interrogative(run_tests: bool) -> R:
    notes = []
    # agents + commands only (skills are not interrogative by design)
    ac_text = agent_text() + command_text()

    # Lines that end with a question mark (literal questions posed)
    question_lines = n(r"[^\n]+\?\s*$", ac_text, re.MULTILINE)

    # Explicit "ask user" instructions
    ask_instructions = n(
        r"\b(ask\s+(the\s+)?(user|researcher|author)|"
        r"inquire\s+about|request\s+clarification|"
        r"identify\s+whether|confirm\s+(with|that|whether))\b",
        ac_text,
    )

    # Interrogative framing in agent descriptions
    interrogative_framing = n(
        r"\b(what\s+is|how\s+(does|do|is)|why\s+does|"
        r"is\s+there|are\s+there|does\s+the)\b",
        ac_text,
    )

    combined = question_lines + ask_instructions * 2 + interrogative_framing
    score = (
        5 if combined >= 50 else
        4 if combined >= 35 else
        3 if combined >= 20 else
        2 if combined >= 10 else 1
    )
    notes.append(
        f"Question lines: {question_lines} | Ask instructions: {ask_instructions} | "
        f"Interrogative framing: {interrogative_framing} | combined: {combined} → {score}/5"
    )
    return R(17, "Interrogative", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D18  Specialized — deep domain expertise, guards against generic dilution
# ══════════════════════════════════════════════════════════════════════════════

def d18_specialized(run_tests: bool) -> R:
    notes = []

    DOMAIN = re.compile(
        r"\b(GMM|IV\b|2SLS|DiD\b|RDD\b|BLP\b|NFXP|MPEC|DGP\b|RMSE\b|"
        r"structural\s+estimation|causal\s+inference|identification\b|"
        r"endogeneity|instrumental\s+variable|Monte\s+Carlo|"
        r"fixed\s+effect|panel\s+data|heteroscedasticity|autocorrelation|"
        r"moment\s+condition|generalized\s+method|Berry.Levinsohn|"
        r"Heckman|selection\s+bias|propensity\s+score|contraction\s+mapping|"
        r"bootstrap\s+standard\s+error|parallel\s+trends|exclusion\s+restriction|"
        r"first\s+stage|weak\s+instrument|overidentification|synthetic\s+control|"
        r"regression\s+discontinuity|difference.in.difference|local\s+average\s+treatment)\b",
        re.IGNORECASE,
    )
    GENERIC = re.compile(
        r"\b(null\s+pointer|stack\s+overflow|dependency\s+injection|"
        r"microservice|REST\s+API|GraphQL|CRUD|OOP|design\s+pattern|"
        r"factory\s+method|singleton|observer\s+pattern)\b",
        re.IGNORECASE,
    )

    domain_n = len(DOMAIN.findall(components_text()))
    generic_n = len(GENERIC.findall(components_text()))
    total = domain_n + generic_n
    ratio = domain_n / total if total > 0 else 0.0

    score = (
        5 if domain_n >= 50 and ratio >= 0.85 else
        4 if domain_n >= 30 and ratio >= 0.75 else
        3 if domain_n >= 15 and ratio >= 0.60 else
        2 if domain_n >= 8 else 1
    )
    notes.append(
        f"Domain terms: {domain_n} | Generic terms: {generic_n} | "
        f"Specialization ratio: {ratio:.2f} → {score}/5"
    )
    return R(18, "Specialized", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D19  Curated — quality-gated at every layer, publication-quality outputs
# ══════════════════════════════════════════════════════════════════════════════

def d19_curated(run_tests: bool) -> R:
    notes = []
    comp = components_text()
    h = hooks_text()

    checks = [
        (
            "'Publication-quality/ready' language (≥3 hits)",
            n(r"\bpublication[- ](quality|ready)\b", comp) >= 3,
        ),
        (
            "Quality-gate phrases: curated / high-signal / filtered (≥4 hits)",
            n(
                r"\b(curated|quality[- ]gated|high[- ]signal|"
                r"filtered|selective|only\s+if\s+quality)\b",
                comp,
            ) >= 4,
        ),
        (
            "Stop hook has suggestion-only (non-blocking) items (≥3 hits)",
            n(r"\b(suggest|non[- ]blocking|recommendation(?!\s+against))\b", h) >= 3,
        ),
        (
            "Output format / template instructions in agents (≥3 hits)",
            n(
                r"\b(output\s+format|format\s*:|template\s*:|"
                r"structure\s+your\s+(output|response)|present\s+as)\b",
                comp,
            ) >= 3,
        ),
        (
            "AEA / journal / publication-standard references (≥4 hits)",
            n(r"\b(AEA|journal\b|publication\s+standard|peer[- ]review|referee)\b", comp) >= 4,
        ),
    ]
    score = checklist(checks, notes)
    return R(19, "Curated", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# D20  Literate — formal code, clear commits, humanized docs
# ══════════════════════════════════════════════════════════════════════════════

def d20_literate(run_tests: bool) -> R:
    notes = []
    contributing = ROOT / "CONTRIBUTING.md"
    contrib_text = contributing.read_text("utf-8", errors="replace") if contributing.exists() else ""
    contrib_words = len(contrib_text.split())

    checks = [
        (
            "CONTRIBUTING.md exists",
            contributing.exists(),
        ),
        (
            "CONTRIBUTING.md ≥ 500 words",
            contrib_words >= 500,
        ),
        (
            "CONTRIBUTING.md has 'Known Gotchas' section",
            n(r"known\s+gotcha", contrib_text) >= 1,
        ),
        (
            "All agent stems are kebab-case (lowercase, hyphens only)",
            all(re.match(r"^[a-z][a-z0-9-]+$", p.stem) for p in agents()),
        ),
        (
            "All command stems are kebab-case",
            all(re.match(r"^[a-z][a-z0-9:-]+$", p.stem) for p in commands()),
        ),
    ]
    score = checklist(checks, notes)
    if contributing.exists():
        notes.append(f"CONTRIBUTING.md: {contrib_words} words")
    return R(20, "Literate", score, notes)


# ══════════════════════════════════════════════════════════════════════════════
# Master runner
# ══════════════════════════════════════════════════════════════════════════════

# ── Active dimensions (10 most relevant for this plugin) ──────────────────────
#
# Cut: D01 Autonomous (CI hygiene, already 5/5), D02 Minimal (code hygiene),
#      D04 Parallel (execution strategy, not content quality),
#      D05 Robust (shellcheck-level, not research quality),
#      D08 Reproducible (deployment portability, already 5/5),
#      D11 Iterative (absorbed by D12 Compounding),
#      D13 Systematic (already 5/5, table stakes for any workflow tool),
#      D17 Interrogative (already 5/5, absorbed by D10 + D16),
#      D19 Curated (subset of D10 Precise + D15 Rigorous),
#      D20 Literate (docs hygiene, not research quality)
#
# Kept: the 10 that map directly to the plugin's core promise —
#       trustworthy, specialized, self-challenging research assistance
#       that compounds over time.

DIMENSIONS = [
    # Trust
    d06_genuine,        # Never falsely claim completion / verification
    d09_calibrated,     # Honest about LLM limits; hedged language
    # Research rigour
    d15_rigorous,       # Mathematical standards: proofs, regularity conditions
    d14_adversarial,    # Self-challenging: identification-critic, stress-test
    d18_specialized,    # Domain expertise: GMM/IV/BLP, not generic coding
    # Research utility
    d10_precise,        # Precision > recall; curated high-signal findings
    d16_actionable,     # Concrete file:line output, not vague complaints
    d07_deterministic,  # Seeded simulations; reproducible research
    # Architecture
    d12_compounding,    # THE defining principle: docs/solutions/ builds over time
    d03_modular,        # One job per agent; focused beats multi-purpose
]

GROUPS = [
    ("Trust",              slice(0, 2)),
    ("Research Rigour",    slice(2, 5)),
    ("Research Utility",   slice(5, 8)),
    ("Architecture",       slice(8, 10)),
]

MAX_SCORE = len(DIMENSIONS) * 5  # 50


def main() -> int:
    global ROOT
    parser = argparse.ArgumentParser(description="Plugin quality evaluator — 10 core dimensions, 50 pts max")
    parser.add_argument("--root", default=".", type=Path, help="Plugin root directory")
    parser.add_argument("--json", action="store_true", help="Emit JSON to stdout")
    parser.add_argument("--run-tests", action="store_true", help="Execute test suite (adds ~60s)")
    args = parser.parse_args()
    ROOT = args.root.resolve()
    _CACHE.clear()  # ensure cache is fresh for this ROOT

    import traceback as _tb

    results: list[R] = []
    for fn in DIMENSIONS:
        try:
            results.append(fn(args.run_tests))
        except Exception as exc:
            # Extract the dimension number from the function name (e.g. d06_genuine → 6)
            m = re.search(r"d(\d+)", fn.__name__)
            dim_num = int(m.group(1)) if m else len(results) + 1
            print(f"ERROR in {fn.__name__}: {exc}", file=sys.stderr)
            _tb.print_exc(file=sys.stderr)
            results.append(R(dim_num, fn.__name__, 1, [f"SCORING ERROR: {exc}"]))

    if args.json:
        print(json.dumps(
            [{"dim": r.dim, "name": r.name, "score": r.score, "notes": r.notes} for r in results],
            indent=2,
        ))
        return 0 if all(r.full for r in results) else 1

    # ── Formatted report ──────────────────────────────────────────────────────
    total = sum(r.score for r in results)
    perfect = sum(1 for r in results if r.full)
    grade = (
        "S" if total == MAX_SCORE else
        "A" if total >= MAX_SCORE * 0.90 else
        "B" if total >= MAX_SCORE * 0.80 else
        "C" if total >= MAX_SCORE * 0.70 else "D"
    )

    W = 62
    print(f"\n{'═' * W}")
    print(f"  compound-science Plugin Quality Report")
    print(f"  {ROOT}")
    print(f"{'═' * W}")

    for group_name, sl in GROUPS:
        group = results[sl]
        group_total = sum(r.score for r in group)
        group_max = len(group) * 5
        print(f"\n  ── {group_name} ({group_total}/{group_max}) {'─' * (W - len(group_name) - 12)}")
        for r in group:
            print(str(r))

    print(f"\n{'─' * W}")
    print(f"  TOTAL  {total}/{MAX_SCORE}  ({perfect}/10 perfect)  Grade: {grade}")

    failing = sorted([r for r in results if not r.full], key=lambda x: x.score)
    if failing:
        print(f"\n  Needs work (lowest scores first):")
        for r in failing:
            tag = r.notes[0] if r.notes else ""
            print(f"    D{r.dim:02d} {r.name} ({r.score}/5) — {tag}")

    print(f"{'═' * W}\n")
    return 0 if total == MAX_SCORE else 1


if __name__ == "__main__":
    sys.exit(main())
