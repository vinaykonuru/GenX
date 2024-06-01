# thermal storage for DAC facility, different from asymmetric storage because all output from the storage goes to the DAC
# doesn't incorporate into the general charge balance


function dac_TES!(EP::Model, inputs::Dict, setup::Dict)
	println("DAC TES Module")

    dfGen = inputs["dfGen"]
	dfDac = inputs["dfDac"]

	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	max_charge_rate = 4000 #MW
	DAC_TES = inputs["DAC_TES"] # DAC_ID of DAC sites with TES
	STOR_TES = inputs["STOR_TES"] # R_ID of TES storage sites from generators_data, ASSIGN A DAC_ID TO THE TES IN GENERATORS

	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]

	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod
	efficiency_TES = 0.7 # efficiency of TES
	MMBTU_per_MW_conversion = 3.412 * efficiency_TES
	### Variables ###
	# New installed energy capacity of resource "y"
	@variable(EP, vCAPENERGY_TES[y in DAC_TES] >= 0) # units of MMBTU
	println("test 0")
	# New installed charge capacity of resource "y"
	@variable(EP, vCAPCHARGE_TES[y in DAC_TES] >= 0) # units of MWh/Hr
	println("test 0.1")
	@variable(EP, vCAPDISCHARGE_TES[y in DAC_TES] >= 0) # units of MWh/Hr

	# Storage level of resource "y" at hour "t" [MWh] on zone "z" - unbounded
	@variable(EP, vS_TES[y in DAC_TES, t=1:T] >= 0);
	println("test 0.2")

	# Energy withdrawn from grid by resource "y" at hour "t" [MWh] on zone "z"
	@variable(EP, vCHARGE_TES[y in DAC_TES, t=1:T] >= 0);
	println("test 0.3")
	@variable(EP, vOUT_TES[y in DAC_TES, t=1:T] >= 0);

	### Expressions ###
	# Losses - vDacpower gives the output of the TES (not taking into account for now)
	# @expression(EP, eELOSS[y in DAC_TES], sum(inputs["omega"][t]*vCHARGE_TES[y,t] for t in 1:T) - sum(inputs["omega"][t]*EP[:eDAC_heat]) for t in 1:T)

	# represent the charging at any hour in units of heat for the TES
	@expression(EP, eCHARGE_TES_HEAT[y in DAC_TES, t=1:T], vCHARGE_TES[y,t] * MMBTU_per_MW_conversion)
	println("test 0.4")

	# COSTS
	# Variable costs of "charging" for technologies "y" during hour "t" in zone "z"
	@expression(EP, eCVar_in_TES[y in DAC_TES,t=1:T], inputs["omega"][t]*dfGen[dfGen.DAC_ID.==y,:Var_OM_Cost_per_MWh_In][1]*vCHARGE_TES[y,t])
	println("test 0.5")

	@expression(EP, eTotalCVarInT_TES[t=1:T], sum(eCVar_in_TES[y,t] for y in DAC_TES))
	@expression(EP, eTotalCVarIn_TES, sum(eTotalCVarInT_TES[t] for t in 1:T))
	println(typeof(eTotalCVarIn_TES))

	EP[:eObj] += sum(eTotalCVarIn_TES)

	# Costs for capacity
	@expression(EP, eCFixEnergy_TES[y in DAC_TES],
		(dfGen[dfGen.DAC_ID.==y,:Inv_Cost_per_MWhyr][1]+ dfGen[dfGen.DAC_ID.==y,:CAPEX_per_MWh_yr][1])*vCAPENERGY_TES[y])
	println("test 0.8")
	@expression(EP, eTotalCFixEnergy_TES, sum(eCFixEnergy_TES[y] for y in DAC_TES))
	println("test1")

	# Costs for max charging rate
	@expression(EP, eCFixCharge_TES[y in DAC_TES],
	(dfGen[dfGen.DAC_ID.==y,:Inv_Cost_per_MWyr][1] + dfGen[dfGen.DAC_ID.==y,:CAPEX_per_MW_Charge_yr][1])*vCAPCHARGE_TES[y])
	# Costs for max discharging rate
	@expression(EP, eCFixDischarge_TES[y in DAC_TES],
	(dfGen[dfGen.DAC_ID.==y,:Inv_Cost_per_MWyr][1] + dfGen[dfGen.DAC_ID.==y,:CAPEX_per_MW_Discharge_yr][1])*vCAPDISCHARGE_TES[y])
	println("test 1.1")

	@expression(EP, eTotalCFixCharge_TES, sum(eCFixCharge_TES[y] + eCFixDischarge_TES[y] for y in DAC_TES))
	# add total TES costs to objective
	println("test 1.2")

	EP[:eObj] += (sum(eTotalCFixEnergy_TES) + sum(eTotalCFixCharge_TES))
	println("test 1.3")


	### Constraints ###

	## Storage energy capacity and state of charge related constraints:

	# Links state of charge in first time step with decisions in last time step of each subperiod
	# We use a modified formulation of this constraint (cSoCBalLongDurationStorageStart) when operations wrapping and long duration storage are being modeled

	# SOC WITH WRAPPING
	println(typeof(dfGen[dfGen.DAC_ID.==1,:Eff_Down]))
	println(typeof(dfGen[dfGen.DAC_ID.==1,:Eff_Down][1]))

	println(dfGen[dfGen.DAC_ID.==1,:Eff_Down][1])
	@constraint(EP, cSoCBalStart_TES[t in START_SUBPERIODS, y in DAC_TES], vS_TES[y,t] ==
		vS_TES[y,t+hours_per_subperiod-1] - 1/dfGen[dfGen.DAC_ID.==y,:Eff_Down][1]*vOUT_TES[y,t] + 
		1/dfGen[dfGen.DAC_ID.==y,:Eff_Up][1]*eCHARGE_TES_HEAT[y,t] - dfGen[dfGen.DAC_ID.==y,:Self_Disch][1]*vS_TES[y,t+hours_per_subperiod-1]	
	)
	
	println("test 1.4")
	# SOC INTERIOR
	@constraint(EP, cSoCBalInterior_TES[t in INTERIOR_SUBPERIODS, y in DAC_TES], vS_TES[y,t] ==
	vS_TES[y,t-1] - 1/dfGen[dfGen.DAC_ID.==y,:Eff_Down][1]*vOUT_TES[y,t] + 
	1/dfGen[dfGen.DAC_ID.==y,:Eff_Up][1]*eCHARGE_TES_HEAT[y,t] - dfGen[dfGen.DAC_ID.==y,:Self_Disch][1]*vS_TES[y,t-1]
	)

	println("test 2")
	# Maximum energy stored must be less than energy capacity
	@constraint(EP, cMaxEnergyCapacity_TES[y in DAC_TES, t in 1:T], vS_TES[y,t] <= vCAPENERGY_TES[y])
	println("test 2.1")

	@constraint(EP, cHeatBalance[y in DAC_TES, t in 1:T], vOUT_TES[y,t] <= vS_TES[y,hoursbefore(hours_per_subperiod,t,1)])

	# charge rate <= max charge
	@constraint(EP, cMaxEnergyCharge_TES[y in DAC_TES, t in 1:T], vCHARGE_TES[y,t] <= vCAPCHARGE_TES[y])
	println("test 2.2")

	# discharge rate <= max discharge (units of MW)
	@constraint(EP, cMaxEnergyDischarge_TES[y in DAC_TES, t in 1:T], vOUT_TES[y,t] / MMBTU_per_MW_conversion <= vCAPDISCHARGE_TES[y])
	println("test 2.3")

	# charging capacity of the TES can't exceed the max charge rate, makes no difference because optimal charge cap at 2233MW
	# @constraint(EP, cMaxChargeRate_TES[y in DAC_TES], vCAPCHARGE_TES[y] <= max_charge_rate)

    @expression(EP, ePowerBalanceDAC_TES[t=1:T, z=1:Z], sum(vCHARGE_TES[y,t] for y in (dfDac[dfDac[!,:Zone].==z,:][!,:DAC_ID])))
	EP[:ePowerBalance] -= (ePowerBalanceDAC_TES)

	println("test 3")
end