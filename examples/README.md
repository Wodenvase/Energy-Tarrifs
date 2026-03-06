Examples and quick runs
=======================

1) Baseline synthetic run

```bash
julia --project=. scripts/simulate.jl
julia --project=. scripts/analysis.jl
```

2) Run scenario (+20% renewables) in REPL

```julia
using Pkg; Pkg.activate(".")
using ET
res = ET.scenario_simulation(nrep=200, pct_increase=0.2)
CSV.write("results/scenario_20pct.csv", res)
```

3) Fit GARCH on the output series

```julia
using ET, CSV
df = CSV.read("results/synthetic_prices.csv", DataFrame)
model = ET.fit_garch(df)
println(model)
```
