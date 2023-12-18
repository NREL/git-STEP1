# The aim of this script is to run appropriate technology models based on media and temperature
import HTTP
import JSON
using Plots

### Inputs
media = 2           # 0 = water, 1 = steam, 2 = air needed by the industrial process
temp = 200.0        # C
lat = 39.7420       # Denver, CO
lon = -104.9915     # Denver, CO

# Define technology options and their limits
struct tech_specs
    name::String        # Name for function calls
    media::Array{Int}   # 0 = water, 1 = steam, 2 = air needed by the industrial process
    temp_LB::Float64    # Temperature lower bound for technology [C]
    temp_UB::Float64    # Temperature upper bound for technology [C]
end

specs_all = tech_specs[]
evactube_specs = tech_specs("evactube",[0],0,100)
flatplate_specs = tech_specs("flatplate",[0],0,100)
lf_specs = tech_specs("lf",[1],100,400)
ptc_specs = tech_specs("ptc",[1],100,550)
mst_specs = tech_specs("mst",[1],400,600)
particle_tower_specs = tech_specs("particle_tower",[1,2],300,800)
particle_elec_specs = tech_specs("particle_elec",[1,2],300,1200)
push!(specs_all,evactube_specs,flatplate_specs,lf_specs,ptc_specs,mst_specs,particle_tower_specs,particle_elec_specs)

function technology_selection(media::Int,temp::Real)
    technologies = ["pv"] # PV will always be evaluated
    for i in 1:length(specs_all)
        if media in specs_all[i].media && temp >= specs_all[i].temp_LB && temp <= specs_all[i].temp_UB
            push!(technologies,specs_all[i].name)
        end
    end
    return technologies
end

function get_pv_production(latitude::Real, longitude::Real)
    ### Defaults
    tilt=latitude
    azimuth=180
    module_type=0
    array_type=1 
    losses=14
    dc_ac_ratio=1.2
    gcr=0.4
    inv_eff=96
    timeframe="hourly"
    radius=0
    time_steps_per_hour=1
    dataset = "nsrdb"
    # Check if site is beyond the bounds of the NRSDB TMY dataset. If so, use the international dataset.
    if longitude < -179.5 || longitude > -21.0 || latitude < -21.5 || latitude > 60.0
        if longitude < 81.5 || longitude > 179.5 || latitude < -60.0 || latitude > 60.0 
            if longitude < 67.0 || latitude < -40.0 || latitude > 38.0
                dataset = "intl"
            end
        end
    end
    #check_api_key()
    api_jgifford = "wKt35uq0aWoNHnzuwbcUxElPhVuo0K18YPSgZ9Ph"
    url = string("https://developer.nrel.gov/api/pvwatts/v8.json", "?api_key=", api_jgifford,
        "&lat=", latitude , "&lon=", longitude, "&tilt=", tilt,
        "&system_capacity=1", "&azimuth=", azimuth, "&module_type=", module_type,
        "&array_type=", array_type, "&losses=", losses, "&dc_ac_ratio=", dc_ac_ratio,
        "&gcr=", gcr, "&inv_eff=", inv_eff, "&timeframe=", timeframe, "&dataset=", dataset,
        "&radius=", radius
        )

    try
        @info "Querying PVWatts for production factor and ambient air temperature... "
        r = HTTP.get(url, keepalive=true, readtimeout=10)
        response = JSON.parse(String(r.body))
        if r.status != 200
            throw(@error("Bad response from PVWatts: $(response["errors"])"))
        end
        @info "PVWatts success."
        # Get both possible data of interest
        watts = collect(get(response["outputs"], "ac", []) / 1000)  # scale to 1 kW system (* 1 kW / 1000 W)
        tamb_celcius = collect(get(response["outputs"], "tamb", []))  # Celcius
        # Validate outputs
        if length(watts) != 8760
            throw(@error("PVWatts did not return a valid prodfactor. Got $watts"))
        end
        # Validate tamb_celcius
        if length(tamb_celcius) != 8760
            throw(@error("PVWatts did not return a valid temperature. Got $tamb_celcius"))
        end 
        # Upsample or downsample based on model time_steps_per_hour
        if time_steps_per_hour > 1
            watts = repeat(watts, inner=time_steps_per_hour)
            tamb_celcius = repeat(tamb_celcius, inner=time_steps_per_hour)
        end
        return watts, tamb_celcius
    catch e
        throw(@error("Error occurred when calling PVWatts: $e"))
    end
end

technologies = technology_selection(media,temp)
production_profiles = Dict{String,Any}("pv"=>zeros(8760))
if length(technologies) > 1
    for i in 2:length(technologies)
        merge!(production_profiles,Dict(technologies[i]=>zeros(8760)))
    end
end


if "pv" in technologies
    output, tamb = get_pv_production(lat,lon)
    time = LinRange(1,length(output),length(output))
    plot(time,output)
end
if "evactube" in technologies
    print("run func_get_evactube_production profile \n")
end
if "flatplate" in technologies
    print("run func_get_flatplate_production profile \n")
end
if "lf" in technologies
    print("run func_get_lf_production profile \n")
end
if "ptc" in technologies
    print("run func_get_ptc_production profile \n")
end
if "mst" in technologies
    print("run func_get_mst_production profile \n")
end
if "particle_tower" in technologies
    print("run func_get_power_tower_production profile \n")
end
if "particle_elec" in technologies
    print("run func_get_particle_elec_production profile \n")
end