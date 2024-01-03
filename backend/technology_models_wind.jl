### Practice using scripts from REopt's wind calls to SAM to make sure the connection to SAM is working

import HTTP
using DelimitedFiles
import JSON

wind_defaults = JSON.parsefile("sam/defaults/defaults_wind.json")

### my inputs
api_jgifford = "wKt35uq0aWoNHnzuwbcUxElPhVuo0K18YPSgZ9Ph"
lat = 39.7420       # Denver, CO
lon = -104.9915     # Denver, CO


### From REopt code
windtoolkit_hub_heights = [10, 40, 60, 80, 100, 120, 140, 160, 200]
hub_height = 100
heights_for_sam = [hub_height]
resources = []
size_class = "large"


if !(hub_height in windtoolkit_hub_heights)
    if hub_height < minimum(windtoolkit_hub_heights)
        heights_for_sam = [windtoolkit_hub_heights[1]]
    elseif hub_height > maximum(windtoolkit_hub_heights)
        heights_for_sam = [windtoolkit_hub_heights[end]]
    else
        upper_index = findfirst(x -> x > hub_height, windtoolkit_hub_heights)
        heights_for_sam = [windtoolkit_hub_heights[upper_index-1], windtoolkit_hub_heights[upper_index]]
    end
end
# TODO validate against API with different hub heights (not in windtoolkit_hub_heights)

for height in heights_for_sam
    url = string("https://developer.nrel.gov/api/wind-toolkit/v2/wind/wtk-srw-download", 
        "?api_key=", api_jgifford,
        "&lat=", lat, "&lon=", lon, 
        "&hubheight=", Int(height), "&year=", 2012
    )
    resource = []
    try
        @info "Querying Wind Toolkit for resource data ..."
        r = HTTP.get(url; retries=5)
        print(r.status)
        if r.status != 200
            throw(@error("Bad response from Wind Toolkit: $(response["errors"])"))
        end
        @info "Wind Toolkit success."

        resource = readdlm(IOBuffer(String(r.body)), ',', Float64, '\n'; skipstart=5);
        # columns: Temperature, Pressure, Speed, Direction (C, atm, m/s, Degrees)
        if size(resource) != (8760, 4)
            throw(@error("Wind Toolkit did not return valid resource data. Got an array with size $(size(resource))"))
        end
    catch e
        throw(@error("Error occurred when calling Wind Toolkit: $e"))
    end
    push!(resources, resource)
end
resources = hcat(resources...)

# Initialize SAM inputs
global hdl = nothing
sam_prodfactor = []

# Corresponding size in kW for generic reference turbines sizes
system_capacity_lookup = Dict(
    "large"=> 2000,
    "medium" => 250,
    "commercial"=> 100,
    "residential"=> 2.5
)
system_capacity = system_capacity_lookup[size_class]

# Corresponding rotor diameter in meters for generic reference turbines sizes
rotor_diameter_lookup = Dict(
    "large" => 55*2,
    "medium" => 21.9*2,
    "commercial" => 13.8*2,
    "residential" => 1.85*2
)
wind_turbine_powercurve_lookup = Dict(
    "large" => [0, 0, 0, 70.119, 166.208, 324.625, 560.952, 890.771, 1329.664,
                1893.213, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000,
                2000, 2000, 2000, 2000, 2000, 2000],
    "medium"=> [0, 0, 0, 8.764875, 20.776, 40.578125, 70.119, 111.346375, 166.208,
                236.651625, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250, 250,
                250, 250, 250, 250, 250],
    "commercial"=> [0, 0, 0, 3.50595, 8.3104, 16.23125, 28.0476, 44.53855, 66.4832,
                    94.66065, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
                    100, 100, 100, 100, 100],
    "residential"=> [0, 0, 0, 0.070542773, 0.1672125, 0.326586914, 0.564342188,
                    0.896154492, 1.3377, 1.904654883, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5,
                    2.5, 2.5, 2.5, 0, 0, 0, 0, 0, 0, 0]
)

libfile = "ssc.dll"

global hdl = joinpath(@__DIR__, "sam", libfile)
wind_module = @ccall hdl.ssc_module_create("windpower"::Cstring)::Ptr{Cvoid}
wind_resource = @ccall hdl.ssc_data_create()::Ptr{Cvoid}  # data pointer
@ccall hdl.ssc_module_exec_set_print(0::Cint)::Cvoid

@ccall hdl.ssc_data_set_number(wind_resource::Ptr{Cvoid}, "latitude"::Cstring, lat::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(wind_resource::Ptr{Cvoid}, "longitude"::Cstring, lon::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(wind_resource::Ptr{Cvoid}, "elevation"::Cstring, 0::Cdouble)::Cvoid  # not used in SAM
@ccall hdl.ssc_data_set_number(wind_resource::Ptr{Cvoid}, "year"::Cstring, 2012::Cdouble)::Cvoid

heights_array = []  # have to repeat heights for each resource column
for h in heights_for_sam
    append!(heights_array, repeat([h], 4))
end
heights_array = convert(Array{Float64}, heights_array)
@ccall hdl.ssc_data_set_array(wind_resource::Ptr{Cvoid}, "heights"::Cstring, 
    heights_array::Ptr{Cdouble}, length(heights_array)::Cint)::Cvoid

# setup column data types: temperature=1, pressure=2, degree=3, speed=4
fields = collect(repeat(range(1, stop=4), length(heights_for_sam)))
fields = convert(Array{Float64}, fields)
@ccall hdl.ssc_data_set_array(wind_resource::Ptr{Cvoid}, "fields"::Cstring, 
    fields::Ptr{Cdouble}, length(fields)::Cint)::Cvoid

print(resources)
nrows, ncols = size(resources)
t = [row for row in eachrow(resources)];
t2 = reduce(vcat, t);
# the values in python api are sent to SAM as vector (35040) with rows concatenated
c_resources = [convert(Float64, t2[i]) for i in eachindex(t2)]
@ccall hdl.ssc_data_set_matrix(wind_resource::Ptr{Cvoid}, "data"::Cstring, c_resources::Ptr{Cdouble}, 
    Cint(nrows)::Cint, Cint(ncols)::Cint)::Cvoid
print(nrows)
print(ncols)

data = @ccall hdl.ssc_data_create()::Ptr{Cvoid}  # data pointer
@ccall hdl.ssc_data_set_table(data::Ptr{Cvoid}, "wind_resource_data"::Cstring, wind_resource::Ptr{Cvoid})::Cvoid
@ccall hdl.ssc_data_free(wind_resource::Ptr{Cvoid})::Cvoid

# Scaler inputs
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "wind_resource_shear"::Cstring, wind_defaults["wind_resource_shear"]::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "wind_resource_turbulence_coeff"::Cstring, 
    0.10000000149011612::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "system_capacity"::Cstring, 
    system_capacity::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "wind_resource_model_choice"::Cstring, wind_defaults["wind_resource_model_choice"]::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "weibull_reference_height"::Cstring, wind_defaults["weibull_reference_height"]::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "weibull_k_factor"::Cstring, wind_defaults["weibull_k_factor"]::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "weibull_wind_speed"::Cstring, wind_defaults["weibull_wind_speed"]::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "wind_turbine_rotor_diameter"::Cstring, 
    rotor_diameter_lookup[size_class]::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "wind_turbine_hub_ht"::Cstring, hub_height::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "wind_turbine_max_cp"::Cstring, wind_defaults["wind_turbine_max_cp"]::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "wind_farm_losses_percent"::Cstring, 0::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "wind_farm_wake_model"::Cstring, 0::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "adjust:constant"::Cstring, 0::Cdouble)::Cvoid

speeds = convert(Array{Float64},
    [0., 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
@ccall hdl.ssc_data_set_array(data::Ptr{Cvoid}, "wind_turbine_powercurve_windspeeds"::Cstring, 
    speeds::Ptr{Cdouble}, length(speeds)::Cint)::Cvoid

powercurve = convert(Array{Float64}, wind_turbine_powercurve_lookup[size_class])
@ccall hdl.ssc_data_set_array(data::Ptr{Cvoid}, "wind_turbine_powercurve_powerout"::Cstring, 
    powercurve::Ptr{Cdouble}, length(powercurve)::Cint)::Cvoid

wind_farm_xCoordinates = [Float64(0)]
@ccall hdl.ssc_data_set_array(data::Ptr{Cvoid}, "wind_farm_xCoordinates"::Cstring, 
    wind_farm_xCoordinates::Ptr{Cdouble}, 1::Cint)::Cvoid

wind_farm_yCoordinates = [Float64(0)]
@ccall hdl.ssc_data_set_array(data::Ptr{Cvoid}, "wind_farm_yCoordinates"::Cstring, 
    wind_farm_yCoordinates::Ptr{Cdouble}, 1::Cint)::Cvoid

if !Bool(@ccall hdl.ssc_module_exec(wind_module::Ptr{Cvoid}, data::Ptr{Cvoid})::Cint)
    log_type = 0
    log_type_ref = Ref(log_type)
    log_time = 0
    log_time_ref = Ref(log_time)
    msg_ptr = @ccall hdl.ssc_module_log(wind_module::Ptr{Cvoid}, 0::Cint, log_type_ref::Ptr{Cvoid}, 
                                    log_time_ref::Ptr{Cvoid})::Cstring
    msg = "no message from ssc_module_log."
    try
        msg = unsafe_string(msg_ptr)
    finally
        throw(@error("SAM Wind simulation error: $msg"))
    end
end

len = 0
len_ref = Ref(len)
#a = @ccall hdl.ssc_data_get_array(data::Ptr{Cvoid}, "gen"::Cstring, len_ref::Ptr{Cvoid})::Ptr{Float64}
a = @ccall hdl.ssc_data_get_array(data::Ptr{Cvoid}, "monthly_energy"::Cstring, len_ref::Ptr{Cvoid})::Ptr{Float64}

#for i in range(1, stop=8760)
for i in range(1, stop=12)
    push!(sam_prodfactor, unsafe_load(a, i))
end
@ccall hdl.ssc_module_free(wind_module::Ptr{Cvoid})::Cvoid   
@ccall hdl.ssc_data_free(data::Ptr{Cvoid})::Cvoid

normalized_prod_factor = sam_prodfactor ./ system_capacity

using Plots

time = LinRange(1,length(normalized_prod_factor),length(normalized_prod_factor))
plot(time,normalized_prod_factor)