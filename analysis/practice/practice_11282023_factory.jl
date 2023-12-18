using JuMP
import CSV
import DataFrames
import StatsPlots
import GLPK

factories_filename = joinpath(@__DIR__, "factory_schedule_factories.txt");
print(read(factories_filename, String))

factory_df = CSV.read(
    factories_filename,
    DataFrames.DataFrame;
    delim = ' ',
    ignorerepeated = true,
)

demand_filename = joinpath(@__DIR__, "factory_schedule_demand.txt");

demand_df = CSV.read(
    demand_filename,
    DataFrames.DataFrame;
    delim = ' ',
    ignorerepeated = true,
)

function validate_data(
    demand_df::DataFrames.DataFrame,
    factory_df::DataFrames.DataFrame,
)
    # Minimum production must not exceed maximum production.
    @assert all(factory_df.min_production .<= factory_df.max_production)
    # Demand, minimum production, fixed costs, and variable costs must all be
    # non-negative.
    @assert all(demand_df.demand .>= 0)
    @assert all(factory_df.min_production .>= 0)
    @assert all(factory_df.fixed_cost .>= 0)
    @assert all(factory_df.variable_cost .>= 0)
    return
end

#validate_data(demand_df, factory_df)

#function solve_factory_scheduling(demand_df::DataFrames.DataFrame,factor_df::DataFrames.DataFrame)
#validate_data(demand_df, factory_df)
M, F = unique(factory_df.month), unique(factory_df.factory)
model = Model(GLPK.Optimizer)
set_silent(model)

# Variable: z_m,f is 1 if factory f runs in month m
@variable(model, z[M,F], Bin)

# Variable: x_m,f is units factory f produces in month m (Integer)
@variable(model, x[M,F], Int)

# Variable: unmet demand
@variable(model, delta[M] >= 0)

# Constraint: maximum production level
for r in eachrow(factory_df)
    m, f = r.month, r.factory
    @constraint(model, x[m,f] <= r.max_production * z[m,f])
    @constraint(model, x[m,f] >= r.min_production * z[m,f])
end

#for f in F
#    @constraint(model, [m in M], x[m,f] <= factory_df[factory_df.factory .== f].max_production[m] * z[m,f])
#end
# Constraint: unmet demand
@constraint(model, [m in M], sum(x[m,f] for f in F) + delta[m] == demand_df.demand[m])
#end

@objective(
        model,
        Min,
        10 * sum(delta) + sum(
            r.fixed_cost * z[r.month, r.factory] +
            r.variable_cost * x[r.month, r.factory] for
            r in eachrow(factory_df)
        )
    )
optimize!(model)
schedules = Dict{Symbol,Vector{Float64}}(
    Symbol(f) => value.(x[:, f]) for f in F
)
schedules[:delta] = value.(delta)

#termination_status = termination_status(model)
cost = objective_value(model)
# This `select` statement re-orders the columns in the DataFrame.
schedules = DataFrames.select(
            DataFrames.DataFrame(schedules),
            [:delta, :A, :B]
        )

## Plot results
StatsPlots.groupedbar(
    Matrix(schedules),
    bar_position = :stack,
    labels = ["Unmet Demand","A","B"],
    xlabel = "Month",
    ylabel = "Production",
    legend = :topleft
)