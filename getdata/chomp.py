from datetime import datetime
import re
import sys
import os.path


item = 0            # Global highest item number processed
currentItem = 0     # Global current item number
lineno = 0          # Global line number of input file
url = ""            # url associated with current item
title = ""          # title associated with current item
description = ""    # short description of the article
pubDate = ""        # date on which the article was published
items = []          # the list of items that are created

# processLine - a function to pull selected data from an RSS item.  It
#               can be called successively as the rss file is processed
#               line-by-line, making it easier to support arbitrarily large
#               rss files.
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
            title = u[0]
            # print("TITLE = " + title)

        if "<description>" in l:
            u = re.findall(r"<description>([^<]+)</description>",l)
            if len(u) > 0:
                description = u[0]
            # print("TITLE = " + title)

        if "<pubDate>" in l:
            u = re.findall(r"<pubDate>([^<]+)</pubDate>",l)
            if len(u) > 0:
                pubDate = datetime.strptime(u[0], '%a, %d %b %Y %H:%M:%S %z')
                # print( "Date = {}".format(pubDate))

        if "</item>" in l:
            items.append((currentItem,pubDate,title,url,description))
            # print(items[item])
            currentItem = 0   # mark that no item is in scope
            url = ""
            title = ""
            description = ""
            pubDate = ""
            item += 1

# exportCSV -  exports fields in item to a a csv format
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

exportCSV(sys.argv[2])

print("Exported {} rows".format(len(items)))
