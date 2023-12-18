### Practice for accessing the solar water heater module in SAM from Julia
using DelimitedFiles
using CSV
using JSON

swh_defaults = JSON.parsefile("sam/defaults/defaults_swh.json")


### my inputs
api_jgifford = "wKt35uq0aWoNHnzuwbcUxElPhVuo0K18YPSgZ9Ph"
lat = 39.7420       # Denver, CO
lon = -104.9915     # Denver, CO

draw = fill(10.0,8760)

global hdl = nothing
sam_prodfactor = []
libfile = "ssc.dll"
global hdl = joinpath(@__DIR__,"sam", libfile)
swh_module = @ccall hdl.ssc_module_create("swh"::Cstring)::Ptr{Cvoid}
swh_resource = @ccall hdl.ssc_data_create()::Ptr{Cvoid}  # data pointer
@ccall hdl.ssc_module_exec_set_print(1::Cint)::Cvoid

@ccall hdl.ssc_data_set_number(swh_resource::Ptr{Cvoid}, "latitude"::Cstring, lat::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(swh_resource::Ptr{Cvoid}, "longitude"::Cstring, lon::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(swh_resource::Ptr{Cvoid}, "elevation"::Cstring, 0::Cdouble)::Cvoid  # not used in SAM
@ccall hdl.ssc_data_set_number(swh_resource::Ptr{Cvoid}, "year"::Cstring, 2012::Cdouble)::Cvoid

data = @ccall hdl.ssc_data_create()::Ptr{Cvoid}  # data pointer
@ccall hdl.ssc_data_set_table(data::Ptr{Cvoid}, "swh_resource_data"::Cstring, swh_resource::Ptr{Cvoid})::Cvoid
@ccall hdl.ssc_data_free(swh_resource::Ptr{Cvoid})::Cvoid


@ccall hdl.ssc_data_set_string(data::Ptr{Cvoid}, "solar_resource_file"::Cstring, "C:/SAM/2021.12.02/solar_resource/phoenix_az_33.450495_-111.983688_psmv3_60_tmy.csv"::Cstring)::Cvoid

draw = convert(Array{Float64},draw)
@ccall hdl.ssc_data_set_array(data::Ptr{Cvoid}, "scaled_draw"::Cstring, draw::Ptr{Cdouble}, 8760::Cint)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "system_capacity"::Cstring, 3.4180599999999992::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "tilt"::Cstring, lat::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "azimuth"::Cstring, 180::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "albedo"::Cstring, 0.20000000000000001::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "irrad_mode"::Cstring, 0::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "sky_model"::Cstring, 0::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "mdot"::Cstring, 0.091055999999999998::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "ncoll"::Cstring, 2::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "fluid"::Cstring, 1::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "area_coll"::Cstring, 2.98::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "FRta"::Cstring, 0.68899999999999995::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "FRUL"::Cstring, 3.8500000000000001::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "iam"::Cstring, 0.20000000000000001::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "test_fluid"::Cstring, 1::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "test_flow"::Cstring, 0.045527999999999999::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "pipe_length"::Cstring, 10::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "pipe_diam"::Cstring, 0.019::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "pipe_k"::Cstring, 0.029999999999999999::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "pipe_insul"::Cstring, 0.0060000000000000001::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "tank_h2d_ratio"::Cstring, 2::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "U_tank"::Cstring, 1::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "V_tank"::Cstring, 0.29999999999999999::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "hx_eff"::Cstring, 0.75::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "T_room"::Cstring, 20::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "T_tank_max"::Cstring, 99::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "T_set"::Cstring, 55::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "pump_power"::Cstring, 45::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "pump_eff"::Cstring, 0.84999999999999998::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "use_custom_mains"::Cstring, 1::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_array(data::Ptr{Cvoid}, "custom_mains"::Cstring,swh_defaults["custom_mains"]::Ptr{Cdouble}, 8760::Cint)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "use_custom_set"::Cstring, 1::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_array(data::Ptr{Cvoid}, "custom_set"::Cstring,swh_defaults["custom_set"]::Ptr{Cdouble}, 8760::Cint)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "adjust:constant"::Cstring, 0::Cdouble)::Cvoid


if !Bool(@ccall hdl.ssc_module_exec(swh_module::Ptr{Cvoid}, data::Ptr{Cvoid})::Cint)
    log_type = 0
    log_type_ref = Ref(log_type)
    log_time = 0
    log_time_ref = Ref(log_time)
    msg_ptr = @ccall hdl.ssc_module_log(swh_module::Ptr{Cvoid}, 0::Cint, log_type_ref::Ptr{Cvoid}, 
                                    log_time_ref::Ptr{Cvoid})::Cstring
    msg = "no message from ssc_module_log."
    try
        msg = unsafe_string(msg_ptr)
    finally
        throw(@error("SAM SWH simulation error: $msg"))
    end
end

len = 0
len_ref = Ref(len)
a = @ccall hdl.ssc_data_get_array(data::Ptr{Cvoid}, "Q_deliv"::Cstring, len_ref::Ptr{Cvoid})::Ptr{Float64}

for i in range(1, stop=8760)
    push!(sam_prodfactor, unsafe_load(a, i))
end
@ccall hdl.ssc_module_free(swh_module::Ptr{Cvoid})::Cvoid   
@ccall hdl.ssc_data_free(data::Ptr{Cvoid})::Cvoid

using Plots

time = LinRange(1,length(sam_prodfactor),length(sam_prodfactor))
plot(time,sam_prodfactor)