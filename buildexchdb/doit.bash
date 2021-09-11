#!/usr/bin/env bash

#  A script to build the foreign exchange rate database
#
#  Data is pulled from https://www.forexite.com/free_forex_quotes/
#  from Jan 1, 2001 through system date - 1 day.  It comes as a
#  zip file. The file is unzipped, and each record is added to
#  the forex mysql database.

OS=$(uname)     # we need this because of quirks with Mac OS date(1)

STARTDAY=01
STARTMONTH=01
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
    URL=$(printf 'https://www.forexite.com/free_forex_quotes/%4d/%02d/%s' "${YEAR}" "${MONTH}" "${FNAME}")
    echo "URL = ${URL}"

    #---------------------------------------------------------------------
    # Download the data for this date and put it into the database...
    #---------------------------------------------------------------------
    curl -s "${URL}" -o "${FNAME}"
    unzip "${FNAME}"
    python3 process.py "${FTEXT}"
    rm -f "${FNAME}" "${FTEXT}"

    DATESECS=$(($DATESECS+$offset))
done
