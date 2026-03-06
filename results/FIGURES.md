Figure 1 — Price vs Renewable Share (results/price_vs_renew_share.png)
-----------------------------------------------------------------
Caption (manuscript-ready): "Hourly wholesale electricity price $P_t$ plotted against the contemporaneous renewable generation share $R_{share,t}=R_t/D_t$. The solid line denotes the conditional mean estimated by local regression (LOESS) and shaded area denotes the 95% bootstrap confidence interval. Higher renewable shares reduce the conditional mean price while the distribution displays heavy right tails indicating persistent spike risk."

Suggested panel usage:
- Panel A: Full scatter + LOESS mean (file above)
- Panel B: Conditional quantile lines (optional — compute from `results/volatility_by_renewable_quantile.csv`)

Notes for methods section: describe LOESS smoothing parameters, bootstrap procedure (n=1000), and units (USD/MWh).

Figure 2 — Volatility heatmap (results/volatility_heatmap.png)
-----------------------------------------------------------
Caption (manuscript-ready): "Empirical price variance (color scale) across hour-of-day (x-axis) and renewable-share quantile (y-axis). Cells show sample variance of $P_t$ within each hour × quantile bin. High-variance clusters identify temporal-regime combinations where scarcity-induced price spikes are concentrated."

Suggested panel usage:
- Main panel: heatmap with annotated high-variance cells (black boxes)
- Inset: row-wise marginal variance vs quantile to show coarse regime trend

Notes for methods: report number of quantiles used (12), aggregation procedure, and any smoothing applied to the heatmap.

Figure 3 — Monte Carlo: 60% renewables — Mean Price Comparison (results/scenario_60_mean_hist.png)
-------------------------------------------------------------------------------------------
Caption (manuscript-ready): "Overlaid histograms of Monte Carlo simulated annual mean wholesale prices under baseline and a scenario with nominal 60% mean renewable share. Histogram shading distinguishes scenarios; vertical lines mark sample means and 95% confidence intervals."

Suggested panel usage:
- Single comparative panel showing distributional shift; annotate Δmean and p-value from a two-sample test.

Figure 4 — Monte Carlo: 60% renewables — Variance Comparison (results/scenario_60_var_hist.png)
------------------------------------------------------------------------------------------
Caption (manuscript-ready): "Overlaid histograms of Monte Carlo simulated price variances under baseline and 60% renewable scenarios. The figure highlights increased dispersion under many scenario draws despite lower means."

Suggested panel usage:
- Pair with Figure 3 (side-by-side) to summarize mean vs volatility trade-off.

Figure 5 — Retail tariff vs wholesale price timeseries (results/price_tariff_timeseries.png)
------------------------------------------------------------------------------------
Caption (manuscript-ready): "Representative hourly time series showing wholesale price and a constructed retail tariff under linear pass-through $T_t=\alpha P_t + \beta$ (illustrative $\alpha\approx0.6$). The retail series demonstrates smoothing of short-term volatility but preserves exposure to tail events."

Suggested panel usage:
- Panel for methods/results describing pass-through estimation; include annotation of estimated $\alpha$ and $\beta$ and a short table of regression statistics (export from scripts).

Additional files
----------------
- `results/monte_carlo_compare_60.csv` — full Monte Carlo outputs (use to compute Δmean, Δvar, percentiles, CVaR).
- `results/volatility_by_renewable_quantile.csv` — summary stats by renewable-share quantile used to generate heatmap and quantile plots.
- `results/synthetic_prices.csv` — synthetic hourly inputs (ts,D,R,P_gas,tau,P,R_share); include in reproducibility appendix if using synthetic experiments.

Recommended figure ordering for manuscript (suggested):
1. Figure 1 (Price vs Renewable Share) — establishes merit-order effect and tails.
2. Figure 2 (Volatility heatmap) — shows temporal/regime structure of volatility.
3. Figures 3–4 (Monte Carlo mean and variance comparisons) — scenario evidence (60% renewables).
4. Figure 5 (Retail tariff timeseries) — connects wholesale dynamics to tariff outcomes.

Suggested captions (short form) for figure list/table-of-contents:
- Fig.1 — Wholesale price vs renewable share (scatter + LOESS mean).
- Fig.2 — Hour × R_share quantile volatility heatmap.
- Fig.3 — Monte Carlo distribution of mean wholesale price (baseline vs 60% renewables).
- Fig.4 — Monte Carlo distribution of price variance (baseline vs 60% renewables).
- Fig.5 — Example wholesale and retail tariff time series under linear pass-through.

Author notes
------------
For publication, replace synthetic experiments with ENTSO‑E/EPEX/Nord Pool runs and include a short table of data sources, sample period, and cleaning steps. Provide code snippet used to reproduce each figure (preferred in supplementary material or a Pluto notebook).
