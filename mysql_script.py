# # Example Script
# import MySQLdb

# if __name__ == '__main__':
#     conn = MySQLdb.connect(user="root", passwd="", db="projdb")
#     # Call model with database connection and query string
#     cur = conn.cursor()
#     # Execute query (from employees sample database: https://github.com/datacharmer/test_db)
#     cur.execute('''SELECT * FROM university''')
#     # Extract row headers
#     row_headers = [x[0] for x in cur.description]
#     # Fetch all from the cursor
#     rv = cur.fetchall()
#     # Create an empty list we can append to
#     payload = []
#     # See https://stackoverflow.com/questions/43796423/python-converting-mysql-query-result-to-json
#     for result in rv:
#         payload.append(dict(zip(row_headers,result)))

#     print(payload)


# Example Table - Average Tuition per State (need to narrow this for selected major)
import MySQLdb

if __name__ == '__main__':
    conn = MySQLdb.connect(user="root", passwd="", db="projdb")
    # Call model with database connection and query string
    cur = conn.cursor()
    # Need to get the
    #cur.execute('''SELECT ROUND(avg(tuition),2) AS ave_tuition FROM university WHERE state_fips=6''')
    cur.execute('''SELECT * FROM university''')

    # Extract row headers
    row_headers = [x[0] for x in cur.description]
    # Fetch all from the cursor
    rv = cur.fetchall()
    # Create an empty list we can append to
    payload = []

    for result in rv:
        payload.append(dict(zip(row_headers,result)))

    print(payload)