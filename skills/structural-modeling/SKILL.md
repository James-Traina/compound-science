---
name: structural-modeling
description: Guide for implementing structural econometric models. Use when the user is building, estimating, or debugging structural models — including BLP demand estimation, dynamic discrete choice, auction models, or any workflow involving moment conditions, nested fixed-point algorithms, or MPEC formulations. Triggers on "structural model", "moment conditions", "NFXP", "MPEC", "BLP", "random coefficients", "dynamic discrete choice", "CCP", "Rust model", "auction estimation", "GMM objective", "inner loop", "contraction mapping", or convergence/starting value problems in optimization-based estimation.
---

# Structural Modeling

Reference for implementing structural econometric models: from economic model to moment conditions to estimated parameters. Covers the full workflow of taking a theoretical model, deriving its empirical content, and recovering structural parameters from data.

## When to Use This Skill

Use when the user is:
- Specifying a structural model and deriving moment conditions
- Implementing NFXP or MPEC estimation routines
- Working with BLP-style demand systems (random coefficients logit)
- Building dynamic discrete choice models (Rust, Hotz-Miller CCP)
- Estimating auction models (first-price, ascending, common value)
- Debugging convergence failures in structural estimation
- Choosing between estimation approaches for a given model

Skip when:
- The task is reduced-form causal inference (use `causal-inference` skill)
- The task is pure simulation design (use `monte-carlo-designer` agent)
- The user just needs standard regression (statsmodels/linearmodels suffice)

## The Structural Estimation Workflow

Every structural estimation follows the same logical arc:

```
Economic Model → Equilibrium/Decision Rule → Observable Implications
    → Moment Conditions → Estimator → Optimization → Inference
```

### Step 1: Model Specification

Define primitives clearly before writing any code:
- **Agents**: Who makes decisions? What are their choice sets?
- **Information**: What do agents observe? What is private?
- **Timing**: Static or dynamic? If dynamic, finite or infinite horizon?
- **Payoffs**: Functional form of utility/profit. Which parameters are structural?
- **Equilibrium concept**: Nash, Bayesian Nash, Markov perfect, competitive?

Document these in a model specification file before estimation code:

```python
# model_spec.py — Document structural primitives
"""
Model: Single-agent optimal stopping (Rust 1987 bus engine replacement)

State:    x_t ∈ {0, 1, ..., X_max}  (mileage bin)
Action:   a_t ∈ {0, 1}  (0 = maintain, 1 = replace)
Flow payoff:
    u(x, 0; θ) = -θ_1 * x - θ_2 * x²     (maintenance cost)
    u(x, 1; θ) = -RC                        (replacement cost)
Discount:  β = 0.9999 (fixed)
Shocks:    ε ~ Type 1 Extreme Value (logit errors)
Transition: x' | (x, a=0) ~ discretized normal increment
            x' | (x, a=1) ~ same distribution from x=0
"""
```

### Step 2: Derive Moment Conditions

The model's empirical content comes from restrictions it places on observables.

**Common moment condition sources:**

| Source | Example | Typical estimator |
|--------|---------|-------------------|
| Optimality conditions (FOCs) | Euler equations, Bellman optimality | GMM |
| Equilibrium restrictions | Market clearing, Nash conditions | GMM / ML |
| Distributional assumptions | Choice probabilities under logit errors | MLE / simulated MLE |
| Exclusion restrictions | Cost shifters excluded from demand | IV-GMM |
| Conditional moment restrictions | E[ε \| Z] = 0 | GMM with instrument functions |

**Key question:** Are moment conditions over-identified, just-identified, or under-identified?
- Just-identified → use method of moments (closed-form or simple root-finding)
- Over-identified → use GMM with optimal weighting matrix
- Under-identified → model is not identified; revisit assumptions

### Step 3: Choose Estimation Approach

Two dominant paradigms for models with latent quantities (unobserved heterogeneity, future expectations, equilibrium objects):

#### NFXP (Nested Fixed-Point)

Solve the model in an **inner loop** for each parameter guess, evaluate likelihood/moments in an **outer loop**.

```
Outer loop: minimize Q(θ) over θ
    Inner loop: solve V = Γ(V; θ) by contraction mapping
    Compute choice probabilities P(a | x; θ, V(θ))
    Evaluate log-likelihood or GMM objective
```

**Advantages:** Conceptually simple, well-understood convergence properties.
**Disadvantages:** Inner loop must fully converge at every outer iteration — computationally expensive, and tight inner tolerance is required to avoid optimization artifacts (see Su & Judd 2012).

```python
import numpy as np
from scipy.optimize import minimize

def solve_inner(theta, beta, trans_mat, n_states):
    """Solve Bellman equation by contraction mapping."""
    RC, theta1 = theta
    flow_maintain = -theta1 * np.arange(n_states)
    EV = np.zeros(n_states)

    for _ in range(2000):  # generous iteration limit
        # Choice-specific value functions (logit shocks)
        cv_maintain = flow_maintain + beta * trans_mat @ EV
        cv_replace = -RC + beta * trans_mat[0, :] @ EV

        # Log-sum formula for expected value with Type 1 EV errors
        EV_new = np.log(np.exp(cv_maintain) + np.exp(cv_replace))

        if np.max(np.abs(EV_new - EV)) < 1e-12:  # tight tolerance
            break
        EV = EV_new

    return EV

def nfxp_objective(theta, data, beta, trans_mat, n_states):
    """Negative log-likelihood for NFXP."""
    EV = solve_inner(theta, beta, trans_mat, n_states)
    RC, theta1 = theta

    flow_maintain = -theta1 * np.arange(n_states)
    cv_maintain = flow_maintain + beta * trans_mat @ EV
    cv_replace = -RC + beta * trans_mat[0, :] @ EV

    # Choice probabilities (logit)
    prob_replace = 1 / (1 + np.exp(cv_maintain - cv_replace))

    # Log-likelihood
    ll = np.sum(
        data['replace'] * np.log(prob_replace[data['state']])
        + (1 - data['replace']) * np.log(1 - prob_replace[data['state']])
    )
    return -ll

result = minimize(nfxp_objective, x0=[5.0, 0.01],
                  args=(data, beta, trans_mat, n_states),
                  method='Nelder-Mead',
                  options={'xatol': 1e-8, 'fatol': 1e-10})
```

#### MPEC (Mathematical Programming with Equilibrium Constraints)

Reformulate as a single constrained optimization: estimate parameters and equilibrium objects simultaneously.

```
minimize   Q(θ, V) over (θ, V)
subject to V = Γ(V; θ)    (equilibrium constraints)
```

**Advantages:** No inner loop — optimizer handles everything. Can be faster for large state spaces. Exploits sparsity in constraints.
**Disadvantages:** Requires a constrained optimizer (IPOPT, KNITRO). Larger decision variable space. Harder to debug when constraints are violated.

```python
# MPEC typically requires a nonlinear programming solver
# cyipopt is the Python interface to IPOPT
import cyipopt

class RustMPEC:
    """MPEC formulation of Rust (1987) bus engine model."""

    def __init__(self, data, beta, trans_mat, n_states):
        self.data = data
        self.beta = beta
        self.trans = trans_mat
        self.n_states = n_states
        # Decision variables: [RC, theta1, EV_0, ..., EV_{n-1}]
        self.n_vars = 2 + n_states

    def objective(self, x):
        """Negative log-likelihood."""
        RC, theta1 = x[0], x[1]
        EV = x[2:]

        flow_maintain = -theta1 * np.arange(self.n_states)
        cv_m = flow_maintain + self.beta * self.trans @ EV
        cv_r = -RC + self.beta * self.trans[0, :] @ EV

        prob_r = 1 / (1 + np.exp(cv_m - cv_r))
        ll = np.sum(
            self.data['replace'] * np.log(prob_r[self.data['state']] + 1e-15)
            + (1 - self.data['replace']) * np.log(1 - prob_r[self.data['state']] + 1e-15)
        )
        return -ll

    def constraints(self, x):
        """Bellman equation constraints: EV = log-sum-exp(CV)."""
        RC, theta1 = x[0], x[1]
        EV = x[2:]

        flow_maintain = -theta1 * np.arange(self.n_states)
        cv_m = flow_maintain + self.beta * self.trans @ EV
        cv_r = -RC + self.beta * self.trans[0, :] @ EV

        EV_implied = np.log(np.exp(cv_m) + np.exp(cv_r))
        return EV - EV_implied  # should equal zero
```

#### When to Choose Which

| Factor | Favors NFXP | Favors MPEC |
|--------|-------------|-------------|
| State space size | Small (< 500 states) | Large (> 1000 states) |
| Inner loop convergence | Fast (contraction rate < 0.9) | Slow or fragile |
| Available solvers | scipy.optimize sufficient | IPOPT/KNITRO available |
| Debugging | Easier to isolate inner vs outer issues | Harder to diagnose |
| Extensions | Standard | Better for models with inequality constraints |

## BLP Demand Estimation

BLP (Berry, Levinsohn, Pakes 1995) is the workhorse for differentiated products demand. Use PyBLP whenever possible — it handles the difficult numerical details correctly.

### Setup

```python
import pyblp

# Define the problem
problem = pyblp.Problem(
    product_formulations=(
        pyblp.Formulation('1 + prices + x1 + x2'),           # linear (β)
        pyblp.Formulation('1 + prices + x1'),                  # random coefficients (Σ)
        pyblp.Formulation('0 + demand_instruments0 + demand_instruments1')  # supply
    ),
    product_data=product_data,  # DataFrame with market_ids, shares, prices, etc.
    agent_formulation=pyblp.Formulation('0 + income'),         # demographics
    agent_data=agent_data
)
```

### Estimation

```python
# Starting values matter — use multiple starting points
results_best = None
for _ in range(10):
    sigma_init = np.random.uniform(0.1, 2.0, size=(3, 3))
    sigma_init = np.tril(sigma_init)  # lower triangular for Cholesky

    results = problem.solve(
        sigma=sigma_init,
        optimization=pyblp.Optimization('l-bfgs-b', {'gtol': 1e-8}),
        iteration=pyblp.Iteration('squarem', {'atol': 1e-14}),  # accelerated contraction
        method='1s'  # start with 1-step GMM, then switch to 2-step
    )

    if results_best is None or results.objective < results_best.objective:
        results_best = results

# Two-step GMM with optimal weighting matrix
results_2s = problem.solve(
    sigma=results_best.sigma,
    optimization=pyblp.Optimization('l-bfgs-b', {'gtol': 1e-8}),
    iteration=pyblp.Iteration('squarem', {'atol': 1e-14}),
    method='2s',
    W=results_best.updated_W
)
```

### BLP Diagnostics Checklist

- [ ] **Instrument validity**: First-stage F-statistics for price (> 10). BLP instruments (sums of rival characteristics) can be weak — consider optimal instruments via `results.compute_optimal_instruments()`
- [ ] **Contraction convergence**: Check `results.contraction_evaluations` — should converge in inner loop at every evaluation. If not, tighten `atol` or switch iteration method
- [ ] **Multiple starting values**: BLP objective is non-convex. Run from 10+ random starts
- [ ] **Own-price elasticities**: Must be negative. Compute via `results.compute_elasticities('prices')`. Cross-price elasticities should be positive for substitutes
- [ ] **Diversion ratios**: Check `results.compute_diversion_ratios()` for economic reasonableness
- [ ] **Marginal costs**: After supply-side estimation, `results.compute_costs()` should be positive
- [ ] **Numerical issues**: Check `results.fp_converged.all()` — all markets must converge

## Dynamic Discrete Choice Models

### Rust (1987) — Full Solution

The bus engine replacement model is the canonical example. See NFXP and MPEC code above for implementation.

**Key implementation decisions:**
- **State space discretization**: Mileage bins of 5,000 miles (Rust uses ~90 bins)
- **Discount factor**: Typically fixed (not estimated) — β = 0.9999
- **Transition probabilities**: Estimate separately from choice data (first stage)
- **Error distribution**: Type 1 Extreme Value gives closed-form choice probabilities

### Hotz-Miller CCP Estimation

Conditional choice probabilities (CCPs) avoid solving the full dynamic program. Two-step approach:

```python
def hotz_miller_ccp(data, n_states, n_actions, beta, trans_mat):
    """
    Hotz-Miller (1993) CCP estimator.
    Step 1: Estimate CCPs nonparametrically.
    Step 2: Use CCPs to form pseudo-value functions, then run simple regression.
    """
    # Step 1: Estimate CCPs from frequency of actions in each state
    ccps = np.zeros((n_states, n_actions))
    for s in range(n_states):
        mask = data['state'] == s
        if mask.sum() > 0:
            for a in range(n_actions):
                ccps[s, a] = (data['action'][mask] == a).mean()

    # Smooth to avoid log(0) — add small probability mass
    ccps = np.clip(ccps, 0.001, 0.999)
    ccps = ccps / ccps.sum(axis=1, keepdims=True)

    # Step 2: Construct pseudo-value functions
    # With logit errors: E[ε | a chosen] = euler_constant - log(P(a))
    euler = 0.5772156649

    # Forward simulation of CCPs to get expected future utilities
    # (simplified — full version uses matrix inversion or forward simulation)
    e_eps = euler - np.log(ccps[:, 0])  # expected shock conditional on maintain

    # Mapping matrix: expected transitions under estimated policy
    F = np.diag(ccps[:, 0]) @ trans_mat + np.diag(ccps[:, 1]) @ trans_mat[[0], :]

    # Pseudo-value: (I - beta * F)^{-1} * (flow_payoff + correction)
    # This gives a linear-in-parameters system for the structural parameters

    return ccps, F
```

**When to use CCP vs full solution:**

| Feature | Full Solution (NFXP/MPEC) | CCP (Hotz-Miller) |
|---------|---------------------------|---------------------|
| Computational cost | High (solve DP at each θ) | Low (no DP solving) |
| Efficiency | Efficient (MLE) | Less efficient (2-step) |
| Finite dependence | Not needed | Exploits it when available |
| Unobserved heterogeneity | Harder to add | Harder to add |
| Counterfactuals | Natural (have full model) | Need to resolve for new policies |

### Finite Dependence

Some dynamic models have the property that the difference in future utility streams between any two choices depends on the current state for only a finite number of periods. This simplifies CCP estimation by allowing value function differences to be expressed using short forward simulations rather than matrix inversions.

## Auction Models

### First-Price Sealed-Bid

The standard approach: Guerre, Perrigne, Vuong (2000) — nonparametric estimation of the latent value distribution from observed bids.

```python
from scipy.interpolate import UnivariateSpline
from scipy.stats import gaussian_kde

def gpv_estimate(bids, n_bidders):
    """
    GPV (2000) nonparametric estimation for symmetric IPV first-price auctions.

    Key insight: In equilibrium, bidder with value v bids:
        b(v) = v - G(b)/(n-1)*g(b)
    where G is the bid distribution and g its density.

    Inversion: v(b) = b + G(b)/((n-1)*g(b))
    """
    n = n_bidders

    # Step 1: Estimate bid distribution and density
    kde = gaussian_kde(bids, bw_method='silverman')

    # Evaluate on a grid
    b_grid = np.linspace(bids.min(), bids.max(), 200)
    g_hat = kde(b_grid)                                    # density
    G_hat = np.array([kde.integrate_box_1d(-np.inf, b) for b in b_grid])  # CDF

    # Step 2: Invert to recover pseudo-values
    v_hat = b_grid + G_hat / ((n - 1) * g_hat)

    # Step 3: Estimate value distribution from pseudo-values
    # (can use kernel density on v_hat, or fit parametric family)

    return b_grid, v_hat, g_hat, G_hat
```

**Diagnostics:**
- Pseudo-values must exceed bids (bidders shade down in first-price auctions)
- Value distribution should have reasonable support (no negative values for cost auctions)
- Boundary bias: kernel density estimation is biased at support boundaries — use boundary-corrected kernels or trimming

### Ascending (English) Auctions

In an independent private values ascending auction, the dominant strategy is to bid up to your value. Observed transaction prices equal the second-highest value. Estimation is simpler:

```python
# Transaction prices = second-order statistics of value distribution
# Use order statistics theory to recover the parent distribution
from scipy.stats import rv_continuous

# With N bidders, price ~ F_{(N-1:N)} distribution
# f_{(k:n)}(x) = n! / ((k-1)!(n-k)!) * F(x)^{k-1} * (1-F(x))^{n-k} * f(x)
```

### Common Value Auctions

Require accounting for the winner's curse. The Milgrom-Weber affiliated values model nests both IPV and pure common value. Estimation is more complex — typically requires parametric assumptions or the structural approach of Li, Perrigne, Vuong (2002).

## Convergence Diagnostics

Convergence failures are the most common problem in structural estimation.

### Starting Values

```python
# Strategy 1: Grid search over coarse parameter space
from itertools import product

param_grid = {
    'RC': [2.0, 5.0, 10.0, 20.0],
    'theta1': [0.001, 0.01, 0.05, 0.1]
}

best_obj = np.inf
best_start = None
for RC, theta1 in product(param_grid['RC'], param_grid['theta1']):
    try:
        obj = nfxp_objective([RC, theta1], data, beta, trans_mat, n_states)
        if obj < best_obj:
            best_obj = obj
            best_start = [RC, theta1]
    except (ValueError, np.linalg.LinAlgError):
        continue

# Strategy 2: Estimate simplified model first
# e.g., static version, or version without random coefficients

# Strategy 3: Use estimates from related data/specification
```

### Diagnosing Convergence Failures

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Optimizer reports convergence but objective varies across starts | Multiple local optima | Run from 20+ random starts, use global optimizer (basin-hopping) |
| Inner loop doesn't converge | Contraction rate near 1, discount factor too high | Accelerate with SQUAREM, reduce β, check transition matrix |
| Gradient is NaN or Inf | Log of zero, overflow in exp | Work in log space, add numerical safeguards |
| Hessian is singular at solution | Flat objective, identification failure | Check rank of Jacobian of moment conditions at solution |
| Parameters hit bounds | Misspecification or poor starting values | Widen bounds, check model, try unconstrained reparameterization |
| Objective decreases but very slowly | Poorly scaled problem | Rescale parameters to similar magnitudes, use preconditioner |

### Numerical Safeguards

```python
# Always work in log space for likelihoods
def safe_log_likelihood(log_prob):
    """Numerically stable log-likelihood computation."""
    return np.sum(log_prob)  # already in log space

# Use logsumexp for softmax/logit choice probabilities
from scipy.special import logsumexp

def logit_choice_probs(utilities):
    """Numerically stable logit probabilities."""
    # utilities: (n_states, n_actions)
    log_denom = logsumexp(utilities, axis=1, keepdims=True)
    log_probs = utilities - log_denom
    return np.exp(log_probs)

# Check condition number of key matrices
def check_conditioning(matrix, name="matrix"):
    cond = np.linalg.cond(matrix)
    if cond > 1e10:
        print(f"WARNING: {name} condition number = {cond:.2e} — near singular")
    return cond
```

## Standard Errors for Structural Models

### GMM Standard Errors

```python
def gmm_standard_errors(theta_hat, moment_fn, data, W, epsilon=1e-5):
    """
    Sandwich standard errors for GMM.

    V(θ) = (G'WG)^{-1} G'W S W G (G'WG)^{-1} / N

    G = Jacobian of moment conditions (∂m/∂θ)
    S = Variance of moment conditions
    W = Weighting matrix
    """
    n_params = len(theta_hat)
    moments = moment_fn(theta_hat, data)  # (N, n_moments)
    N = moments.shape[0]

    # Numerical Jacobian
    G = np.zeros((moments.shape[1], n_params))
    for j in range(n_params):
        theta_plus = theta_hat.copy()
        theta_minus = theta_hat.copy()
        theta_plus[j] += epsilon
        theta_minus[j] -= epsilon
        G[:, j] = (moment_fn(theta_plus, data).mean(axis=0)
                    - moment_fn(theta_minus, data).mean(axis=0)) / (2 * epsilon)

    # Long-run variance of moments
    S = moments.T @ moments / N

    # Sandwich formula
    GWG_inv = np.linalg.inv(G.T @ W @ G)
    V = GWG_inv @ (G.T @ W @ S @ W @ G) @ GWG_inv / N

    se = np.sqrt(np.diag(V))
    return se
```

### Bootstrap for Complex Models

When analytic standard errors are difficult (e.g., multi-step estimators, simulation-based estimators):

```python
def parametric_bootstrap(estimate_fn, data, n_bootstrap=200, seed=42):
    """
    Parametric bootstrap: resample from estimated model.
    For structural models, often better than nonparametric bootstrap
    because it preserves the data structure (markets, panels).
    """
    rng = np.random.default_rng(seed)
    theta_hat = estimate_fn(data)

    boot_estimates = []
    for b in range(n_bootstrap):
        # Resample: cluster at appropriate level (market, individual, etc.)
        idx = rng.choice(len(data), size=len(data), replace=True)
        data_b = data.iloc[idx].reset_index(drop=True)

        try:
            theta_b = estimate_fn(data_b)
            boot_estimates.append(theta_b)
        except Exception:
            continue  # skip failed replications but log the count

    boot_estimates = np.array(boot_estimates)
    se = boot_estimates.std(axis=0)

    # Report: how many bootstrap replications converged
    convergence_rate = len(boot_estimates) / n_bootstrap
    if convergence_rate < 0.8:
        print(f"WARNING: Only {convergence_rate:.0%} of bootstrap samples converged")

    return se, boot_estimates
```

## Common Anti-Patterns

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| Estimating β (discount factor) and payoff parameters jointly | Notoriously poorly identified; flat objective | Fix β at reasonable value (0.95, 0.99) or calibrate from external data |
| Loose inner loop tolerance (1e-6) | Optimization sees noise as signal; spurious convergence | Use 1e-12 or tighter for inner loop; see Su & Judd (2012) |
| Single starting value | Structural objectives are non-convex | Use 10+ random starts plus grid search |
| Ignoring simulation error in simulated MLE/MSM | Biased standard errors | Use enough simulation draws (R >> N), or bias-correct |
| Computing numerical gradients with default step size | Inaccurate for poorly scaled problems | Use central differences with problem-specific step sizes, or analytic gradients (JAX autodiff) |
| Hard-coding state space discretization | Results may be sensitive to grid coarseness | Test sensitivity to grid refinement; use adaptive methods |

## JAX for Structural Models

JAX provides automatic differentiation and JIT compilation — valuable for structural models where analytic gradients are tedious.

```python
import jax
import jax.numpy as jnp
from jax import grad, jit

@jit
def bellman_operator(EV, theta, beta, trans_mat):
    """JAX-compatible Bellman operator with autodiff support."""
    RC, theta1 = theta[0], theta[1]
    n_states = EV.shape[0]

    flow_maintain = -theta1 * jnp.arange(n_states, dtype=float)
    cv_maintain = flow_maintain + beta * trans_mat @ EV
    cv_replace = -RC + beta * trans_mat[0, :] @ EV

    # logsumexp for numerical stability
    EV_new = jnp.logaddexp(cv_maintain, cv_replace)
    return EV_new

# Automatic gradient of the objective w.r.t. parameters
# — no hand-derived gradients needed
grad_objective = jit(grad(nfxp_objective_jax, argnums=0))
```

**When to use JAX:**
- Models with many parameters (gradient computation is expensive)
- Need second derivatives (Hessian) for standard errors or Newton steps
- Inner loop can be expressed as a differentiable fixed-point iteration
- Want GPU acceleration for large state spaces

**When NOT to use JAX:**
- Simple models where scipy.optimize works fine
- Models with non-differentiable components (discrete jumps, if-else logic)
- PyBLP already handles the specific model class
