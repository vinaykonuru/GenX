using JuMP, MathOptInterface,CSV,Gurobi


# Load the model from the file
model = read_from_file( "C:\\Users\\Vinay Konuru\\Documents\\Thesis\\GenX\\ERCOT_input_files\\Results\\saved_model.mps")
set_optimizer(model, Gurobi.Optimizer)
# Extract the variable values
var_values = Dict{Symbol, Any}()
println("test 1")
x = all_variables(model)
println("test 2")
println(value.(variable_by_name(model,"vS_TES[1,1]")))
# df = DataFrame(
#     name = name.(x),
#     value = value.(x),
# )
println("test 3")
# CSV.write(joinpath(@__FILE__,"all_variables.csv"), dfTES_DAC)