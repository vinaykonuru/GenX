# thermal storage for DAC facility, different from asymmetric storage because all output from the storage goes to the DAC
# doesn't incorporate into the general charge balance

# CONSTANTS
# Eff_Down = 0.92
# Eff_Up = 0.92
# eTotalCapEnergy = capacity = 4MW
# eTotalCap = max power discharge
# cost per unit capacity

# to do:
# find MW to MMBTU conversion for TES, multiply this constant for all vCHARGE
# WRAP AROUND CONSTRAINT FOR TES CHARGE
function dac_TES!(EP::Model, inputs::Dict, setup::Dict)
	println("DAC TES Module")

    dfGen = inputs["dfGen"]
	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
	DAC_TES = inputs["DAC_TES"] # DAC_ID of DAC sites with TES
	STOR_TES = inputs["STOR_TES"] # R_ID of TES storage sites from generators_data, ASSIGN A DAC_ID TO THE TES IN GENERATORS

	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]

	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod
	MMBTU_per_MW_conversion = 3.412 # assumes 100% efficiency
	### Variables ###
	# New installed energy capacity of resource "y"
	@variable(EP, vCAPENERGY_TES[y in DAC_TES] >= 0) # units of MMBTU
	println("test 0")
	# New installed charge capacity of resource "y"
	@variable(EP, vCAPCHARGE_TES[y in DAC_TES] >= 0) # units of MWh/Hr
	println("test 0.1")

	# Storage level of resource "y" at hour "t" [MWh] on zone "z" - unbounded
	@variable(EP, vS_TES[y in DAC_TES, t=1:T] >= 0);
	println("test 0.2")

	# Energy withdrawn from grid by resource "y" at hour "t" [MWh] on zone "z"
	@variable(EP, vCHARGE_TES[y in DAC_TES, t=1:T] >= 0);
	println("test 0.3")

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
		(dfGen[dfGen.DAC_ID.==y,:Inv_Cost_per_MWhyr][1]+ dfGen[dfGen.DAC_ID.==y,:Fixed_OM_Cost_per_MWhyr][1])*vCAPENERGY_TES[y])
	println("test 0.8")
	@expression(EP, eTotalCFixEnergy_TES, sum(eCFixEnergy_TES[y] for y in DAC_TES))
	println("test1")

	# Costs for power
	@expression(EP, eCFixCharge_TES[y in DAC_TES],
	(dfGen[dfGen.DAC_ID.==y,:Inv_Cost_per_MWyr][1] + dfGen[dfGen.DAC_ID.==y,:Fixed_OM_Cost_per_MWyr][1])*vCAPENERGY_TES[y])
	println("test 1.1")
	@expression(EP, eTotalCFixCharge_TES, sum(eCFixCharge_TES[y] for y in DAC_TES))
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
		vS_TES[y,t+hours_per_subperiod-1] - (1/dfGen[dfGen.DAC_ID.==y,:Eff_Down][1])*EP[:eDAC_heat][y,t] + 
		1/dfGen[dfGen.DAC_ID.==y,:Eff_Up][1]*eCHARGE_TES_HEAT[y,t] - dfGen[dfGen.DAC_ID.==y,:Self_Disch][1]*vS_TES[y,t+hours_per_subperiod-1]
	)
	println("test 1.4")
	# SOC INTERIOR
	@constraint(EP, cSoCBalInterior_TES[t in INTERIOR_SUBPERIODS, y in DAC_TES], vS_TES[y,t] ==
	vS_TES[y,t-1] - 1/dfGen[dfGen.DAC_ID.==y,:Eff_Down][1]*EP[:eDAC_heat][y,t] + 
	dfGen[dfGen.DAC_ID.==y,:Eff_Up][1]*eCHARGE_TES_HEAT[y,t] - dfGen[dfGen.DAC_ID.==y,:Self_Disch][1]*vS_TES[y,t-1]
	)
	println("test 2")
	# Maximum energy stored must be less than energy capacity
	@constraint(EP, cMaxEnergyCapacity_TES[y in DAC_TES, t in 1:T], vS_TES[y,t] <= vCAPENERGY_TES[y])
	println("test 2.1")
	# Assume charge and discharge are symmetric for now

	# charge rate <= max charge
	@constraint(EP, cMaxEnergyCharge_TES[y in DAC_TES, t in 1:T], vCHARGE_TES[y,t] <= vCAPCHARGE_TES[y])
	println("test 2.2")
	# discharge rate <= max charge
	@constraint(EP, cMaxEnergyDischarge_TES[y in DAC_TES, t in 1:T], EP[:eDAC_heat][y,t] / MMBTU_per_MW_conversion <= vCAPCHARGE_TES[y])
	println("test 2.3")
	# charge + discharge rate <= max charge
	@constraint(EP, cMaxEnergyTotal_TES[y in DAC_TES, t in 1:T], EP[:eDAC_heat][y,t] / MMBTU_per_MW_conversion + vCHARGE_TES[y,t] <= vCAPCHARGE_TES[y])
	println("test 2.4")

	# # Storage discharge and charge power (and reserve contribution) related constraints:
	# if Reserves == 1
	# 	storage_all_reserves!(EP, inputs)
	# else
	# 	# Note: maximum charge rate is also constrained by maximum charge power capacity, but as this differs by storage type,
	# 	# this constraint is set in functions below for each storage type

	# 	# Maximum discharging rate must be less than power rating OR available stored energy in the prior period, whichever is less
	# 	# wrapping from end of sample period to start of sample period for energy capacity constraint
	# 	@constraints(EP, begin
	# 		[y in DAC_TES, t=1:T], EP[:vP][y,t] <= EP[:eTotalCap][y]
	# 		[y in DAC_TES, t=1:T], EP[:vP][y,t] <= vS_TES[y, hoursbefore(hours_per_subperiod,t,1)]*dfGen[y,:Eff_Down]
	# 	end)
	# end
	#From co2 Policy module
	# @expression(EP, eELOSSByZone[z=1:Z],
	# 	sum(EP[:eELOSS][y] for y in intersect(DAC_TES, dfGen[dfGen[!,:Zone].==z,:R_ID]))
	# )
	# power balance:


	println("test 3")
end