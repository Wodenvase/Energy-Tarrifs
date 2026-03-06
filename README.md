Modeling Electricity Prices and Tariff Dynamics Under Renewable Penetration
=======================================================================

> **Core research deliverable: reproducible results that quantify how renewable penetration changes wholesale price levels, price volatility, and retail tariff stability.**

This repository contains a compact Julia framework that: (1) generates or ingests supply/demand and price inputs, (2) computes a merit-order wholesale price series, (3) measures how price statistics vary with renewable share, and (4) quantifies retail tariff pass-through and scenario risk under alternative renewable penetration levels.

---

**🎯 Research Question**

How does increasing renewable penetration affect wholesale electricity price mean and volatility, and what are the implications for retail tariff stability under realistic pass‑through?

Key hypotheses:
- Increased renewable share reduces mean wholesale prices (merit-order effect).
- Increased renewable share increases price variance (more zero-price hours + occasional scarcity spikes).
- Incomplete or lagged pass-through dampens retail tariff volatility but may introduce cross-subsidy and risk.

---

**I. Structural model (compact, interpretable)**

Wholesale price model (merit-order intuition):

$$
P_t = f\big(D_t - R_t, P^{gas}_t, \tau_t\big)
$$

Operational rule used in code:

If residual demand $x_t = D_t - R_t > Q_{baseload}$ then

$$
P_t = HR\cdot P^{gas}_t + \tau_t\cdot EI
$$

Else

$$
P_t \approx 0
$$

Parameters and units:
- $D_t$ — demand (MWh)
- $R_t$ — renewable output (MWh)
- $P^{gas}_t$ — gas price (USD / MWh)
- $\tau_t$ — carbon price (USD / ton)
- $HR$ — heat rate (MWh_fuel / MWh_elec)
- $EI$ — emissions intensity (ton CO2 / MWh)
- $Q_{baseload}$ — baseload generation capacity (MWh)

Retail tariff model (linear pass-through):

$$
T_t = \alpha P_t + \beta
$$

Estimate $\alpha$ (pass-through) via regression; analyze lagged and smoothed versions to assess tariff stability.

---

**II. Data & Inputs**

- Synthetic generator (default) implemented in [src/ET.jl](src/ET.jl) to enable fast reproducibility and scenario testing.
- Replace with market data from ENTSO‑E, EPEX SPOT, or Nord Pool for production analysis. See `examples/README.md` and notes below.

Primary real-data fields required per timestamp:
- `D` — demand (MWh)
- `R` — renewables generation (MWh)
- `P_gas` — gas price (USD/MWh)
- `tau` — carbon price (USD/ton)

Units must be consistent.

---

**III. Methods**

- Time-series summary by renewable-share quantiles (mean, variance)
- Volatility heatmap: variance by hour-of-day × R_share quantile
- Regression (OLS) for tariff pass-through: estimate $\alpha$ and $\beta$ and test lags
- GARCH on log-returns (ARCHModels.jl) for volatility dynamics
- Monte Carlo scenario simulations and comparative risk (e.g., baseline vs 60% renewables)

---

**IV. Project structure & key files**

- File: [Project.toml](Project.toml) — Julia dependencies
- File: [src/ET.jl](src/ET.jl) — core model functions: `synthetic_data`, `merit_order_price`, `compute_Rshare`, `estimate_pass_through`, `fit_garch`, `volatility_heatmap`, `monte_carlo_compare`, `scenario_plot`, `plot_tariff_timeseries`
- File: [scripts/simulate.jl](scripts/simulate.jl) — runs baseline synthetic simulation and writes `results/synthetic_prices.csv`
- File: [scripts/analysis.jl](scripts/analysis.jl) — computes `volatility_by_renewable_quantile.csv`, builds a demonstration tariff, and saves `results/price_vs_renew_share.png`
- File: [scripts/extended_analysis.jl](scripts/extended_analysis.jl) — produces heatmap, scenario (60%) plots, Monte Carlo CSVs, density/histogram comparisons, and tariff timeseries plot
- Directory: `results/` — generated CSVs and PNGs (the central deliverables)

---

**V. Reproducing the results (quick commands)**

From the project root (`/Users/dipantabhattacharyya/ET`):

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
julia --project=. scripts/simulate.jl         # generates results/synthetic_prices.csv
julia --project=. scripts/analysis.jl         # quick analysis plot + volatility CSV
julia --project=. scripts/extended_analysis.jl # heatmap, scenario & Monte Carlo plots + CSVs
```

Files you will find in `results/` (central deliverables):
- `synthetic_prices.csv` — hourly synthetic series: `ts,D,R,P_gas,tau,P,R_share`
- `volatility_by_renewable_quantile.csv` — mean/variance of price by R_share quantile
- `price_vs_renew_share.png` — scatter of price vs renewable share
- `volatility_heatmap.png` — heatmap of price variance (hour × R_share quantile)
- `scenario_60_mean_hist.png`, `scenario_60_var_hist.png` — Monte Carlo histograms comparing baseline vs 60% renewables
- `scenario_60_mc.csv`, `monte_carlo_compare_60.csv` — scenario simulation outputs for statistical comparison
- `price_tariff_timeseries.png` — example wholesale vs retail tariff time series

These outputs are the central scientific artifacts: use them directly in figures, tables, or further statistical analysis.

---

**Results (Generated Figures)**

Below are the central figures produced by the scripts in this repository. Each image is in the `results/` folder and includes a short inference you can use in presentations or the manuscript.

- **Price vs Renewable Share:**

	![Price vs Renewable Share](results/price_vs_renew_share.png)

	- **Inference:** Mean wholesale price decreases as renewable share increases, but a visible tail of price spikes remains — consistent with lower average prices and higher conditional volatility.

- **Volatility Heatmap (hour × R_share quantile):**

	![Volatility Heatmap](results/volatility_heatmap.png)

	- **Inference:** High variance concentrates in specific hours and intermediate-to-low renewable-share quantiles (scarcity hours), indicating that volatility risk is both temporal and regime-dependent.

- **Scenario 60% Renewables — Mean Price Comparison:**

	![Scenario Mean Hist](results/scenario_60_mean_hist.png)

	- **Inference:** Monte Carlo distribution shows a leftward shift in mean wholesale price under 60% renewables (lower average), but overlap indicates retained tail risk.

- **Scenario 60% Renewables — Variance Comparison:**

	![Scenario Variance Hist](results/scenario_60_var_hist.png)

	- **Inference:** Price variance increases under the high-renewable scenario in many Monte Carlo draws, confirming that higher renewables can increase volatility even as mean falls.

- **Monte Carlo Comparison CSV:**

	- File: [results/monte_carlo_compare_60.csv](results/monte_carlo_compare_60.csv)

	- **Inference:** Use this CSV to compute summary statistics (mean difference, variance ratio, percentile shifts). Example metrics to report: Δmean, Δvar, ΔP99 frequency.

- **Retail Tariff vs Wholesale Price Time Series:**

	![Price Tariff Timeseries](results/price_tariff_timeseries.png)

	- **Inference:** With linear pass-through `T_t = αP_t + β` (example α≈0.6), retail tariffs smooth some wholesale volatility but do not eliminate tail spikes; fixed charge `β` reduces bill variability but shifts risk to suppliers.

---

**VI. Example interpretations (how to read the results)**

- Wholesale price vs renewable share (scatter) — expect decreasing conditional mean with higher `R_share` but a fatter tail (spikes) at low residual demand margins.
- Volatility heatmap (hour × R_share quantile) — identifies hours and R_share regimes with elevated variance (e.g., late-evening scarcity spikes when renewables drop, or midday low-price clusters).
- Monte Carlo scenario histograms — compare distributional shifts (means and variances) when increasing average renewables to 60%: report changes in mean price, variance, and tail risk (99th percentile).
- Tariff pass-through regression — estimated `α` indicates how sensitively retail tariffs track wholesale price; low `α` with high β indicates consumer price smoothing but higher supplier risk.

Example inference to include in manuscript or presentation:
"Increasing renewable share from baseline to 60% reduces average wholesale prices by X% (Monte Carlo mean difference), but increases price variance by Y% and increases 95/99th percentile spike frequency by Z. Under linear pass-through `T_t=αP_t+β` with estimated α≈0.6, retail tariff mean falls but household tariff volatility falls less than wholesale volatility due to fixed charge `β` smoothing — creating residual supplier exposure to price risk."

---

**VII. Data hygiene & production notes**

- Replace `synthetic_data` with CSV ingestion from ENTSO‑E/EPEX/NordPool. Align timestamps (UTC), handle daylight saving time, and convert units to MWh and USD consistently.
- Merge wholesale prices and gas/carbon price series on timestamps; if missing, use interpolation or forward-fill carefully (note bias implications).
- Validate `R` by technology where available (solar diurnal patterns vs wind stochasticity). Calibrate `HR` and `EI` to local fleet characteristics for realism.

---

**VIII. Suggested next steps (pick one)**

1. Replace synthetic generator with ENTSO‑E / EPEX ingestion + cleaning pipeline; re-run `scripts/extended_analysis.jl` on real data.
2. Add richer tariff models (lagged pass-through, block tariffs, time-of-use tariffs) and compute consumer risk measures (CVaR of bills).
3. Add spatial coupling across bidding zones (two-region model) and run comparative risk analysis.
4. Produce a Pluto notebook that walks through the figures and concise inference text for a results-ready README section.

---

**IX. Key references & data sources**

- ENTSO‑E Transparency Platform — market fundamentals and generation by type
- EPEX SPOT — day-ahead and intraday prices (DE/AT/FR/BE)
- Nord Pool — Nordic market prices and generation
- Academic references on merit-order effect and renewable integration (e.g., Sensfuß et al., 2008; Deane et al., 2012)

---

**Contact**

Author: Dipanta Bhattacharyya
Project: Modeling Electricity Prices and Tariff Dynamics Under Renewable Penetration

If you want, I can now (pick one):
- add a `results/FIGURES.md` that annotates each generated figure with a ready-to-copy caption and interpretation, or
- wire ENTSO‑E ingestion and produce a small real-data run for Germany.

Abstract
--------
This repository supplies a compact, reproducible Julia framework for examining how increasing penetration of variable renewable generation affects wholesale electricity price levels and volatility, and how those wholesale dynamics translate into retail tariff outcomes under simple pass-through rules. The implementation combines a transparent merit-order pricing rule, synthetic (or ingested) time series for demand and renewable output, volatility diagnostics (including an hourly × renewable-share heatmap), GARCH estimation, and Monte Carlo scenario analysis (e.g., 60% renewables). The primary deliverables are reproducible figures and CSV summaries in `results/`.

1. Introduction
---------------
Understanding the interaction between renewable penetration and electricity price formation is essential for market design, risk management, and regulatory policy. We provide an interpretable structural model that reproduces two widely discussed effects: (i) the merit-order effect (declining average wholesale prices) and (ii) increased price intermittency and extreme spikes arising from residual demand dynamics. We quantify these effects with empirical-style diagnostics and scenario simulations designed for reproducible research.

2. Model specification
----------------------
Wholesale price is constructed from residual demand and marginal thermal costs using a parsimonious merit-order rule. Denote demand $D_t$, renewable output $R_t$, gas price $P^{gas}_t$, and carbon price $\tau_t$. Residual demand is $x_t=D_t-R_t$. The implemented rule is:

$$
P_t = \begin{cases}
HR\cdot P^{gas}_t + \tau_t\cdot EI, & x_t > Q_{baseload}, \\
0, & x_t \le Q_{baseload}.
\end{cases}
$$

Retail tariff is modeled as a linear pass-through:

$$
T_t = \alpha P_t + \beta,
$$
where $\alpha$ (pass-through) is estimated by OLS and $\beta$ is a fixed charge. The code supports constructing synthetic tariff series for demonstration and estimating $\alpha$ from data.

3. Data and synthetic generator
-------------------------------
The codebase provides `synthetic_data` to generate hourly series (default one year) for demand, renewable output, gas price and a slowly varying carbon price. For applied work, replace the synthetic generator with cleaned market data from ENTSO‑E, EPEX SPOT or Nord Pool. Required fields are `ts, D, R, P_gas, tau` and units must be consistent.

4. Methods
----------
- Renewable share: $R_{share,t}=R_t/D_t$. We compute summary statistics (mean, variance) of $P_t$ conditional on quantiles of $R_{share}$.
- Volatility heatmap: compute price variance across hour-of-day × renewable-share quantile cells to reveal temporal-regime structure of volatility.
- GARCH: fit an ARCH(1,1) model to log returns of $P_t$ to characterize conditional volatility dynamics.
- Monte Carlo scenario analysis: stochastic repeats with either scaling of renewables or direct scenario specification (e.g., mean renewable share = 60%). Compare distributions of mean and variance across draws; compute tail risk metrics (percentiles, CVaR).

5. Results (central figures)
---------------------------
All figures are reproducible by running `scripts/extended_analysis.jl`. Below we present the primary results and concise inferences suitable for inclusion in manuscripts.

Figure 1. Price vs Renewable Share

![Figure 1: Wholesale price vs renewable share](results/price_vs_renew_share.png)

Caption: Scatter plot of hourly wholesale price $P_t$ against renewable share $R_{share,t}$. The conditional mean declines with $R_{share}$ while the distribution develops heavier tails at certain ranges, indicating retained spike risk despite lower averages.

Inference: The merit-order effect reduces average prices; however, tails remain and spike frequency can increase in particular residual-demand regimes.

Figure 2. Volatility heatmap (hour × renewable-share quantile)

![Figure 2: Volatility heatmap](results/volatility_heatmap.png)

Caption: Heatmap of empirical price variance for each hour-of-day (columns) versus renewable-share quantile (rows). High variance clusters indicate temporal windows and renewable regimes where scarcity-induced price spikes are more likely.

Inference: Volatility risk is structured both temporally (specific hours) and by regime (renewable share), suggesting targeted hedging or capacity mechanisms could mitigate peak risk.

Figure 3. Monte Carlo: 60% renewables — mean price comparison

![Figure 3: Monte Carlo mean comparison (60% renewables)](results/scenario_60_mean_hist.png)

Caption: Overlaid histograms of Monte Carlo simulated mean wholesale prices under baseline and 60% renewable scenarios.

Inference: The scenario with 60% renewables reduces the central tendency of mean prices but results overlap indicates remaining uncertainty; report Δmean and confidence intervals from `results/monte_carlo_compare_60.csv`.

Figure 4. Monte Carlo: 60% renewables — variance comparison

![Figure 4: Monte Carlo variance comparison (60% renewables)](results/scenario_60_var_hist.png)

Caption: Overlaid histograms of Monte Carlo simulated price variances under baseline and 60% renewables.

Inference: Many Monte Carlo draws show increased variance under higher renewable penetration, confirming the hypothesis that mean downward pressure can coexist with higher volatility.

Figure 5. Retail tariff vs wholesale price timeseries

![Figure 5: Retail tariff vs wholesale price](results/price_tariff_timeseries.png)

Caption: Example hourly series of wholesale price and constructed retail tariff with linear pass-through (illustrative α≈0.6). Fixed charge reduces short-run household bill variability but does not remove supplier exposure to spikes.

Inference: Linear pass-through with a fixed charge smooths consumer bills but transfers residual volatility and tail risk to suppliers or balancing mechanisms.

6. Reproducibility and usage
---------------------------
To reproduce the figures above, execute the following in the project root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
julia --project=. scripts/simulate.jl
julia --project=. scripts/analysis.jl
julia --project=. scripts/extended_analysis.jl
```

Output files and formats are documented in Section IV of this repository. For production analysis, replace `synthetic_data` with curated market data and calibrate `HR` and `EI` to fleet characteristics.

7. Limitations and extensions
-----------------------------
- The current merit-order rule is stylized and omits intra-day unit commitment, reserve constraints, and market bidding behavior. Use market-level supply curves and unit commitment models for higher fidelity.
- Tariff formulation is linear; extending to lagged pass-through, time-of-use tariffs, or retail hedging contracts is straightforward within the code base.
- Future work: ingest ENTSO‑E/EPEX/Nord Pool, calibrate heat rates/emissions, incorporate spatial coupling between bidding zones, and implement market-clearing with merit-order supply stacks.

8. References
-------------
- Sensfuß, F., Ragwitz, M., & Genoese, M. (2008). The merit-order effect: A detailed analysis of the price effect of renewable electricity generation on spot prices. *Energy Policy.*
- Deane, J. P., Ó Gallachóir, B. P., & McKeogh, E. J. (2012). Quantifying the system costs of additional balancing and frequency control with increasing levels of wind generation. *Energy Policy.*
- ENTSO‑E Transparency Platform; EPEX SPOT; Nord Pool (data sources).

9. Contact
----------
Dipanta Bhattacharyya — for questions, data requests, or collaboration proposals.

If you would like, I can (select one):
- prepare `results/FIGURES.md` with manuscript-ready captions and suggested figure panels, or
- implement ENTSO‑E ingestion and demonstrate a real-data analysis for a selected market (Germany recommended).

