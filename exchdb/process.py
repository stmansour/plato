import sys
import csv
import json
import datetime
import mysql.connector
from mysql.connector import errorcode
import ticker

#------------------------------------------------------------------------------
#  This program processes a daily forex file from https://www.forexite.com
#  Data from the site is a csv file formatted as follows:
#
# <TICKER>,<DTYYYYMMDD>,<TIME>,<OPEN>,<HIGH>,<LOW>,<CLOSE>
# EURUSD,20110102,230100,1.3345,1.3345,1.3345,1.3345
# EURUSD,20110102,230200,1.3344,1.3345,1.3340,1.3342
# EURUSD,20110102,230300,1.3341,1.3342,1.3341,1.3341
# EURUSD,20110102,230400,1.3341,1.3343,1.3341,1.3343
#
#  Example Usage:
#
#   bash$  python3 process.py  myfile.csv
#------------------------------------------------------------------------------

def Main():
    UID=-99998

    #-------------------------------------------------------------
    #  Read config info
    #-------------------------------------------------------------
    try:
        f = open('config.json','r')
        config = json.load(f)
    except FileNotFoundError as err:
        print("\n\n\n*** Problem opening config.json: ")
        print(err)
        sys.exit()

    #-------------------------------------------------------------
    #  Connect to the database
    #-------------------------------------------------------------
    try:
        cnx = mysql.connector.connect(user=config.get("PlatoDbuser"),
                                      password=config.get("PlatoDbpass"),
                                      database=config.get("PlatoDbname"),
                                      host=config.get("PlatoDbhost"))
        cursor = cnx.cursor()
        print("cursor acquired!")
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("\n\n\n*** Problem with user name or password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print("\n\n\n*** Database does not exist")
        else:
            print(err)
        sys.exit()

    add_exch = ("INSERT INTO Exch "
                "(Dt, Ticker, Open, High, Low, Close, LastmodBy, CreateBy) "
                "VALUES (%(Dt)s, %(Ticker)s, %(Open)s, %(High)s, %(Low)s, %(Close)s, %(LastModBy)s, %(CreateBy)s)")

    ticker.initTicker()
    print("ticker initialized")
    #-------------------------------------------------------------
    #  Process the input file...
    #-------------------------------------------------------------
    with open(sys.argv[1]) as csv_file:
        reader = csv.reader(csv_file, delimiter=',')
        line = 0

        for r in reader:
            if line == 0:
                pass
            else:
                try:
                    x = ticker.tickers[r[0]]
                except KeyError:
                    print("key error");
                    ticker.unknownTicker(r[0])
                    sys.exit()

                if x == 1:
                    y = int(r[1][:4])   # the date is in this format: YYYYMMDD
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
                        'LastModBy': UID,
                        'CreateBy': UID,
                    }
                    print("{}. {} {}-{}-{} {}:{} UID={}".format(line,r[0],y,m,d,H,M,UID))
                    try:
                        cursor.execute(add_exch,rec)
                    except mysql.connector.Error as err:
                        print("db error on insert: ")
                        print(err)
                        cursor.close()
                        cnx.close()
                        sys.exit()
            line += 1

    cnx.commit()
    cursor.close()
    cnx.close()

Main()
