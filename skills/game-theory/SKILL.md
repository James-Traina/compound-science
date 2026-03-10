---
name: game-theory
description: >-
  Guide for game-theoretic methods in structural econometrics and industrial organization. Use when the user is working with strategic interactions, equilibrium analysis, or game-theoretic structural models — including entry games, conduct testing, auction models with strategic bidding, bargaining, or matching markets. Triggers on "Nash equilibrium", "subgame perfect", "best response", "strategic interaction", "entry game", "conduct testing", "auction", "mechanism design", "matching market", "bargaining", "BNE", "Bayesian Nash", "static game", "dynamic game", "repeated game", "multiple equilibria", "equilibrium selection", "discrete game", "oligopoly", "game-theoretic", "player", "payoff", "strategy", "dominant strategy", "Bresnahan-Reiss", "Ciliberto-Tamer", "partial identification", "set identification", or markup test.
---

# Game Theory

Reference for game-theoretic methods in applied structural econometrics and industrial organization. Covers equilibrium concepts, computational methods, structural IO applications, and the identification challenges unique to game-theoretic models.

## When to Use This Skill

Use when the user is:
- Estimating a structural model where agents interact strategically (oligopoly, entry, bargaining, auctions)
- Deriving or computing Nash equilibria, BNE, or subgame perfect equilibria
- Handling the multiple equilibria problem in empirical games
- Testing firm conduct (competitive vs. collusive vs. oligopolistic)
- Estimating entry models, matching models, or bargaining models
- Formalizing an identification argument for a game-theoretic model

Skip when:
- The model is single-agent (use `structural-modeling` skill for dynamic discrete choice, demand estimation)
- The task is standard causal inference without strategic interaction (use `causal-inference` skill)
- The game is a well-known IO model with standard estimation code (pyblp covers BLP demand; see `structural-modeling`)

## Where to Start
- **Choosing equilibrium concept?** See [Framework Overview](#framework-overview)
- **Computing equilibria?** See `references/equilibrium-computation.md`
- **Estimating an IO model?** See `references/io-applications.md`
- **Facing multiple equilibria?** See [The Multiple Equilibria Problem](#the-multiple-equilibria-problem)
- **Confused about identification?** See [Identification in Games](#identification-in-games)

---

## Framework Overview

### Static Games of Complete Information

**Normal form:** A game is defined by (N, {S_i}, {u_i}) — N players, strategy sets S_i, payoff functions u_i(s_1, ..., s_N).

**Nash equilibrium:** A strategy profile s* such that no player can profitably deviate:
```
u_i(s_i*, s_{-i}*) >= u_i(s_i, s_{-i}*)   for all i, all s_i ∈ S_i
```

**Dominant strategies:** s_i* dominates s_i' if u_i(s_i*, s_{-i}) > u_i(s_i', s_{-i}) for all s_{-i}. Dominant strategy equilibria are robust — they do not require beliefs about opponents.

**Mixed strategies:** When no pure-strategy Nash equilibrium exists (or multiple exist), players randomize. A mixed Nash equilibrium requires each player to be indifferent over all strategies in their support. Computing mixed equilibria is more demanding computationally and creates the equilibrium selection problem for estimation.

**Relevance for IO:** Most empirical entry and conduct models are static complete-information games. The workhorse examples are Bresnahan-Reiss (1991) and Berry (1992).

### Dynamic Games: Extensive Form and SPE

**Extensive form:** Represents the sequential structure of a game — who moves when, what they observe, what actions are available.

**Subgame perfect equilibrium (SPE):** Computed by backward induction. A Nash equilibrium that is also an equilibrium in every proper subgame. Eliminates non-credible threats.

```
Terminal nodes → payoffs
         ↑
Last-mover's optimal actions (given payoffs)
         ↑
Second-to-last mover's optimal actions (given last mover's best responses)
         ...
         ↑
First mover's optimal action
```

**Markov perfect equilibrium (MPE):** The standard refinement for dynamic oligopoly games (Ericson-Pakes 1995, Pakes-McGuire 1994). Strategies depend only on the current payoff-relevant state, not full histories. This tractability is essential for empirical work — MPE reduces the strategy space to Markov strategies indexed by a state variable.

**Key difference from single-agent dynamics:** In MPE, each firm's continuation value depends on *competitors' strategies*, so the inner loop must solve a system of coupled Bellman equations simultaneously, not one agent's problem in isolation.

### Incomplete Information: Bayesian Nash Equilibrium

**Bayesian game:** Players have private types θ_i drawn from distributions F_i (the type space). A type summarizes private information — cost, quality, value, capability.

**Bayesian Nash equilibrium (BNE):** A profile of strategies s_i*(θ_i) such that each player maximizes expected utility given their type and beliefs about opponents' types and strategies:
```
s_i*(θ_i) ∈ argmax E_{θ_{-i}} [u_i(s_i, s_{-i}*(θ_{-i}), θ_i, θ_{-i})]
```

**Why it matters empirically:** Auctions are the canonical Bayesian game — bidders have private values (IPV framework) or affiliated signals (mineral rights model). Entry models can be cast as either complete or incomplete information, with very different empirical implications (Bajari, Hong, Ryan 2010).

**Complete vs. incomplete information in entry:**

| Feature | Complete Information | Incomplete Information |
|---------|---------------------|----------------------|
| Equilibrium concept | Nash (pure or mixed) | Bayesian Nash (in thresholds) |
| Multiple equilibria | Severe | Often unique in monotone strategies |
| Identification | Harder (selection rule needed) | Easier (equilibrium pins down behavior) |
| Standard reference | Berry (1992), Bresnahan-Reiss (1991) | Seim (2006), Bajari-Hong-Ryan (2010) |

### Repeated Games: Folk Theorem and Collusion

In infinitely repeated games, cooperation can be sustained as a subgame perfect equilibrium even when one-shot incentives favor defection — the folk theorem.

**Grim trigger strategy:** Cooperate in every period; switch to Nash reversion forever after any defection. Cooperation is sustainable when:
```
π_collude / (1 - δ) >= π_deviate + δ * π_Nash / (1 - δ)
```
Solving: `δ >= (π_deviate - π_collude) / (π_deviate - π_Nash)`

**Empirical relevance:** The Rotemberg-Saloner (1986) model and Green-Porter (1984) provide structural foundations for testing collusion. Empirical work (Porter 1983, Ellison 1994) estimates threshold discount factors and tests whether observed conduct is consistent with Nash reversion strategies.

**Key implication for conduct testing:** Repeated game models predict that collusion is harder to sustain when: (1) discount factor is lower, (2) deviation gains are higher, (3) detection lag is longer. These comparative statics generate testable restrictions.

---

## Structural IO Applications: Overview

For full implementation code, see `references/io-applications.md`.

### Entry Models

Entry models are the canonical empirical application of game theory in IO. Observed market structure (number of entrants) must be consistent with Nash equilibrium, but multiple equilibria may exist. Three main approaches:

**Bresnahan-Reiss (1991)** exploits variation in market size to estimate how competitive conduct changes with the number of firms. The N-th firm enters only if the market is large enough; threshold ratios S_N*/S_{N-1}* > 1 indicate market power. Estimation uses ordered probit on observed firm counts.

**Berry (1992)** extends to asymmetric firms. An ordering restriction (firms enter in order of their profitability index) selects a unique equilibrium, achieving point identification. Estimated by MLE with equilibrium constraints.

**Ciliberto-Tamer (2009)** drops the equilibrium selection assumption. The model is set-identified: the identified set contains all parameter values consistent with *some* Nash equilibrium selection. Estimation uses moment inequalities; confidence regions require Chernozhukov-Hong-Tamer (2007) or Romano-Shaikh subsampling.

### Conduct Testing

Conduct testing asks what game firms are actually playing. The standard approach estimates a conduct parameter θ ∈ [0,1] nesting Bertrand (θ=0), Cournot (θ=1/N), and joint monopoly (θ=1) from the markup equation `p_j - mc_j = -θ * (∂Q_j/∂p_j)^{-1} * Q_j`. In the BLP framework, add a supply side with cost shifters (input prices, factor costs) as instruments. Use the Rivers-Vuong (2002) non-nested test to choose between conduct specifications.

### Bargaining Models

Bargaining models are the standard for vertical IO with bilateral negotiation. The generalized Nash bargaining solution maximizes `(u_1 - d_1)^β * (u_2 - d_2)^{1-β}`, where d_i are disagreement payoffs and β is the bargaining weight (Horn-Wolinsky 1988). The bargaining weight β is identified from variation in outside options — prices should respond to outside option shifts in proportion to (1-β). Applications include medical device markets (Grennan 2013) and cable TV (Crawford-Yurukoglu 2012). The Rubinstein (1982) alternating-offers game provides strategic micro-foundations; its unique SPE converges to Nash bargaining as discount factors approach 1.

### Auctions

Auction models embed the Bayesian game framework directly. In first-price sealed-bid auctions under IPV, the unique symmetric BNE bid function is `b*(v) = E[v_{(N-1)} | v_{(N-1)} < v]`; GPV (Guerre-Perrigne-Vuong 2000) inverts this relationship nonparametrically to recover the private value distribution from observed bids. Second-price and ascending auctions have dominant strategies under IPV (bid true value), simplifying identification. Common value and affiliated value settings require separating signal distributions from the common value — substantially harder. Full auction estimation code is in the `structural-modeling` skill; the game-theoretic foundations are here.

---

## The Multiple Equilibria Problem

The multiple equilibria problem is the central identification challenge in empirical games. When a game has more than one equilibrium, the econometrician needs an additional assumption to determine which equilibrium is played — or must relax point identification.

### Why Multiple Equilibria Arise

**Coordination games:** Multiple equilibria by design (Stag Hunt, Battle of the Sexes). Players coordinate on one of several Pareto-ranked equilibria.

**Entry games:** The game in which firms simultaneously decide whether to enter can have equilibria where firm A enters and B stays out, B enters and A stays out, or both enter — all consistent with Nash. The observed outcome depends on unmodeled coordination mechanisms.

**Symmetric games:** Any symmetric game has a symmetric Nash equilibrium (players randomize identically), but may also have asymmetric equilibria.

### Equilibrium Selection Approaches

| Selection Rule | Basis | Applicability |
|---------------|-------|--------------|
| Risk dominance (Harsanyi-Selten 1988) | Robustness to opponents' mixing | 2x2 games; computationally difficult for large games |
| Payoff dominance | Pareto ranking of equilibria | Only applies when one NE Pareto-dominates all others |
| Trembling-hand perfect (Selten 1975) | Robustness to small mistakes | Refines away weakly dominated strategies |
| Sequential rationality (Kreps-Wilson) | Consistency at off-path information sets | Extensive-form games |
| Quantal Response Equilibrium (McKelvey-Palfrey) | Bounded rationality, logistic choice | Generates unique equilibrium; testable |
| Ordered equilibrium (Berry 1992) | Exogenous ordering by profitability | Entry games with asymmetric firms |

**Quantal Response Equilibrium (QRE):** Firms respond probabilistically — more profitable strategies are played more often, but not with certainty. QRE is indexed by a precision parameter λ → ∞ (QRE converges to Nash), making it useful for equilibrium selection via model fit.

```python
def quantal_response_equilibrium(payoff_matrix, lambda_param=2.0, tol=1e-10, max_iter=5000):
    n = payoff_matrix.shape[0]
    p = np.ones(n) / n
    for _ in range(max_iter):
        eu = payoff_matrix @ p
        log_p_new = lambda_param * eu - (lambda_param * eu).max()
        p_new = np.exp(log_p_new) / np.exp(log_p_new).sum()
        if np.max(np.abs(p_new - p)) < tol:
            return p_new
        p = p_new
    raise RuntimeError("QRE iteration did not converge")
```

### Set Identification (Ciliberto-Tamer Bounds)

When no selection rule is imposed, the model is set-identified. The sharp identified set contains all parameter values θ such that the observed data is consistent with *some* equilibrium selection mechanism under θ.

**Practical approach:**
1. For each θ on a grid, compute all Nash equilibria of the game
2. Check whether the observed outcome distribution can be rationalized as a mixture of Nash equilibria
3. The identified set = {θ : observed distribution ∈ convex hull of Nash outcome distributions}

**Inference:** Use Chernozhukov, Hong, Tamer (2007) for confidence regions, or Romano-Shaikh (2010) subsampling. These are more demanding computationally than point-identified models.

### Using Multiplicity as Identifying Variation

A clever alternative: exploit the fact that different markets may play different equilibria, and use observable correlates of equilibrium selection as instruments (Sweeting 2009, Ellickson-Misra 2011). This requires a model of equilibrium selection, but allows point identification of structural parameters.

---

## Identification in Games

### The Core Challenge

In single-agent models, identification of preferences is straightforward: variation in the agent's choice environment traces out the preference parameters. In games, observed behavior reflects the *interaction* of preferences and equilibrium play. Separating these is the identification problem in games.

**Two sources of endogeneity:**
1. **Strategic complementarities/substitutes:** Firm i's action affects firm j's optimal action, creating a simultaneity problem
2. **Correlated unobservables:** Common market-level shocks (ξ) affect all firms' profits, creating spurious correlation in actions

### Exclusion Restrictions in Games

The standard approach: firm-specific instruments that affect firm i's profitability but not firm j's:

```
π_i(enter) = f(X_m, Z_i, ε_i) - competitive_effects(N_{-i})
π_j(enter) = f(X_m, Z_j, ε_j) - competitive_effects(N_{-i})
```

Here Z_i (firm i's cost, distance to market, regulatory history) are excluded from j's profit equation. Variation in Z_i shifts firm i's entry decision, which then acts as an instrument for firm j's strategic response.

**Formal rank condition (Bajari-Hong-Ryan 2010):** The Jacobian of the equilibrium best-response system with respect to exogenous variables must have full rank at the true parameter value. Failures occur when:
- All firms face the same instruments (no within-market variation)
- Competitive effects are zero (no strategic interaction — reduces to single-agent problem)
- Instruments are weak (modest first-stage relevance)

### Separating Preferences from Equilibrium Behavior

**Two-step approaches:**
1. **Reduced form first:** Estimate best-response functions or conditional choice probabilities from data (nonparametrically if possible)
2. **Structural second:** Map the estimated reduced-form objects back to structural parameters

This logic underlies Hotz-Miller CCP estimation in dynamic games and the Bajari-Hong-Ryan approach for static games.

**Identification of competitive effects:** Competitive effects (how rivals' entry affects own profit) are identified from cross-firm variation in profitability:

```
Cov(entry_j, entry_i | X_m, Z_i, Z_j) ≠ 0

identified from: variation in Z_j conditional on Z_i and X_m
```

If Z_j is a valid firm j-specific instrument, its effect on entry_j, controlling for entry_i, identifies the competitive effect on firm i.

### Rank Conditions for Conduct Parameters

In conduct testing, the conduct parameter θ is identified if demand and cost curves shift independently — the standard simultaneous equations rank condition. Specifically:

**Berry-Levinsohn-Pakes identification of conduct:** Cost shifters (input prices, factor costs) shift the supply equation without shifting demand, tracing out the demand curve and pinning down markups. The conduct parameter is identified from the curvature of the markup-quantity relationship.

**Potential failure modes:**
- Cost shifters correlated with demand shocks (instruments are endogenous)
- Cost shifters only shift the level of costs, not the shape of the markup-quantity relationship (rank failure)
- Products are homogeneous (quantity competition and price competition are identical: Kreps-Scheinkman 1983)

---

## Integration with compound-science

- Use `equilibrium-analyst` agent to verify equilibrium existence, uniqueness, and stability properties before reporting results
- Use `structural-modeling` skill for the estimation machinery (GMM, MLE, NFXP, MPEC) when the game-theoretic structure is already set up
- Use `identification-critic` agent to stress-test the game-theoretic identification argument — exclusion restrictions, rank conditions, separability assumptions
- Use the `/identify` command to formalize the full identification argument: target parameter → model → equilibrium concept → moment conditions → rank condition
- Use `simulation-designer` agent to design Monte Carlo studies verifying identification and estimator performance in your specific game

---

## Common Anti-Patterns

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| Assuming unique equilibrium without verification | Model may have multiple equilibria; point estimates are identification-assumption-dependent | Enumerate all Nash equilibria at estimated parameters; verify uniqueness or state selection rule |
| Using complete-information entry model when firms have private information | Equilibrium concept is wrong; identification fails | Use incomplete-information model (Seim 2006, Bajari-Hong-Ryan 2010) or test for information structure |
| Ignoring the multiple equilibria problem in partial identification | Inference is invalid under point identification when set identification is required | Use Ciliberto-Tamer bounds or impose and justify a selection rule |
| Conduct test with weak instruments | Low power to reject Bertrand; cannot distinguish conduct | Report first-stage relevance; use optimal instruments (BLP supply side) |
| Treating equilibrium prices as exogenous regressors in demand | Prices are endogenous (set in equilibrium); OLS demand estimates are biased | Instrument with cost shifters; use BLP/IV approach |
| Estimating bargaining weight without outside option variation | β is not identified without variation in outside options | Find instruments for outside options (market-level variation in alternatives) |
| Nash reversion assumption in collusion test without threshold test | Assumes away the inference problem | Estimate threshold discount factor; test whether δ* is plausible given observed interest rates |
| Not reporting equilibrium verification | Referees cannot assess model validity | Always report that estimated parameters support equilibrium existence |

---

## Method Selection Guide

| Setting | Model | Equilibrium Concept | Estimation Approach | Key Reference |
|---------|-------|---------------------|--------------------|--------------:|
| Oligopoly market structure | Complete information entry | Nash (ordered selection) | Ordered probit MLE | Bresnahan-Reiss (1991) |
| Asymmetric firm entry | Complete information entry | Nash (ordered selection) | MLE with equilibrium constraints | Berry (1992) |
| Entry with multiple equilibria | Partial identification | Nash (all equilibria) | Moment inequalities | Ciliberto-Tamer (2009) |
| Entry with private cost info | Bayesian game | Bayesian Nash (threshold) | MLE / two-step | Seim (2006) |
| Conduct: competitive vs. collusive | Oligopoly pricing | Nash in prices/quantities | BLP supply + Rivers-Vuong test | Berry-Levinsohn-Pakes (1995) |
| Vertical bargaining | Nash bargaining | Generalized Nash solution | GMM with outside option instruments | Horn-Wolinsky (1988), Crawford-Yurukoglu (2012) |
| Procurement auctions | First-price sealed-bid | Bayesian Nash (bidding) | GPV nonparametric inversion | Guerre-Perrigne-Vuong (2000) |
| Takeover/merger auctions | Ascending auction | Dominant strategy (IPV) | Order statistics / MLE | Athey-Haile (2002) |
| Common value auctions | Affiliated values | BNE (affiliated) | Parametric MLE | Li-Perrigne-Vuong (2002) |
| Dynamic oligopoly | Markov perfect equilibrium | MPE | CCP two-step (Bajari-Benkard-Levin) | Pakes-McGuire (1994), Bajari et al. (2007) |
| Collusion sustainability | Repeated game | Subgame perfect | Threshold discount factor estimation | Green-Porter (1984), Porter (1983) |
| Matching markets | Stable matching | Stable (Gale-Shapley) | Revealed preference from match outcomes | Fox (2010), Choo-Siow (2006) |
| Small 2-player game (theory) | Normal form | Nash (all equilibria) | nashpy / gambit computation | — |

**Decision heuristic:**
1. Is the game static or dynamic?
   - Dynamic → Markov perfect equilibrium; use CCP two-step (Bajari-Benkard-Levin 2007)
   - Static → proceed below
2. Is information complete or incomplete?
   - Incomplete (private types) → BNE; use threshold strategy estimation or GPV for auctions
   - Complete → Nash equilibrium; proceed below
3. Are there multiple equilibria at plausible parameter values?
   - Yes, and willing to impose selection → ordered probit / Berry (1992)
   - Yes, and not willing to impose selection → moment inequalities / Ciliberto-Tamer (2009)
   - No → standard MLE or GMM
4. Is the question about conduct?
   - Use BLP supply side + Rivers-Vuong test, or Rotemberg-Saloner markup test
5. Is bargaining the mechanism?
   - Use generalized Nash bargaining with outside option instruments

---

## Reference Files

Read these when implementing a specific model type:
- `references/equilibrium-computation.md` — Computing Nash, BNE, and SPE: best response iteration, support enumeration, Gambit solver integration, linear complementarity, dynamic programming
- `references/io-applications.md` — Entry models (Bresnahan-Reiss, Ciliberto-Tamer), conduct testing (Bresnahan 1982, markup test), BLP-style IO demand, auctions (first-price, ascending, common value), bargaining (Nash, Rubinstein), matching markets
- `references/estimation-diagnostics.md` — Estimation code (SMM, MSL, BBL, MPEC), convergence diagnostics, model fit tests, counterfactual simulation
