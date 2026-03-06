#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using ET
using CSV, DataFrames, Plots, GLM

function main()
    df = CSV.read("results/synthetic_prices.csv", DataFrame)
    df = ET.compute_Rshare(df)
    stats = ET.volatility_stats(df, nquantiles=10)
    CSV.write("results/volatility_by_renewable_quantile.csv", stats)
    println("Wrote results/volatility_by_renewable_quantile.csv")
    # Simple pass-through estimation: create synthetic tariff for demo
    α_true = 0.6
    β_true = 10.0
    df.T = α_true .* df.P .+ β_true .+ 0.5 .* randn(nrow(df))
    model = ET.estimate_pass_through(df, tariff_col=:T, price_col=:P)
    println(coef(model))
    # Plot mean price vs R_share scatter
    scatter(df.R_share, df.P, alpha=0.3, xlabel="R_share", ylabel="Wholesale Price", title="Price vs Renewable Share")
    savefig("results/price_vs_renew_share.png")
    println("Saved results/price_vs_renew_share.png")
end

main()
