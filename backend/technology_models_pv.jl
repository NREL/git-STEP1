lat = 39.7420       # Denver, CO
lon = -104.9915     # Denver, CO
import HTTP
import JSON
using Plots

function call_pvwatts_api(latitude::Real, longitude::Real)
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


output, tamb = call_pvwatts_api(lat,lon)
time = LinRange(1,length(output),length(output))
plot(time,output)