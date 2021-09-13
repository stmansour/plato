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

Initialize () {
    OS=$(uname)     # we need this because of quirks with Mac OS date(1)

    STARTDAY=01
    STARTMONTH=02
    STARTYEAR=2011
    STARTDATE="${STARTYEAR}-${STARTMONTH}-${STARTDAY}"

    # STOPYEAR=$(date "+%Y")
    # STOPMONTH=$(date "+%m")
    # STOPDAY=$(date "+%d")
    STOPDAY=01
    STOPMONTH=02
    STOPYEAR=2016
    STOPDATE="${STOPYEAR}-${STOPMONTH}-${STOPDAY}"

    echo "Start Date:  ${STARTDATE}"
    echo " Stop Date:  ${STOPDATE}"

    echo -n "Resetting exch database... "
    mysql --no-defaults < schema.sql
    echo "done!"

    clean
}

clean () {
    rm -rf *.txt __pycache__ *.zip
}

usage() {
    PROGNAME="newdb.sh"
    cat <<ZZEOF

Foreign Exchange Database Creator

    Usage:   newdb.sh [OPTIONS] CMD

    This command removes a mysql database named exch and create a new one based
    on the configuration parameters in Initialize.

OPTIONS:
    (currently there are no options)

CMD:
    CMD is one of the following:

    clean
        Use this command to remove any temporary files that the script
        creates during a run operation.

EXAMPLES:
    Command to start newdb.sh, remove the old exch database and create a new one
    	bash$  ./newdb.sh

    Command to remove any temporary files that may be in this directory due
    to stopping the program earlier or due to an error.
    	bash$  ./newdb.sh clean

    Command to see if ${PROGNAME} is ready for commands... the response
    will be "OK" if it is ready, or something else if there are problems:

        bash$  activate.sh ready
        OK
ZZEOF
}

ProcessExch () {
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
    echo -n "${URL}  ..."

    #---------------------------------------------------------------------
    # Download the data for this date and put it into the database...
    #---------------------------------------------------------------------
    curl -s "${URL}" -o "${FNAME}"
    retval=$?
    if [ ${retval} -ne 0 ]; then
        echo "Problem downloading ${URL}"
        exit 1
    fi
    unzip -qq "${FNAME}"
    echo -n "..."
    python3 process.py "${FTEXT}"
    rm -f "${FNAME}" "${FTEXT}"
    echo "done!"
}

#===========================================================================

for arg do
	# echo '--> '"\`$arg'"
	cmd=$(echo ${arg}|tr "[:upper:]" "[:lower:]")
    case "$cmd" in
	"clean")
		clean
		exit 0
		;;
	*)
		echo "Unrecognized command: $arg"
		usage
		exit 1
		;;
    esac
done

Initialize

#---------------------------------------------------------------------
# build a URL of the form:
#      https://www.forexite.com/free_forex_quotes/2001/11/011101.zip
#---------------------------------------------------------------------
if [ "${OS}" == "Darwin" ]; then
    STARTDATESECS=$(date -j -f "%Y-%m-%d" "${STARTDATE}" "+%s")
    STOPDATESECS=$(date -j -f "%Y-%m-%d" "${STOPDATE}" "+%s")
else
    STARTDATESECS=$(date -d "${STARTDATE}" "+%s")
    STOPDATESECS=$(date -d "${STOPDATE}" "+%s")
fi


DATESECS="${STARTDATESECS}"
offset=86400

while [ "${DATESECS}" -lt "${STOPDATESECS}" ];
do
    if [ "${OS}" == "Darwin" ]; then
        d=$(date -j -f "%s" "${DATESECS}" "+%Y-%m-%d")
    else
        d=$(date -d "@${DATESECS}" "+%Y-%m-%d")
    fi

    if [ "${OS}" == "Darwin" ]; then
        YEAR="${d:0:4}"
        MONTH="${d:5:2}"
        DAY="${d:8:2}"
    else
        DAY=$(date -d "${d}" "+%d")
        MONTH=$(date -d "${d}" "+%m")
        YEAR=$(date -d "${d}" "+%Y")
    fi

    echo -n "${YEAR}-${MONTH}-${DAY} (${DATESECS}) :: "
    # echo "DATESECS = ${DATESECS}, STOPDATESECS = ${STOPDATESECS}"

    ProcessExch

    DATESECS=$(($DATESECS+$offset))
done

if [ -f "missing.txt" ]; then
    echo "--------------------------------------------------"
    echo "               **** NOTICE ****"
    echo "--------------------------------------------------"
    echo "There are unhandled tickers:"
    cat missing.txt
    echo "--------------------------------------------------"
fi
