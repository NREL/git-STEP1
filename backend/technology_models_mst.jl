# A script for calling and running the molten salt tower model in SAM 
using DelimitedFiles
using JSON
using CSV
mst_defaults = JSON.parsefile("backend/sam/defaults/mspt_defaults_v2022_11_21.json")

### my inputs
api_jgifford = "wKt35uq0aWoNHnzuwbcUxElPhVuo0K18YPSgZ9Ph"
lat = 39.7420       # Denver, CO
lon = -104.9915     # Denver, CO


# Initialize SAM inputs
global hdl = nothing
sam_prodfactor = []
libfile = "ssc.dll"
global hdl = joinpath(@__DIR__, "sam", libfile)
mst_module = @ccall hdl.ssc_module_create("tcsmolten_salt"::Cstring)::Ptr{Cvoid}
mst_resource = @ccall hdl.ssc_data_create()::Ptr{Cvoid}  # data pointer
@ccall hdl.ssc_module_exec_set_print(0::Cint)::Cvoid
data = @ccall hdl.ssc_data_create()::Ptr{Cvoid}  # data pointer

@ccall hdl.ssc_data_set_string(data::Ptr{Cvoid}, "solar_resource_file"::Cstring, "C:/SAM/2021.12.02/solar_resource/daggett_ca_34.865371_-116.783023_psmv3_60_tmy.csv"::Cstring)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "csp_financial_model"::Cstring, 1::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid},"ppa_multiplier_model"::Cstring, 0::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_array(data::Ptr{Cvoid}, "dispatch_factors_ts"::Cstring, mst_defaults["dispatch_factors_ts"]::Ptr{Cdouble}, 8760::Cint)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid},"field_model_type"::Cstring, 2::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid},"gross_net_conversion_factor"::Cstring, 0.9::Cdouble)::Cvoid
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "receiver_type", 0 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "cav_rec_height", 10 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "cav_rec_width", 10 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "n_cav_rec_panels", 6 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "cav_rec_span", 180 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "cav_rec_passive_abs", 0.29999999999999999 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "cav_rec_passive_eps", 0.5 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "helio_width", 12.199999999999999 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "helio_height", 12.199999999999999 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "helio_optical_error_mrad", 1.53 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "helio_active_fraction", 0.98999999999999999 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "dens_mirror", 0.96999999999999997 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "helio_reflectance", 0.90000000000000002 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "rec_absorptance", 0.93999999999999995 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "rec_hl_perm2", 30 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "land_max", 9.5 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "land_min", 0.75 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "dni_des", 950 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "p_start", 0.025000000000000001 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "p_track", 0.055 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "hel_stow_deploy", 8 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "v_wind_max", 15 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "c_atm_0", 0.0067889999999999999 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "c_atm_1", 0.1046 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "c_atm_2", -0.017000000000000001 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "c_atm_3", 0.0028449999999999999 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "n_facet_x", 2 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "n_facet_y", 8 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "focus_type", 1 );
@ccall hdl.ssc_data_set_number(data::Ptr{Cvoid}, "cant_type", 1 );
ssc_data_set_number( data, "n_flux_days", 8 );
ssc_data_set_number( data, "delta_flux_hrs", 2 );
ssc_data_set_number( data, "water_usage_per_wash", 0.69999999999999996 );
ssc_data_set_number( data, "washing_frequency", 63 );
ssc_data_set_number( data, "check_max_flux", 0 );
ssc_data_set_number( data, "sf_excess", 1 );
ssc_data_set_number( data, "tower_fixed_cost", 3000000 );
ssc_data_set_number( data, "tower_exp", 0.011299999999999999 );
ssc_data_set_number( data, "rec_ref_cost", 103000000 );
ssc_data_set_number( data, "rec_ref_area", 1571 );
ssc_data_set_number( data, "rec_cost_exp", 0.69999999999999996 );
ssc_data_set_number( data, "site_spec_cost", 16 );
ssc_data_set_number( data, "heliostat_spec_cost", 140 );
ssc_data_set_number( data, "plant_spec_cost", 1040 );
ssc_data_set_number( data, "bop_spec_cost", 290 );
ssc_data_set_number( data, "tes_spec_cost", 22 );
ssc_data_set_number( data, "land_spec_cost", 10000 );
ssc_data_set_number( data, "contingency_rate", 7 );
ssc_data_set_number( data, "sales_tax_rate", 5 );
ssc_data_set_number( data, "sales_tax_frac", 80 );
ssc_data_set_number( data, "cost_sf_fixed", 0 );
ssc_data_set_number( data, "fossil_spec_cost", 0 );
ssc_data_set_number( data, "flux_max", 1000 );
ssc_data_set_number( data, "opt_init_step", 0.059999999999999998 );
ssc_data_set_number( data, "opt_max_iter", 200 );
ssc_data_set_number( data, "opt_conv_tol", 0.001 );
ssc_data_set_number( data, "opt_flux_penalty", 0.25 );
ssc_data_set_number( data, "opt_algorithm", 1 );
ssc_data_set_number( data, "csp.pt.cost.epc.per_acre", 0 );
ssc_data_set_number( data, "csp.pt.cost.epc.percent", 13 );
ssc_data_set_number( data, "csp.pt.cost.epc.per_watt", 0 );
ssc_data_set_number( data, "csp.pt.cost.epc.fixed", 0 );
ssc_data_set_number( data, "csp.pt.cost.plm.percent", 0 );
ssc_data_set_number( data, "csp.pt.cost.plm.per_watt", 0 );
ssc_data_set_number( data, "csp.pt.cost.plm.fixed", 0 );
ssc_data_set_number( data, "csp.pt.sf.fixed_land_area", 45 );
ssc_data_set_number( data, "csp.pt.sf.land_overhead_factor", 1 );
ssc_data_set_number( data, "T_htf_cold_des", 290 );
ssc_data_set_number( data, "T_htf_hot_des", 574 );
ssc_data_set_number( data, "P_ref", 115 );
ssc_data_set_number( data, "design_eff", 0.41199999999999998 );
ssc_data_set_number( data, "tshours", 10 );
ssc_data_set_number( data, "solarm", 2.3999999999999999 );
ssc_data_set_number( data, "N_panels", 20 );
ssc_data_set_number( data, "d_tube_out", 40 );
ssc_data_set_number( data, "th_tube", 1.25 );
ssc_data_set_number( data, "mat_tube", 2 );
ssc_data_set_number( data, "rec_htf", 17 );
print("made it")