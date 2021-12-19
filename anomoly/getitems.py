import sys
import csv
import datetime
import mysql.connector

def Test1():
    MaxItems = 10000
    DtStart = "2021-09-01"
    DtStop = "2021-11-15"
    q = 'SELECT Title,IID FROM Item WHERE "{}" <= PubDt AND PubDt < "{}" LIMIT {};'.format(DtStart,DtStop,MaxItems)
    print("query = " + q)
    cursor.execute(q)
    rows = cursor.fetchall()
    print( "Number of rows found: {}".format(len(rows)))

def Test2():
    f = "https://rss.nytimes.com/services/xml/rss/nyt/World.xml"
    q = 'SELECT RSSID FROM RSSFeed WHERE URL = "{}";'.format(f)
    cursor.execute(q)
    row = cursor.fetchall()
    print("len(row) = {}".format(len(row)))
    print(row)

    f = "https://rss.nytimes.com/services/xml/rss/nyt/USA.xml"
    q = 'SELECT RSSID FROM RSSFeed WHERE URL = "{}";'.format(f)
    row = cursor.fetchall()
    print("len(row) = {}".format(len(row)))
    print(row)

    if len(row) == 0:
        add_feed = ("INSERT INTO RSSFeed" "(URL,LastModBy,CreateBy)" "VALUES (%(URL)s, %(CreateBy)s, %(LastModBy)s)")
        UID = -99997  # chomp.py program
        rec = {
            'URL' : f,
            'CreateBy': UID,
            'LastModBy': UID,
        }
        try:
            cursor.execute(add_feed,rec)
        except mysql.connector.Error as err:
            print("db error on RSSFeed insert: " + str(err))
            sys.exit("error writing to db")

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

#Test1()
Test2()
cnx.commit()
cursor.close()
cnx.close()
