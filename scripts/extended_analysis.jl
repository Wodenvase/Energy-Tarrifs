#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using ET
using CSV, DataFrames, Plots

function main()
    # Read base synthetic results (or regenerate)
    if !isfile("results/synthetic_prices.csv")
        println("Running simulate.jl to generate base data...")
        run(`julia --project=. scripts/simulate.jl`)
    end
    df = CSV.read("results/synthetic_prices.csv", DataFrame)
    df = ET.compute_Rshare(df)

    # Volatility heatmap
    mat, qedges = ET.volatility_heatmap(df, nquantiles=12)
    heatmap(mat, xlabel="Hour of day", ylabel="R_share quantile", title="Price variance by R_share quantile & hour")
    savefig("results/volatility_heatmap.png")
    println("Saved results/volatility_heatmap.png")

    # Scenario 60% renewables plots
    res = ET.scenario_plot("results/scenario_60", pct_target=0.6, nrep=200)
    CSV.write("results/scenario_60_mc.csv", res)
    println("Saved Monte Carlo scenario results and plots for 60% renewables")

    # Monte Carlo comparison summary
    comp = ET.monte_carlo_compare(nrep=300, pct_scenario=0.6)
    CSV.write("results/monte_carlo_compare_60.csv", comp)
    println("Saved results/monte_carlo_compare_60.csv")

    # Extra visualisations: overlayed density for baseline vs scenario mean prices
    plt = histogram(comp.base_mean, bins=40, alpha=0.6, label="Baseline", xlabel="Mean price", ylabel="Count", title="Mean price: baseline vs 60% renewables")
    histogram!(plt, comp.sc_mean, bins=40, alpha=0.6, label="60% Renew")
    savefig("results/mean_price_density_60.png")
    println("Saved results/mean_price_density_60.png")

    # Tariff timeseries example: create synthetic tariff and plot
    α_true = 0.6
    β_true = 10.0
    df.T = α_true .* df.P .+ β_true .+ 0.5 .* randn(nrow(df))
    ET.plot_tariff_timeseries(df, price_col=:P, tariff_col=:T, outfile="results/price_tariff_timeseries.png")
    println("Saved results/price_tariff_timeseries.png")
end

main()
