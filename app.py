import datetime
from flask import Flask
from flask import request
from flask import render_template
from flask import url_for

app = Flask(__name__)
app.config.update({'DEBUG': True })

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/hello")
def hello():
    return "Hello, world!"

@app.route("/upload", methods=["POST"])
def upload():
    image = request.files["image"]
    filename = "./static/images/" + datetime.date.today().strftime("%Y%m%d%H%M%S") + "_" + image.filename
    image.save(filename)

    return filename

if __name__ == "__main__":
    app.run()
