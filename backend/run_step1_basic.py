### Basic function for Python-Web Connection
import numpy as np

inputs = {
    "latitude" : 39.7392,
    "longitude" : -104.9903,
    "land price" : 123.5,
    "land price units" : "$/acre",
    "land area": 100,
    "land area units": "acre",
    "process media type": "steam",
    "process temperature": 135.7,
    "process temperature units": "C",
    "process flow rate": 23.4,
    "process flow rate units": "kg/s",
    "electric bill": 1e6,
    "electric bill units": "month",
    "fuel bill": 1e6,
    "fuel bill units": "year",
    "is load profile": True,
    "load profile file": "load_profile_test_incorrect.csv",
    "fuel type" : "natural gas",
    "technologies": ["pv","lf"],
    "max invest": 1e6,
    "max payback": 5,
    "is decarb goal": True,
    "decarb goal": 100
}

def run_STEP1(inputs):
    error = ""
    
    # Nominals (just for thi test)
    temp_nom = 100
    flowrate_nom = 100
    decarb_goal_nom = 50

    
    # Geography
    lat = inputs["latitude"]                                #double
    lon = inputs["longitude"]                               #double
    land_price = inputs["land price"]                       #double
    land_price_unit = inputs["land price units"]            #string
    land_area = inputs["land area"]                         #integer
    land_area_unit = inputs["land area units"]              #string

    # Process
    process_type = inputs["process media type"]             #string
    temp = inputs["process temperature"]                    #integer
    temp_unit = inputs["process temperature units"]         #string
    flowrate = inputs["process flow rate"]                  #double
    flowrate_unit = inputs["process flow rate units"]       #string
    electric_bill = inputs["electric bill"]
    electric_bill_unit = inputs["electric bill units"]
    fuel_bill = inputs["fuel bill"]
    fuel_bill_unit = inputs["fuel bill units"]
    is_load_profile = inputs["is load profile"]
    if is_load_profile:
        #read csv
        load_profile = np.loadtxt("data/" + inputs["load profile file"],delimiter=",")
        if not (int(len(load_profile)) == 8760):
            error += "Load profile length is " + str(int(len(load_profile))) + ", but length of 8760 is required. Please reupload. \n"
            load_profile_normalized = np.zeros(8760)
        else:
            load_profile_normalized = load_profile / np.max(load_profile)
    else:
        load_profile_normalized = np.ones(8760)
    fuel_type = inputs["fuel type"]
    technologies = inputs["technologies"]
    max_invest = inputs["max invest"]
    max_payback = inputs["max payback"]
    is_decarb_goal = inputs["is decarb goal"]
    if is_decarb_goal:
        decarb_goal = inputs["decarb goal"]
    else:
        decarb_goal = 0.0
    
    ### Check on lat/lon
    if lat > 0:
        hemi = "N"
    else:
        hemi = "S"
    if lon > 0:
        hemi = hemi + "E"
    else:
        hemi = hemi + "W"
    
    ### Electric bill units
    if electric_bill_unit == "month":
        electric_bill = electric_bill*12
    elif electric_bill_unit == "year":
        pass
    else:
        error += "Incorrect electric bill units. \n"
    if fuel_bill_unit == "month":
        fuel_bill = fuel_bill*12
    elif fuel_bill_unit == "year":
        pass
    else:
        error += "Incorrect fuel bill units. \n"
    
    ### Land price conversion
    if land_price_unit == "acre":
        land_price = land_price * 247.105 # 247.105 acres = 1 km2
    if land_area_unit == "acre":
        land_area = land_area * 247.105 # 247.105 acres = 1 km2
    cost_land = land_area*land_price
    
    ### Temperature conversion
    if temp_unit == "F":
        temp = (5.0/9.0) * (temp - 32.0) # F to C
    elif temp_unit == "K":
        temp = temp - 273.15 # K to C
    else:
        pass

    ### Flow rate conversion
    if flowrate_unit == "lb/hr":
        flowrate = flowrate / 3600 / 2.20462 # 3600sec = 1hr, 2.20462lb = 1kg
    else:
        pass

    ### Mock total cost calculation
    cost_total = 1e3 # Mock nominal cost
    cost_total += cost_land
    cost_total = cost_total * temp/temp_nom
    cost_total = cost_total * flowrate/flowrate_nom
    if is_decarb_goal:
        cost_total = cost_total * decarb_goal/decarb_goal_nom
    cost_total = cost_total * np.sum(load_profile_normalized) / 8760

    ### Create random SOC of TES profile to test passing an array to results UI
    soc_tes = np.random.rand(8760)
    
    ### Check if exceeds maximum invest cost
    if cost_total > max_invest:
        error += "Cost exceeds maximum investmant cost. \n"
        is_max_invest_exceeded = True
    else:
        is_max_invest_exceeded = False
    
    ### Finalize outputs
    if error == "":
        error = "No errors found."
    outputs = {
        "hemi" : hemi,                              #string
        "total cost" : cost_total,                  #double
        "max cost exceed" : is_max_invest_exceeded, #boolean
        "soc TES": soc_tes,                         #state of charge of TES, array of 8760 between 0 and 1
        "error" : error,                            #message
    }
    return outputs

out = run_STEP1(inputs)
