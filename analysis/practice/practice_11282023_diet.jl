using JuMP
import CSV
import DataFrames
import GLPK

### Define parameters
dir = mktempdir()

food_csv_filename = joinpath(dir, "diet_foods.csv")
open(food_csv_filename, "w") do io
    write(
        io,
        """
        name,cost,calories,protein,fat,sodium
        hamburger,2.49,410,24,26,730
        chicken,2.89,420,32,10,1190
        hot dog,1.50,560,20,32,1800
        fries,1.89,380,4,19,270
        macaroni,2.09,320,12,10,930
        pizza,1.99,320,15,12,820
        salad,2.49,320,31,12,1230
        milk,0.89,100,8,2.5,125
        ice cream,1.59,330,8,10,180
        """,
    )
    return
end
foods = CSV.read(food_csv_filename, DataFrames.DataFrame)

nutrient_csv_filename = joinpath(dir, "diet_nutrient.csv")
open(nutrient_csv_filename, "w") do io
    write(
        io,
        """
        nutrient,min,max
        calories,1800,2200
        protein,91,
        fat,0,65
        sodium,0,1779
        """,
    )
    return
end
limits = CSV.read(nutrient_csv_filename, DataFrames.DataFrame)

limits.max = coalesce.(limits.max, Inf)
limits

### Model
model = Model(GLPK.Optimizer)
set_silent(model)

@variable(model,x[foods.name] >= 0)

foods.x = Array(x)

@objective(model, Min, sum(foods.cost .* foods.x))

@constraint(model, [row in eachrow(limits)], row.min <= sum(foods[!,row.nutrient] .* foods.x) <= row.max)

optimize!(model)

solution_summary(model)

for row in eachrow(foods)
    println(row.name, " = ", value(row.x))
end

dairy_foods = ["milk", "ice cream"]
is_dairy = map(name -> name in dairy_foods, foods.name)
dairy_constraint = @constraint(model, sum(foods[is_dairy, :x]) <= 8.5)
optimize!(model)
solution_summary(model)