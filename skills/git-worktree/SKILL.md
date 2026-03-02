---
name: git-worktree
description: "Manages Git worktrees for isolated parallel research work — running concurrent estimation specifications, comparing identification strategies side-by-side, or isolating experimental numerical code. Use when you need parallel branches for different estimators (NFXP vs MPEC), want to run multiple robustness specifications simultaneously, need isolation for risky numerical experiments, or when /workflows:work needs concurrent execution paths."
---

# Git Worktree Manager

This skill provides a unified interface for managing Git worktrees across your research workflow. Whether you're running concurrent estimation specifications, comparing identification strategies side-by-side, or isolating experimental Monte Carlo designs, this skill handles all the complexity.

## What This Skill Does

- **Create worktrees** from main branch with clear branch names
- **List worktrees** with current status
- **Switch between worktrees** for parallel work
- **Clean up completed worktrees** automatically
- **Interactive confirmations** at each step
- **Automatic .gitignore management** for worktree directory
- **Automatic .env file copying** from main repo to new worktrees

## CRITICAL: Always Use the Manager Script

**NEVER call `git worktree add` directly.** Always use the `worktree-manager.sh` script.

The script handles critical setup that raw git commands don't:
1. Copies `.env`, `.env.local`, `.env.test`, etc. from main repo
2. Ensures `.worktrees` is in `.gitignore`
3. Creates consistent directory structure

```bash
# CORRECT - Always use the script
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create nfxp-starting-values

# WRONG - Never do this directly
git worktree add .worktrees/nfxp-starting-values -b nfxp-starting-values main
```

## When to Use This Skill

Use this skill in these scenarios:

1. **Review (`/workflows:review`)**: If NOT already on the target branch (PR branch or requested branch), offer worktree for isolated review
2. **Research Work (`/workflows:work`)**: Always ask if user wants parallel worktree or live branch work
3. **Parallel Estimation**: Running BLP with different starting value grids, comparing NFXP vs MPEC vs CCP on the same data, or testing alternative instrument sets simultaneously
4. **Concurrent Simulations**: Running Monte Carlo studies with different DGP specifications in parallel (e.g., varying sample sizes, error distributions, or endogeneity strength)
5. **Robustness Branches**: Isolating specification variants — DiD with staggered adoption vs standard two-period, IV with different exclusion restrictions, alternative moment conditions
6. **Cleanup**: After completing work in a worktree

## How to Use

### In Claude Code Workflows

The skill is automatically called from `/workflows:review` and `/workflows:work` commands:

```
# For review: offers worktree if not on PR branch
# For work: always asks - new branch or worktree?
```

### Manual Usage

You can also invoke the skill directly from bash:

```bash
# Create a new worktree (copies .env files automatically)
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create blp-alt-moments

# List all worktrees
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh list

# Switch to a worktree
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh switch blp-alt-moments

# Copy .env files to an existing worktree (if they weren't copied)
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh copy-env blp-alt-moments

# Clean up completed worktrees
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh cleanup
```

## Commands

### `create <branch-name> [from-branch]`

Creates a new worktree with the given branch name.

**Options:**
- `branch-name` (required): The name for the new branch and worktree
- `from-branch` (optional): Base branch to create from (defaults to `main`)

**Example:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create nfxp-starting-values
```

**What happens:**
1. Checks if worktree already exists
2. Updates the base branch from remote
3. Creates new worktree and branch
4. **Copies all .env files from main repo** (.env, .env.local, .env.test, etc.)
5. Shows path for cd-ing to the worktree

### `list` or `ls`

Lists all available worktrees with their branches and current status.

**Example:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh list
```

**Output shows:**
- Worktree name
- Branch name
- Which is current (marked with ✓)
- Main repo status

### `switch <name>` or `go <name>`

Switches to an existing worktree and cd's into it.

**Example:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh switch nfxp-starting-values
```

**Optional:**
- If name not provided, lists available worktrees and prompts for selection

### `cleanup` or `clean`

Interactively cleans up inactive worktrees with confirmation.

**Example:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh cleanup
```

**What happens:**
1. Lists all inactive worktrees
2. Asks for confirmation
3. Removes selected worktrees
4. Cleans up empty directories

## Workflow Examples

### Comparing Estimation Methods

```bash
# Run BLP demand estimation with NFXP (nested fixed-point):
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create blp-nfxp

# In parallel, run the same model with MPEC (constrained optimization):
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create blp-mpec

# And a CCP (conditional choice probability) approach:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create blp-ccp

# List all concurrent estimation runs:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh list

# Switch to check convergence on the NFXP run:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh switch blp-nfxp

# After comparing results across methods, clean up:
cd .
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh cleanup
```

### Parallel Robustness Specifications

```bash
# Baseline DiD specification with staggered adoption (copies .env files):
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create did-staggered-robust

# Alternative: Callaway-Sant'Anna estimator:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create did-callaway-santanna

# Alternative: Sun-Abraham interaction-weighted estimator:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create did-sun-abraham

# List what you have:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh list

# Switch between them to compare treatment effect estimates:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh switch did-staggered-robust

# Return to main and cleanup when done:
cd .
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh cleanup
```

### Concurrent Monte Carlo Simulations

```bash
# Baseline DGP with homoskedastic errors:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create mc-dgp-homoskedastic

# Variant with heteroskedastic errors:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create mc-dgp-heteroskedastic

# Variant with weak instruments:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh create mc-dgp-weak-iv

# Each worktree runs its simulation independently.
# Switch to check bias/RMSE/coverage results:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh switch mc-dgp-weak-iv

# Cleanup after consolidating results:
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh cleanup
```

## Key Design Principles

### KISS (Keep It Simple, Stupid)

- **One manager script** handles all worktree operations
- **Simple commands** with sensible defaults
- **Interactive prompts** prevent accidental operations
- **Clear naming** using branch names directly

### Opinionated Defaults

- Worktrees always created from **main** (unless specified)
- Worktrees stored in **.worktrees/** directory
- Branch name becomes worktree name
- **.gitignore** automatically managed

### Safety First

- **Confirms before creating** worktrees
- **Confirms before cleanup** to prevent accidental removal
- **Won't remove current worktree**
- **Clear error messages** for issues

## Integration with Workflows

### `/workflows:review`

Instead of always creating a worktree:

```
1. Check current branch
2. If ALREADY on target branch (PR branch or requested branch) → stay there, no worktree needed
3. If DIFFERENT branch than the review target → offer worktree:
   "Use worktree for isolated review? (y/n)"
   - yes → call git-worktree skill
   - no → proceed with PR diff on current branch
```

The `research-coordinator` agent can help decide when parallel worktrees are appropriate versus sequential work on a single branch. Typical triggers: running alternative estimation specifications that each take hours, or isolating a risky numerical experiment (e.g., new optimizer settings) from your working results.

### `/workflows:work`

Always offer choice:

```
1. Ask: "How do you want to work?
   1. New branch on current worktree (sequential — e.g., one specification at a time)
   2. Worktree (parallel — e.g., run NFXP and MPEC simultaneously)"

2. If choice 1 → create new branch normally
3. If choice 2 → call git-worktree skill to create from main
```

## Troubleshooting

### "Worktree already exists"

If you see this, the script will ask if you want to switch to it instead.

### "Cannot remove worktree: it is the current worktree"

Switch out of the worktree first (to main repo), then cleanup:

```bash
cd $(git rev-parse --show-toplevel)
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh cleanup
```

### Lost in a worktree?

See where you are:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh list
```

### .env files missing in worktree?

If a worktree was created without .env files (e.g., via raw `git worktree add`), copy them:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/scripts/worktree-manager.sh copy-env blp-alt-moments
```

Navigate back to main:

```bash
cd $(git rev-parse --show-toplevel)
```

## Technical Details

### Directory Structure

```
.worktrees/
├── blp-nfxp/               # NFXP estimation run
│   ├── .git
│   ├── src/
│   └── ...
├── blp-mpec/               # MPEC estimation run
│   ├── .git
│   ├── src/
│   └── ...
├── did-staggered-robust/   # Robustness specification
│   ├── .git
│   ├── src/
│   └── ...
└── ...

.gitignore (updated to include .worktrees)
```

### How It Works

- Uses `git worktree add` for isolated environments
- Each worktree has its own branch
- Changes in one worktree don't affect others
- Share git history with main repo
- Can push from any worktree

### Performance

- Worktrees are lightweight (just file system links)
- No repository duplication
- Shared git objects for efficiency
- Much faster than cloning or stashing/switching
