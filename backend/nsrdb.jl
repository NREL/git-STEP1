import HTTP
using DelimitedFiles
using DataFrames
using CSV


lat = 39.7420       # Denver, CO
lon = -104.9915     # Denver, CO


function get_weatherdata(lat::Float64,lon::Float64)
    ### Call NSRDB
    api_jgifford = "wKt35uq0aWoNHnzuwbcUxElPhVuo0K18YPSgZ9Ph"
    attributes = "ghi,dhi,dni,wind_speed,air_temperature,surface_pressure,relative_humidity"
    url = string("http://developer.nrel.gov/api/nsrdb/v2/solar/full-disc-download.csv?api_key=",api_jgifford,
                "&wkt=POINT(",lon,"%20",lat,")&attributes=",attributes,
                "&names=2019&utc=true&leap_day=true&interval=60&email=jeffrey.gifford@nrel.gov")
    r = HTTP.request("GET", url)
    df = DataFrame(CSV.File(IOBuffer(String(r.body))))

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
    weatherdata["dn"] = parse.(Float64,new_df."Time Zone") # Time Zone --> dn (Direct Normal Irradiance)
    weatherdata["df"] = parse.(Float64,new_df."Longitude") # Longitude --> df (Direct Horizontal Irradiance)
    weatherdata["gh"] = parse.(Float64,new_df."Latitude") # Latitude --> gh (Global Horizontal Irradiance)
    weatherdata["wspd"] = parse.(Float64,new_df."Elevation") # Elevation -> wspd
    weatherdata["tdry"] = parse.(Float64,new_df."Local Time Zone") # Local Time Zone --> tdry
    weatherdata["rhum"] = parse.(Float64,new_df."Clearsky DNI Units") # Clearsky DNI Units --> rhum (RH)
    weatherdata["pres"] = parse.(Float64,new_df."Clearsky DHI Units") # Clearsky DHI Units --> pres

    return weatherdata
end

weatherdata = get_weatherdata(lat,lon)

if typeof(weatherdata) == Dict{Any,Any}
    print("it is of type Dict()")
end

inputs = Dict()
inputs["eta_pump"] = 0.9000
inputs["solar_resource_data"] = weatherdata

### minute, day, year, month, hour