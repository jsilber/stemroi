from flask import Flask, jsonify
from flask_mysqldb import MySQL

app = Flask(__name__)
app.config["MYSQL_HOST"] = "localhost"
app.config["MYSQL_USER"] = "root"
app.config["MYSQL_PASSWORD"] = ""
app.config["MYSQL_DB"] = "projdb"
db = MySQL(app)

@app.route('/api/depts')
def getDepartments():
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


# Runs Flask's built-in web server--will only be used during development!
if __name__ == '__main__':
    app.run(debug=True)
