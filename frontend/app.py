from flask import Flask, render_template, request
app = Flask(__name__)
from run_step1_basic import run_STEP1

inputs = {
    "latitude" : 39.7392,
    "longitude" : -104.9903,
    "land price" : 2000,
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
    "is load profile": False,
    "load profile file": "",
    "fuel type" : "natural gas",
    "technologies": ["pv","lf"],
    "max invest": 1e6,
    "max payback": 5,
    "is decarb goal": True,
    "decarb goal": 100
}

@app.route("/")
def home():
    return render_template('index.html')
@app.route("/workflow", methods=['GET', 'POST'])
def workflow():
    return render_template('workflow.html')
@app.route("/location", methods=['GET', 'POST'])
def location():
    if request.method == 'POST':
        return render_template("location.html")
@app.route("/process", methods=['GET', 'POST'])
def process():
    if request.method == 'POST' and request.form.get("latitude"):
        latitude = request.form["latitude"]
        inputs.update({"latitude": float(latitude)})
        longitude = request.form["longitude"]
        inputs.update({"longitude": float(longitude)})
        land_unit_price = request.form["land_unit_price"]
        land_unit_price_units = request.form["land_unit_price_units"]
        inputs.update({"land price units": land_unit_price_units})
        land_area = request.form["land_area"]
        inputs.update({"land area": int(land_area)})
        land_area_units = request.form["land_area_units"]
        inputs.update({"land area units": land_area_units})
        if land_unit_price == "":
            land_unit_price = "2000"
        inputs.update({"land price": float(land_unit_price)})
        return render_template("process.html")
    elif request.method == 'POST':
        return render_template("process.html")
@app.route("/constraints", methods=['GET', 'POST'])
def constraints():
    if request.method == 'POST' and request.form.get("process_type"):
        process_type = request.form["process_type"]
        inputs.update({"process media type": process_type})
        maximum_process_temperature = request.form["maximum_process_temperature"]
        inputs.update({"process temperature": float(maximum_process_temperature)})
        maximum_process_temperature_units = request.form["maximum_process_temperature_units"]
        inputs.update({"process temperature units": maximum_process_temperature_units})
        flow_rate = request.form["flow_rate"]
        inputs.update({"process flow rate": float(flow_rate)})
        flow_rate_units = request.form["flow_rate_units"]
        inputs.update({"process flow rate units": flow_rate_units})
        electric_bill = request.form["electric_bill"]
        inputs.update({"electric bill": int(electric_bill)})
        gas_bill = request.form["gas_bill"]
        inputs.update({"fuel bill": int(gas_bill)})
        current_fuel_type = request.form["current_fuel_type"]
        inputs.update({"fuel type": current_fuel_type})
        load_profile_boolean = False
        load_profile = request.form["load_profile"]
        if load_profile != "":
            load_profile_boolean = True
        inputs.update({"is load profile": load_profile_boolean})
        inputs.update({"load profile file": load_profile})
        gas_bill_units = request.form["gas_bill_units"]
        inputs.update({"fuel bill units": gas_bill_units})
        electric_bill_units = request.form["electric_bill_units"]
        inputs.update({"electric bill units": electric_bill_units})
        return render_template("constraints.html", temperatureInput=int(maximum_process_temperature))
    elif request.method == "POST":
        return render_template("constraints.html")
@app.route("/results", methods=['GET', 'POST'])
def results():
    if request.method == 'POST':
        pref_tech_arr = []
        if request.form.get("pv"):
            pref_tech_arr.append("pv")
        if request.form.get("evacuated_tubes"):
            pref_tech_arr.append("evacuated_tubes")
        if request.form.get("flat_plate"):
            pref_tech_arr.append("flat_plate")
        if request.form.get("lf"):
            pref_tech_arr.append("lf")
        if request.form.get("parabolic_trough"):
            pref_tech_arr.append("parabolic_trough")
        if request.form.get("mst"):
            pref_tech_arr.append("mst")
        if request.form.get("particle_tower"):
            pref_tech_arr.append("particle_tower")
        inputs.update({"technologies": pref_tech_arr})
        decarbonization_target = request.form["slider"]
        inputs.update({"decarb goal": int(decarbonization_target)})
        decarbonization_boolean = True
        inputs.update({"is decarb goal": decarbonization_boolean})
        if decarbonization_target == 0:
            decarbonization_target = False
        maximum_payback_period = request.form["mpp"]
        inputs.update({"max payback": int(maximum_payback_period)})
        maximum_investment_cost = request.form["mic"]
        inputs.update({"max invest": int(maximum_investment_cost)})
        outputs = run_STEP1(inputs)
        return render_template(
            "results.html",
            hemisphere=outputs["hemi"],
            total_cost=outputs["total cost"],
            max_cost_exceeded=outputs["max cost exceed"],
            soc_tes=outputs["soc TES"],
            error=outputs["error"]
        )
if __name__ == '__main__':
    app.run(debug=True)