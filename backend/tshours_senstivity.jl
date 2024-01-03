using Plots

# Function to normalize each array by its first value
function normalize_values(values)
    return values ./ values[1]
end

### Hours of storage simulated for each city
tshours = [10.0,50.0,100.0,200.0,500.0]

### Annual generation at various cities at the various hours of storage
R_mst = Dict(
    "Chicago, IL" => Any[2.1569206771634895e8, 1.151199587198164e8, 2.2770226512255323e8, 1.9123016084953985e8, 2.3582485150334632e8],
    "Houston, TX" => Any[2.9225491018942976e8, 2.038606525191638e8, 3.0209897410616934e8, 2.7097180071675706e8, 3.083836391327336e8],
    "Los Angeles, CA" => Any[5.0305752006402045e8, 4.245801875724107e8, 5.116378253836802e8, 4.845324729925852e8, 5.1124798917873853e8],
    "Miami, FL" => Any[3.6451089013625443e8, 2.842766350254101e8, 3.732440747787738e8, 3.4533316985272765e8, 3.7988070284115857e8],
    "New York City, NY" => Any[2.6135594099541864e8, 1.657768049347264e8, 2.7232948788617015e8, 2.3910171394154435e8, 2.7965336207312083e8],
    "Denver, CO" => Any[4.256629708768576e8, 3.430560171371995e8, 4.3460474640424573e8, 4.0604854010459745e8, 4.3291671955869913e8])

# Plot each array after normalization
plot()
for (city, values) in R_mst
    normalized_values = normalize_values(values)
    plot!(tshours,normalized_values, label=city)
end

xlabel!("tshours [hrs]")
ylabel!("Normalized Annual Production")
#xtick_labels = ["Label1", "Label2", "Label3", "Label4", "Label5"]  # Replace with your predefined labels
xticks!(tshours)