
import numpy as np
import json
import PySSC
import matplotlib.pyplot as plt


defaults_file = "mspt_defaults_v2022_11_21.json"


#========================================================================== 
# Set ssc data values from dictionary object (D)
def set_ssc_data_from_dict(ssc_api, ssc_data, D):
    for key in D.keys():
        try:
            if type(D[key]) in [type(1), type(1.), type(np.array([1.])[0]), type(np.array([1], dtype=int)[0])]:  # Single-valued numeric inputs
               ssc_api.data_set_number(ssc_data, key.encode("utf-8"), D[key])
            elif type(D[key]) == type(True):  # Boolean inputs
               ssc_api.data_set_number(ssc_data, key.encode("utf-8"), 1 if D[key] else 0)
            elif type(D[key]) == type(""):    # String inputs
               ssc_api.data_set_string(ssc_data, key.encode("utf-8"), D[key].encode("utf-8"))  
            elif type(D[key]) == type([]):    # Arrays
               if len(D[key]) > 0:
                   if type(D[key][0]) == type([]):
                       ssc_api.data_set_matrix(ssc_data, key.encode("utf-8"), D[key])
                   else:
                       ssc_api.data_set_array(ssc_data, key.encode("utf-8"), D[key])
               else:
                   print ("Did not assign empty array " + key)
                   pass
            elif type(D[key]) == type({}):  
                table = ssc_api.data_create()
                set_ssc_data_from_dict(ssc_api, table, D[key])
                ssc_api.data_set_table(ssc_data, key.encode("utf-8"), table)
                ssc_api.data_free(table)
            else:
               print ("Could not assign variable " + key )
               raise KeyError
        except:
            print ("Error assigning variable " + key + ": bad data type")
			

		
#========================================================================== 
# Set default SAM inputs, replace those specified in "inputs" dictionary, run SAM, and extract results
def run_ssc(inputs, outputs = None):   
    ssc = PySSC.PySSC()
    dat = ssc.data_create()
    mspt = ssc.module_create("tcsmolten_salt".encode("utf-8"))
    
    #--- Set default inputs
    with open(defaults_file, 'r') as f:
        V = json.load(f)
    set_ssc_data_from_dict(ssc, dat, V)

    #-- Update inputs with user-supplied values
    set_ssc_data_from_dict(ssc, dat, inputs)  
    
    #--- Run simulation
    ssc.module_exec_set_print(0) #0 = no, 1 = yes (print progress updates)
    if ssc.module_exec(mspt, dat) == 0:
        print ('Simulation error')
        idx = 1
        msg = ssc.module_log(mspt, 0)
        while (msg != None):
            print ('	: ' + msg.decode("utf-8"))
            msg = ssc.module_log(mspt, idx)
            idx = idx + 1

    #--- Retrive results 
    keys =  ['beam', 'tdry', 'wspd', 'clearsky', 'solzen', 'solaz',                                       # Resource
            'q_sf_inc', 'eta_field', 'defocus', 'rec_defocus',                                            # Field and defocus
            'q_dot_rec_inc', 'eta_therm', 'Q_thermal', 'm_dot_rec', 'q_startup', 'T_rec_in', 'T_rec_out', # Receiver
            'T_rec_out_end', 'T_rec_out_max', 'T_panel_out_max', 'T_wall_rec_inlet', 'T_wall_rec_outlet', # Receiver transient
            'T_tes_hot', 'T_tes_cold', 'e_ch_tes', 'mass_tes_hot', 'mass_tes_cold', 'q_heater',           # TES
            'q_pb', 'q_dot_pc_startup', 'P_cycle', 'P_out_net', 'gen'                                     # Power block
            ] 
    
    if outputs is not None:  # Use user-specified ouputs in place of default outputs above
        keys = outputs

    R = {}
    for k in keys:
        if k in ['eta_map_out', 'flux_maps_out', 'flux_maps_for_import']:
            R[k] = ssc.data_get_matrix(dat, k.encode('utf-8'))
        elif k in ['A_sf']:
            R[k] = ssc.data_get_number(dat, k.encode('utf-8'))
        else:
            R[k] = ssc.data_get_array(dat, k.encode('utf-8'))
            R[k] = np.array(R[k])
    
    ssc.module_free(mspt)
    ssc.data_free(dat)   
    return R



inputs = {
    "tshours": 10.0
}
R_10hr = run_ssc(inputs)
print(R_10hr["Q_thermal"])

inputs = {
    "tshours": 12.0
}
R_12hr = run_ssc(inputs)
print(R_12hr["Q_thermal"])

time = np.linspace(1,len(R_12hr["Q_thermal"]),len(R_12hr["Q_thermal"]))
plt.plot(time,R_10hr["mass_tes_hot"],'b')
plt.plot(time,R_12hr["mass_tes_hot"],'r')

plt.show()



print(max(R_10hr["mass_tes_hot"]))
print(max(R_12hr["mass_tes_hot"]))