using JuMP
import GLPK
import JSON

data = JSON.parse("""
{
    "plants": {
        "Seattle": {"capacity": 350},
        "San-Diego": {"capacity": 600}
    },
    "markets": {
        "New-York": {"demand": 300},
        "Chicago": {"demand": 300},
        "Topeka": {"demand": 300}
    },
    "distances": {
        "Seattle => New-York": 2.5,
        "Seattle => Chicago": 1.7,
        "Seattle => Topeka": 1.8,
        "San-Diego => New-York": 2.5,
        "San-Diego => Chicago": 1.8,
        "San-Diego => Topeka": 1.4
    }
}
""")

### Create sets
P = keys(data["plants"])
M = keys(data["markets"])

distance(p::String, m::String) = data["distances"]["$(p) => $(m)"]

### Create model
model = Model(GLPK.Optimizer)

# Decision variable is indexed over the set of plants and markets
@variable(model, x[P,M] >= 0)

# Constraint: Plant can ship no more than its capacity
@constraint(model, [p in P], sum(x[p,:]) <= data["plants"][p]["capacity"])

# Constraint: Each market must receive at least its demand
@constraint(model, [m in M], sum(x[:,m]) >= data["markets"][m]["demand"])

# Objective is to minimize the transporation distance
@objective(model, Min, sum(distance(p,m) .* x[p,m] for m in M, p in P))

optimize!(model)
solution_summary(model)

for p in P, m in M
    println(p, " => ", m, ": ", value(x[p, m]))
end