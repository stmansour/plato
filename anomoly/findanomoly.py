import sys
import csv
import datetime
import mysql.connector

#-------------------------------------------------------------
#  Connect to the database
#-------------------------------------------------------------
try:
    cnx = mysql.connector.connect(user='ec2-user', database='plato', host='localhost')
    cursor = cnx.cursor()
except mysql.connector.Error as err:
    if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
        print("Problem with user name or password")
    elif err.errno == errorcode.ER_BAD_DB_ERROR:
        print("Database does not exist")
    else:
        print(err)
    sys.exit()

#                      [0] [1]
Ticker = "AUDUSD"
query = 'SELECT Dt,Close FROM Exch WHERE Ticker="{}" AND MINUTE(Dt)=0 AND HOUR(Dt)=0'.format(Ticker)
cursor.execute(query)
rows = cursor.fetchall()
l = len(rows) - 1

Ticker = "AUDUSD"
Threshold = float(0.02)  # that is, 2%

hits = 0    # number of anomlies that matched our criteria
i = 0       # counter
while i < l:
    v1 = rows[i][1]     # Closing value on dt
    v2 = rows[i+1][1]   # Closing value on dt + 1day
    dt = rows[i][0]     # datetime of this record (midnight each day)
    delta = abs(v2-v1)  # difference between this record and the next record's closing exch rate
    thresh = float(v1) * Threshold; # 1% of this row's closing exchange rate
    if  delta > thresh:
        d = dt.strftime("%b %d, %Y")
        hits = hits + 1
        print('{}\t{} v1={}  v2={} delta={}, Threshold={:.4f}'.format(hits,d,v1,v2,delta,thresh))
    i = i+1
print(f"total anomolies found: {hits}")
