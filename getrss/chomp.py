from datetime import datetime
import json
import re
import sys
import os.path
import mysql.connector
from mysql.connector import errorcode


item = 0            # Global highest item number processed
currentItem = 0     # Global current item number
lineno = 0          # Global line number of input file
url = ""            # url associated with current item
title = ""          # title associated with current item
description = ""    # short description of the article
pubDate = ""        # date on which the article was published
items = []          # the list of items that are created
cnx = None
add_item = ("INSERT INTO Item "
            "(Title, Description, PubDt, Link) "
            "VALUES (%(Title)s, %(Description)s, %(PubDt)s, %(Link)s)")

# def forceDBError():
#     add_test = ("INSERT INTO Item "
#                 "(Title, Description, Link) "
#                 "VALUES (%(Title)s, %(Description)s, %(Link)s)")
#     try:
#         cnx = mysql.connector.connect(user='ec2-user', database='plato', host='localhost')
#         cursor = cnx.cursor()
#     except mysql.connector.Error as err:
#         if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
#             print("Problem with user name or password")
#         elif err.errno == errorcode.ER_BAD_DB_ERROR:
#             print("Database does not exist")
#         else:
#             print(err)
#         sys.exit()
#
#     rec1 = {
#         'Title' : 'hey',
#         'Description' : 'hey there',
#         'Link' : 'http://example.com/hey',
#     }
#     rec2 = {
#         'Title' : 'heyYou',
#         'Description' : 'heyYou there',
#         'Link' : 'http://example.com/hey',
#     }
#     try:
#         cursor.execute(add_test,rec1)
#         cursor.execute(add_test,rec2)
#     except mysql.connector.Error as err:
#         print("db error on insert: " + str(err))
#
#     #------------------------------------
#     #  Now commit all the updates...
#     #------------------------------------
#     cnx.commit()
#     cursor.close()
#     cnx.close()


def updateDB():
    global cnx
    dups = {}

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
    # Open the database and copy the RSS info to the Item table
    #-------------------------------------------------------------
    try:
        # cnx = mysql.connector.connect(user='ec2-user', database='plato', host='localhost')
        cnx = mysql.connector.connect(user=config.get("PlatoDbuser"),
                                      password=config.get("PlatoDbpass"),
                                      database=config.get("PlatoDbname"),
                                      host=config.get("PlatoDbhost"))
        cursor = cnx.cursor()
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("Problem with user name or password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print("Database does not exist")
        else:
            print(err)
        sys.exit()

    for i in items:
        #-----------------------------------------------------
        # never write the same article out twice...
        #-----------------------------------------------------
        try:
            found = dups[i[3]]
        except Exception as e:
            dups[i[3]] = 1
            found = 0
        if found > 0:
            print("Duplicate: {}".format(i[2]))
        else:
            rec = {
                'Title' : i[2],
                'Description' : i[4],
                'PubDt' : i[1],
                'Link' : i[3],
            }
            try:
                cursor.execute(add_item,rec)
            except mysql.connector.Error as err:
                s = str(err)
                idx = s.find("Duplicate entry")
                if idx >= 0:
                    print('duplicate not added: ' + i[3])
                else:
                    print("db error on insert: " + s)
                    sys.exit("error writing to db")

    #------------------------------------
    #  Now commit all the updates...
    #------------------------------------
    cnx.commit()
    cursor.close()
    cnx.close()


# processLine - a function to pull selected data from an RSS item.  It
#               can be called successively as the rss file is processed
#               line-by-line, making it easier to support arbitrarily large
#               rss files.
#
#               This code looks for the following tags:
#                   <item>
#                   <link>
#                   <title>
#                   <description>
#                   <pubDate>
#
# l    = the line being processed
#-----------------------------------------------------------------------------
def processLine(l):
    global item
    global lineno
    global currentItem
    global url
    global title
    global description
    global pubDate

    l = l.rstrip()
    if "<item>" in l:
        if currentItem > 0:
            print("l = " + l)
            sys.exit("found <item> at line {} and currentItem = {}".format(lineno,currentItem))
        currentItem = item+1
        return

    if currentItem > 0:

        if "<link>" in l:
            u = re.findall(r"<link>([^<]+)</link>",l)
            url = u[0]
            # print("URL = " + url)

        if "<title>" in l:
            u = re.findall(r"<title>([^<]+)</title>",l)
            if len(u) < 1:
                print("**** WARNING ****  Could not match title end.  l = " + l)
                idx = l.find("<title>")
                s = l[idx + 7:]
                print("                   Setting title to partial value:  " + s)
                title = s
                return
            title = u[0]
            # print("TITLE = " + title)

        if "<description>" in l:
            i = l.find("<description>")
            if i < 0:
                pass
            s = l[i+13:-14]    # grab everything past <description> up to </description>
            i = s.find("<![CDATA[")
            if i >= 0:
                s = s[i+9:-3]   # everything after '<![CDATA[' up to ']]>'
            description = s
            # print("description = " + description)

        if "<pubDate>" in l:
            u = re.findall(r"<pubDate>([^<]+)</pubDate>",l)
            if len(u) > 0:
                pubDate = datetime.strptime(u[0], '%a, %d %b %Y %H:%M:%S %z')
                # print( "Date = {}".format(pubDate))

        if "</item>" in l:
            #                 0          1      2    3   4
            items.append((currentItem,pubDate,title,url,description))
            # print(items[item])
            currentItem = 0   # mark that no item is in scope
            url = ""
            title = ""
            description = ""
            pubDate = ""
            item += 1

# exportCSV -  exports each item in the global items[] to the supplied csv file.
#
#  fname = name of csv file. It will be created if it does not exist. Otherwise,
#          it will be appended to
#------------------------------------------------------------------------------
def exportCSV(fname):
    fopenopts = 'w'
    if os.path.exists(fname):
        fopenopts = 'a'

    dups = {}

    try:
        with open(sys.argv[2],fopenopts) as f:
            if fopenopts == 'w':
                f.write('"Pub Date","Title","Link","Description"\n')
            for i in items:
                #-----------------------------------------------------
                # never write the same article out twice...
                #-----------------------------------------------------
                try:
                    found = dups[i[3]]
                except Exception as e:
                    dups[i[3]] = 1
                    found = 0
                if found > 0:
                    print("Duplicate: {}".format(i[2]))
                else:
                    f.write('"{}", "{}", "{}", "{}"\n'.format(i[1],i[2],i[3],i[4]))
            f.close()
    except OSError as err:
        sys.exit("error opening/writing to file {}: {}".format(fname,err))


###############################################################################
#  MAIN ROUTINE
#
#  python3 chomp.py f1 f2
#
#  f1 = local file containing the rss feed in xml format
#  f2 = output csv file.  It will be created if it doesn't exist.  It will be
#       updated if it does exist.
###############################################################################
if len(sys.argv) < 3:
    sys.exit("You need to supply the file name to be parsed and the output file name.")

try:
    with open(sys.argv[1]) as f:
        for line in f:
            lineno += 1
            # print("{}: {}".format(lineno,line.rstrip()))
            processLine(line)
        f.close()
except OSError as err:
    sys.exit("error opening/reading {}: {}".format(sys.argv[1],err))



# exportCSV(sys.argv[2])
updateDB();
print("Exported {} rows".format(len(items)))
