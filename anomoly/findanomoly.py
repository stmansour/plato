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

#                      [0] [1] [2]
cursor.execute('SELECT XID,Dt,Close FROM Exch WHERE Ticker="AUDUSD" AND MINUTE(Dt)=0 AND HOUR(Dt)=0' )
rows = cursor.fetchall()
l = len(rows) - 1

hits = 0    # number of anomlies that matched our criteria
i = 0       # counter
while i < l:
    v1 = rows[i][2]     # Closing value on dt
    v2 = rows[i+1][2]   # Closing value on dt + 1day
    dt = rows[i][1]     # datetime of this record (midnight each day)
    delta = abs(v2-v1)  # difference between this record and the next record's closing exch rate
    threshold = v1/100; # 1% of this row's closing exchange rate
    if  delta > threshold:
        d = dt.strftime("%b %d, %Y")
        hits = hits + 1
        print(f'{hits}\t{d} v1={v1}  v2={v2} delta={delta}, threshold={threshold}')
    i = i+1
