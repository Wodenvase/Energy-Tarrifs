module ET

using DataFrames, Distributions, Random, StatsBase
using StatsModels, GLM, CSV
using Plots
using ARCHModels

export synthetic_data, merit_order_price, compute_Rshare, estimate_pass_through, volatility_stats, scenario_simulation
export volatility_heatmap, monte_carlo_compare, scenario_plot, plot_tariff_timeseries
"""
Generate synthetic hourly time series for one year (default) with demand, renewables, gas price, and carbon price.
Returns a DataFrame with columns: `:ts, :D, :R, :P_gas, :tau`.
"""
function synthetic_data(;T=8760, seed=123, base_demand=50000.0, renew_mean_share=0.4)
    Random.seed!(seed)
    ts = collect(1:T)
    # Seasonal demand: daily + weekly + yearly (simplified)
    hours = ts .% 24
    day_frac = 2π .* hours ./ 24
    daily = 0.1 .* base_demand .* (1 .+ 0.3 .* sin.(day_frac))
    noise = rand(Normal(0, 0.05*base_demand), T)
    D = base_demand .+ daily .+ noise .+ 2000 .* randn(T)
    # Renewable generation: share of demand with variability and diurnal pattern
    solar = 0.25 .* D .* clamp.(sin.(day_frac), 0, 1)
    wind = 0.2 .* D .* (0.6 .+ 0.4 .* rand(Normal(0,0.5), T))
    R = renew_mean_share .* D .* (0.8 .+ 0.4 .* rand(Normal(0,0.3), T))
    R .= clamp.(R, 0, D)
    # Gas price: mean with stochastic shocks
    P_gas = 20 .+ 5 .* randn(T)
    P_gas .= clamp.(P_gas, 1.0, Inf)
    # Carbon price: slowly varying
    tau = 30 .+ cumsum(0.01 .* randn(T))
    df = DataFrame(ts=ts, D=D, R=R, P_gas=P_gas, tau=tau)
    return df
end

"""
Merit-order pricing function.
P_t = HR * P_gas_t + tau_t * EI if residual demand > Q_baseload, else price ~ 0
EI = emissions intensity (ton CO2 per MWh)
HR = heat rate (MWh of gas per MWh electricity) — set default 0.2 as example
"""
function merit_order_price(df::DataFrame; Q_baseload=20000.0, HR=0.2, EI=0.25)
    T = nrow(df)
    P = zeros(T)
    for i in 1:T
        resid = df.D[i] - df.R[i]
        if resid > Q_baseload
            P[i] = HR * df.P_gas[i] + df.tau[i] * EI
        else
            P[i] = 0.0
        end
    end
    df.P = P
    return df
end

"""
Compute renewable share R_share = R / D
"""
function compute_Rshare(df::DataFrame)
    df.R_share = df.R ./ df.D
    return df
end

"""
Estimate retail tariff pass-through: T_t = α * P_t + β + ε
Returns GLM fit and coefficients.
Assumes retail tariff series `T` available in df, else builds synthetic tariff using α, β.
"""
function estimate_pass_through(df::DataFrame; tariff_col=:T, price_col=:P)
    # Normalize column names to Symbols and check presence robustly
    tcol = Symbol(tariff_col)
    pcol = Symbol(price_col)
    colstrs = string.(names(df))
    if !(string(tcol) in colstrs)
        error("Tariff column $(tariff_col) not found in DataFrame")
    end
    if !(string(pcol) in colstrs)
        error("Price column $(price_col) not found in DataFrame")
    end
    # Build formula using StatsModels.Term to avoid macro interpolation issues
    f = StatsModels.Term(tcol) ~ StatsModels.Term(pcol)
    model = lm(f, df)
    return model
end

"""
Compute volatility stats: mean and variance by R_share quantile
"""
function volatility_stats(df::DataFrame; nquantiles=10)
    df = compute_Rshare(df)
    q = quantile(df.R_share, range(0, stop=1, length=nquantiles+1))
    rows = Vector{DataFrame}(undef, nquantiles)
    stats = DataFrame(q_low=Float64[], q_high=Float64[], meanP=Float64[], varP=Float64[])
    for i in 1:nquantiles
        mask = (df.R_share .>= q[i]) .& (df.R_share .< q[i+1])
        sub = df[mask, :]
        push!(stats, (q[i], q[i+1], mean(sub.P), var(sub.P)))
    end
    return stats
end

"""
Scenario simulation: change renewable share by pct (e.g., +0.2 for +20% share)
Run Monte Carlo repeats and return aggregated results.
"""
function scenario_simulation(;nrep=100, pct_increase=0.2, T=8760)
    results = DataFrame(meanP=Float64[], varP=Float64[], renew_share=Float64[])
    for r in 1:nrep
        df = synthetic_data(T=T, seed=1000 + r)
        df.R .= clamp.(df.R .* (1 + pct_increase), 0, df.D)
        df = merit_order_price(df)
        push!(results, (mean(df.P), var(df.P), mean(df.R ./ df.D)))
    end
    return results
end

"""
Example function to run GARCH on price series using ARCHModels.jl
"""
function fit_garch(df::DataFrame; price_col=:P)
    if !haskey(df, price_col)
        error("Price column $(price_col) not found in DataFrame")
    end
    p = df[!, price_col]
    # simple log-returns for volatility modeling
    r = log.(p .+ 1) .- log.(shift(p, 1) .+ 1)
    r = r[2:end]
    model = fit(ARCH{1,1}, r)
    return model
end

"""
Compute a volatility heatmap: rows = R_share quantiles, cols = hour-of-day
Returns matrix (nq x 24) of mean price variance within each quantile-hour cell
"""
function volatility_heatmap(df::DataFrame; nquantiles=10)
    df = compute_Rshare(df)
    df.hour = ((df.ts .- 1) .% 24) .+ 1
    qedges = quantile(df.R_share, range(0, stop=1, length=nquantiles+1))
    mat = zeros(nquantiles, 24)
    for i in 1:nquantiles
        for h in 1:24
            mask = (df.R_share .>= qedges[i]) .& (df.R_share .< qedges[i+1]) .& (df.hour .== h)
            sub = df[mask, :]
            mat[i, h] = isempty(sub.P) ? 0.0 : var(sub.P)
        end
    end
    return mat, qedges
end

"""
Run Monte Carlo comparisons for baseline and a scenario and produce summary DataFrame.
"""
function monte_carlo_compare(;nrep=200, pct_scenario=0.6, T=8760)
    base_means = Float64[]
    base_vars = Float64[]
    sc_means = Float64[]
    sc_vars = Float64[]
    for r in 1:nrep
        df = synthetic_data(T=T, seed=2000 + r)
        df = merit_order_price(df)
        push!(base_means, mean(df.P)); push!(base_vars, var(df.P))
        # scenario: set average renewable share to pct_scenario by scaling R
        df2 = deepcopy(df)
        # scale R to reach target mean share
        current_share = mean(df2.R ./ df2.D)
        factor = pct_scenario / (current_share + eps())
        df2.R .= clamp.(df2.R .* factor, 0, df2.D)
        df2 = merit_order_price(df2)
        push!(sc_means, mean(df2.P)); push!(sc_vars, var(df2.P))
    end
    results = DataFrame(base_mean=base_means, base_var=base_vars, sc_mean=sc_means, sc_var=sc_vars)
    return results
end

"""
Produce scenario plot comparing price distributions between baseline and a 60% renewables scenario.
"""
function scenario_plot(outfile::AbstractString; pct_target=0.6, nrep=200, T=8760)
    res = monte_carlo_compare(nrep=nrep, pct_scenario=pct_target, T=T)
    p1 = histogram(res.base_mean, bins=40, alpha=0.6, label="Baseline mean P", xlabel="Mean wholesale price", ylabel="Count", title="Monte Carlo: Mean Price")
    histogram!(p1, res.sc_mean, bins=40, alpha=0.6, label=string(pct_target*100, "% renew"))
    savefig(p1, outfile * "_mean_hist.png")
    p2 = histogram(res.base_var, bins=40, alpha=0.6, label="Baseline var P", xlabel="Variance wholesale price", ylabel="Count", title="Monte Carlo: Price Variance")
    histogram!(p2, res.sc_var, bins=40, alpha=0.6, label=string(pct_target*100, "% renew"))
    savefig(p2, outfile * "_var_hist.png")
    return res
end

"""
Plot tariff and price time series (useful for pass-through visualisation)
"""
function plot_tariff_timeseries(df::DataFrame; price_col=:P, tariff_col=:T, outfile="results/price_tariff_timeseries.png")
    if !(string(price_col) in string.(names(df))) || !(string(tariff_col) in string.(names(df)))
        error("Price or tariff column missing in DataFrame")
    end
    t = df.ts
    p = df[!, price_col]
    T = df[!, tariff_col]
    plt = plot(t, p, label="Wholesale Price", xlabel="Time", ylabel="Price", legend=:topright)
    plot!(plt, t, T, label="Retail Tariff")
    savefig(plt, outfile)
    return outfile
end

end # module
