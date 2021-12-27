from datetime import datetime
import json
import re
import sys
import os.path
import mysql.connector
from mysql.connector import errorcode
from urllib import parse

###############################################################################
#  chomp.py
#
#  USAGE:
#  bash$ python3 chomp.py rssfeed f1 [f2]
#
#  INPUTS:
#  rssfeed = the url used to load the RSS Feed
#  f1      - the xml rss file to be parsed
#  f2      - optional - the name of the csv file that should be written out.
###############################################################################
item = 0            # Global highest item number processed
currentItem = 0     # Global current item number
lineno = 0          # Global line number of input file
url = ""            # url associated with current item
title = ""          # title associated with current item
description = ""    # short description of the article
pubDate = ""        # date on which the article was published
items = []          # the list of items that are created
cnx = None
duplicates = 0      # keep track of the number of duplicate entries
newrecs = 0         # keep track of the number of writes
rssfeed = ""        # name of rssfeed from which Items came.
UID = -99997        # chomp.py program
RSSID = 0           # ID of the RSSFeed for the articles being processed



# processFeedName -
#   1. Extract the feedname from the rssfeed url
#   2. If database already has this feed pull get its RSSID
#   3. If the feed does not yet exist, add it
#
#------------------------------------------------------------------------------
def processFeedName(f):
    global RSSID
    print("calling parse.urlsplit on: {}".format(f))
    rssfeed = parse.urlsplit(f)  # break up the URL into its component pieces
    feedname = os.path.splitext(os.path.basename(rssfeed.path))[0]  # basefilename minus extension is feedname
    cursor = cnx.cursor()

    q = 'SELECT RSSID FROM RSSFeed WHERE URL = "{}";'.format(f)
    cursor.execute(q)
    rows = cursor.fetchall()

    if len(rows) == 0:
        add_feed = ("INSERT INTO RSSFeed" "(URL,LastModBy,CreateBy)" "VALUES (%(URL)s, %(CreateBy)s, %(LastModBy)s)")
        UID = -99997  # chomp.py program
        rec = {
            'URL' : f,
            'CreateBy': UID,
            'LastModBy': UID,
        }
        try:
            cursor2 = cnx.cursor()
            cursor2.execute(add_feed,rec)
            cursor2.execute(q)
            rows = cursor2.fetchall()
            if len(rows) == 0:
                print("could not read back RSSID after write!")
                sys.exit("error reading back new RSSID after write")
        except mysql.connector.Error as err:
            print("db error on RSSFeed insert: " + str(err))
            sys.exit("error writing to db")

    RSSID = rows[0][0]
    print("Processing articles from RSSID = {} - {} ({})".format(RSSID,feedname,f))


#-------------------------------------------------------------------------------
# updateDB - writes items to the database
#
# INPUTS
# f = rssfeed name
#-------------------------------------------------------------------------------
def updateDB(feed):
    global cnx
    global duplicates
    global newrecs
    global RSSID
    dups = {}
    UID = -99998

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

    #------------------------------------------------
    # First thing to do is set the RSSFeed...
    #------------------------------------------------
    processFeedName(feed)

    add_item = ("INSERT INTO Item "
                "(Title, Description, PubDt, Link, CreateBy, LastModBy) "
                "VALUES (%(Title)s, %(Description)s, %(PubDt)s, %(Link)s, %(CreateBy)s, %(LastModBy)s)")
    add_itemfeed = ("INSERT INTO ItemFeed "
                    "(IID,RSSID)"
                    "VALUES (%(IID)s, %(RSSID)s)")
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
            duplicates = duplicates + 1
        else:
            rec = {
                'Title' : i[2],
                'Description' : i[4],
                'PubDt' : i[1],
                'Link' : i[3],
                'CreateBy': UID,
                'LastModBy': UID,
            }
            try:
                newrecs = newrecs + 1
                cursor.execute(add_item,rec)
                q = 'SELECT IID FROM Item WHERE Link="{}"'.format(i[3])
                cursor.execute(q)
                rows = cursor.fetchall()
                if rows == 0:
                    print("Could not read back Item after writing it!")
                    sys.exit("Could not find Item just written")
                IID = rows[0][0]
                itemfeed = {
                    'IID' : IID,
                    'RSSID' : RSSID,
                }
                try:
                    cursor.execute(add_itemfeed,itemfeed)
                except mysql.connector.Error as err:
                    print("Error writing ItemFeed: " + str(err))
                    sys.exit("Failed to write ItemFeed")

            except mysql.connector.Error as err:
                s = str(err)
                idx = s.find("Duplicate entry")
                if idx >= 0:
                    print('duplicate not added: ' + i[3])
                    duplicates = duplicates + 1
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
    fmts = ['%a, %d %b %Y %H:%M:%S %z', '%a, %d %b %Y %H:%M:%S %Z']

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
            found = False
            if len(u) > 0:
                s = u[0]
                for fmt in fmts:
                    try:
                        pubDate = datetime.strptime(s, fmt)
                        found = True
                        break
                    except ValueError as e:
                        found = False

            if found == False:
                print("No format found that parses {}".format(s))

        if "</item>" in l:
            #                 0          1      2    3   4
            items.append((currentItem,pubDate,title,url,description))
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
#  python3 chomp.py rssfeed f1 [f2]
#
#  sys.argv[1]: rssfeed = name of rssfeed supplying these articles
#  sys.argv[2]: f1 = local file containing the rss feed in xml format
#  sys.argv[3]: f2 = output csv file.  It will be created if it doesn't exist.
#               It will be created if it does exist.
###############################################################################
if len(sys.argv) < 3:
    sys.exit("You must supply the rssfeed name and the file to be parsed.\nThe output file is optional.")

try:
    print("Opening: " +sys.argv[2])
    with open(sys.argv[2]) as f:
        for line in f:
            lineno += 1
            # print("{}: {}".format(lineno,line.rstrip()))
            processLine(line)
        f.close()
except OSError as err:
    sys.exit("error opening/reading {}: {}".format(sys.argv[2],err))

# removed for now because we really want this information in a database
# exportCSV(sys.argv[2])

updateDB(sys.argv[1]);
print("New records: {}\nDuplicates: {}\n".format(newrecs-duplicates, duplicates))
