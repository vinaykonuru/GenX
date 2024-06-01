"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
	write_capacity(path::AbstractString, inputs::Dict, setup::Dict, EP::Model))

Function for writing the diferent capacities for the different generation technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_dac_capacity(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    # scale factor
	scale_factor = setup["ParameterScale"] == 1 ? ModelScalingFactor : 1
	# Capacity decisions
	dfDac = inputs["dfDac"]
	#MultiStage = setup["MultiStage"]
	NEW_CAP = dfDac[dfDac[!,:NEW_CAP] .==1,:R_ID]
	TES = inputs["DAC_TES"]
	DAC_COMMIT = dfDac[dfDac[!,:DAC_COMMIT] .==1,:R_ID]
	capdDac = zeros(size(dfDac[!,:Resource]))
	for i in  NEW_CAP
		capdDac[i] = value(EP[:vCAP_DAC][i])
		println("CAPACITY OF DAC")
		println(value(EP[:vCAP_DAC][i]))
	end

	dfCapDac = DataFrame(
		Resource = dfDac[!,:Resource],
		Zone = dfDac[!,:Zone],
		StartCap = dfDac[!,:Existing_Cap_CO2],
		NewCap = capdDac[:],
		EndCap = capdDac[:] + dfDac[!,:Existing_Cap_CO2]
	)

	dfCapDac.StartCap = dfCapDac.StartCap * scale_factor
	dfCapDac.NewCap = dfCapDac.NewCap * scale_factor
	dfCapDac.EndCap = dfCapDac.EndCap * scale_factor

	CSV.write(joinpath(path, "capacity_dac.csv"), dfCapDac)
	# TES_capacity = zeros(size(dfDac[!,:Resource]))
	# TES_charge_max = zeros(size(dfDac[!,:Resource]))
	# println(value.(EP[:vCAPENERGY_TES][1]))
	# println(TES)
	# for i in TES
	# 	TES_capacity[i] = value(EP[:vCAPENERGY_TES][i])
	# 	TES_charge_max[i] = value(EP[:vCAPCHARGE_TES][i])
	# end

	# TES_SOC = value.(EP[:vS_TES])
	# TES_CHARGE = value.(EP[:eCHARGE_TES_HEAT])
	# TES_DISCHARGE = value.(EP[:eDAC_heat])
	# println(typeof(TES_SOC))
	# println(typeof(TES_CHARGE))
	# println(typeof(TES_DISCHARGE))

	# println("TES SOC")
	# keys_SOC = collect(keys(TES_SOC))
	# values_SOC = [TES_SOC[k] for k in keys(TES_SOC)]
	# dim1_TES_SOC = [k[1] for k in keys_SOC]
	# dim2_TES_SOC = [k[2] for k in keys_SOC]
	# TES_SOC_df = DataFrame(
	# 	Resource = dim1_TES_SOC,
	# 	Zone = dim2_TES_SOC,
	# 	SOC = values_SOC
	# )
	# println("TES CHARGE")
	# keys_TES_CHARGE = collect(keys(TES_CHARGE))
	# values_TES_CHARGE = [TES_CHARGE[k] for k in keys(TES_CHARGE)]
	# dim1_TES_CHARGE = [k[1] for k in keys_TES_CHARGE]
	# dim2_TES_CHARGE = [k[2] for k in keys_TES_CHARGE]
	# TES_CHARGE_df = DataFrame(
	# 	Resource = dim1_TES_CHARGE,
	# 	Zone = dim2_TES_CHARGE,
	# 	CHARGE = values_TES_CHARGE
	# )


	# println("TES DISCHARGE")
	# keys_TES_DISCHARGE = collect(keys(TES_DISCHARGE))
	# values_TES_DISCHARGE = [TES_CHARGE[k] for k in keys(TES_CHARGE)]
	# dim1_TES_DISCHARGE = [k[1] for k in keys_TES_DISCHARGE]
	# dim2_TES_DISCHARGE = [k[2] for k in keys_TES_DISCHARGE]
	# TES_DISCHARGE_df = DataFrame(
	# 	Resource = dim1_TES_DISCHARGE,
	# 	Zone = dim2_TES_DISCHARGE,
	# 	CHARGE = values_TES_DISCHARGE
	# )

	# CSV.write(joinpath(path, "tes_SOC.csv"), TES_SOC_df)
	# CSV.write(joinpath(path, "tes_charge.csv"), TES_CHARGE_df)
	# CSV.write(joinpath(path, "tes_discharge.csv"), TES_DISCHARGE_df)

	# dfTES_DAC = DataFrame(
	# 	Resource = dfDac[!, :Resource],
	# 	Zone = dfDac[!, :Zone],
	# 	TES_Capacity = TES_capacity,
	# 	TES_Charge = TES_charge_max
	# )
	# dfTES_DAC.TES_Capacity .* scale_factor
	# dfTES_DAC.TES_Charge .* scale_factor

	# CSV.write(joinpath(path, "capacity_tes_dac.csv"), dfTES_DAC)

    # write the dual capex cost if fix cost = 0
	#CapexDAC = zeros(size(dfDac[!,:Resource]))

	# if !isempty(dual.(EP[:cDACCapacity]))
	# 	for i in NEW_CAP
	# 	    CapexDAC[i] = dual.(EP[:cDACCapacity])*scale_factor
	#     end
	# end

	# if !isempty(dual.(EP[:cDAC_removal]))
	# 	for i in NEW_CAP
	# 	    CostsDAC[i] = dual.(EP[:cDAC_removal])*scale_factor
	#     end
	# end

	# dfCostDac = DataFrame(
	# 	Resource = dfDac[!,:Resource],
	# 	Zone = dfDac[!,:Zone],
	# 	CostDAC = -CapexDac[:]
	# )

	# if 0 in dfDac.Fix_Cost_per_tCO2_yr
	# 	CSV.write(joinpath(path, "costs_dual_dac.csv"), dfCostDac)
	# end


	# write dac cost

	dfDac = inputs["dfDac"]
    # Number of time steps (hours)

	# dfCost = DataFrame(Costs = ["cTotal", "cFix", "cFix_Energy", "cVar", "cCO2_seq", "cCO2_tax"])
	# removing cVar for now until I know what to put for fuel costs
	dfCost = DataFrame(Costs = ["cTotal", "cFix", "cFix_Energy", "cCO2_seq"])

	cVar = (!isempty(inputs["dfDac"]) ? value(EP[:eCTotalVariableDAC])*scale_factor^2 : 0.0)
	cFix = (!isempty(inputs["dfDac"]) ? value(EP[:eTotalCFixedDAC])*scale_factor^2 : 0.0)
	cFix_E = (!isempty(inputs["dfDac"]) ? value(EP[:eTotalCFixedDAC_Energy])*scale_factor^2 : 0.0)
    cCO2_seq =  (!isempty(inputs["dfDac"]) ? value(EP[:eCTotalCO2TS])*scale_factor^2 : 0.0)


	# cCO2_tax =  ((setup["CO2Tax"]  > 0)  ? value.(EP[:eTotalCCO2TaxDAC])*scale_factor^2 : 0)

	cDacTotal = 0 
	cDacTotal += (cFix + cFix_E+ cCO2_seq)

	dfCost[!,Symbol("Total")] = [cDacTotal, cFix, cFix_E, cCO2_seq]

	CSV.write(joinpath(path, "Dac_costs.csv"), dfCost)
	# save all variables for debugging
	x = all_variables(EP)
	# all_vars = DataFrame(name = variable_name.(x), Value = value.(x))
	# CSV.write(joinpath(path, "all_vars.csv"), all_vars)
end