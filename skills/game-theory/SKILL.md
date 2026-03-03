---
name: game-theory
description: Guide for game-theoretic methods in structural econometrics and industrial organization. Use when the user is working with strategic interactions, equilibrium analysis, or game-theoretic structural models — including entry games, conduct testing, auction models with strategic bidding, bargaining, or matching markets. Triggers on "Nash equilibrium", "subgame perfect", "best response", "strategic interaction", "entry game", "conduct testing", "auction", "mechanism design", "matching market", "bargaining", "BNE", "Bayesian Nash", "static game", "dynamic game", "repeated game", "multiple equilibria", "equilibrium selection", "discrete game", "oligopoly", "game-theoretic", "player", "payoff", "strategy", "dominant strategy", "Bresnahan-Reiss", "Ciliberto-Tamer", "partial identification", "set identification", or markup test.
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
- **Computing equilibria?** See [Computational Methods](#computational-methods)
- **Estimating an IO model?** Go directly to [Structural IO Applications](#structural-io-applications)
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

## Computational Methods

### Best-Response Iteration

For symmetric games or games with a unique equilibrium, best-response iteration often converges to Nash:

```python
import numpy as np

def best_response_iteration(payoff_matrix, tol=1e-10, max_iter=10000):
    """
    Best-response iteration for 2-player symmetric games.

    payoff_matrix: (n_actions, n_actions) — row player's payoffs
    Assumes row = column (symmetric game).
    """
    n = payoff_matrix.shape[0]

    # Start with uniform mixed strategy
    p = np.ones(n) / n   # row player's mixed strategy
    q = np.ones(n) / n   # column player's mixed strategy

    for iteration in range(max_iter):
        # Column player's best response to p
        expected_payoffs_col = payoff_matrix.T @ p
        q_new = np.zeros(n)
        q_new[np.argmax(expected_payoffs_col)] = 1.0

        # Row player's best response to q_new
        expected_payoffs_row = payoff_matrix @ q_new
        p_new = np.zeros(n)
        p_new[np.argmax(expected_payoffs_row)] = 1.0

        if np.max(np.abs(p_new - p)) < tol and np.max(np.abs(q_new - q)) < tol:
            return p_new, q_new, iteration

        p, q = p_new, q_new

    raise RuntimeError(f"Best-response iteration did not converge in {max_iter} iterations")

# Example: Prisoner's Dilemma
# Strategies: [Cooperate, Defect]
pd_payoffs = np.array([
    [3, 0],   # Cooperate vs (Cooperate, Defect)
    [5, 1],   # Defect vs (Cooperate, Defect)
])
# Dominant strategy: Defect — iteration converges immediately
p_eq, q_eq, iters = best_response_iteration(pd_payoffs)
print(f"Equilibrium: row={p_eq}, col={q_eq} (converged in {iters} iterations)")
```

**Caveat:** Iteration is not guaranteed to converge to a mixed-strategy Nash equilibrium — it converges to pure-strategy Nash equilibria when they exist and are stable. For mixed equilibria, use support enumeration or nashpy.

### Support Enumeration (nashpy)

For small 2-player games, nashpy implements support enumeration to find all Nash equilibria:

```python
import nashpy as nash
import numpy as np

# Define a 2-player game
# Row player's payoff matrix A, column player's B
A = np.array([[3, 0], [5, 1]])   # Row player (Prisoner's Dilemma)
B = np.array([[3, 5], [0, 1]])   # Column player (transpose of A for symmetric game)

game = nash.Game(A, B)

# Find ALL Nash equilibria via support enumeration
equilibria = list(game.support_enumeration())
for i, (sigma_r, sigma_c) in enumerate(equilibria):
    print(f"Equilibrium {i+1}: row={sigma_r.round(3)}, col={sigma_c.round(3)}")

# Vertex enumeration (alternative — more numerically stable for degenerate games)
equilibria_vertex = list(game.vertex_enumeration())

# Lemke-Howson (finds one equilibrium, not all — but faster for large games)
equilibrium_lh = game.lemke_howson(initial_label=0)
```

**Computational limits:** Support enumeration has worst-case exponential complexity in the number of strategies. For games with more than ~10 strategies per player, use gambit.

### gambit (via pygambit) for Large and Extensive-Form Games

gambit is the standard computational game theory package. It handles normal-form and extensive-form games, and implements multiple equilibrium-finding algorithms:

```python
import pygambit as gbt

# Create a normal-form game
g = gbt.Game.new_table([2, 2])
g.title = "Coordination Game"

# Set payoffs (player, strategy_profile, payoff)
g[0, 0][0] = 2; g[0, 0][1] = 2    # Both coordinate: (2, 2)
g[0, 1][0] = 0; g[0, 1][1] = 0    # Mismatch: (0, 0)
g[1, 0][0] = 0; g[1, 0][1] = 0    # Mismatch: (0, 0)
g[1, 1][0] = 1; g[1, 1][1] = 1    # Both coordinate: (1, 1)

# Find all Nash equilibria (support enumeration)
solver = gbt.nash.ExternalEnumMixedSolver()
equilibria = solver.solve(g)
for eq in equilibria:
    print(eq)

# Quantal Response Equilibrium (for selecting among multiple equilibria)
qre_solver = gbt.nash.ExternalLogitSolver()
qre = qre_solver.solve(g)

# Sequential equilibria for extensive-form games
g_ext = gbt.Game.read_game("extensive_form.efg")
seq_solver = gbt.nash.ExternalSequenceFormSolver()
seq_eq = seq_solver.solve(g_ext)
```

### Linear Programming for Zero-Sum Games

Zero-sum games have a unique Nash equilibrium value (minimax theorem). LP gives a direct solution:

```python
from scipy.optimize import linprog
import numpy as np

def solve_zerosum(A):
    """
    Solve a zero-sum game with payoff matrix A (row player's payoffs).
    Returns row player's equilibrium mixed strategy and game value.

    LP formulation: maximize v subject to A^T p >= v*1, sum(p) = 1, p >= 0
    Standard form: maximize -v' subject to -A^T p + v' <= 0, ...
    """
    m, n = A.shape

    # Row player: maximize v subject to A @ q <= v*1, sum(q)=1, q>=0
    # Reformulate as: min -v s.t. -A q + v <= 0, sum(q) = 1, q >= 0
    # Variables: [q_1,...,q_m, v] — length m+1

    # Objective: minimize -v
    c = np.zeros(m + 1)
    c[-1] = -1   # -v

    # Inequality: -A @ q + v * 1 <= 0  →  [-A | 1] @ x <= 0
    A_ub = np.hstack([-A, np.ones((n, 1))])
    b_ub = np.zeros(n)

    # Equality: sum(q) = 1
    A_eq = np.zeros((1, m + 1))
    A_eq[0, :m] = 1.0
    b_eq = np.array([1.0])

    # Bounds: q >= 0, v is free
    bounds = [(0, None)] * m + [(None, None)]

    result = linprog(c, A_ub=A_ub, b_ub=b_ub, A_eq=A_eq, b_eq=b_eq,
                     bounds=bounds, method='highs')

    if result.status != 0:
        raise RuntimeError(f"LP failed: {result.message}")

    q_eq = result.x[:m]
    v = result.x[-1]
    return q_eq, v

# Example: Matching Pennies
A = np.array([[1, -1], [-1, 1]], dtype=float)
q_eq, v = solve_zerosum(A)
print(f"Row player equilibrium: {q_eq.round(3)}")
print(f"Game value: {v:.4f}")   # Should be 0 for matching pennies
```

### Packages Summary

| Package | Language | Best For | Notes |
|---------|----------|----------|-------|
| nashpy | Python | Small normal-form games, learning | Support enumeration, vertex enumeration, Lemke-Howson |
| pygambit | Python | Extensive-form, QRE, research use | Wraps gambit; most complete feature set |
| scipy.optimize.linprog | Python | Zero-sum games | No extra dependency; use HiGHS solver |
| gambit CLI | Any (subprocess) | Batch computation, large games | Direct CLI faster than pygambit for bulk runs |

---

## Structural IO Applications

### Entry Models

Entry models are the canonical empirical application of game theory in IO. The key challenge: observed market structure (number of entrants) must be consistent with Nash equilibrium, but multiple equilibria may exist.

#### Bresnahan-Reiss (1991): Ordered Probit Approach

Bresnahan and Reiss estimate how competitive conduct changes with market structure by exploiting variation in market size. The key insight: if entry is free, the N-th firm enters only if the market is large enough to sustain N firms profitably.

**Model:**
```
π_N = (per-firm variable profit when N firms operate) × (market size S) - entry cost F_N
```

Firms enter until the marginal entrant earns zero profit. The threshold market size to support N firms is:
```
S_N* = F_N / V_N(N)
```

where V_N(N) is per-firm variable profit with N competitors.

**Ordered probit estimation:**

```python
import numpy as np
from scipy.stats import norm
from scipy.optimize import minimize

def bresnahan_reiss_loglik(params, N_obs, S_obs, X_obs):
    """
    Ordered probit log-likelihood for Bresnahan-Reiss entry model.

    params: [alpha_0, alpha_1, ..., alpha_k, beta_0, beta_1, ..., beta_m]
        alpha: coefficients for threshold equation (market size, demographics)
        beta: entry cost shifters
    N_obs: observed number of firms in each market
    S_obs: market size (population, income, etc.)
    X_obs: market characteristics
    """
    n_markets = len(N_obs)
    n_alpha = X_obs.shape[1]

    alpha = params[:n_alpha]
    sigma = np.exp(params[n_alpha])  # log-parameterize for positivity

    # Thresholds: ln(S_N*) = alpha @ X + error
    # Firm N enters iff ln(S) >= ln(S_N*), i.e., standardized: (ln(S) - alpha@X)/sigma >= 0
    thresholds = X_obs @ alpha   # log-threshold for each market

    ll = 0.0
    max_N = int(N_obs.max())

    for i in range(n_markets):
        n_i = int(N_obs[i])
        z_i = (np.log(S_obs[i]) - thresholds[i]) / sigma

        if n_i == 0:
            # No entry: P(N=0) = Phi(-z_1)
            prob = norm.cdf(-z_i)
        elif n_i == max_N:
            # Maximum observed: P(N >= max) = Phi(z_{max})
            prob = norm.cdf(z_i)
        else:
            # Interior: P(N=n) = Phi(z_n) - Phi(z_{n+1})
            # Requires separate threshold per N — simplified here as linear shift
            prob = norm.cdf(z_i) - norm.cdf(z_i - 1.0 / sigma)

        ll += np.log(max(prob, 1e-15))

    return -ll

# Estimation
result = minimize(bresnahan_reiss_loglik,
                  x0=np.zeros(X_obs.shape[1] + 1),
                  args=(N_obs, S_obs, X_obs),
                  method='Nelder-Mead',
                  options={'xatol': 1e-8, 'fatol': 1e-10})
```

**Key results to report:** Threshold ratios S_N*/S_{N-1}*. Under perfect competition these ratios should equal 1. Ratios > 1 indicate market power — the per-firm profit needed to sustain an additional entrant exceeds the competitive level.

**Reference:** Bresnahan, T., and P. Reiss. 1991. "Entry and Competition in Concentrated Markets." *Journal of Political Economy* 99(5): 977-1009.

#### Berry (1992): Complete Information Entry

Berry extends Bresnahan-Reiss to allow firms to be asymmetric. The key equilibrium condition: firm i enters market m if and only if its equilibrium profit is non-negative.

**Model:**
```
π_im = X_m β + Z_im γ - δ * N_m^* + ε_im  >= 0  ↔  firm i enters
```

where N_m^* is the equilibrium number of entrants (endogenous).

**Ordered equilibrium:** Berry imposes an ordering restriction — firms enter in order of their profitability (highest first). This selects a unique equilibrium from the multiple equilibria that generally exist, making the model point-identified.

```python
def berry_entry_loglik(params, entry_data):
    """
    Berry (1992) entry model with ordered equilibrium selection.

    params: [beta, gamma, delta, sigma_eps]
    entry_data: DataFrame with market characteristics, firm dummies, entry outcomes
    """
    beta = params[0]
    delta = params[1]
    sigma = np.exp(params[2])

    ll = 0.0
    for market_id, market in entry_data.groupby('market_id'):
        n_firms = len(market)
        n_entered = market['entered'].sum()

        # Ordered equilibrium: top n_entered firms (by observed rank) entered
        # Equilibrium profit of marginal entrant must be >= 0
        # Profit of first non-entrant must be < 0

        X_m = market['X'].iloc[0]   # market-level variable

        for firm_idx, row in market.iterrows():
            z_profit = (X_m * beta - delta * n_entered + row['Z'] * 0.1) / sigma

            if row['entered']:
                ll += np.log(max(norm.cdf(z_profit), 1e-15))
            else:
                ll += np.log(max(1 - norm.cdf(z_profit), 1e-15))

    return -ll
```

**Reference:** Berry, S. 1992. "Estimation of a Model of Entry in the Airline Industry." *Econometrica* 60(4): 889-917.

#### Ciliberto-Tamer (2009): Partial Identification with Multiple Equilibria

Ciliberto and Tamer drop the equilibrium selection assumption entirely. The model only requires that observed outcomes are consistent with *some* Nash equilibrium — it does not specify which one. This yields a partially identified model: the sharp identified set rather than a point.

**Model setup:**
```
Firm i enters market m if and only if:
    X_m β_i + Z_im γ_i + Σ_{j≠i} α_ij * 1[j enters] + ε_im >= 0

where α_ij < 0 captures competitive effects (entry of j reduces i's profit)
```

**Sharp identified set:** The set of parameter values θ such that there exist selection probabilities that rationalize the data:

```python
def ciliberto_tamer_bounds(params, market_data, n_draws=500, seed=42):
    """
    Ciliberto-Tamer (2009) moment inequality estimator.

    For each parameter value θ, compute:
        H_upper(θ) = P(outcome) under best-case equilibrium selection
        H_lower(θ) = P(outcome) under worst-case equilibrium selection

    θ is in the identified set iff H_lower(θ) <= P_data(outcome) <= H_upper(θ)
    """
    rng = np.random.default_rng(seed)
    beta = params[:2]
    alpha = params[2]   # competitive effect (should be negative)

    n_markets = market_data['market_id'].nunique()
    moment_violations = 0

    for market_id, market in market_data.groupby('market_id'):
        X_m = market['X'].iloc[0]
        n_firms = len(market)
        observed_entry = market['entered'].values

        # Enumerate all Nash equilibria for this market and parameter value
        # For 2-firm case: 4 possible outcomes {(0,0), (0,1), (1,0), (1,1)}
        nash_equilibria = []
        for outcome in [(0, 0), (0, 1), (1, 0), (1, 1)]:
            is_nash = True
            for i in range(n_firms):
                n_others = sum(outcome[j] for j in range(n_firms) if j != i)
                profit_if_enter = X_m * beta[i] + alpha * n_others
                profit_if_stay_out = 0

                if outcome[i] == 1 and profit_if_enter < 0:
                    is_nash = False
                    break
                if outcome[i] == 0 and profit_if_enter > 0:
                    is_nash = False
                    break

            if is_nash:
                nash_equilibria.append(outcome)

        # Check if observed outcome is a Nash equilibrium
        if tuple(observed_entry) not in nash_equilibria:
            moment_violations += 1

    # Return proportion of markets where observed outcome is not a NE
    # In the identified set: this should be 0 (or within sampling error)
    return moment_violations / n_markets

# Outer criterion function for set estimation
def ct_criterion(params, market_data, confidence_level=0.95):
    """
    Chernozhukov-Hong-Tamer (2007) criterion for confidence region.
    Returns the test statistic for whether params is in the confidence set.
    """
    violation_rate = ciliberto_tamer_bounds(params, market_data)
    # Compare to critical value from subsampling or bootstrap
    return violation_rate
```

**Estimation procedure:**
1. Grid search over parameter space (or Markov Chain Monte Carlo)
2. At each θ, check whether observed data is consistent with some Nash equilibrium
3. Report the identified set: all θ consistent with the data
4. Confidence region via Chernozhukov-Hong-Tamer (2007) or Romano-Shaikh subsampling

**Reference:** Ciliberto, F., and E. Tamer. 2009. "Market Structure and Multiple Equilibria in Airline Markets." *Econometrica* 77(6): 1791-1828.

### Conduct Testing

Conduct testing asks: what game are firms actually playing? The standard approach estimates a conduct parameter θ ∈ [0,1] that nests Bertrand (θ=0), Cournot (θ=1/N), and joint monopoly (θ=1).

#### Markup Tests (Roternberg-Saloner, BLP Supply Side)

The workhorse markup equation from oligopoly theory:

```
p_j - mc_j = -θ * (∂Q_j/∂p_j)^{-1} * Q_j
```

where θ is the conduct parameter. Under Bertrand pricing θ = 1 (own elasticity only), under Cournot θ = market share, under collusion θ = industry-level term.

In the BLP framework with a supply side:

```python
import pyblp

# After solving demand, add supply side
problem = pyblp.Problem(
    product_formulations=(
        pyblp.Formulation('1 + prices + x1 + x2'),    # demand linear
        pyblp.Formulation('1 + prices'),               # demand nonlinear
    ),
    product_data=product_data,
    # Supply formulation: marginal cost = gamma @ w + omega
    cost_formulation=pyblp.Formulation('1 + w1 + w2'),
)

# Estimate under Bertrand conduct
results_bertrand = problem.solve(
    sigma=sigma_init,
    pi=pi_init,
    beta=beta_init,
    method='2s',
)

# Retrieve implied marginal costs and markups
costs = results_bertrand.compute_costs()
markups = results_bertrand.compute_markups()
prices_implied = costs + markups

# Conduct test: compare Bertrand vs Cournot vs collusion via
# - J-test on overidentifying restrictions
# - Rivers-Vuong non-nested test
```

#### Rivers-Vuong Non-Nested Conduct Test

Rivers and Vuong (2002) provide a non-nested hypothesis test between conduct specifications:

```python
from scipy.stats import norm as scipy_norm
import numpy as np

def rivers_vuong_test(ll_model1, ll_model2, n_obs):
    """
    Rivers-Vuong (2002) non-nested test between two conduct models.

    H0: models are asymptotically equivalent (neither fits better)
    H1: Model 1 fits better (T > 1.96) or Model 2 fits better (T < -1.96)

    ll_model1, ll_model2: arrays of per-observation log-likelihoods
    """
    d = ll_model1 - ll_model2
    d_bar = d.mean()
    sigma_d = d.std(ddof=1)

    T = np.sqrt(n_obs) * d_bar / sigma_d

    p_value = 2 * (1 - scipy_norm.cdf(abs(T)))

    print(f"Rivers-Vuong T-statistic: {T:.4f}")
    print(f"p-value: {p_value:.4f}")

    if T > 1.96:
        print("Reject H0 in favor of Model 1")
    elif T < -1.96:
        print("Reject H0 in favor of Model 2")
    else:
        print("Fail to reject H0 — models are observationally equivalent")

    return T, p_value
```

**References:**
- Rotemberg, J., and G. Saloner. 1986. "A Supergame-Theoretic Model of Price Wars during Booms." *American Economic Review* 76(3): 390-407.
- Rivers, D., and Q. Vuong. 2002. "Model Selection Tests for Nonlinear Dynamic Models." *Econometrics Journal* 5(1): 1-39.

### Bargaining Models

#### Nash Bargaining (Axiomatic)

The Nash bargaining solution maximizes the Nash product subject to individual rationality:

```
max_{x ∈ F} (u_1(x) - d_1)^β * (u_2(x) - d_2)^{1-β}
```

where d_i are disagreement payoffs (outside options) and β ∈ (0,1) is the bargaining weight.

**Generalized Nash Bargaining (Horn-Wolinsky 1988):** The standard model for vertical bargaining in IO (used in Grennan 2013 for medical device markets, Crawford-Yurukoglu 2012 for cable TV):

```python
import numpy as np
from scipy.optimize import brentq

def nash_bargaining_surplus(prices, costs, outside_options, beta, demand_fn):
    """
    Generalized Nash Bargaining: seller sets price maximizing Nash product.

    Firm's Nash bargaining solution price: implicit equation from FOC of Nash product.
    """
    def nash_product_foc(p, buyer_id):
        """FOC of Nash product w.r.t. price — find root."""
        q = demand_fn(p)
        profit_seller = (p - costs[buyer_id]) * q
        surplus_buyer = outside_options[buyer_id] - p * q   # simplified

        # FOC: beta * d(profit)/dp / profit + (1-beta) * d(surplus)/dp / surplus = 0
        dprofit_dp = q + (p - costs[buyer_id]) * 0   # ignoring demand slope for illustration
        dsurplus_dp = -q

        if profit_seller <= 0 or surplus_buyer <= 0:
            return np.inf
        return beta * dprofit_dp / profit_seller + (1 - beta) * dsurplus_dp / surplus_buyer

    equilibrium_prices = {}
    for buyer_id in range(len(outside_options)):
        try:
            p_star = brentq(nash_product_foc, costs[buyer_id] + 0.01, 100.0,
                           args=(buyer_id,), xtol=1e-10)
            equilibrium_prices[buyer_id] = p_star
        except ValueError:
            equilibrium_prices[buyer_id] = np.nan

    return equilibrium_prices
```

**Structural estimation of bargaining weight β:**

```python
def estimate_bargaining_weight(data, cost_fn, demand_fn, outside_option_fn):
    """
    Identify β from variation in outside options (Horn-Wolinsky).

    Key moment: prices should respond to changes in outside options
    in proportion to (1-β). More variation in outside options → better identification.
    """
    from scipy.optimize import minimize_scalar

    def gmm_objective(beta):
        predicted_prices = []
        observed_prices = data['price'].values

        for i, row in data.iterrows():
            c_i = cost_fn(row)
            d_i = outside_option_fn(row)

            # Nash bargaining price (analytical solution for linear demand)
            # p* = (c + d/q) * beta + (p_monopoly) * (1 - beta)
            # Simplified: illustrative functional form
            p_star = beta * c_i + (1 - beta) * row['reservation_price']
            predicted_prices.append(p_star)

        residuals = observed_prices - np.array(predicted_prices)
        return (residuals ** 2).mean()

    result = minimize_scalar(gmm_objective, bounds=(0.01, 0.99), method='bounded')
    return result.x

# In practice: use GMM with outside option instruments (Crawford-Yurukoglu 2012)
```

#### Alternating Offers (Rubinstein 1982)

The unique SPE of the Rubinstein alternating-offers game is:

```
Proposer gets:   s_1* = 1 / (1 + δ_2)
Responder gets:  s_2* = δ_2 / (1 + δ_2)
```

As δ_1 = δ_2 = δ → 1: s_1* → 1/2 (equal split). This converges to Nash bargaining with equal weights as bargaining frictions vanish.

**For structural estimation:** The alternating-offers model provides micro-foundations for the generalized Nash bargaining solution. With δ_1 ≠ δ_2, the equilibrium shares are:

```
s_1* = (1 - δ_2) / (1 - δ_1 * δ_2)
s_2* = δ_2 * (1 - δ_1) / (1 - δ_1 * δ_2)
```

Estimating δ_1 and δ_2 separately requires variation in outside options and costs that affects each party asymmetrically.

### Auction Models: Game-Theoretic Foundations

Auction estimation is covered in detail in the `structural-modeling` skill. Here we focus on the game-theoretic foundations and the connection to the BNE framework.

**First-price sealed-bid auctions (FPSB):** A Bayesian game where each bidder i has private value v_i ~ F independently. The unique symmetric BNE bid function is:

```
b*(v) = E[v_{(N-1)} | v_{(N-1)} < v] = v - ∫_v_low^v G(t)^{N-1} dt / G(v)^{N-1}
```

where G(·) is the CDF of the value distribution. GPV (Guerre, Perrigne, Vuong 2000) inverts this to recover F from observed bids — a key application of BNE inversion.

**Second-price / ascending auctions (SPSB):** Dominant strategy for each bidder is to bid their true value. Observed transaction prices equal the second-highest value, making identification straightforward under IPV.

**Common value auctions:** Bidders share a common unknown value; their signals are correlated. The winner's curse — the winner draws an upward-biased signal — must be accounted for. Identification requires separating the signal distribution from the common value distribution (Hendricks-Porter 1988, Li-Perrigne-Vuong 2002).

**Affiliated values (Milgrom-Weber 1982):** Values and signals are affiliated (positive dependence). Predicts: ascending auction revenue > second-price > first-price. Revenue equivalence breaks down. Structural estimation with affiliation is substantially harder.

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
    """
    Logistic QRE for a symmetric 2-player game.

    Each player chooses strategy j with probability proportional to exp(lambda * EU_j).
    """
    n = payoff_matrix.shape[0]
    p = np.ones(n) / n   # uniform starting point

    for _ in range(max_iter):
        # Expected utility of each strategy given opponent plays p
        eu = payoff_matrix @ p
        # Softmax response
        log_p_new = lambda_param * eu
        log_p_new -= log_p_new.max()   # numerical stability
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

## Estimation

### Maximum Likelihood for Complete Information Games

For complete information games with a unique equilibrium (or a maintained selection rule), MLE is straightforward:

```python
from scipy.optimize import minimize
import numpy as np
from scipy.stats import norm

def complete_info_entry_mle(params, market_data):
    """
    MLE for Berry (1992) complete information entry model.

    Equilibrium selection: ordered by profitability index.
    """
    beta = params[:3]    # market characteristic coefficients
    gamma = params[3]    # competitive effect
    sigma = np.exp(params[4])   # error scale

    ll = 0.0
    for _, market in market_data.groupby('market_id'):
        n_entered = market['entered'].sum()
        n_firms = len(market)

        # Rank firms by profit index (excluding error)
        profit_indices = market[['X1', 'X2', 'X3']].values @ beta

        # Under ordered equilibrium: top n_entered firms enter
        # Marginal entrant condition: profit_n - gamma*(n-1) + eps > 0
        # First non-entrant condition: profit_{n+1} - gamma*n + eps < 0

        for rank, (_, row) in enumerate(market.sort_values('profit_index', ascending=False).iterrows()):
            z = (profit_indices[rank] - gamma * min(rank, n_entered - 1)) / sigma
            if rank < n_entered:
                ll += np.log(max(norm.cdf(z), 1e-15))
            else:
                ll += np.log(max(1 - norm.cdf(z - gamma / sigma), 1e-15))

    return -ll
```

### Two-Step Estimation

Two-step approaches avoid solving for the full equilibrium at each parameter guess:

**Step 1:** Estimate best-response probabilities (P(firm i enters | rivals' actions and market characteristics)) using flexible methods (logit, probit, local polynomial).

**Step 2:** Given Step 1 estimates, form pseudo-log-likelihood or moment conditions for structural parameters.

```python
from sklearn.linear_model import LogisticRegression
from scipy.optimize import minimize
import numpy as np

def two_step_entry_estimation(market_data, n_rivals_max=5):
    """
    Two-step estimation for entry game (Bajari-Hong-Ryan 2010 approach).

    Step 1: Estimate entry probabilities nonparametrically (logit).
    Step 2: Recover structural profit parameters from estimated probabilities.
    """
    # === STEP 1: Estimate entry probabilities ===
    X_step1 = market_data[['X_market', 'Z_firm', 'n_rivals']].values
    y_step1 = market_data['entered'].values

    logit = LogisticRegression(C=1e6, solver='lbfgs', max_iter=1000)
    logit.fit(X_step1, y_step1)

    # Predicted entry probabilities for each firm in each market
    market_data = market_data.copy()
    market_data['p_enter_hat'] = logit.predict_proba(X_step1)[:, 1]

    # === STEP 2: Recover structural parameters ===
    def step2_moments(params):
        """
        Moment conditions: E[Z_i * (entry_i - p_enter_hat_i)] = 0
        where p_enter_hat is constructed from Step 1 probabilities
        and the structural profit function.
        """
        beta_0, beta_1, gamma = params

        # Predicted entry under structural model
        profit_linear = (beta_0 + beta_1 * market_data['X_market']
                         + gamma * market_data['n_rivals'])
        p_structural = 1 / (1 + np.exp(-profit_linear))

        # Moment conditions: instrument * (structural - nonparam)
        Z = market_data['Z_firm'].values
        residuals = market_data['p_enter_hat'].values - p_structural.values
        moments = Z * residuals

        return moments

    def step2_objective(params):
        moments = step2_moments(params)
        return (moments ** 2).mean()

    result = minimize(step2_objective, x0=[0.0, 0.1, -0.5],
                      method='Nelder-Mead', options={'xatol': 1e-8})

    return result.x, market_data['p_enter_hat']
```

### MPEC Formulation for Games

For complete information games with a unique equilibrium, MPEC can be applied directly — treat the equilibrium strategy profile as a decision variable and impose equilibrium conditions as constraints.

```python
# MPEC for Bertrand pricing game
# Variables: [theta, p_1, ..., p_J] — structural parameters + equilibrium prices
# Constraints: FOC of each firm's pricing problem (Nash conditions)

def bertrand_nash_constraints(x, data, n_products):
    """
    Nash conditions for Bertrand pricing: each firm's price satisfies its FOC.
    Constraint: dπ_j/dp_j = 0 for all j.
    """
    theta = x[:n_params]
    prices = x[n_params:]

    constraints = []
    for j in range(n_products):
        q_j = demand_fn(prices, theta, j, data)
        dq_dpj = demand_derivative(prices, theta, j, data)
        mc_j = cost_fn(theta, j, data)

        # FOC: q_j + (p_j - mc_j) * dq/dp_j = 0
        foc_j = q_j + (prices[j] - mc_j) * dq_dpj
        constraints.append(foc_j)

    return np.array(constraints)
```

### Moment Inequality Estimation

For partially identified models (Ciliberto-Tamer), moment inequality estimators are required:

```python
from scipy.optimize import differential_evolution
import numpy as np

def moment_inequality_criterion(params, market_data, alpha=0.05):
    """
    Andrews-Guggenberger (2009) or Rosen (2008) moment inequality criterion.

    For each parameter value, test whether all moment inequalities hold.
    The identified set = {theta : all moment inequalities hold at level alpha}.
    """
    # Upper and lower bounds on moments
    moments_upper, moments_lower = compute_moment_bounds(params, market_data)

    # Test statistic: sum of violations
    violations_upper = np.maximum(moments_upper - 0, 0) ** 2
    violations_lower = np.maximum(0 - moments_lower, 0) ** 2

    T = violations_upper.sum() + violations_lower.sum()
    return T

def compute_moment_bounds(params, market_data):
    """
    For each observed outcome, compute best-case and worst-case
    predicted probabilities over all Nash equilibria.
    """
    beta, alpha_comp = params[0], params[1]
    moments_upper = []
    moments_lower = []

    for _, market in market_data.groupby('market_id'):
        observed = tuple(market['entered'].values)

        # Find all Nash equilibria
        all_ne = find_all_nash_equilibria(params, market)

        if len(all_ne) == 0:
            # Parameter value implies no equilibrium — outside identified set
            return np.array([1.0]), np.array([-1.0])

        # Best-case: equilibrium selection that maximizes predicted probability
        # Worst-case: equilibrium selection that minimizes it
        ne_matches = [int(ne == observed) for ne in all_ne]
        moments_upper.append(max(ne_matches))
        moments_lower.append(min(ne_matches))

    return np.array(moments_upper), np.array(moments_lower)
```

---

## Diagnostics and Validation

### Equilibrium Validity Checklist

- [ ] **Existence verified:** Does a Nash equilibrium exist for the estimated parameters and every market in the data? If not, the model is misspecified.
- [ ] **Uniqueness or selection rule stated:** If the game has multiple equilibria at the estimated parameters, state explicitly which selection rule is used — and justify it.
- [ ] **Best-response mapping verified:** For each player, check that the estimated strategy is actually a best response given opponents' strategies. Compute deviations and verify they are unprofitable.
- [ ] **Off-equilibrium behavior consistent:** If the model implies specific off-equilibrium beliefs (e.g., in signaling games), check that these beliefs satisfy the maintained refinement (sequential rationality, D1 criterion).
- [ ] **Conduct restrictions testable:** If imposing conduct restrictions (Bertrand, Cournot, collusion), carry out a formal test of the restriction — do not just assume the conduct assumption is correct.
- [ ] **Equilibrium stability:** In dynamic games, verify that the MPE is locally stable — small perturbations in the state converge back to the equilibrium path.

```python
def verify_nash_equilibrium(strategies, payoff_fns, tol=1e-6):
    """
    Verify that a strategy profile is a Nash equilibrium.
    Returns True if Nash, and a list of profitable deviations if not.
    """
    n_players = len(strategies)
    profitable_deviations = []

    for i in range(n_players):
        eq_payoff = payoff_fns[i](strategies)

        # Check all deviations for player i
        for dev_strategy in get_all_strategies(i):
            dev_profile = strategies.copy()
            dev_profile[i] = dev_strategy
            dev_payoff = payoff_fns[i](dev_profile)

            if dev_payoff > eq_payoff + tol:
                profitable_deviations.append({
                    'player': i,
                    'deviation': dev_strategy,
                    'gain': dev_payoff - eq_payoff
                })

    is_nash = len(profitable_deviations) == 0
    return is_nash, profitable_deviations
```

### Model Fit for Game-Theoretic Models

```python
def game_model_fit_stats(observed_outcomes, predicted_probs, model_name=""):
    """
    Goodness-of-fit statistics for discrete games.
    """
    import pandas as pd
    from scipy.stats import chi2

    n = len(observed_outcomes)
    unique_outcomes = np.unique(observed_outcomes, axis=0)

    # Predicted vs. observed frequency for each outcome
    rows = []
    for outcome in unique_outcomes:
        mask = np.all(observed_outcomes == outcome, axis=1)
        obs_freq = mask.mean()

        # Average predicted probability for this outcome
        pred_freq = predicted_probs[mask].mean() if mask.sum() > 0 else 0.0

        rows.append({
            'outcome': str(tuple(outcome)),
            'observed_freq': obs_freq,
            'predicted_freq': pred_freq,
            'n_obs': mask.sum()
        })

    fit_table = pd.DataFrame(rows)
    fit_table['residual'] = fit_table['observed_freq'] - fit_table['predicted_freq']

    # Pearson chi-squared test
    chi2_stat = n * ((fit_table['residual'] ** 2) / fit_table['predicted_freq'].clip(1e-10)).sum()
    df = len(unique_outcomes) - 1
    p_value = 1 - chi2.cdf(chi2_stat, df)

    print(f"\n{model_name} Model Fit:")
    print(fit_table.to_string(index=False))
    print(f"\nPearson chi-squared: {chi2_stat:.3f} (df={df}, p={p_value:.4f})")

    return fit_table, chi2_stat, p_value
```

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
