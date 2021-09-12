import sys
import csv
import datetime
import mysql.connector
from mysql.connector import errorcode

#------------------------------------------------------------------------------
#  This program processes a daily forex file from https://www.forexite.com
#  Data from the site is a csv file formatted as follows:
#
# <TICKER>,<DTYYYYMMDD>,<TIME>,<OPEN>,<HIGH>,<LOW>,<CLOSE>
# EURUSD,20110102,230100,1.3345,1.3345,1.3345,1.3345
# EURUSD,20110102,230200,1.3344,1.3345,1.3340,1.3342
# EURUSD,20110102,230300,1.3341,1.3342,1.3341,1.3341
# EURUSD,20110102,230400,1.3341,1.3343,1.3341,1.3343
#------------------------------------------------------------------------------

# a class to hold a record of foreign exchange info
# class Forex:
#     def __str__(self):
#         return self.Ticker + " " + self.Dt.strftime("%d-%b-%Y (%H:%M)") + " " + str(self.Close)

#-------------------------------------------------------------
#  Connect to the database
#-------------------------------------------------------------
try:
    cnx = mysql.connector.connect(user='ec2-user', database='exch', host='localhost')
    cursor = cnx.cursor()
except mysql.connector.Error as err:
    if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
        print("Problem with user name or password")
    elif err.errno == errorcode.ER_BAD_DB_ERROR:
        print("Database does not exist")
    else:
        print(err)
    sys.exit()

add_exch = ("INSERT INTO Exch "
            "(Dt, Ticker, Open, High, Low, Close) "
            "VALUES (%(Dt)s, %(Ticker)s, %(Open)s, %(High)s, %(Low)s, %(Close)s)")

#-------------------------------------------------------------
#  Process the input file...
#-------------------------------------------------------------
with open(sys.argv[1]) as csv_file:
    reader = csv.reader(csv_file, delimiter=',')
    line = 0
    for r in reader:
        if line == 0:
            # print(f'Column names are {", ".join(r)}')
            pass
        else:
            # the date is in this format: YYYYMMDD
            y = int(r[1][:4])
            m = int(r[1][4:6])
            d = int(r[1][6:])
            H = int(r[2][:2])
            M = int(r[2][2:4])
            rec = {
                'Ticker' : r[0],
                'Dt' : datetime.datetime(y,m,d,H,M),
                'Open' : float(r[3]),
                'High' : float(r[4]),
                'Low' : float(r[5]),
                'Close' : float(r[6]),
            }
            # print( "rec = ", rec)
            try:
                cursor.execute(add_exch,rec)
            except mysql.connector.Error as err:
                print("db error on insert: " + err)
                sys.exit()

        line += 1

cnx.commit()
cursor.close()
cnx.close()
