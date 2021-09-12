#!/usr/bin/env bash

#  A script to build the foreign exchange rate database
#
#  Data is pulled from https://www.forexite.com/free_forex_quotes/
#  from Jan 1, 2001 through system date - 1 day.  It comes as a
#  zip file. The file is unzipped, and each record is added to
#  the forex mysql database.

#
#  Data from the site looks like this:
#
# <TICKER>,<DTYYYYMMDD>,<TIME>,<OPEN>,<HIGH>,<LOW>,<CLOSE>
# EURUSD,20110102,230100,1.3345,1.3345,1.3345,1.3345
# EURUSD,20110102,230200,1.3344,1.3345,1.3340,1.3342
# EURUSD,20110102,230300,1.3341,1.3342,1.3341,1.3341
# EURUSD,20110102,230400,1.3341,1.3343,1.3341,1.3343
#
# It is processed by the python program process.py
#=======================================================================

OS=$(uname)     # we need this because of quirks with Mac OS date(1)

STARTDAY=01
STARTMONTH=02
STARTYEAR=2011
STARTDATE="${STARTYEAR}-${STARTMONTH}-${STARTDAY}"

STOPYEAR=$(date "+%Y")
STOPMONTH=$(date "+%m")
STOPDAY=$(date "+%d")
STOPDATE="${STOPYEAR}-${STOPMONTH}-${STOPDAY}"

echo "Start Date:  ${STARTDATE}"
echo " Stop Date:  ${STOPDATE}"

#---------------------------------------------------------------------
# build a URL of the form:
#      https://www.forexite.com/free_forex_quotes/2001/11/011101.zip
#---------------------------------------------------------------------
STARTDATESECS=$(date -j -f "%Y-%m-%d" "${STARTDATE}" "+%s")
STOPDATESECS=$(date -j -f "%Y-%m-%d" "${STOPDATE}" "+%s")
DATESECS="${STARTDATESECS}"
offset=86400

while [ "${DATESECS}" -lt "${STOPDATESECS}" ]
do
    d=$(date -j -f "%s" "${DATESECS}" "+%Y-%m-%d")
    if [ "${OS}" == "Darwin" ]; then
        YEAR="${d:0:4}"
        MONTH="${d:5:2}"
        DAY="${d:8:2}"
    else
        DAY=$(date "-v"-d "${d}" "+%d")
        MONTH=$(date -d "${d}" "+%m")
        YEAR=$(date -d "${d}" "+%Y")
    fi

    echo "YEAR = ${YEAR}, MONTH = ${MONTH}, DAY = ${DAY}"

    #---------------------------------------------------------------------
    # build a URL of the form:                        YYYY MM DDMMYY
    #      https://www.forexite.com/free_forex_quotes/2001/11/011101.zip
    #---------------------------------------------------------------------
    y="${YEAR:2:2}"
    FROOT="${DAY}${MONTH}${y}"
    FNAME="${FROOT}.zip"
    FTEXT="${FROOT}.txt"
    rm -f "${FNAME}" "${FTEXT}"
    URL=$(printf 'https://www.forexite.com/free_forex_quotes/%4d/%02d/%s' "${YEAR}" "${MONTH}" "${FNAME}")
    echo "URL = ${URL}"

    #---------------------------------------------------------------------
    # Download the data for this date and put it into the database...
    #---------------------------------------------------------------------
    curl -s "${URL}" -o "${FNAME}"
    unzip "${FNAME}"
    python3 process.py "${FTEXT}"
    exit 0
    rm -f "${FNAME}" "${FTEXT}"

    DATESECS=$(($DATESECS+$offset))
done
