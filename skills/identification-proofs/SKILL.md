---
name: identification-proofs
description: Systematic guide for writing formal identification arguments and proofs in structural and reduced-form econometrics. Use when the user needs to prove or formalize that a parameter is identified — including writing identification propositions, stating regularity conditions, deriving rank conditions, or showing observational equivalence fails. Triggers on "identification proof", "identification argument", "identify the parameter", "show identification", "identification condition", "exclusion restriction proof", "rank condition", "order condition", "identification strategy formal", "nonparametric identification", "parametric identification", "local identification", "global identification", "observational equivalence", "identification at infinity", "completeness condition", "regularity conditions", "Rothenberg", "proof of identification", "identification result", "identified parameter", "point identified", "set identified", "partial identification".
---

# Identification Proofs

Reference for writing formal and informal identification arguments: from stating the target parameter precisely, through deriving the identification result, to connecting it to a feasible estimator. Covers parametric and nonparametric identification, the implicit function theorem approach, completeness conditions, and partial identification.

## When to Use This Skill

Use when the user is:
- Writing a formal identification proposition for a paper or theory appendix
- Deriving whether a structural or causal parameter is point identified
- Stating and verifying regularity conditions for an identification result
- Working through rank or order conditions for GMM moment conditions
- Arguing identification for IV, DiD, RDD, or structural models
- Checking whether two models are observationally equivalent
- Characterizing an identified set under partial identification

Skip when:
- The task is implementing a causal estimator (use `causal-inference` skill)
- The task is structural model estimation code (use `structural-modeling` skill)
- The user needs only informal intuition, not a formal argument

---

## 1. What Identification Means

**Core definition.** A parameter $\theta_0$ is *identified* if the map from the true parameter value to the distribution of observables is injective: no other parameter value $\theta \neq \theta_0$ is consistent with the same observable distribution.

Formally, let $P_\theta$ denote the distribution of observed data $(Y, X, Z)$ under parameter $\theta \in \Theta$. Then $\theta_0$ is identified if

$$P_{\theta_1} = P_{\theta_2} \implies \theta_1 = \theta_2.$$

**Observational equivalence.** Two values $\theta_1$ and $\theta_2$ are *observationally equivalent* if $P_{\theta_1} = P_{\theta_2}$. Identification fails precisely when observational equivalence holds for some pair $\theta_1 \neq \theta_2$.

**Local vs global identification.** A parameter is *locally identified* at $\theta_0$ if there exists a neighborhood $\mathcal{N}(\theta_0)$ such that no other $\theta \in \mathcal{N}(\theta_0)$ is observationally equivalent to $\theta_0$. It is *globally identified* if the injectivity holds over the entire parameter space $\Theta$. Local identification is weaker: a globally non-identified parameter can still be locally identified (the model has multiple isolated solutions). For estimation, global identification is what ensures the estimator converges to the true value.

**Point vs set identification.** Under *point identification*, the data uniquely determine $\theta_0$. Under *partial identification* (Manski 1990), the data are consistent with a set of parameter values — the *identified set* $\Theta^* \supseteq \{\theta_0\}$. Partial identification arises when the model is underdetermined: too many degrees of freedom for the observable variation to pin down.

**Why identification precedes estimation.** A parameter can only be consistently estimated if it is identified. The GMM/MLE/2SLS estimator converges in probability to the set of solutions to the population criterion — if that set is not a singleton, the estimator has no well-defined probability limit. Checking identification before writing estimation code prevents a class of hard-to-diagnose failures: code runs and produces output, but the output is arbitrary.

---

## 2. The Standard Architecture of an Identification Argument

Every formal identification argument follows the same logical structure. Work through all seven components before claiming identification.

### Step 1 — Target Parameter

State precisely *what* $\theta$ you want to identify. Not "the causal effect of education on wages" but the exact functional or structural parameter:

- The coefficient $\beta$ in $Y = X\beta + \varepsilon$ under endogeneity
- The average structural function $g(x) = E[Y(x)]$ for potential outcome $Y(x)$
- The vector of taste parameters $(\alpha, \beta, \sigma)$ in a BLP demand model
- The replacement cost $RC$ in the Rust (1987) bus engine model

**Common mistake:** conflating the target parameter with the estimand. The LATE from IV is not the ATE. The ATT from DiD is not the ATE. State which object you are identifying and why it is the policy-relevant quantity.

### Step 2 — Model Primitives

State the model: its ingredients, what is observed vs latent, and what restrictions are imposed.

- **Observables**: $(Y_i, X_i, Z_i)$ for $i = 1, \ldots, N$
- **Latent variables**: $\varepsilon_i$, unobserved heterogeneity $\eta_i$, private information
- **Structural equations**: e.g., $Y = g(X, \varepsilon; \theta)$ or $U(x; \theta) + \varepsilon$
- **Error restrictions**: independence, mean independence, quantile independence
- **Functional form**: parametric family vs nonparametric class $\mathcal{G}$
- **Equilibrium concept**: if the model involves strategic interaction

### Step 3 — Source of Variation

State explicitly what observable variation provides identification leverage. This is the empirical content of the argument.

- **IV**: the instrument $Z$ varies across units; by exclusion, this variation is exogenous to $Y$ conditional on $X$
- **DiD**: a policy change affects one group but not another; time variation separates the treatment effect from fixed group differences
- **RDD**: agents on either side of a cutoff are comparable in all respects except treatment status
- **Structural**: a cost shifter that enters the firm's pricing problem but not demand

The source of variation must be distinct from functional form assumptions. If identification rests entirely on distributional or functional form assumptions (e.g., identification of the variance of random coefficients from distributional tail behavior), state this clearly and note the fragility.

### Step 4 — Key Assumptions

Enumerate the identifying assumptions explicitly. Label them A1, A2, ... for reference in the proof.

Common categories:
- **Exclusion restrictions**: $Z \perp Y | X$, or in structural models, $Z$ excluded from the demand equation
- **Rank / order conditions**: the Jacobian of moment conditions has full column rank
- **Support conditions**: the instrument has sufficient variation (e.g., $\Pr(Z=1) \in (0,1)$; continuous instruments have full support)
- **Independence**: $Z \perp \varepsilon$ or $Z \perp (Y(0), Y(1))$
- **Monotonicity**: for LATE, $D(Z=1) \geq D(Z=0)$ almost surely
- **Continuity**: for RDD, $E[Y(0)|X=x]$ and $E[Y(1)|X=x]$ are continuous at the cutoff
- **Parallel trends**: for DiD, counterfactual trends are equal across treated and control groups

Each assumption must be statable in terms of population quantities (not sample statistics). Each must be either testable (and tested) or defended on substantive grounds.

### Step 5 — Identification Result

Derive the identification. There are three main proof strategies:

1. **Explicit formula**: Show that $\theta_0 = h(P_{\theta_0})$ for some known functional $h$ of the observable distribution. This is the strongest form — it gives both identification and an estimator.

2. **Implicit function theorem (IFT)**: Show that the moment conditions $E[m(X;\theta)] = 0$ have $\theta_0$ as a unique solution locally, by verifying the Jacobian has full rank.

3. **Injectivity argument**: Show directly that $P_{\theta_1} = P_{\theta_2} \implies \theta_1 = \theta_2$ by algebraic manipulation.

### Step 6 — Regularity Conditions

State the conditions under which the identification result holds. See Section 6 for a complete checklist.

### Step 7 — Estimation Link

Connect the identification result to a feasible estimator:
- If $\theta_0 = h(P)$ for a functional $h$, the estimator is $\hat\theta = h(P_n)$ where $P_n$ is the empirical distribution
- If identification is via moment conditions, the estimator is GMM
- If identification is via a likelihood, the estimator is MLE
- State the consistency result that follows from identification + the law of large numbers

---

## 3. Tools for Deriving Identification

### 3.1 Implicit Function Theorem Approach (Parametric Models)

The IFT is the workhorse for local identification in parametric models with moment conditions.

**Setup.** Suppose the model implies moment conditions

$$\mathbb{E}[m(X; \theta)] = 0$$

where $m: \mathcal{X} \times \Theta \to \mathbb{R}^L$ and $\theta \in \mathbb{R}^K$.

**Order condition (necessary).** Identification requires at least as many moment conditions as parameters: $L \geq K$. If $L < K$, the system is underdetermined and $\theta$ is not identified.

**Rank condition (sufficient for local identification).** Assume:
- $\theta_0$ satisfies $\mathbb{E}[m(X;\theta_0)] = 0$
- $\mathbb{E}[m(X;\theta)]$ is continuously differentiable in $\theta$ at $\theta_0$
- The Jacobian $G(\theta_0) \equiv \frac{\partial}{\partial \theta'} \mathbb{E}[m(X;\theta)]\big|_{\theta=\theta_0}$ has full column rank $K$

Then $\theta_0$ is locally identified (Rothenberg 1971).

**Intuition.** Full column rank of $G$ means the moment conditions are "sensitive" to each direction in parameter space — there is no direction $d\theta$ along which all moment conditions are insensitive to the perturbation. If the Jacobian is rank-deficient, there is a direction $d\theta$ along which $\theta_0 + t \cdot d\theta$ is also a solution, at least locally.

**Global identification.** Local identification via the rank condition does not imply global identification. Global identification requires additionally that $\theta_0$ is the *unique* global solution to $\mathbb{E}[m(X;\theta)] = 0$. This typically requires additional restrictions:
- Convexity of the criterion function
- Compactness of $\Theta$ combined with uniqueness on the interior
- Structural arguments (e.g., the contraction mapping in BLP's Berry inversion establishes a unique mean utility vector)

**Worked example: Linear IV.** The structural equation is $Y = X\beta + \varepsilon$ with instruments $Z$ ($K$ endogenous regressors, $L \geq K$ instruments). The moment conditions are

$$\mathbb{E}[Z(Y - X\beta)] = 0 \implies \mathbb{E}[ZY] = \mathbb{E}[ZX]\beta.$$

The Jacobian is $G = -\mathbb{E}[ZX']$, a $L \times K$ matrix. The rank condition requires $\text{rank}(\mathbb{E}[ZX']) = K$, which is the standard IV rank condition. When $L = K$ (just-identified), the unique solution is

$$\beta_0 = (\mathbb{E}[ZX'])^{-1} \mathbb{E}[ZY],$$

establishing point identification via the explicit formula route.

### 3.2 Completeness Approach (Nonparametric IV)

In nonparametric IV settings, identification of the structural function $g$ in $Y = g(X) + \varepsilon$ (with $\mathbb{E}[\varepsilon|Z] = 0$) requires a completeness condition.

**Definition (L2 completeness).** The conditional distribution of $X$ given $Z$ is *L2-complete* if for any square-integrable function $\phi$:

$$\mathbb{E}[\phi(X)|Z] = 0 \text{ a.s.} \implies \phi(X) = 0 \text{ a.s.}$$

**Why it matters.** The moment condition $\mathbb{E}[\varepsilon|Z] = \mathbb{E}[Y - g(X)|Z] = 0$ pins down $g$ only if the map $\phi \mapsto \mathbb{E}[\phi(X)|Z]$ is injective. Completeness is exactly this injectivity condition. Without completeness, the moment condition is consistent with multiple functions $g$.

**When completeness holds:**
- Continuous instruments with a density that is bounded away from zero on its support
- Exponential family models for $(X|Z)$ — Newey and Powell (2003) give sufficient conditions
- Binary instrument $Z$: completeness fails for nonparametric identification; this is why nonparametric LATE is not identified from a binary instrument without additional assumptions

**Connection to parametric IV.** For a parametric class $\mathcal{G} = \{g(\cdot;\theta): \theta \in \Theta\}$, completeness is not needed — the rank condition on the Jacobian suffices. Completeness is the nonparametric analog of full column rank.

### 3.3 Wald Estimand: Identification of LATE

The IV Wald estimand identifies the Local Average Treatment Effect (LATE) — the average effect for *compliers*, units whose treatment status is changed by the instrument.

**Setup.** Binary instrument $Z \in \{0,1\}$, binary treatment $D \in \{0,1\}$, outcome $Y$. Potential outcomes: $Y(d)$ for $d \in \{0,1\}$; potential treatment: $D(z)$ for $z \in \{0,1\}$.

**Assumptions (Imbens and Angrist 1994):**
- **A1 (Relevance):** $\mathbb{E}[D|Z=1] \neq \mathbb{E}[D|Z=0]$ (instrument moves treatment)
- **A2 (Exclusion):** $Y(d,z) = Y(d)$ for all $d,z$ (instrument affects $Y$ only through $D$)
- **A3 (Independence):** $(Y(0), Y(1), D(0), D(1)) \perp Z$
- **A4 (Monotonicity):** $D(1) \geq D(0)$ almost surely (no defiers)

**Identification proof (step by step):**

*Step 1 — Reduced form.* Under A2 and A3:

$$\mathbb{E}[Y|Z=1] - \mathbb{E}[Y|Z=0] = \mathbb{E}[Y(D(1)) - Y(D(0))].$$

*Step 2 — Complier decomposition.* Under A4, the population consists of three strata: always-takers ($D(0)=D(1)=1$), never-takers ($D(0)=D(1)=0$), and compliers ($D(0)=0, D(1)=1$). There are no defiers.

For always-takers and never-takers, $D(1) = D(0)$, so $Y(D(1)) - Y(D(0)) = 0$. Therefore:

$$\mathbb{E}[Y(D(1)) - Y(D(0))] = \mathbb{E}[Y(1) - Y(0) \mid \text{complier}] \cdot \Pr(\text{complier}).$$

*Step 3 — First stage.* Under A3 and A4:

$$\mathbb{E}[D|Z=1] - \mathbb{E}[D|Z=0] = \Pr(\text{complier}).$$

*Step 4 — Conclusion.* Combining steps 2 and 3:

$$\text{LATE} = \mathbb{E}[Y(1)-Y(0) \mid \text{complier}] = \frac{\mathbb{E}[Y|Z=1] - \mathbb{E}[Y|Z=0]}{\mathbb{E}[D|Z=1] - \mathbb{E}[D|Z=0]}.$$

The right-hand side involves only observable quantities, establishing point identification. The Wald estimator $\hat\beta_{IV}$ consistently estimates LATE. $\square$

**What LATE is not.** LATE is not ATE (the average over all units) unless treatment effects are homogeneous or the instrument affects everyone (all units are compliers). The policy relevance of LATE depends on whether compliers are the population of interest.

### 3.4 Regression Discontinuity Identification

**Sharp RD.** Let $X$ be the running variable, $c$ the cutoff, and $D = \mathbf{1}(X \geq c)$ the treatment indicator.

**Assumption (Lee 2008 — Continuity):** The conditional regression functions $E[Y(0)|X=x]$ and $E[Y(1)|X=x]$ are continuous in $x$ at $c$.

**Identification result:**

$$E[Y(1) - Y(0) | X = c] = \lim_{x \downarrow c} E[Y|X=x] - \lim_{x \uparrow c} E[Y|X=x].$$

**Proof.** At $x \geq c$, all units are treated so $E[Y|X=x] = E[Y(1)|X=x]$. At $x < c$, all units are untreated so $E[Y|X=x] = E[Y(0)|X=x]$. Taking limits and invoking continuity:

$$\lim_{x \downarrow c} E[Y|X=x] = E[Y(1)|X=c], \quad \lim_{x \uparrow c} E[Y|X=x] = E[Y(0)|X=c].$$

The difference identifies the average treatment effect at the cutoff. $\square$

**What the continuity assumption rules out.** Sorting: agents cannot precisely manipulate $X$ to be just above vs just below the cutoff. The Lee (2008) density test (implemented via `rddensity`) tests for discontinuity in the density of $X$ at $c$ as a falsification check — a density discontinuity is inconsistent with the continuity assumption.

### 3.5 DiD Identification

**Classic 2x2 DiD.** Two groups ($D \in \{0,1\}$, treated and control), two periods ($T \in \{0,1\}$, pre and post). Treatment occurs for the treated group in period 1.

**Parallel trends assumption:**

$$\mathbb{E}[Y(0)_{T=1} - Y(0)_{T=0} \mid D=1] = \mathbb{E}[Y_{T=1} - Y_{T=0} \mid D=0].$$

This states that the *counterfactual* trend for the treated group (what would have happened absent treatment) equals the observed trend for the control group.

**Identification result:**

$$ATT = \mathbb{E}[Y(1)_{T=1} - Y(0)_{T=1} \mid D=1]$$
$$= (\mathbb{E}[Y_{T=1}|D=1] - \mathbb{E}[Y_{T=0}|D=1]) - (\mathbb{E}[Y_{T=1}|D=0] - \mathbb{E}[Y_{T=0}|D=0]).$$

**Staggered treatment (Callaway and Sant'Anna 2021).** Define group $g$ as units first treated at time $g$. The conditional parallel trends assumption:

$$\mathbb{E}[Y_t(0) - Y_{g-1}(0) \mid G=g, X] = \mathbb{E}[Y_t(0) - Y_{g-1}(0) \mid G=\infty, X],$$

for $t < g$, where $G=\infty$ denotes never-treated units and $X$ are pre-treatment covariates. The group-time ATT $ATT(g,t)$ is identified under this assumption plus a no-anticipation condition.

### 3.6 BLP Demand Identification

**Berry (1994) mean utility inversion.** In the random coefficients logit model, market shares $s_j$ are nonlinear functions of mean utilities $\delta_j$. Berry shows that the mapping $\delta \mapsto s(\delta)$ is invertible — the contraction mapping

$$\delta^{(k+1)} = \delta^{(k)} + \ln s_{\text{obs}} - \ln s(\delta^{(k)})$$

converges to the unique $\delta^*$ such that $s(\delta^*) = s_{\text{obs}}$ (Berry 1994, Proposition 1). This inversion is the inner-loop contraction in BLP estimation and establishes that the mean utilities (and hence the linear parameters $\beta$) are identified up to instruments.

**Rank condition for BLP instruments.** The identification of $\beta$ requires instruments $Z_j$ (excluded from the demand equation) that are correlated with prices after controlling for observed product characteristics. Standard BLP instruments are sums of rivals' product characteristics:

$$Z_j = \sum_{k \neq j, k \in \text{same market}} x_k.$$

The rank condition requires $\text{rank}(E[Z'X]) = K$ where $X$ are the endogenous variables (prices) and $Z$ are the instruments. This parallels the IV rank condition. Weak BLP instruments — a common problem — lead to poorly identified price coefficients and unreliable elasticities.

---

## 4. Formal Proof Template

Use this template for writing an identification proposition in a paper or theory appendix. Adapt the assumptions to your model.

### LaTeX Template

```latex
\begin{assumption}[Model restrictions]\label{ass:model}
  \begin{enumerate}[(i)]
    \item (Structural equation) $Y_i = g(X_i, \varepsilon_i;\, \theta_0)$ a.s.
    \item (Exogeneity) $\mathbb{E}[\varepsilon_i \mid Z_i] = 0$.
    \item (Relevance) $\mathbb{E}[X_i Z_i'] = \Pi$ with $\mathrm{rank}(\Pi) = K$.
    \item (Support) $Z_i$ has full support on $\mathcal{Z} \subseteq \mathbb{R}^L$.
    \item (Compactness) $\Theta \subset \mathbb{R}^K$ is compact.
    \item (Continuity) $\mathbb{E}[m(X_i;\theta)]$ is continuously differentiable in $\theta$.
  \end{enumerate}
\end{assumption}

\begin{proposition}[Identification of $\theta_0$]\label{prop:id}
  Under Assumption~\ref{ass:model}(i)--(vi), $\theta_0$ is the unique element of
  $\Theta$ satisfying $\mathbb{E}[m(X_i;\theta_0)] = 0$.
\end{proposition}

\begin{proof}
  \textbf{Step 1 (Observational implications).}
  Show that the structural equation implies a set of moment conditions
  $\mathbb{E}[m(X_i;\theta_0)] = 0$ that are functions of the observable distribution.
  [Derivation here.]

  \textbf{Step 2 (Rank condition implies local injectivity).}
  The Jacobian $G(\theta) \equiv \partial\mathbb{E}[m(X;\theta)]/\partial\theta'$
  has full column rank $K$ at $\theta_0$ by Assumption~\ref{ass:model}(iii).
  By the implicit function theorem, $\theta_0$ is the unique solution in a
  neighborhood $\mathcal{N}(\theta_0)$.

  \textbf{Step 3 (Global uniqueness).}
  [Argue that $\theta_0$ is the unique global solution, e.g., by convexity
  of the moment function, or by a direct argument that $P_{\theta_1} = P_{\theta_2}
  \implies \theta_1 = \theta_2$ over $\Theta$.]

  Combining Steps 1--3, $\theta_0$ is the unique element of $\Theta$ consistent
  with the observable distribution $P_{\theta_0}$. \hfill$\square$
\end{proof}
```

### Plain-Language Structure

When writing for a paper (not a theory appendix), use the same logical structure in prose:

1. **State the target**: "We seek to identify the price coefficient $\alpha$ in the demand equation..."
2. **State the model and observables**: "The model implies market shares $s_j$ are related to mean utilities $\delta_j(\alpha)$ by..."
3. **State the identifying variation**: "Identification comes from variation in BLP instruments — sums of rival product characteristics — which shift prices but are excluded from the demand equation..."
4. **State the key assumption**: "We assume the instruments satisfy the exclusion restriction: $\mathbb{E}[Z_j \xi_j] = 0$, where $\xi_j$ is the demand shock..."
5. **State the identification result**: "Under the rank condition [cite], the parameter vector $\alpha$ is uniquely identified from the system of first-order conditions..."
6. **State regularity conditions**: "This identification requires: (i) $\Theta$ compact; (ii) $s(\delta)$ continuous in $\delta$; (iii) full rank instruments..."

---

## 5. Common Identification Arguments by Method

| Method | Key Identifying Assumption | Formal Statement | Common Failure Mode | Standard Test |
|--------|---------------------------|------------------|---------------------|---------------|
| IV/2SLS | Exclusion restriction | $Z \perp \varepsilon$ (or $\mathbb{E}[Z\varepsilon]=0$) | Instrument affects $Y$ directly | Overidentification test (not definitive); substantive argument |
| LATE (binary IV) | Exclusion + monotonicity | $D(1) \geq D(0)$ a.s.; $Z \perp (Y(0),Y(1),D(0),D(1))$ | Defiers present; exclusion violated | Monotonicity is typically untestable; test exclusion via falsification |
| DiD | Parallel trends | $\mathbb{E}[Y(0)_{t=1}-Y(0)_{t=0}|D=1] = \mathbb{E}[Y_{t=1}-Y_{t=0}|D=0]$ | Differential anticipation; differential trends | Pre-treatment event study; Rambachan-Roth bounds |
| Sharp RDD | Continuity at cutoff | $E[Y(0)|X=x]$ continuous at $c$ | Manipulation of running variable | McCrary/rddensity density test; covariate smoothness |
| Fuzzy RDD | Continuity + first stage | Cutoff shifts $D$ discontinuously; no jump in $Y(0)$ | Compound discontinuity (other treatments at same cutoff) | Placebo outcomes; covariate balance |
| Structural (BLP) | Rank condition on instruments | $\mathrm{rank}(\mathbb{E}[Z'X]) = K$ | Weak instruments (collinear product characteristics) | First-stage F; Cragg-Donald statistic |
| Structural (dynamic) | Exclusion in Bellman equation | State variable $x$ captures all payoff-relevant history | State misspecification (omitted state variable) | Specification test: residual correlation with omitted variables |
| Nonparametric IV | Completeness | $\mathbb{E}[\phi(X)|Z]=0 \implies \phi=0$ a.s. | Discrete instrument with binary treatment | Completeness not directly testable; check support conditions |

---

## 6. Regularity Conditions Checklist

For every identification argument, verify each condition before claiming the result.

- [ ] **Support condition**: Does the instrument $Z$ have sufficient support? For binary $Z$: $\Pr(Z=1) \in (0,1)$. For continuous $Z$ in nonparametric IV: full support on $\mathcal{Z}$.
- [ ] **Rank condition**: Is the Jacobian $G(\theta_0) = \partial\mathbb{E}[m]/\partial\theta'|_{\theta_0}$ full column rank? Check this numerically at your preliminary estimates — a near-singular Jacobian signals weak identification.
- [ ] **Order condition**: Number of moment conditions $L \geq$ number of parameters $K$.
- [ ] **Compactness**: Is the parameter space $\Theta$ compact? Required for most consistency theorems and for applying extreme value theorems in the proof.
- [ ] **Continuity**: Are the moment functions $\theta \mapsto \mathbb{E}[m(X;\theta)]$ continuous (or differentiable where needed) in $\theta$?
- [ ] **Integrability**: Are all expectations $\mathbb{E}[m(X;\theta)]$ finite? Check that $m(X;\theta)$ is dominated by an integrable function uniformly in $\theta \in \Theta$.
- [ ] **Unique zero (global)**: For global identification, is $\theta_0$ the unique solution to $\mathbb{E}[m(X;\theta)] = 0$ over all of $\Theta$?
- [ ] **Monotonicity (for IV LATE)**: Is $D(Z=1) \geq D(Z=0)$ a.s.? This rules out defiers. Often defended by design (one-sided non-compliance) or institutional argument.
- [ ] **No anticipation (for DiD)**: $Y_{it}(g) = Y_{it}(\infty)$ for $t < g$ (potential outcomes before treatment are unaffected by future treatment status).
- [ ] **Overlap / common support (for ATE, ATT)**: $0 < \Pr(D=1|X) < 1$ over the support of $X$.

**What to do when a condition fails:**
- Rank condition fails: the model is not identified — revisit assumptions or add instruments
- Support condition fails (e.g., instrument has limited support): partial identification may be possible; see Section 7
- Global uniqueness hard to verify: report local identification, note the caveat, use multiple starting values to search for alternative solutions

---

## 7. Partial Identification

When point identification fails, characterize what the data *do* identify: the identified set $\Theta^* = \{\theta \in \Theta : P_\theta = P_{\theta_0}\}$.

### Manski (1990) Sharp Bounds

The canonical example is the average treatment effect under sample selection or missing data. With binary outcome $Y \in \{0,1\}$ and binary treatment $D$:

$$E[Y(1)] \in \left[\frac{E[YD]}{E[D]}, \quad \frac{E[YD]}{E[D]} + \frac{E[1-D]}{1}\right]$$

(the lower bound uses $Y(1)=0$ for non-treated; the upper bound uses $Y(1)=1$). These *sharp* bounds — the tightest possible given the observable distribution — define the identified set without assuming missing-at-random.

Tightening sharp bounds requires additional assumptions: monotone treatment response, monotone treatment selection, or an instrument. Each additional assumption narrows $\Theta^*$. The partial identification approach is explicit about the trade-off between assumptions and set width.

### Intersection Bounds

When multiple identifying assumptions each imply an upper or lower bound on $\theta_0$, the intersection of these bounds is sharper:

$$\theta_0 \in \bigcap_{k} \left[L_k, U_k\right].$$

Chernozhukov, Lee, and Rosen (2013) provide inference methods for intersection bounds.

### Interval Regression

With interval-censored data — $Y \in [Y_L, Y_U]$ — the regression coefficient is set-identified. Stoye (2010) characterizes the identified set and provides valid confidence regions.

### Connection to Sensitivity Analysis

Partial identification and sensitivity analysis are related: Oster (2019) bounds on treatment effects under proportional selection on observables are equivalent to characterizing the identified set under a restriction on the degree of selection. The `/stress-test` command implements Oster bounds and related sensitivity exercises. Both approaches answer the same question: "How much can the unidentified component vary, and what does that imply for the parameter?"

---

## 8. The Informal vs Formal Argument: When Each Is Appropriate

**Informal identification argument** (for the body of an empirical paper):
- Prose description of the source of variation
- Verbal statement of the key assumption(s)
- Intuition for why the assumption is plausible in context
- Reference to a canonical result (e.g., Imbens-Angrist 1994 for LATE, Lee 2008 for RDD)
- Appropriate length: 1–3 paragraphs

**Formal identification proof** (for theory appendices, methods papers, or new estimators):
- Full Proposition/Proof structure (see template in Section 4)
- All assumptions stated as numbered conditions
- Explicit proof steps (observational implications → rank/injectivity → uniqueness)
- All regularity conditions enumerated
- Discussion of which conditions are testable vs maintained
- Appropriate length: 1–5 pages depending on complexity

**When a formal proof is required:**
- You are proposing a new estimator or identification strategy
- The identification relies on non-standard assumptions (partial identification, extrapolation)
- The model involves equilibrium restrictions or fixed-point arguments where uniqueness is non-obvious
- A reviewer has raised an identification concern
- The paper is methodological rather than primarily empirical

**When an informal argument suffices:**
- You are applying a well-known method with established identification results (IV, standard DiD, RDD)
- The identification assumptions are standard for the method and context
- The contribution of the paper is empirical, not methodological

---

## 9. Integration with compound-science Agents and Commands

- **`identification-critic` agent**: Use to review a completed identification argument. The agent checks assumption completeness, exclusion restriction plausibility, rank condition verification, and support conditions.

- **`mathematical-prover` agent**: Use to verify individual proof steps — fixed-point arguments, rank conditions, uniqueness arguments. Particularly useful for structural model identification where the proof involves contraction mappings or matrix algebra.

- **`/identify` command**: Walks through the full identification workflow interactively — target parameter, model, assumptions, derivation, regularity conditions, estimation link.

- **`causal-inference` skill**: Has method-specific implementation details (IV code, DiD code, RDD code) that complement the identification arguments outlined here. Use it for estimation after the identification argument is established.

- **`structural-modeling` skill**: Covers BLP and dynamic discrete choice identification in the context of building and estimating those models. Use it for implementation details after establishing identification here.

- **`/stress-test` command**: Runs Oster bounds, specification curves, and breakdown frontiers — the empirical complement to the partial identification framework in Section 7.
