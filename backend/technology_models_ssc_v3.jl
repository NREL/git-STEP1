### Script for running any type of SSC module
using JSON
import HTTP
using DelimitedFiles
using DataFrames
using CSV
using Base.Iterators

function set_ssc_data_from_dict(D,model,data)
    j = 0
    for (key, value) in D
        if key == "solar_resource_file"
            continue
        elseif typeof(value) == String
            @ccall hdl.ssc_data_set_string(data::Ptr{Cvoid},key::Cstring,D[key]::Cstring)::Cvoid
            j += 1
        elseif typeof(D[key]) in [Int64,Float64]
            @ccall hdl.ssc_data_set_number(data::Ptr{Cvoid},key::Cstring,D[key]::Cdouble)::Cvoid
            j += 1
        elseif typeof(D[key]) == Vector{Any} || typeof(D[key]) == Vector{Float64} || typeof(D[key]) == Vector{Int64}
            nrows, ncols = length(D[key]), length(D[key][1])
            c_matrix = []
            for k in 1:nrows
                for l in 1:ncols
                    push!(c_matrix,D[key][k][l])
                end
            end
            if ncols == 1 && (nrows > 2 || model == "mst")
                c_matrix = convert(Array{Float64},c_matrix)
                @ccall hdl.ssc_data_set_array(data::Ptr{Cvoid},key::Cstring,c_matrix::Ptr{Cdouble},length(D[key])::Cint)::Cvoid
                j += 1
            else
                c_matrix = convert(Array{Float64},c_matrix)
                @ccall hdl.ssc_data_set_matrix(data::Ptr{Cvoid},key::Cstring,c_matrix::Ptr{Cdouble},Cint(nrows)::Cint,Cint(ncols)::Cint)::Cvoid
                j += 1
            end
        elseif typeof(D[key]) == Dict{Any,Any}
            table = @ccall hdl.ssc_data_create()::Ptr{Cvoid}  # data pointer
            set_ssc_data_from_dict(D[key],model,table)
            @ccall hdl.ssc_data_set_table(data::Ptr{Cvoid}, key::Cstring, table::Ptr{Cvoid})::Cvoid
            @ccall hdl.ssc_data_free(table::Ptr{Cvoid})::Cvoid
        else
            print("Could not assign variable " * key)
        end
        
    end
end

function get_weatherdata(lat::Float64,lon::Float64)
    ### Call NSRDB
    api_jgifford = "wKt35uq0aWoNHnzuwbcUxElPhVuo0K18YPSgZ9Ph"
    attributes = "ghi,dhi,dni,wind_speed,air_temperature,surface_pressure,relative_humidity"
    url = string("http://developer.nrel.gov/api/nsrdb/v2/solar/full-disc-download.csv?api_key=",api_jgifford,
                "&wkt=POINT(",lon,"%20",lat,")&attributes=",attributes,
                "&names=2019&utc=true&leap_day=true&interval=60&email=jeffrey.gifford@nrel.gov")
    r = HTTP.request("GET", url)
    df = DataFrame(CSV.File(IOBuffer(String(r.body)), silencewarnings = true)) # "silencewarnings" suppresses the CSV warnings regarding "missing" columns 
    ### Create weather data dataframe for SAM
    # Items in header
    weatherdata = Dict()
    weatherdata["tz"] = parse(Int64,df."Time Zone"[1])
    weatherdata["elev"] = parse(Float64,df."Elevation"[1])
    weatherdata["lat"] = parse(Float64,df."Latitude"[1])
    weatherdata["lon"] = parse(Float64,df."Longitude"[1])
    # Items in subheaders
    new_df = vcat(df[3:end, :])
    weatherdata["year"] = parse.(Int64,new_df."Source") # Source --> year
    weatherdata["month"] = parse.(Int64,new_df."Location ID") # Location ID --> month
    weatherdata["day"] = parse.(Int64,new_df."City") # City --> day 
    weatherdata["hour"] = parse.(Int64,new_df."State") # State --> hour
    weatherdata["minute"] = parse.(Int64,new_df."Country") # Country --> minute
    weatherdata["dn"] = parse.(Float64,new_df."Time Zone") # Time Zone --> dn (DNI)
    weatherdata["df"] = parse.(Float64,new_df."Longitude") # Longitude --> df (DHI)
    weatherdata["gh"] = parse.(Float64,new_df."Latitude") # Latitude --> gh (GHI)
    weatherdata["wspd"] = parse.(Float64,new_df."Elevation") # Elevation -> wspd
    weatherdata["tdry"] = parse.(Float64,new_df."Local Time Zone") # Local Time Zone --> tdry
    weatherdata["rhum"] = parse.(Float64,new_df."Clearsky DNI Units") # Clearsky DNI Units --> rhum (RH)
    weatherdata["pres"] = parse.(Float64,new_df."Clearsky DHI Units") # Clearsky DHI Units --> pres

    return weatherdata
end

function run_ssc(model::String,lat::Float64,lon::Float64,inputs::Dict,outputs::Vector)
    R = Dict()
    error = ""
    
    ### Check model name
    model_names = Dict(
        "mst" => "tcsmolten_salt",
        "swh" => "swh",
        "lf" => "linear_fresnel_dsg_iph",
        "ptc" => "trough_physical_process_heat"
    ) # relates internal names to specific models in SAM (for example, there are multiple molten salt tower models to pick from in the SSC)
    if !(model in collect(keys(model_names)))
        error =  error * "Model is not available at this time. \n"
    else
        ### Setup SSC
        global hdl = nothing
        libfile = "ssc.dll"
        global hdl = joinpath(@__DIR__, "sam", libfile)
        ssc_module = @ccall hdl.ssc_module_create(model_names[model]::Cstring)::Ptr{Cvoid}
        data = @ccall hdl.ssc_data_create()::Ptr{Cvoid}  # data pointer
        @ccall hdl.ssc_module_exec_set_print(0::Cint)::Cvoid # change to 1 to print outputs/errors (for debugging)

        ### Import defaults
        defaults_file = "sam/defaults/defaults_" * model * ".json" ### CHANGE
        defaults = JSON.parsefile(defaults_file)
        set_ssc_data_from_dict(defaults,model,data)

        ### Get weather data
        weatherdata = get_weatherdata(lat,lon)
        inputs["solar_resource_data"] = weatherdata

        ### Set inputs
        set_ssc_data_from_dict(inputs,model,data)

        ### Execute simulation
        @ccall hdl.ssc_module_exec(ssc_module::Ptr{Cvoid}, data::Ptr{Cvoid})::Cint

        ### Retrieve results
        len = 0
        len_ref = Ref(len)
        for k in outputs
            c_response = @ccall hdl.ssc_data_get_array(data::Ptr{Cvoid}, k::Cstring, len_ref::Ptr{Cvoid})::Ptr{Float64}
            #c_response = @ccall hdl.ssc_data_get_number(data::Ptr{Cvoid}, k::Cstring, len_ref::Ptr{Cvoid})::Ptr{Float64}
            
            #print(c_response)
            response = []
            for i in 1:8760
                push!(response,unsafe_load(c_response,i))
            end
            R[k] = response
        end

        ### Free SSC
        @ccall hdl.ssc_module_free(ssc_module::Ptr{Cvoid})::Cvoid   
        @ccall hdl.ssc_data_free(data::Ptr{Cvoid})::Cvoid
    end
    
    ### Check for errors
    if error == ""
        error = "No errors found."
    end
    R["error"] = error
    #return R
    return R["gen"]
end

# model = "mst"
# inputs = Dict(
#     "receiver_type" => 0,
#     "field_model_type" => 1,
# )
# outputs = ["mass_tes_hot","mass_tes_cold"]
# R_mst = run_ssc(model,inputs,outputs)
# print("completed mst \n")

# model = "swh"
# inputs = Dict(
#     "FRUL" => 4.0
# )
# outputs = ["Q_deliv"]
# R_swh = run_ssc(model,inputs,outputs)
# print("completed swh \n")

# model = "lf"
# inputs = Dict(
#     "eta_pump" => 0.9000,
# )
# outputs = ["gen"]
# R_lf = run_ssc(model,inputs,outputs)
# print("completed lf \n")

# model = "lf"
# lat = 39.7420       # Denver, CO
# lon = -104.9915     # Denver, CO
# lat = 36.1715       # Las Vegas, NV 
# lon = -115.1391     # Las Vegas, NV
# inputs = Dict()
# inputs["eta_pump"] = 0.9000
# outputs = ["gen"]
# R_denver = run_ssc(model,lat,lon,inputs,outputs)
# print("completed lf - Denver\n")

# lat = 44.9778       # Minneapolis, MN 36.1716° N, 115.1391° W
# lon = -93.2650      # Minneapolis, MN
# inputs = Dict()
# inputs["eta_pump"] = 0.9000
# outputs = ["gen"]
# R_minneapolis = run_ssc(model,lat,lon,inputs,outputs)
# print("completed lf - Minneapolis\n")

# model = "ptc_red"
# inputs = Dict(
#     "eta_pump" => 0.9000,
# )
# outputs = ["q_dot_htf_od"]
# R_ptc = run_ssc(model,inputs,outputs)
# print("completed ptc reduced \n")


### Test case list
# Define the dictionary with cities as keys and latitudes/longitudes as arrays
cities_dict = Dict(
    "New York City, NY" => [40.7128, -74.0060],
    "Los Angeles, CA" => [34.0522, -118.2437],
    "Chicago, IL" => [41.8781, -87.6298],
    "Houston, TX" => [29.7604, -95.3698],
    "Miami, FL" => [25.7617, -80.1918],
    "Seattle, WA" => [47.6062, -122.3321],
    "Denver, CO" => [39.7392, -104.9903],
    # "Atlanta, GA" => [33.7490, -84.3880],
    # "Boston, MA" => [42.3601, -71.0589],
    # "San Francisco, CA" => [37.7749, -122.4194],
    # "Phoenix, AZ" => [33.4484, -112.0740],
    # "Philadelphia, PA" => [39.9526, -75.1652],
    # "San Antonio, TX" => [29.4241, -98.4936],
    # "San Diego, CA" => [32.7157, -117.1611],
    # "Dallas, TX" => [32.7767, -96.7970],
    # "Portland, OR" => [45.5051, -122.6750],
    # "Detroit, MI" => [42.3314, -83.0458],
    # "Minneapolis, MN" => [44.9778, -93.2650],
    # "Tampa, FL" => [27.9506, -82.4572],
    # "Charlotte, NC" => [35.2271, -80.8431],
    # "New Orleans, LA" => [29.9511, -90.0715],
    # "Raleigh, NC" => [35.7796, -78.6382],
    # "Salt Lake City, UT" => [40.7608, -111.8910],
    # "Indianapolis, IN" => [39.7684, -86.1581],
    # "San Jose, CA" => [37.3382, -121.8863],
    # "Columbus, OH" => [39.9612, -82.9988],
    # "Las Vegas, NV" => [36.1699, -115.1398],
    # "Austin, TX" => [30.2500, -97.7500],
    # "Nashville, TN" => [36.1627, -86.7816],
    # "Pittsburgh, PA" => [40.4406, -79.9959],
    # "St. Louis, MO" => [38.6270, -90.1994],
    # "Portland, ME" => [43.6591, -70.2568],
    # "Albuquerque, NM" => [35.0844, -106.6504],
    # "Louisville, KY" => [38.2527, -85.7585],
    # "Memphis, TN" => [35.1495, -90.0490],
    # "Buffalo, NY" => [42.8802, -78.8782],
    # "Anchorage, AK" => [61.0160, -149.7375],
    # "Madison, WI" => [43.0731, -89.4012],
    # "Harrisburg, PA" => [40.2732, -76.8867],
    # "Boise, ID" => [43.6150, -116.2023]
)

model = "ptc"
outputs = ["gen"]
tshours = [10.0,50.0,100.0,200.0,500.0]
R_all = Dict()
global msg = ""
for (key, value) in cities_dict
    R = Dict()  
    for t in tshours
        inputs = Dict()
        inputs["tshours"] = t
        global msg = msg * "Began calculation for " * key * ". \n"
        R[string(t)] = sum(run_ssc(model,value[1],value[2],inputs,outputs))
        # if R[string(t)] > 0
        #     global msg = msg * "The model for " * key * " was successful. \n"
        #     #print("The model for " * key * " was successful. \n")
        # else
        #     global msg = msg * "The model for " * key * " was unsuccessful. \n"
        #     #print("The model for " * key * " was unsuccessful. \n")
        # end
    end
    R_all[key] = collect(values(R))
end

print(R_all)

using Plots

# Function to normalize each array by its first value
function normalize_values(values)
    return values ./ values[1]
end

# Plot each array after normalization
plot()
for (city, values) in R_all
    normalized_values = normalize_values(values)
    plot!(normalized_values, label=city)
end

xlabel!("tshours [hrs]")
ylabel!("Normalized Annual Production")
# title!("Normalized Values of Cities")
legend()

# Display the plot
#display(Plots.plot!())  # This line is necessary in some environments (e.g., Jupyter Notebooks) to show the plot
