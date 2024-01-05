### import Pkg; Pkg.add("package_name")

function py_jl_connection_number(lat::Float64,lon::Float64)
    output = lat + lon
    return output
end

function py_jl_connection_array(lat::Float64,lon::Float64)
    output = LinRange(lat,lon,8760)
    return output
end