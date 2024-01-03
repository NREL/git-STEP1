using JSON

defaults_file = "sam/defaults/mspt_defaults_v2022_11_21.json"

defaults = JSON.parsefile(defaults_file)

i = 0
TYPES = []
for (key, value) in defaults
    if !(typeof(defaults[key]) in TYPES)
        push!(TYPES,typeof(defaults[key]))
    end
    global i += 1
end


### SAM Setup Calls
global hdl = nothing
sam_prodfactor = []
libfile = "ssc.dll"
global hdl = joinpath(@__DIR__, "sam", libfile)
mst_module = @ccall hdl.ssc_module_create("tcsmolten_salt"::Cstring)::Ptr{Cvoid}
data = @ccall hdl.ssc_data_create()::Ptr{Cvoid}  # data pointer
@ccall hdl.ssc_module_exec_set_print(1::Cint)::Cvoid


### Function for setting SSC inputs from a dictionary
function set_scc_data_from_dict(D)
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
            if ncols == 1
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
    return j
end

### Set and check defaults 
j = set_scc_data_from_dict(defaults)
if i == j
    print("Successfully processed all default inputs in JSON file.\n")
else
    print("Error: Did not successfully process all default inputs in JSON file.\n")
end

### Specify inputs
inputs = Dict(
    "receiver_type" => 0,
    "field_model_type" => 1
)
out = set_scc_data_from_dict(inputs)

### Execute module
@ccall hdl.ssc_module_exec(mst_module::Ptr{Cvoid}, data::Ptr{Cvoid})::Cint

### Gather results
K = ["mass_tes_hot"]
R_10hr = Dict()
len = 0
len_ref = Ref(len)
for k in K
    c_output = @ccall hdl.ssc_data_get_array(data::Ptr{Cvoid}, k::Cstring, len_ref::Ptr{Cvoid})::Ptr{Float64}
    output = []
    for i in 1:8760
        push!(output,unsafe_load(c_output,i))
    end
    R_10hr[k] = output
end

### Specify inputs
inputs = Dict(
    "receiver_type" => 0,
    "field_model_type" => 1,
    "tshours" => 24
)
out = set_scc_data_from_dict(inputs)

### Execute module
@ccall hdl.ssc_module_exec(mst_module::Ptr{Cvoid}, data::Ptr{Cvoid})::Cint

### Gather results
R_24hr = Dict()
for k in K
    c_output = @ccall hdl.ssc_data_get_array(data::Ptr{Cvoid}, k::Cstring, len_ref::Ptr{Cvoid})::Ptr{Float64}
    output = []
    for i in 1:8760
        push!(output,unsafe_load(c_output,i))
    end
    R_24hr[k] = output
end



@ccall hdl.ssc_module_free(mst_module::Ptr{Cvoid})::Cvoid   
@ccall hdl.ssc_data_free(data::Ptr{Cvoid})::Cvoid
