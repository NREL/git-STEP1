from flask import Flask, render_template, request
app = Flask(__name__)
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
    if request.method == 'POST':
        return render_template("process.html")
@app.route("/constraints", methods=['GET', 'POST'])
def constraints():
    if request.method == 'POST':
        return render_template("constraints.html")
@app.route("/results", methods=['GET', 'POST'])
def results():
    if request.method == 'POST':
        return render_template("results.html")
if __name__ == '__main__':
    app.run(debug=True)