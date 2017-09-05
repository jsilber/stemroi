from flask import Flask, request, render_template, jsonify
from flask_mysqldb import MySQL

app = Flask(__name__)
app.config["MYSQL_HOST"] = "localhost"
app.config["MYSQL_USER"] = "root"
app.config["MYSQL_PASSWORD"] = ""
app.config["MYSQL_DB"] = "stemroidb"
db = MySQL(app)

@app.route("/")
def index():
    return render_template("index.html")

#Flask function for Google Map University Points
@app.route('/api/unis', methods=['GET'])
def allUniversities():
    # Get a connected cursor
    cur = db.connection.cursor()
    # Execute query (from employees sample database: https://github.com/datacharmer/test_db)
    cur.execute('''SELECT * FROM university''')
    # Extract row headers
    row_headers = [x[0] for x in cur.description]
    # Fetch all from the cursor
    rv = cur.fetchall()
    # Create an empty list we can append to
    payload = []
    # See https://stackoverflow.com/questions/43796423/python-converting-mysql-query-result-to-json
    for result in rv:
        payload.append(dict(zip(row_headers,result)))

    # Convert list of dict to JSON and send response code 200
    # (see https://en.wikipedia.org/wiki/List_of_HTTP_status_codes and look for 200)
    return jsonify(payload), 200


#Flask function for states dropdown menu
@app.route('/api/statesdd', methods=['GET'])
def allStatenamesGet():
    cur = db.connection.cursor()
    cur.execute("SELECT state_fips, area_name FROM state_abrev")
    payload = []
    for row in cur:
        #row_data = {'id':row[0], 'state':row[1]}
        payload.append({'fips':row[0],'state':row[1]})

    return jsonify(payload), 200


#Flask function for university dropdown menu
@app.route('/api/universitydd', methods=['POST'])
def selectUnis():
    if request.is_json:
        # Get JSON sent
        content = request.get_json()
        print(content)
        # Check to see if the field(s) we are looking for exist
        if 'fips' in content:
            # Get the state value
            fips = content['fips']

            cur = db.connection.cursor()

            cur.execute("SELECT university.unitid, university.university_name \
                FROM stemroidb.university INNER JOIN stemroidb.state_abrev \
                ON stemroidb.university.state_fips=stemroidb.state_abrev.state_fips \
                WHERE stemroidb.state_abrev.state_fips = '{0}' \
                ORDER BY stemroidb.university.university_name".format(fips))
            payload = []
            for row in cur:
                payload.append({'unitid':row[0], 'university_name':row[1]})
        else:
            return jsonify({"errors":"Malformed JSON or incorrect format"}), 400
    else:
        return jsonify({"errors":"Malformed JSON or incorrect format"}), 400
    return jsonify(payload), 200




#Flask function for major dropdown menu
@app.route('/api/majordd', methods=['POST'])
def selectMajor():
    if request.is_json:
        # Get JSON sent
        content = request.get_json()
        print(content)
        # Check to see if the field(s) we are looking for exist
        #COME BACK TO THIS
        if 'unitid' in content:
            # Get the university value
            unitid = content['unitid']

            cur = db.connection.cursor()

            cur.execute("SELECT m.cip, m.cip_title \
                FROM stemroidb.university u, stemroidb.university_major um, stemroidb.major m \
                WHERE  u.unitid = um.unitid and um.cip = m.cip and u.unitid = '{0}'\
                ORDER BY m.cip_title".format(unitid))
            payload = []
            for row in cur:
                payload.append({'cip':row[0], 'major':row[1]})
        else:
            return jsonify({"errors":"Malformed JSON or incorrect format"}), 400
    else:
        return jsonify({"errors":"Malformed JSON or incorrect format"}), 400
    return jsonify(payload), 200


#Flask function for datagrid table
#https://stackoverflow.com/questions/14032066/can-flask-have-optional-url-parameters
@app.route('/api/roimajorbystate/<cip>', methods=['GET'])
def avgROI(cip):
    #print(cip)
    cur = db.connection.cursor()
    # Parameters must be passed to stored procedures as tuples
    # Note that strings in just parentheses [ex, (cip)] -ARE- tuples
    # See https://dev.mysql.com/doc/connector-python/en/connector-python-api-mysqlcursor-callproc.html
    # See http://www.openbookproject.net/books/bpp4awd/ch03.html (look at the '3.2.1 Indexing' section)
    cur.callproc("averages_by_state", [cip])
    rows = cur.fetchall()



    payload = []
    for row in rows:
        all_greater_than_zero = True
        plrow = {'State':str(row[0]), 'AveTuition': '${0:.2f}'.format(row[1])}
        if row[2] == 0.00:
            plrow['AveStart'] = 'N/A'
            all_greater_than_zero = False
        else:
            plrow['AveStart'] = '${0:.2f}'.format(row[2])
        if row[3] == 0.00:
            plrow['AvePeak'] = 'N/A'
            all_greater_than_zero = False
        else:
            plrow['AvePeak'] = '${0:.2f}'.format(row[3])
        if row[4] == 0.00 or not all_greater_than_zero:
            plrow['10YRROI'] = 'N/A'
        else:
            plrow['10YRROI'] = '{0:.2f}'.format(row[4])
        # (((ROUND(AVG(js.a_pct10),2))+(((ROUND(AVG(js.a_pct90),2))-(ROUND(AVG(js.a_pct10),2)))/43)*10))/(ROUND(AVG(u.tuition),2)) as roi10yr
        payload.append(plrow)
        # See https://stackoverflow.com/questions/455612/limiting-floats-to-two-decimal-points
        #payload.append({'State':str(row[0]), 'AveTuition': '${0:.2f}'.format(row[1]), 'AveStart':'${0:.2f}'.format(row[2]), 'AvePeak':'${0:.2f}'.format(row[3]), '10YRROI':'{0:.2f}'.format(row[4])})
    return jsonify(payload), 200


#Flask function for D3 Compare Tuition within State selected
@app.route('/api/compare_tuition', methods=['POST'])
def tuitionChart():
    if request.is_json:
        # Get JSON sent
        content = request.get_json()
        #print(content)
        # Check to see if the field(s) we are looking for exist
        if 'fips' in content:
            # Get the state value
            fips = content['fips']

            cur = db.connection.cursor()

            cur.execute("SELECT u.university_name, u.tuition \
                FROM stemroidb.state_abrev s, stemroidb.university u \
                WHERE u.state_fips = s.state_fips and s.state_fips = '{0}'".format(fips))
            payload = []
            for row in cur:
                payload.append({'university_name':row[0], 'tuition':row[1]})
        else:
            return jsonify({"errors":"Malformed JSON or incorrect format"}), 400
    else:
        return jsonify({"errors":"Malformed JSON or incorrect format"}), 400
    return jsonify(payload), 200



if __name__ == "__main__":
    app.run(debug=True)

#Use this example once I have more than one paramenter
#cur.execute("SELECT stemroidb.university.university_name FROM stemroidb.university INNER JOIN stemroidb.state_abrev ON stemroidb.university.state_fips=stemroidb.state_abrev.state_fips WHERE stemroidb.state_abrev.area_name = '{0}' AND school = '{1}'".format(state, uni))
