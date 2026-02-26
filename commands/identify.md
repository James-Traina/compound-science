---
name: identify
description: "Formalize identification argument with assumptions, derivation, regularity conditions, and adversarial review"
argument-hint: "<target parameter, model description, or identification strategy>"
---

# Identification Argument Pipeline

**Pipeline mode:** This command operates fully autonomously. All decisions are made automatically.

Construct a complete, self-contained identification argument step-by-step. Produces a formal document that states the target parameter, enumerates all assumptions, derives the identification result, states regularity conditions, connects to an estimator, and undergoes adversarial review. An identification argument that does not explicitly state ALL assumptions is incomplete.

## Input Document

<input_document> #$ARGUMENTS </input_document>

**If no input:** Search for files containing identification-related content (terms like "exclusion restriction", "identification", "instrument", "assumption", "identified", "moment condition"). If found, use the most recently modified file. If nothing found, state "No identification context found. Provide a target parameter or model description (e.g., 'demand elasticity in differentiated products market')." and stop.

## Execution Workflow

### Phase 1: Target Parameter

Clearly state what we are trying to identify. Ambiguity here propagates through the entire argument.

1. **Define the target parameter** in formal notation:
   - θ₀ = ... (the parameter of interest, precisely defined)
   - If a function: θ₀ = g(F) where F is the joint distribution of observables
   - If a structural parameter: θ₀ is the value in the true DGP

2. **Economic interpretation:**
   - What does θ₀ mean in economic terms?
   - Example: "The average price elasticity of demand for cereal, measuring the percentage change in quantity demanded for a 1% increase in price, holding product characteristics and consumer demographics fixed."

3. **Why it matters:**
   - Policy relevance: what decisions depend on knowing θ₀?
   - Theoretical importance: what does θ₀ tell us about economic mechanisms?
   - Literature context: where does this fit in the existing body of work?

4. **Point vs set identification:**
   - Is the goal to uniquely pin down θ₀ (point identification)?
   - Or to bound θ₀ within an identified set Θ₀ (partial/set identification)?
   - Auto-determine based on context: if the model has discrete outcomes with limited variation, set identification may be the natural target. Otherwise default to point identification.

### Phase 2: Model & Assumptions

Document the complete model. Every assumption must be stated explicitly — unstated assumptions are the most common source of identification failures.

1. **Model specification:**

   Choose the appropriate framework:

   | Framework | When to use |
   |-----------|------------|
   | **Structural equations** | Supply/demand, production functions, dynamic models |
   | **Potential outcomes** | Treatment effects, program evaluation |
   | **Selection model** | Sample selection, Roy model |
   | **Game-theoretic** | Entry, auctions, bargaining |

   Write the complete model:
   - All equations (outcome, selection, equilibrium conditions)
   - All random variables and their domains
   - All deterministic functions and their properties

2. **Enumerate ALL assumptions** — number them sequentially:

   ```
   A1. [Assumption name]: [Formal statement]
       Economic interpretation: ...
       Plausibility: ...
       Testable implications: [if any]

   A2. [Assumption name]: [Formal statement]
       Economic interpretation: ...
       Plausibility: ...
       Testable implications: [if any]

   ...
   ```

3. **Classify each assumption:**

   | Assumption | Type | Role | Testable? |
   |-----------|------|------|-----------|
   | A1: ... | Identifying | Required for point identification | Yes/No |
   | A2: ... | Identifying | Required for point identification | Yes/No |
   | A3: ... | Auxiliary | Convenience (simplifies derivation but not strictly needed) | Yes/No |
   | A4: ... | Normalizing | Scale/location normalization | N/A |

   **Common assumption types to check for:**

   | Category | Examples |
   |----------|---------|
   | **Exclusion restrictions** | Instrument Z affects D but not Y directly |
   | **Independence/exogeneity** | E[U|Z] = 0, or full independence U ⊥ Z |
   | **Monotonicity** | D(z) is monotone in z (Imbens-Angrist LATE) |
   | **Rank conditions** | E[ZD'] has full rank (relevance) |
   | **Support conditions** | Support of Z|X covers support of D|X |
   | **Functional form** | Linearity, additivity, parametric distribution |
   | **Stationarity** | Distribution doesn't change over time |
   | **No interference (SUTVA)** | Unit i's outcome doesn't depend on unit j's treatment |
   | **Common trends** | Parallel trends assumption for DiD |

4. **What the data can identify directly:**
   - List the observable joint distribution: F(Y, D, X, Z)
   - List what is directly computable: conditional means, regression coefficients, quantiles
   - These are the building blocks of the identification argument

### Phase 3: Identification Derivation

Step-by-step proof that the target parameter is identified from observables under the stated assumptions. Dispatch `mathematical-prover` agent to verify.

1. **Start from observables:**
   - Begin with what the data gives us: E[Y|X,Z], Pr(D=1|Z), F(Y|D,X), etc.
   - Each step must be explicit and verifiable

2. **Apply assumptions one at a time:**
   ```
   Step 1: From the data, we observe E[Y|Z=z].
           By the model (equation 1), E[Y|Z=z] = E[α + βD + U|Z=z]

   Step 2: By A1 (exogeneity), E[U|Z=z] = 0.
           Therefore E[Y|Z=z] = α + βE[D|Z=z]

   Step 3: By A2 (relevance), E[D|Z=z] varies with z.
           Therefore β = Cov(Y,Z)/Cov(D,Z) = E[Y|Z=1]-E[Y|Z=0] / E[D|Z=1]-E[D|Z=0]

   Step 4: The right-hand side is a function of observables only.
           Therefore β is identified. □
   ```

3. **For each step, note which assumptions are used:**
   - This makes it transparent which assumptions drive the result
   - A reader should be able to trace exactly where each assumption enters

4. **Handle point vs set identification:**

   | Case | Derivation approach |
   |------|-------------------|
   | **Point identification** | Show θ₀ = h(observables) — a unique function |
   | **Set identification** | Show θ₀ ∈ Θ₀ = {θ : observable restrictions hold} — characterize the set |
   | **Partial identification (bounds)** | Derive θ_L ≤ θ₀ ≤ θ_U from observable restrictions |

5. **Dispatch `mathematical-prover` agent** (via Task tool) to verify:
   - Each step follows logically from the previous
   - No hidden assumptions (every transition uses a stated assumption or mathematical identity)
   - Quantifiers are correctly ordered (∀ vs ∃, sup vs inf)
   - Edge cases handled (what if denominator is zero? what if support condition binds?)

### Phase 4: Regularity Conditions

State the conditions needed for the identification result to support estimation. These bridge identification theory and statistical inference.

1. **Smoothness/differentiability:**
   - Is the identified parameter a smooth function of observables?
   - Are moment conditions differentiable in the parameter? (needed for GMM asymptotic theory)
   - If the identification relies on derivatives (e.g., marginal effects): are the relevant densities smooth?

2. **Moment existence:**
   - Which moments must exist? (e.g., E[Y²] < ∞ for OLS consistency)
   - For GMM: do the moment conditions have finite variance? (needed for asymptotic normality)
   - For maximum likelihood: does the log-likelihood have finite Fisher information?

3. **Compactness and boundedness:**
   - Is the parameter space Θ compact? (needed for uniform convergence)
   - Are parameter values bounded away from boundary? (boundary issues change asymptotic distribution)

4. **Uniqueness (global identification):**
   - Is θ₀ the UNIQUE solution to the identifying equations?
   - Or just a local solution? (local vs global identification)
   - If multiple solutions exist: which additional conditions select θ₀?
   - For GMM: is the weighting matrix full rank?

5. **Rate of convergence:**
   - Standard √N rate? (regular case)
   - Slower rate? (e.g., nonparametric, near-boundary, weak identification)
   - This affects confidence interval construction

6. **Compile regularity conditions table:**

   | Condition | Formal statement | Why needed | Plausible? |
   |-----------|-----------------|------------|------------|
   | R1: ... | ... | For consistency | Yes/No/Likely |
   | R2: ... | ... | For asymptotic normality | Yes/No/Likely |
   | R3: ... | ... | For valid inference | Yes/No/Likely |

### Phase 5: Estimation Connection

Link the identification result to a concrete estimator. An identification argument is incomplete if it doesn't connect to how θ₀ is actually estimated.

1. **Estimator specification:**
   - Which estimator implements this identification strategy?
   - Write the estimator explicitly: θ̂ = argmin Q_N(θ) or θ̂ = solution to moment conditions

2. **Moment conditions or objective function:**

   | Identification strategy | Estimator | Moment conditions |
   |------------------------|-----------|-------------------|
   | IV exclusion restriction | 2SLS/GMM | E[Z(Y - Xβ)] = 0 |
   | MLE parametric model | MLE | ∂/∂θ Σ log f(yᵢ|xᵢ; θ) = 0 |
   | Conditional moment restriction | MD/SMD | min_θ ∫(m(x;θ) - m̂(x))² dx |
   | Parallel trends | DiD | E[Y(0)_{t+1} - Y(0)_t | D=1] = E[Y(0)_{t+1} - Y(0)_t | D=0] |
   | BLP demand inversion | BLP-GMM | E[Zξ(θ)] = 0 where ξ = demand unobservable |
   | Contraction mapping | NFXP | Inner: σ(δ;θ) = s, Outer: min_θ ξ(δ(s;θ))'ZWZ'ξ(δ(s;θ)) |

3. **Asymptotic properties:**
   - Consistency: under which conditions does θ̂ →_p θ₀?
   - Rate of convergence: √N(θ̂ - θ₀) →_d ?
   - Limiting distribution: typically Normal, but note exceptions (weak IV, boundary, non-standard)
   - Efficiency: is this estimator efficient in some class? (e.g., GMM with optimal weighting matrix)

4. **Practical considerations:**
   - Computational cost: closed-form vs iterative vs nested
   - Finite-sample behavior: is the estimator known to have bias in small samples?
   - Implementation: which packages implement this estimator?
   - Starting values: how sensitive is the estimator to initialization?

5. **Connect back to identification:**
   - Map each identifying assumption to its role in the estimator
   - Which assumptions ensure consistency? Which ensure valid inference?
   - What happens if an assumption fails? (sensitivity analysis)

### Phase 6: Adversarial Review

Dispatch `identification-critic` agent for a thorough adversarial review of the complete argument.

1. **Dispatch `identification-critic` agent** (via Task tool) with the full identification document:
   - Challenge the exclusion restrictions: is there a plausible violation?
   - Test whether functional form is doing the identification work (would the result hold nonparametrically?)
   - Check for completeness: are there unstated assumptions?
   - Verify point vs set identification claim is correct
   - Assess whether monotonicity/single-crossing conditions are plausible
   - Look for the most common identification pitfalls:

     | Pitfall | Description |
     |---------|------------|
     | Exclusion by assertion | "Z is excluded" without economic argument |
     | Functional form identification | Result only holds under linearity/normality |
     | Missing support conditions | Identification requires variation that may not exist |
     | Confusing correlation with exogeneity | Instrument is relevant but not valid |
     | Ignoring general equilibrium | Partial equilibrium argument in GE setting |
     | Weak identification | Formally identified but nearly unidentifiable in practice |

2. **Dispatch `mathematical-prover` agent** (via Task tool) for final proof check:
   - Verify all steps are valid
   - Check edge cases
   - Confirm quantifier ordering

3. **Compile review findings:**
   - List of concerns (critical / non-critical)
   - Suggested improvements
   - Assessment of overall argument strength

4. **Address critical concerns:**
   - If the identification-critic flags a genuine gap: note it prominently and suggest how to address it
   - If concerns are about plausibility (not logic): document the concern and the economic argument for the assumption
   - Do not silently ignore critic findings

## Output Format

**Success Output:**

```
## Identification Argument: <target parameter>

### Target Parameter
θ₀ = <formal definition>
Interpretation: <economic meaning>

### Model
<structural equations or potential outcomes>

### Assumptions
A1: <name> — <formal statement>
A2: <name> — <formal statement>
...
[Identifying: A1, A2 | Auxiliary: A3 | Normalizing: A4]

### Identification Result
<derivation summary>
Conclusion: θ₀ is [point/set] identified under A1-AN.

### Regularity Conditions
R1-RK: <summary>

### Estimation Connection
Estimator: <name>
Moments: <moment conditions>
Asymptotic distribution: <result>

### Critic Assessment
- Overall: [Strong/Moderate/Weak] identification argument
- Concerns: <list>
- Suggestions: <list>

### Files
- Argument: docs/identification/YYYY-MM-DD-<topic>.md
```

**Partial Identification Output:**

```
## Identification Argument: <target parameter>

### Identified Set
θ₀ ∈ [θ_L, θ_U] where:
  θ_L = <lower bound expression>
  θ_U = <upper bound expression>

### Assumptions for Tighter Bounds
Adding A(K+1) would narrow the set to [θ_L', θ_U']
...
```

## Routes To

- `/estimate` — run the estimator connected to this identification strategy
- `/simulate` — Monte Carlo study of the estimator's properties under this DGP
- `/workflows:review` — full multi-agent review of the identification argument
- `/workflows:compound` — capture identification insights in knowledge base

## Common Identification Strategies Reference

| Strategy | Target | Key assumptions | Classic reference |
|----------|--------|----------------|-------------------|
| IV/2SLS | LATE or ATE | Exclusion, relevance, monotonicity | Imbens & Angrist (1994) |
| DiD | ATT | Parallel trends, no anticipation | Callaway & Sant'Anna (2021) |
| RDD | LATE at cutoff | Continuity of potential outcomes | Cattaneo, Idrobo & Titiunik (2020) |
| BLP demand | Own-price elasticity | Excluded instruments, IIA-free substitution | Berry, Levinsohn & Pakes (1995) |
| Roy model | Selection-corrected returns | Normality or independence of errors | Heckman (1979) |
| Bunching | Elasticity at kink | No optimization frictions, smooth counterfactual | Saez (2010) |
| Auction models | Value distribution | IPV or affiliated values | Guerre, Perrigne & Vuong (2000) |
| Dynamic discrete choice | Per-period payoffs | Additive separability, discount factor known | Rust (1987) |
