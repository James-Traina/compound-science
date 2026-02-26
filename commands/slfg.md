---
name: slfg
description: Full autonomous research workflow using swarm mode for parallel execution
argument-hint: "[research task, estimation problem, or methodological improvement]"
disable-model-invocation: true
---

Swarm-enabled LFG. Run these steps in order, parallelizing where indicated. Do not stop between steps — complete every step through to the end.

Load skill: orchestrating-swarms

## Sequential Phase

1. `/workflows:plan $ARGUMENTS`
2. `/workflows:work` — **Use swarm mode**: Break the plan into independent tasks and launch parallel subagents via Task tool to build them concurrently. Each subagent handles one task from the plan.

## Parallel Phase

After work completes, launch steps 3 and 4 as **parallel swarm agents** (both only need completed code to operate):

3. `/workflows:review` — spawn as background Task agent
4. `/workflows:compound` — spawn as background Task agent

Wait for both to complete before finishing.

## Output

When all steps are done, output:

```
Research workflow complete.

Plan: [plan file path]
Work: [summary of implementation]
Review: [summary of findings]
Documentation: [docs/solutions/ path if created]
```

Start with step 1 now.
