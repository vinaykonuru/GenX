using Plots
using CSV
using DataFrames
using StatsBase
# storage = 500:1100
# charge = 3000:6000
basepath = dirname(@__FILE__)
DAC_dnalysis_path = joinpath(basepath, "DAC_efficiency_and_costs.csv")
DAC_analysis_df = CSV.read(DAC_dnalysis_path, DataFrame)
DAC_eff_data = DAC_analysis_df[:,["TES_stor_cap_cost","TES_charge_cap_cost", "cost_of_effective_capture"]]
# DAC_eff_data = convert(Matrix, DAC_eff_data)
x_values = sort!(unique(DAC_analysis_df[!, "TES_stor_cap_cost"]))
y_values = sort!(unique(DAC_analysis_df[!, "TES_charge_cap_cost"]))
# x_values = filter(x -> 500 <= x <= 1000, x_values)
# y_values = filter(y -> 3000 <= y <= 6000, y_values)

println(x_values)
z_values = Matrix{Float64}(undef, length(y_values), length(x_values))
for (i, y) in enumerate(y_values)
    for (j, x) in enumerate(x_values)
        mask = (DAC_analysis_df[!, "TES_stor_cap_cost"] .== x) .& (DAC_analysis_df[!, "TES_charge_cap_cost"] .== y)
        # gets the DAC_efficiency that corresponds with a given (TES_charge, TES_stor) cost pair
        z_values[i, j] = mean(DAC_analysis_df[mask, "cost_of_capture"])
    end
end
x_values = x_values ./ (0.0899 * 1000) .* 3.412 # $/kWh
y_values = y_values ./ (0.0899 * 1000) # $/kW

gr()
color_scheme = cgrad(:thermal, rev = false)
plot = heatmap(x_values, y_values, z_values, color=color_scheme, 
    xlabel="Storage Capacity Cost (\$/kWh)", ylabel="Charge Capacity Cost(\$/kW)",
    title = "TES DAC System Cost of Capture (\$/tCO2)")
display(plot)
println("success")
readline()