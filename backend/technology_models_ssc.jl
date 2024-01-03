### Script for running any type of SSC module
using JSON

function set_scc_data_from_dict(D,model,data)
    j = 0
    for (key, value) in D
        if typeof(value) == String
            @ccall hdl.ssc_data_set_string(data::Ptr{Cvoid},key::Cstring,D[key]::Cstring)::Cvoid
            j += 1
        elseif typeof(D[key]) in [Int64,Float64]
            @ccall hdl.ssc_data_set_number(data::Ptr{Cvoid},key::Cstring,D[key]::Cdouble)::Cvoid
            j += 1
        elseif typeof(D[key]) == Vector{Any}
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
        else
            print("Could not assign variable " + D[key])
        end
        
    end
end

function run_ssc(model::String,inputs::Dict,outputs::Vector)
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
        set_scc_data_from_dict(defaults,model,data)

        ### Set inputs
        set_scc_data_from_dict(inputs,model,data)

        ### Execute simulation
        @ccall hdl.ssc_module_exec(ssc_module::Ptr{Cvoid}, data::Ptr{Cvoid})::Cint

        ### Retrieve results
        len = 0
        len_ref = Ref(len)
        for k in outputs
            c_response = @ccall hdl.ssc_data_get_array(data::Ptr{Cvoid}, k::Cstring, len_ref::Ptr{Cvoid})::Ptr{Float64}
            #c_response = @ccall hdl.ssc_data_get_number(data::Ptr{Cvoid}, k::Cstring, len_ref::Ptr{Cvoid})::Ptr{Float64}
            
            print(c_response)
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

# model = "ptc"
# inputs = Dict(
#     "eta_pump" => 0.9000,
# )
# outputs = ["gen"]
# R_ptc = run_ssc(model,inputs,outputs)
# print("completed ptc \n")

# model = "ptc_red"
# inputs = Dict(
#     "eta_pump" => 0.9000,
# )
# outputs = ["q_dot_htf_od"]
# R_ptc = run_ssc(model,inputs,outputs)
# print("completed ptc reduced \n")
