---
title: BLP Starting Values — Contraction Mapping Convergence
category: estimation-issues
estimator: BLP demand
symptom: contraction mapping diverges or converges to wrong fixed point
keywords: BLP, starting values, contraction mapping, inner loop, delta, market shares
solved: true
---

# Problem

BLP inner loop (contraction mapping for mean utilities δ) fails to converge or converges to a local fixed point that does not match observed market shares within tolerance.

## Root Cause

Starting values for δ (mean utilities) are too far from the true fixed point. Common triggers:
- Initializing δ = 0 when true utilities are large in magnitude
- Using stale δ from a previous parameter draw with a very different θ₂
- Contraction tolerance set too loose (>1e-12) causing premature exit

## Solution

1. **Warm-start from logit**: initialize δ from the plain logit inversion before starting BLP contraction.
2. **Tighten inner-loop tolerance**: use `inner_tol = 1e-14` (PyBLP default is fine; manual implementations often use 1e-6 which is too loose).
3. **Check contraction Lipschitz constant**: BLP contraction is contractive iff the mapping is a contraction on the space of market share predictions. Verify `||T(δ') - T(δ)|| < ||δ' - δ||` holds numerically.

```python
# Warm-start: logit inversion
import numpy as np
delta_init = np.log(shares) - np.log(shares_outside)   # logit starting point
# Pass delta_init as starting_delta in pyblp.Simulation or custom solver
```

## References

- Berry, Levinsohn, Pakes (1995) §3 — original contraction mapping
- Nevo (2000) "Practitioner's Guide" — practical starting value advice
- PyBLP documentation — `Simulation.solve()` warm-start options
