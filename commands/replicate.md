---
name: replicate
description: "Build and verify replication packages — routes to reproducibility-auditor agent"
disable-model-invocation: true
---

This command routes to the `reproducibility-auditor` agent, which performs both structural checks (seeds, versions, paths, pipeline integrity) and functional checks (reproduction, data documentation, environment, output matching).

Run the `reproducibility-auditor` agent on the current project. The agent preloads the `reproducible-pipelines` skill, which includes the `references/replication-package.md` checklist for AEA-compliant packages.
