using CSV
using DataFrames

# Base directory
base_dir = dirname(@__FILE__)
DAC_eff_and_cost = DataFrame(
    case_name = String[],
    TES_stor_cap_cost = Float64[],
    TES_charge_cap_cost = Float64[],
    TES_discharge_cap_cost = Float64[],
    TES_stor_cap = Float64[],
    TES_charge_cap = Float64[],
    TES_fixed_costs = Float64[],
    total_TES_charge_costs = Float64[],
    total_hp_power_costs = Float64[],
    total_DAC_TES_costs = Float64[],
    system_emissions_reduction = Float64[],
    cost_of_capture = Float64[],
    cost_of_effective_capture = Float64[],
    DAC_efficiency = Float64[]
)
MMBTU_per_MWh_conversion = 3.412
# Iterate over all items in the base directory
for item in readdir(base_dir)
    # Construct the full path to the item
    item_path = joinpath(base_dir, item)
    
    # Check if the item is a directory
    if isdir(item_path)
        # Construct the path to the target files in the directory
        soln_path = joinpath(item_path, "solution.csv")
        emissions_path = joinpath(item_path, "emissions.csv")
        prices_path = joinpath(item_path, "prices.csv")
        DAC_path = joinpath(item_path, "Dac_costs.csv")
        
        emissions_df = CSV.read(emissions_path,DataFrame)
        system_emissions = emissions_df[1,"1"] # total emissions in zone 1
        baseline_emissions = 7.83224 * 10^7
        DAC_CO2_captured = 10^6
        system_emissions_reduction = baseline_emissions - (system_emissions - DAC_CO2_captured)

        soln_df = CSV.read(soln_path, DataFrame)
        TES_charge_row = findfirst(soln_df.name .== ["vCHARGE[1,1]"])
        TES_charge_data = soln_df[TES_charge_row:TES_charge_row + 8759,:]
        CSV.write(joinpath(item_path,"TES_charge_data"),TES_charge_data)
        TES_charge_data = TES_charge_data[:, "value"]

        DAC_hp_row = findfirst(soln_df.name .== ["vDAC_elec_heat[1,1]"])
        DAC_hp_data = soln_df[DAC_hp_row:DAC_hp_row + 8759,:]
        CSV.write(joinpath(item_path,"DAC_hp_data"),DAC_hp_data)
        DAC_hp_data = DAC_hp_data[:,"value"]
        
        DAC_costs_df = CSV.read(DAC_path, DataFrame)
        DAC_fix_costs = DAC_costs_df[1,"Total"]

        price_df = CSV.read(prices_path, DataFrame)
        price_data = price_df[:,"1"]

        TES_stor_cap_row = findfirst(soln_df.name .== ["vCAPENERGY_TES[1]"])
        TES_charge_cap_row = findfirst(soln_df.name .== ["vCAPCHARGE_TES[1]"])
        TES_discharge_cap_row = findfirst(soln_df.name .== ["vCAPDISCHARGE_TES[1]"])
        TES_stor_cap = soln_df[TES_stor_cap_row, "value"]
        TES_charge_cap = soln_df[TES_charge_cap_row, "value"]
        TES_discharge_cap = soln_df[TES_discharge_cap_row, "value"]
        
        TES_discharge_cap_cost = 0
        parts = split(item, "_")
        TES_charge_cap_cost = parse(Int, parts[2])
        TES_stor_cap_cost = parse(Int, parts[4])

        TES_fixed_costs = TES_stor_cap * TES_stor_cap_cost + TES_charge_cap * TES_charge_cap_cost + TES_discharge_cap * TES_discharge_cap_cost
        total_TES_charge_costs = sum(TES_charge_data .* price_data)
        total_hp_power_costs = sum(DAC_hp_data .* price_data)
        
        total_DAC_TES_costs = DAC_fix_costs + TES_fixed_costs + total_TES_charge_costs + total_TES_charge_costs + total_hp_power_costs
        cost_of_capture = total_DAC_TES_costs / DAC_CO2_captured
        cost_of_effective_capture = total_DAC_TES_costs / system_emissions_reduction
        DAC_efficiency = system_emissions_reduction / DAC_CO2_captured

        push!(DAC_eff_and_cost, (
            item,
            TES_stor_cap_cost, 
            TES_charge_cap_cost,
            TES_discharge_cap_cost,
            TES_stor_cap,
            TES_charge_cap, 
            TES_fixed_costs, 
            total_TES_charge_costs, 
            total_hp_power_costs, 
            total_DAC_TES_costs,
            system_emissions_reduction, 
            cost_of_capture, 
            cost_of_effective_capture, 
            DAC_efficiency))
    end
end
CSV.write(joinpath(base_dir,"DAC_efficiency_and_costs.csv"),DAC_eff_and_cost)