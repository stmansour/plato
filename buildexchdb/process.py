import sys
import csv
import datetime

# a class to hold a record of foreign exchange info
class Forex:
    pass

with open(sys.argv[1]) as csv_file:
    reader = csv.reader(csv_file, delimiter=',')
    line = 0
    for r in reader:
        if line == 0:
            print(f'Column names are {", ".join(r)}')
        else:
            rec = Forex()
            rec.Ticker = r[0]    # a string
            # the date is in this format: YYYYMMDD
            y = int(r[1][:4])
            m = int(r[1][5:7])
            d = int(r[1][7:])
            H = int(r[2][:2])
            M = int(r[2][2:4])
            rec.Date = datetime.datetime(y,m,d,H,M)
            print("Ticker = ", rec.Ticker, " ", rec.Date)
        line += 1
    print(f'Processed {line} lines.')
