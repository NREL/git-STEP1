using JuMP
using GLPK

n = 5
capacity = 10.0
profit = [5.0, 3.0, 2.0, 7.0, 4.0]
weight = [2.0, 8.0, 4.0, 2.0, 5.0]

function solve_knapsack_problem(; profit::Vector{Float64},weight::Vector{Float64},capacity::Float64,)
    n = length(weight)
    # The profit and weight vectors must be of equal length.
    @assert length(profit) == n
    model = Model(GLPK.Optimizer)
    set_silent(model)
    @variable(model, x[1:n], Bin)
    #@variable(model, 0 <= x[1:n] <= 1000, Int)
    @objective(model, Max, profit' * x)
    @constraint(model, weight' * x <= capacity)
    optimize!(model)
    @assert termination_status(model) == OPTIMAL
    @assert primal_status(model) == FEASIBLE_POINT
    println("Objective is: ", objective_value(model))
    println("Solution is: ")
    for i in 1:n
        print("x[$i] = ", round(Int, value(x[i])))
        println(", c[$i]/w[$i] = ", profit[i]/weight[i])
    end
    chosen_items = [i for i in 1:n if value(x[i]) >= 0.5]
    return return chosen_items
end

solve_knapsack_problem(; profit=profit, weight=weight, capacity=capacity)