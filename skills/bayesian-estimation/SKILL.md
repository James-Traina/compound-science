---
name: bayesian-estimation
description: Guide for Bayesian estimation and inference in quantitative social science. Use when the user is specifying priors, running MCMC, diagnosing chain convergence, or reporting posterior summaries — including hierarchical models, Bayesian structural models, and small-sample settings where priors regularize. Triggers on "Bayesian estimation", "Bayesian inference", "MCMC", "Markov chain Monte Carlo", "Stan", "PyMC", "NumPyro", "prior", "posterior", "credible interval", "Bayesian structural", "Bayesian BLP", "Bayesian DSGE", "hierarchical model", "random effects Bayesian", "posterior predictive check", "Bayes factor", "prior predictive check", "NUTS", "HMC", "Hamiltonian Monte Carlo", "R-hat", "rhat", "effective sample size", "ESS", "Bayesian calibration", "posterior distribution", "prior elicitation", "weakly informative prior", "brms", "rstanarm", "cmdstanpy", "pymc", "arviz".
---

# Bayesian Estimation

Reference for Bayesian estimation in quantitative social science: from prior elicitation to MCMC implementation to posterior reporting. Covers the full workflow of specifying a Bayesian model, running inference, diagnosing convergence, and communicating results — with applications to structural models, hierarchical designs, and small-sample settings.

## When to Use This Skill

Use when the user is:
- Specifying priors and setting up a Bayesian model in Stan, PyMC, NumPyro, brms, or rstanarm
- Running MCMC and diagnosing R-hat, ESS, divergences, or trace plots
- Implementing hierarchical (multilevel) models with partial pooling
- Adding Bayesian inference to a structural model (BLP, dynamic discrete choice, DSGE)
- Reporting credible intervals, posterior predictive checks, or model comparison statistics
- Eliciting priors from calibration targets or literature benchmarks
- Debugging sampling pathologies: divergences, low acceptance rates, poor mixing

Skip when:
- The model is large-N and well-identified (frequentist MLE/GMM is more efficient and faster)
- The task is pure structural estimation without Bayesian components (use `structural-modeling` skill)
- The user needs classical causal inference (use `causal-inference` skill)

## When to Use Bayesian Estimation

### Advantages

**Small samples**: Priors act as regularization. With N < 100 observations and several parameters, MLE can overfit or fail to converge. A weakly informative prior is often equivalent to several additional observations of prior knowledge.

**Hierarchical structure**: When data have natural groupings (markets, countries, firms), Bayesian partial pooling is more efficient than either pooling all groups (ignores variation) or fitting each group separately (ignores shared structure). Random effects Bayesian models borrow strength across groups.

**Uncertainty propagation**: The posterior is a full distribution. Downstream quantities (elasticities, welfare changes, counterfactuals) inherit full uncertainty without a delta method approximation.

**Natural model comparison**: Posterior predictive checks and LOO-CV are cleaner than frequentist test-based model selection, especially for non-nested models.

**Constrained parameters**: Parameters with domain restrictions (discount factors in [0,1], positive variances, simplex probability vectors) are handled naturally via transformed parameter blocks and appropriate priors, without projection or re-parametrization hacks.

### When to Prefer Frequentist

- Large N (N > 10,000): Priors become irrelevant as the likelihood dominates; MLE or GMM is faster and results are nearly identical
- Simple models where MLE is efficient (OLS, logit, Poisson): No benefit from Bayesian approach
- Publication venues requiring classical standard errors and p-values (some applied micro journals)
- Models requiring solving equilibrium constraints (NFXP/MPEC) at each draw — computationally prohibitive

### Comparison Table

| Scenario | Bayesian | Frequentist |
|----------|----------|-------------|
| N = 50, 10 parameters | Preferred — priors regularize | MLE may not converge |
| N = 100,000, 5 parameters | Either works; MLE faster | Preferred — priors irrelevant |
| Hierarchical / multi-group | Preferred — partial pooling | Mixed effects via ML is comparable |
| Uncertainty in counterfactuals | Preferred — natural propagation | Delta method or bootstrap |
| Structural model, large state space | Difficult — MCMC over full model | Preferred — NFXP/MPEC more tractable |
| Non-standard likelihood | Either — depends on differentiability | GMM often more flexible |
| Model comparison, non-nested | LOO-CV / WAIC | AIC/BIC, Vuong test |
| Publication: applied micro top-5 | Use sparingly; justify carefully | Standard expectation |

---

## Prior Elicitation

The core task: encode genuine prior knowledge without overwhelming the likelihood.

### Weakly Informative Defaults

These encode vague knowledge — parameters are unlikely to be astronomically large — without strongly influencing the posterior when data are informative. These follow Gelman et al. (2008, 2017) recommendations:

| Parameter type | Recommended prior | Rationale |
|----------------|-------------------|-----------|
| Location / intercept (raw scale) | Normal(0, 10) | Very diffuse; most applications won't have effects > 10 SDs |
| Location (standardized predictors) | Normal(0, 2.5) | Rules out extreme effects; standard for logistic regression |
| Scale / variance | HalfNormal(1) or Exponential(1) | Positive, concentrates near zero but with wide right tail |
| Log-scale parameters (elasticities) | Normal(0, 1) on log scale | Implies elasticity plausibly between 0.14 and 7.4 |
| Correlation matrices | LKJ(2) | Shrinks toward identity; LKJ(1) is uniform on correlations |
| Simplex (probability vectors) | Dirichlet(1, ..., 1) | Uniform over simplex |

### Informative Priors from Calibration Targets

When the literature provides benchmark values, use them as prior means with SD reflecting plausible variation:

1. Use the `benchmark-researcher` agent to find reference parameter values
2. Set prior mean to the benchmark: e.g., price elasticity of -1.2 from literature
3. Set prior SD to cover the plausible range: if literature range is [-0.5, -2.0], use Normal(-1.2, 0.4) so that the range is roughly within 2 SDs
4. Verify with a prior predictive check (see below) that implied observables are plausible

```python
# Example: Informative prior on price elasticity from literature
# Literature: price elasticity typically -0.5 to -2.0 (mean around -1.2)
# SD = (2.0 - 0.5) / 4 ≈ 0.4 (so ~95% of prior mass covers the range)

import pymc as pm
import numpy as np

with pm.Model() as demand_model:
    # Informative prior from literature
    alpha = pm.Normal("alpha", mu=-1.2, sigma=0.4)  # price elasticity (log scale)

    # Weakly informative for income elasticity
    beta_inc = pm.Normal("beta_inc", mu=0, sigma=1.0)

    # Positive scale parameter
    sigma = pm.HalfNormal("sigma", sigma=1.0)
```

### Prior Predictive Checks — Do This Before Estimation

Sample from the prior distribution, generate implied data, and verify the generated data is scientifically plausible. If the prior implies impossible values (negative prices, market shares > 1, demand curves that slope up), tighten the prior.

```python
import pymc as pm
import numpy as np
import matplotlib.pyplot as plt

with pm.Model() as model:
    # Priors
    beta = pm.Normal("beta", mu=0, sigma=2)
    sigma = pm.HalfNormal("sigma", sigma=1)

    # Likelihood (observed data not yet attached for prior predictive)
    mu = beta * X_obs
    y_obs = pm.Normal("y_obs", mu=mu, sigma=sigma, observed=Y_obs)

# Draw from the prior (ignore observed data)
with model:
    prior_predictive = pm.sample_prior_predictive(samples=500, random_seed=42)

# Inspect
prior_y = prior_predictive.prior_predictive["y_obs"].values.squeeze()
print(f"Prior predictive range: [{prior_y.min():.2f}, {prior_y.max():.2f}]")
print(f"Actual data range:      [{Y_obs.min():.2f}, {Y_obs.max():.2f}]")

# Verdict: if prior predictive range is 1000x wider than data, prior is too diffuse
plt.hist(prior_y.flatten(), bins=50, alpha=0.5, label="Prior predictive")
plt.hist(Y_obs, bins=30, alpha=0.5, label="Observed data")
plt.legend()
```

**Decision rules for prior predictive checks:**
- Prior predictive implies impossible values (negative income, market share > 1) → constrain the prior or use a transformed parameter
- Prior predictive range is > 100x the observed data range → prior too diffuse; tighten it
- Prior predictive range is narrower than observed variation → prior too tight; loosen it
- All looks plausible → proceed to posterior estimation

### Prior Sensitivity Analysis

After estimation, verify that results are not driven by prior choice:

```python
import pymc as pm
import arviz as az

def fit_model(prior_sigma):
    with pm.Model() as m:
        beta = pm.Normal("beta", mu=0, sigma=prior_sigma)
        sigma = pm.HalfNormal("sigma", sigma=1)
        mu = beta * X_obs
        y_obs = pm.Normal("y_obs", mu=mu, sigma=sigma, observed=Y_obs)
        trace = pm.sample(2000, tune=1000, chains=4, random_seed=42,
                          return_inferencedata=True, progressbar=False)
    return trace

# Run with baseline and perturbed priors
trace_base = fit_model(prior_sigma=2.0)
trace_tight = fit_model(prior_sigma=1.0)   # 0.5x
trace_loose = fit_model(prior_sigma=4.0)   # 2x

# Compare posterior means
for label, t in [("base", trace_base), ("tight", trace_tight), ("loose", trace_loose)]:
    summary = az.summary(t, var_names=["beta"])
    print(f"{label}: mean={summary['mean'].values[0]:.3f}, "
          f"sd={summary['sd'].values[0]:.3f}")

# If posterior mean shifts by more than 0.5 SD when prior changes 2x,
# the prior is informative — report sensitivity results.
```

---

## MCMC Algorithms

### Hamiltonian Monte Carlo (HMC) and NUTS

HMC uses gradient information (the log-posterior gradient) to make large, directed proposals that avoid the random walk behavior of simpler samplers. NUTS (No-U-Turn Sampler) automatically tunes HMC step size and trajectory length, making it the default for Stan and NumPyro.

**When to use:** Continuous, differentiable posteriors — the vast majority of structural and reduced-form models.

**Requirements:** The log-posterior must be differentiable with respect to all parameters. Discrete parameters are not supported directly; they require marginalization or approximation.

### Random Walk Metropolis-Hastings

Simpler but less efficient for high-dimensional posteriors. Proposal is a random perturbation of the current state; no gradient information is used. Acceptance rate should target 20–40%.

**When to use:** Non-differentiable posteriors, custom likelihood functions that cannot be auto-differentiated, models with integer-valued parameters.

### Gibbs Sampling

Efficient when full conditional distributions are available in closed form (conjugate priors). Each parameter is updated conditional on all others.

**When to use:** Bayesian linear regression with conjugate normal-inverse-gamma priors, Dirichlet-Multinomial models, latent variable models with data augmentation (probit via Albert-Chib).

### Variational Inference (ADVI)

Approximates the posterior with a simpler parametric family (usually a mean-field Gaussian) by minimizing KL divergence. Fast but approximate.

**When to use:** Very large datasets (N > 100,000) where MCMC is too slow, or during model development for fast iteration.

**Warning:** Variational inference typically underestimates posterior variance, especially for correlated parameters. Use for exploration and model building, not final reported results. Always verify with a small MCMC run on a subset of the data.

---

## Implementation by Framework

### Stan (via cmdstanpy in Python)

Stan compiles to efficient C++ and is the gold standard for serious Bayesian structural work.

```stan
// bayesian_iv.stan — Bayesian instrumental variables
data {
  int<lower=0> N;
  vector[N] Y;   // outcome
  vector[N] D;   // endogenous regressor
  vector[N] Z;   // instrument
}
parameters {
  real alpha;            // intercept
  real beta;             // causal effect (structural parameter)
  real gamma;            // first stage: effect of Z on D
  real<lower=0> sigma_y; // outcome noise
  real<lower=0> sigma_d; // first stage noise
}
model {
  // Weakly informative priors
  alpha ~ normal(0, 10);
  beta  ~ normal(0, 2);
  gamma ~ normal(0, 2);
  sigma_y ~ exponential(1);
  sigma_d ~ exponential(1);

  // First stage: D = gamma * Z + error
  D ~ normal(gamma * Z, sigma_d);

  // Structural equation: Y = alpha + beta * D + error
  Y ~ normal(alpha + beta * D, sigma_y);
}
generated quantities {
  // Posterior predictive draws for model checking
  vector[N] Y_rep;
  for (n in 1:N)
    Y_rep[n] = normal_rng(alpha + beta * D[n], sigma_y);
}
```

```python
import cmdstanpy
import numpy as np
import arviz as az

# Compile model (once)
model = cmdstanpy.CmdStanModel(stan_file="bayesian_iv.stan")

# Fit
data_dict = {"N": len(Y), "Y": Y.tolist(), "D": D.tolist(), "Z": Z.tolist()}

fit = model.sample(
    data=data_dict,
    chains=4,
    iter_warmup=1000,
    iter_sampling=2000,
    seed=42,
    show_progress=True
)

# Convert to ArviZ InferenceData for diagnostics
idata = az.from_cmdstanpy(fit)

# Check convergence
print(az.summary(idata, var_names=["alpha", "beta", "gamma"]))
```

**Key Stan code patterns:**
- `transformed parameters` block: compute derived quantities (e.g., elasticities from raw parameters) — these are sampled and stored
- `generated quantities` block: posterior predictive draws, log-likelihood for LOO-CV — computed after sampling, not part of the geometry
- `<lower=0>` / `<upper=1>` constraints: enforce parameter support without manual transformation

### PyMC

PyMC uses Aesara (now PyTensor) as its backend, with NUTS as the default sampler. Well-suited for Python-native workflows and hierarchical models.

```python
import pymc as pm
import numpy as np
import arviz as az

with pm.Model() as hierarchical_demand:
    # Hyperpriors (population-level)
    mu_beta = pm.Normal("mu_beta", mu=-1.0, sigma=0.5)   # population mean elasticity
    sigma_beta = pm.HalfNormal("sigma_beta", sigma=0.3)   # cross-market dispersion

    # Market-level elasticities (partial pooling)
    n_markets = len(market_ids)
    beta_raw = pm.Normal("beta_raw", mu=0, sigma=1, shape=n_markets)
    beta = pm.Deterministic("beta", mu_beta + sigma_beta * beta_raw)  # non-centered

    # Observation noise
    sigma = pm.HalfNormal("sigma", sigma=1.0)

    # Likelihood
    mu = beta[market_idx] * log_price
    log_quantity = pm.Normal("log_quantity", mu=mu, sigma=sigma, observed=Y_obs)

    # Sample
    trace = pm.sample(
        draws=2000,
        tune=1000,
        chains=4,
        target_accept=0.9,   # raise if divergences appear
        random_seed=42,
        return_inferencedata=True
    )

# Posterior predictive check
with hierarchical_demand:
    ppc = pm.sample_posterior_predictive(trace, random_seed=42)

az.plot_ppc(az.from_pymc(trace, posterior_predictive=ppc))
```

### NumPyro (JAX-based, for large models)

NumPyro runs on JAX, enabling JIT compilation and GPU acceleration. Best for large-scale structural models where PyMC or Stan are too slow.

```python
import numpyro
import numpyro.distributions as dist
from numpyro.infer import MCMC, NUTS
import jax.numpy as jnp
from jax import random

def hierarchical_model(market_idx, log_price, Y_obs=None, n_markets=None):
    # Hyperpriors
    mu_beta = numpyro.sample("mu_beta", dist.Normal(-1.0, 0.5))
    sigma_beta = numpyro.sample("sigma_beta", dist.HalfNormal(0.3))

    # Non-centered parametrization (critical for hierarchical models)
    with numpyro.plate("markets", n_markets):
        beta_raw = numpyro.sample("beta_raw", dist.Normal(0, 1))
    beta = numpyro.deterministic("beta", mu_beta + sigma_beta * beta_raw)

    sigma = numpyro.sample("sigma", dist.HalfNormal(1.0))

    mu = beta[market_idx] * log_price
    numpyro.sample("log_quantity", dist.Normal(mu, sigma), obs=Y_obs)

# Run NUTS
kernel = NUTS(hierarchical_model)
mcmc = MCMC(kernel, num_warmup=1000, num_samples=2000, num_chains=4)
mcmc.run(
    random.PRNGKey(42),
    market_idx=market_idx,
    log_price=log_price,
    Y_obs=Y_obs,
    n_markets=n_markets
)

# Convert to ArviZ
import arviz as az
idata = az.from_numpyro(mcmc)
```

**When to use NumPyro over PyMC:** GPU available, model has large arrays that benefit from JAX vectorization, or you want easy integration with JAX-based structural solvers.

### R: brms and rstanarm

For applied researchers working in R, brms provides a formula interface to Stan for hierarchical models, and rstanarm provides pre-compiled Stan programs for common model families.

```r
library(brms)
library(rstanarm)

# brms: Bayesian hierarchical demand model
# Random slopes by market, weakly informative priors

fit_brms <- brm(
  log_quantity ~ log_price + (log_price | market_id),
  data = demand_data,
  family = gaussian(),
  prior = c(
    prior(normal(-1, 0.5), class = b, coef = log_price),  # informative on elasticity
    prior(normal(0, 10),   class = Intercept),
    prior(exponential(1),  class = sd),                    # group-level SDs
    prior(lkj(2),          class = cor)                    # correlation between RE
  ),
  chains = 4,
  iter = 3000,
  warmup = 1000,
  seed = 42,
  cores = 4
)

# Check convergence
summary(fit_brms)          # R-hat, bulk ESS, tail ESS
plot(fit_brms)             # trace plots
pp_check(fit_brms, ndraws = 100)  # posterior predictive check

# rstanarm: simpler for standard models
fit_stan <- stan_lmer(
  log_quantity ~ log_price + (log_price | market_id),
  data = demand_data,
  prior = normal(0, 2.5, autoscale = TRUE),
  seed = 42
)
```

---

## MCMC Diagnostics

Always run these diagnostics before reporting any results. A posterior with poor convergence is not a valid posterior.

### R-hat (Potential Scale Reduction Factor)

R-hat compares variance within chains to variance between chains. Values near 1.0 indicate chains have mixed and converged to the same distribution.

**Decision rules:**
- R-hat < 1.01: Good convergence (Stan default threshold)
- 1.01 <= R-hat < 1.05: Borderline — run longer chains (double iterations)
- R-hat >= 1.05: Poor convergence — chains have not mixed; do not report results
- R-hat >= 1.1: Severe non-convergence — model geometry problem; reparametrize

```python
import arviz as az

# Full summary with R-hat and ESS for all parameters
summary = az.summary(idata, var_names=["beta", "sigma", "mu_beta"])
print(summary[["mean", "sd", "hdi_3%", "hdi_97%", "r_hat", "ess_bulk", "ess_tail"]])

# Flag parameters with R-hat > 1.01
bad_rhat = summary[summary["r_hat"] > 1.01]
if len(bad_rhat) > 0:
    print("WARNING: R-hat > 1.01 for:", bad_rhat.index.tolist())
```

### Effective Sample Size (ESS)

ESS measures the number of independent draws the MCMC chain is equivalent to. High autocorrelation between draws reduces ESS below the total number of draws.

- **Bulk ESS**: Reliability of posterior means and medians. Should be > 400.
- **Tail ESS**: Reliability of tail quantiles (5th, 95th percentile). Should be > 400; needs 1000+ for reliable 90% HDI.

**Decision rules:**
- ESS / total_draws > 0.5: Excellent mixing
- ESS / total_draws 0.1–0.5: Acceptable
- ESS / total_draws < 0.1: Poor mixing — increase iterations or reparametrize

```python
# Check ESS for all parameters
print(summary[["ess_bulk", "ess_tail"]])

total_draws = 4 * 2000  # 4 chains * 2000 draws each
summary["ess_ratio"] = summary["ess_bulk"] / total_draws
low_ess = summary[summary["ess_ratio"] < 0.1]
if len(low_ess) > 0:
    print("WARNING: Low ESS ratio for:", low_ess.index.tolist())
    print("Fix: increase iterations, reduce autocorrelation via reparametrization")
```

### Trace Plots

Visual check that chains have converged and are mixing well.

```python
# Trace plots — should look like "fuzzy caterpillars"
az.plot_trace(idata, var_names=["beta", "sigma"])

# Pathological patterns to watch for:
# - Upward/downward trends: chain not converged, needs longer warmup
# - Stuck chain: one chain at a different level, possible local mode
# - Spiky chain with low acceptance: step size too large
# - All chains superimposed but oscillating widely: high variance, need more draws
```

### Divergences — Zero Tolerance

A divergence indicates the NUTS trajectory left a region of high probability density, signaling a pathological posterior geometry. Even 1% divergence rate invalidates the posterior.

```python
# Count divergences
divergences = idata.sample_stats["diverging"].values.sum()
total_draws = idata.sample_stats["diverging"].values.size
print(f"Divergences: {divergences} / {total_draws} ({divergences/total_draws:.1%})")

if divergences > 0:
    print("ACTION REQUIRED: Fix divergences before reporting results.")
    print("See reparametrization section below.")

# Visualize where divergences occur in parameter space
az.plot_pair(idata, var_names=["beta", "sigma"], divergences=True)
# Divergent draws appear as red dots — their location shows which parameters
# have problematic geometry.
```

**Fixes for divergences (in order of preference):**
1. Raise `target_accept` from 0.8 to 0.9 or 0.95 (slows sampling but reduces divergences)
2. Apply non-centered parametrization (most common fix for hierarchical models — see Section 8)
3. Tighten priors on scale parameters (very wide scale priors create funnels in the posterior)
4. Reparametrize constrained parameters (log transform, Cholesky decomposition)

### Energy Diagnostic (BFMI)

The Bayesian Fraction of Missing Information (BFMI) measures how efficiently the sampler explores the posterior energy landscape.

```python
# Compute BFMI per chain
bfmi = az.bfmi(idata)
print(f"BFMI: {bfmi}")

# Decision rule:
# BFMI > 0.3: Good
# 0.2 < BFMI < 0.3: Borderline — investigate further
# BFMI < 0.2: Poor — geometry problem, reparametrize

# Low BFMI often co-occurs with divergences; fix the root cause, not the symptom.
```

### Complete Diagnostic Checklist

Run this after every MCMC fit before proceeding to inference:

- [ ] R-hat < 1.01 for all parameters
- [ ] Bulk ESS > 400 for all parameters
- [ ] Tail ESS > 400 (ideally > 1000 for reported credible intervals)
- [ ] Zero divergences
- [ ] BFMI > 0.2
- [ ] Trace plots show fuzzy caterpillar pattern (no trends, no stuck chains)
- [ ] Prior predictive check was run before estimation
- [ ] Posterior predictive check passes (model can reproduce observed data)

---

## Posterior Inference and Reporting

### Credible Intervals

The highest density interval (HDI) is preferred over the equal-tailed interval when posteriors are skewed. The HDI is the shortest interval containing the specified probability mass.

```python
import arviz as az

# 90% HDI for all parameters
hdi_90 = az.hdi(idata, hdi_prob=0.90)
print(hdi_90)

# Reporting template:
# "The posterior mean price elasticity is -1.24 (90% HDI: [-1.61, -0.89])."
# Prefer 90% over 95% in applied economics (matches one-tailed 5% frequentist convention).

# Posterior mean and SD
summary = az.summary(idata, hdi_prob=0.90)
print(summary[["mean", "sd", "hdi_5%", "hdi_95%"]])
```

### Posterior Predictive Checks

Generate data from the posterior and compare to observed data. This is the primary model validation tool in Bayesian analysis.

```python
# PyMC: sample posterior predictive
with model:
    ppc = pm.sample_posterior_predictive(trace, random_seed=42)

idata_full = az.from_pymc(trace, posterior_predictive=ppc)

# Visual check: does the model reproduce the observed distribution?
az.plot_ppc(idata_full, data_pairs={"log_quantity": "log_quantity"}, num_pp_samples=200)

# Specific statistics: does the model reproduce observed mean, variance, skewness?
import numpy as np

y_rep = ppc.posterior_predictive["log_quantity"].values.reshape(-1, len(Y_obs))
print(f"Observed mean: {Y_obs.mean():.3f}")
print(f"Predicted mean: {y_rep.mean():.3f} (95%: {np.percentile(y_rep.mean(axis=1), [2.5, 97.5])})")

print(f"Observed SD:   {Y_obs.std():.3f}")
print(f"Predicted SD:  {y_rep.std(axis=1).mean():.3f}")
```

**What to look for:**
- The distribution of replicated datasets should overlap substantially with observed data
- If the model systematically misses the tails, consider a heavier-tailed likelihood (Student-t instead of Normal)
- If the model misses discrete features (spikes, multi-modality), the model may be misspecified

### Effect Size Reporting

The posterior enables natural probability statements without p-values:

```python
import numpy as np

beta_draws = idata.posterior["beta"].values.flatten()

# Probability of direction (analogous to sign test)
prob_negative = (beta_draws < 0).mean()
print(f"P(beta < 0 | data) = {prob_negative:.3f}")

# Probability of practical significance
threshold = -0.5  # elasticity threshold for meaningful effect
prob_meaningful = (beta_draws < threshold).mean()
print(f"P(beta < {threshold} | data) = {prob_meaningful:.3f}")

# These are the cleanest effect summaries to report alongside the posterior mean and HDI.
```

### Model Comparison

Use LOO-CV (leave-one-out cross-validation) or WAIC for comparing non-nested models. Prefer LOO-CV — it has better theoretical properties and ArviZ computes it efficiently via Pareto-smoothed importance sampling (PSIS).

```python
import arviz as az

# Compute LOO-CV for each model
# Requires log-likelihood to be stored (use compute_log_likelihood=True in sampling)
loo_m1 = az.loo(idata_model1, pointwise=True)
loo_m2 = az.loo(idata_model2, pointwise=True)

# Compare models
comparison = az.compare({"model1": idata_model1, "model2": idata_model2}, ic="loo")
print(comparison)

# Interpretation:
# - elpd_diff: difference in expected log predictive density (higher is better)
# - se: standard error of the difference
# - If |elpd_diff| / se < 2: models are indistinguishable

# Warning: check Pareto k values
print(loo_m1.pareto_k[loo_m1.pareto_k > 0.7])
# Pareto k > 0.7 for an observation: that observation is highly influential.
# LOO estimate is unreliable for that observation. Use K-fold CV instead.
```

---

## Bayesian Structural Models

### Bayesian Hierarchical Demand (Random Coefficients)

In a random coefficients logit model, consumer taste heterogeneity is the random effect. A full Bayesian treatment puts a prior on the distribution of heterogeneity and propagates uncertainty through to demand and welfare predictions.

```python
# Conceptual PyMC structure for a random coefficients demand model
# (simplified — for full BLP, numerical integration over the population
#  distribution is required at each draw)

with pm.Model() as rc_demand:
    # Population distribution of price sensitivity
    mu_alpha = pm.Normal("mu_alpha", mu=-1.0, sigma=0.5)    # mean price sensitivity
    sigma_alpha = pm.HalfNormal("sigma_alpha", sigma=0.3)   # dispersion

    # Consumer-level price sensitivity (N_consumers draws)
    alpha_i = pm.Normal("alpha_i", mu=mu_alpha, sigma=sigma_alpha,
                         shape=N_consumers)

    # Product fixed effects (mean utility)
    delta = pm.Normal("delta", mu=0, sigma=2, shape=N_products)

    # Market shares via softmax over consumer-specific utilities
    # (requires numerical integration / simulation over consumer draws)
```

For serious Bayesian BLP estimation, the dominant approach is to use the BLP contraction mapping to recover mean utilities delta given parameters, then place a Bayesian prior on the random coefficient distribution. This hybrid approach (frequentist inner loop, Bayesian outer loop) is computationally tractable.

### Hierarchical Panel Models

```r
# R: Bayesian hierarchical DiD with brms
library(brms)

# Event study with heterogeneous treatment effects by state
fit_did <- brm(
  outcome ~ time + treated + time:treated + (time:treated | state),
  data = panel_data,
  family = gaussian(),
  prior = c(
    prior(normal(0, 1), class = b),
    prior(normal(0, 10), class = Intercept),
    prior(exponential(1), class = sd),
    prior(lkj(2), class = cor)
  ),
  chains = 4, iter = 3000, warmup = 1000, seed = 42, cores = 4
)

# Partial pooling: state-specific treatment effects borrow strength from the
# population distribution. More stable than fixed effects with small per-state N.
```

### Bayesian Dynamic Discrete Choice

Placing a prior on structural utility parameters and estimating via MCMC through the full Bellman equation is computationally expensive — each MCMC draw requires solving the inner loop. Practical approaches:

1. **Bayesian CCP (Imai, Jain, Ching 2009)**: Update parameters and CCPs jointly via MCMC, avoiding full Bellman solution at each draw. Computationally feasible.

2. **Approximate Bayesian Computation (ABC)**: Simulate from the model at each proposed parameter draw, match to observed data moments. No likelihood evaluation needed — useful for models without closed-form likelihood.

3. **Laplace approximation**: Find the posterior mode (MAP estimate), approximate the posterior as a Gaussian centered at the mode. Cheap but ignores posterior skewness.

```python
# MAP estimation (frequentist mode of the posterior) as a fast approximation
import scipy.optimize as opt

def neg_log_posterior(theta, data, beta, trans_mat, n_states):
    """Negative log posterior = negative log likelihood + negative log prior."""
    # Prior: Normal(0, 2) on both parameters (log scale)
    log_prior = -0.5 * (theta[0]**2 / 4 + theta[1]**2 / 4)
    log_lik = -nfxp_objective(theta, data, beta, trans_mat, n_states)
    return -(log_lik + log_prior)

map_result = opt.minimize(neg_log_posterior, x0=[5.0, 0.01],
                           args=(data, beta, trans_mat, n_states),
                           method='Nelder-Mead')
map_estimate = map_result.x

# Laplace approximation: compute Hessian at MAP
hessian = opt.approx_fprime(map_estimate, lambda t: opt.approx_fprime(
    t, lambda s: -neg_log_posterior(s, data, beta, trans_mat, n_states), 1e-5), 1e-5)
posterior_cov = np.linalg.inv(hessian)
posterior_se = np.sqrt(np.diag(posterior_cov))
```

---

## Reparametrization

Poor posterior geometry is the most common cause of MCMC pathologies (divergences, low ESS, poor mixing). Reparametrization resolves geometry problems without changing the model.

### Non-Centered Parametrization

The most important reparametrization for hierarchical models. Centered parametrization creates a funnel geometry that NUTS cannot navigate efficiently.

```python
# WRONG: Centered parametrization (creates funnel)
with pm.Model() as centered:
    mu = pm.Normal("mu", mu=0, sigma=1)
    sigma = pm.HalfNormal("sigma", sigma=1)
    beta = pm.Normal("beta", mu=mu, sigma=sigma, shape=N_groups)  # problematic

# CORRECT: Non-centered parametrization (separates geometry)
with pm.Model() as noncentered:
    mu = pm.Normal("mu", mu=0, sigma=1)
    sigma = pm.HalfNormal("sigma", sigma=1)
    beta_raw = pm.Normal("beta_raw", mu=0, sigma=1, shape=N_groups)  # N(0,1)
    beta = pm.Deterministic("beta", mu + sigma * beta_raw)            # transform
```

In Stan:
```stan
parameters {
  real mu;
  real<lower=0> sigma;
  vector[N_groups] beta_raw;  // N(0,1)
}
transformed parameters {
  vector[N_groups] beta = mu + sigma * beta_raw;  // non-centered
}
model {
  mu ~ normal(0, 1);
  sigma ~ exponential(1);
  beta_raw ~ normal(0, 1);  // prior is on the raw parameter
  // likelihood uses beta
}
```

### Log Parametrization for Positive Parameters

```python
# Instead of: sigma ~ HalfNormal(1) (can create geometry issues near zero)
# Use:
log_sigma = pm.Normal("log_sigma", mu=0, sigma=1)
sigma = pm.Deterministic("sigma", pm.math.exp(log_sigma))
```

### Cholesky Parametrization for Covariance Matrices

Sampling a full covariance matrix directly is inefficient and can violate positive-definiteness. Sample the Cholesky factor instead.

```stan
// Stan: Cholesky factor for multivariate normal
parameters {
  cholesky_factor_corr[K] L_corr;   // Cholesky factor of correlation matrix
  vector<lower=0>[K] sigma_vec;      // marginal SDs
}
transformed parameters {
  matrix[K, K] Sigma = diag_matrix(sigma_vec) * L_corr * L_corr'
                       * diag_matrix(sigma_vec);  // covariance matrix
}
model {
  L_corr ~ lkj_corr_cholesky(2);   // LKJ prior on Cholesky factor
  sigma_vec ~ exponential(1);
}
```

### Diagnosing Geometry Problems

| Symptom | Cause | Fix |
|---------|-------|-----|
| Divergences in hierarchical model | Funnel geometry (centered parametrization) | Non-centered parametrization |
| Low ESS for scale parameters | Near-zero scale posterior (sigma → 0) | Log parametrization of sigma |
| Divergences with covariance matrices | Ill-conditioned matrix near boundary | Cholesky parametrization, LKJ(2) prior |
| Slow mixing for correlated parameters | High posterior correlation | Reparametrize to decorrelate (PCA rotation) |
| BFMI < 0.2 with no divergences | Global geometry issue | Increase target_accept, check prior scale |

---

## Integration with compound-science

**Agents to invoke alongside Bayesian estimation:**

- `numerical-auditor`: Review MCMC convergence diagnostics — R-hat, ESS, divergences. Report format should include all five convergence metrics.
- `calibration-assessor`: Review prior elicitation strategy, sensitivity analysis, and whether priors are consistent with identification. Use for prior predictive checks and moment-matching to literature targets.
- `benchmark-researcher`: Find literature calibration targets to set informative prior means. Ask for point estimates and uncertainty ranges, not just means.
- `results-verifier`: Verify that reported posterior means, credible intervals, and model comparison statistics match the actual ArviZ/Stan output.

**Related skills:**

- `structural-modeling`: Frequentist counterpart — NFXP, MPEC, BLP, dynamic discrete choice. Use Bayesian skills on top of the structural model framework when small samples or hierarchical structure warrants it.
- `causal-inference`: For reduced-form causal methods. Bayesian DiD and RD designs follow the same identification logic; the Bayesian layer adds partial pooling and uncertainty propagation.

**Commands that extend naturally to Bayesian context:**

- `/diagnose`: Convergence diagnostics (R-hat, ESS, divergences) are a subset of the full diagnostic battery
- `/simulate`: Prior predictive simulation is a special case of the Monte Carlo simulation workflow
- `/stress-test`: Prior sensitivity analysis (vary prior SD 0.5x and 2x) is a natural robustness check for Bayesian models

---

## Common Anti-Patterns

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| Reporting results without checking R-hat | Non-convergence masquerades as valid posterior | Always run full diagnostic checklist first |
| Using uniform priors (flat priors) | Improper or extremely diffuse; creates pathological geometry in hierarchical models | Use weakly informative priors (Normal(0, 2.5) or HalfNormal(1)) |
| Centered parametrization for hierarchical models | Funnel geometry; divergences and low ESS for scale parameters | Non-centered parametrization always for hierarchical models |
| Using variational inference for final results | Underestimates posterior variance; may miss multimodality | MCMC for final results; VI only for exploration |
| Skipping prior predictive check | Priors may imply scientifically impossible data | Always run prior predictive before fitting |
| Single chain | Cannot compute R-hat; cannot detect non-convergence | Always run 4 chains |
| Treating credible interval as confidence interval | Different interpretation; CI covers true parameter with 95% frequency, HDI covers 90% of posterior mass | Report as "90% credible interval" and be precise about the interpretation |
| Bayes factors for model comparison | Extremely sensitive to prior specification; computationally unstable | Use LOO-CV (PSIS-LOO) via ArviZ instead |
| Ignoring Pareto k diagnostics | LOO-CV unreliable for high-k observations | Check `loo.pareto_k > 0.7`; use K-fold CV for problematic observations |
