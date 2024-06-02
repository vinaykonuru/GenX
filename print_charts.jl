println("test")
using CSV
println("test 1")
using DataFrames
println("test 2")
using Plots
gr()
# Step 1: Read the CSV file
println("test")
data_price = CSV.read("C:\\Users\\Vinay Konuru\\Documents\\Thesis\\GenX\\ERCOT_input_files\\Case_Results\\DACTESGRID_HP2\\prices.csv", DataFrame)
# data_charge = CSV.read("C:\\Users\\Vinay Konuru\\Documents\\Thesis\\GenX\\ERCOT_input_files\\Case_Results\\Real_Costs_DACTESGRID_HP2\\TES_charge.csv", DataFrame)
data_SOC = CSV.read("C:\\Users\\Vinay Konuru\\Documents\\Thesis\\GenX\\ERCOT_input_files\\Case_Results\\DACTESGRID_HP2\\TES_soc.csv", DataFrame)
data_grid_heat = CSV.read("C:\\Users\\Vinay Konuru\\Documents\\Thesis\\GenX\\ERCOT_input_files\\Case_Results\\DACTESGRID_HP2\\DAC_grid_heat.csv", DataFrame)

# Step 2: Assume there's a column named "hourly_price" in the datas
hourly_prices = data_price[1:2:240, "1"]
# hourly_charge = data_charge[1:2:240, "Charge"]
hourly_SOC = data_SOC[1:2:240, "SOC"]
hourly_heat_grid = data_grid_heat[1:2:240, "Heat"]
# Step 3: Create a histogram
println("test")
p1=plot(hourly_prices, xlabel="Time", ylabel="Price(\$/MWh)", title="Power Pricing",label="Price(\$/MWh)")
# p2=plot(hourly_charge, xlabel="Time", ylabel="Charging(MWh)", title="TES Charge",label="Charge(Mwh)")
p3=plot(hourly_SOC, xlabel="Time", ylabel="SOC(MMBTU)", title="TES SoC",label="SoC(MMBTU)")
p4=plot(hourly_heat_grid, xlabel="Time", ylabel="Heat_Grid(MW)", title="DAC Heat Demand from Grid",label="Heat from Grid (MW)")

# Stack the two plots
plot(p1, p3, p4, layout = (3, 1), size = (600, 600))