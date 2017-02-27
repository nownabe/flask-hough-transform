from datetime import datetime
import os
import cv2
import numpy as np
from flask import Flask
from flask import jsonify
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
    filename = "./static/images/" + datetime.today().strftime("%Y%m%d%H%M%S") + "_" + image.filename
    image.save(filename)

    filenames = hough_transform(filename)

    return jsonify(filenames)

def hough_transform(filepath):
    img = cv2.imread(filepath)
    filename = datetime.today().strftime("%Y%m%d%H%M%S") + "_" + os.path.basename(filepath)

    # hight = img.shape[0]
    # width = img.shape[1]
    # img = cv2.resize(img, (int(width / 3), int(hight / 3)))

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray_file = "./static/images/gray/" + filename
    cv2.imwrite(gray_file, gray)

    edges = cv2.Canny(gray, 50, 150, apertureSize = 3)
    edges_file = "./static/images/edges/" + filename
    cv2.imwrite(edges_file, edges)

    img = hough_lines(img, edges)
    img = hough_lines_p(img, edges)

    new_filepath = "./static/images/hough_lines/" + filename
    cv2.imwrite(new_filepath, img)

    return [gray_file, edges_file, new_filepath]

def hough_lines(img, edges):
    lines = cv2.HoughLines(edges, 1, np.pi/180, 50)
    for rho, theta in lines[0]:
        a = np.cos(theta)
        b = np.sin(theta)
        x0 = a*rho
        y0 = b*rho
        x1 = int(x0 + 1000*(-b))
        y1 = int(y0 + 1000*(a))
        x2 = int(x0 - 1000*(-b))
        y2 = int(y0 - 1000*(a))

        cv2.line(img, (x1, y1), (x2, y2), (0, 255, ), 5)

    return img

def hough_lines_p(img, edges):
    min_line_length = 50
    max_line_gap = 10
    lines = cv2.HoughLinesP(edges, 1, np.pi/180, 50, min_line_length, max_line_gap)

    for x1, y1, x2, y2 in lines[0]:
        cv2.line(img, (x1, y1), (x2, y2), (0, 255, 0), 5)

    return img

if __name__ == "__main__":
    app.run(host="0.0.0.0")
