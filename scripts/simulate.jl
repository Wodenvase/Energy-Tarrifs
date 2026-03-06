#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using ET
using CSV
using DataFrames

# Simple script to run a base synthetic simulation and write outputs
function main()
    df = ET.synthetic_data(T=8760, seed=123, renew_mean_share=0.45)
    df = ET.merit_order_price(df)
    df = ET.compute_Rshare(df)
    CSV.write("results/synthetic_prices.csv", df)
    println("Wrote results/synthetic_prices.csv")
end

main()
