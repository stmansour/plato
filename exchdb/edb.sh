#!/usr/bin/env bash

#  edb.sh    Exchange DataBase
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
NEWDB=0         # assume we're just going to add to the current db
MODE="today"    # all, today, ...
OFFSET=86400    # seconds per day
OS=$(uname)     # we need this because of quirks with Mac OS date(1)
DEBUG=0
KEEP=0

#-------------------------------------------------------------------------------
#  Today  -  set the start and stop dates to pull today's information
#
#  $1 = string to print if DEBUG != 0
#-------------------------------------------------------------------------------
Trace () {
    if ((DEBUG != 0)); then
        echo "TRACE:  ${1}"
    fi
}

#-------------------------------------------------------------------------------
#  SetDateSecs  -  STARTDATESECS and STOPDATESECS based on STARTDATE and
#                  STOPDATE
#
#  Note: the command used is OS dependent.
#-------------------------------------------------------------------------------
SetDateSecs () {
    Trace "SetDateSecs  - OS: ${OS}, STARTDATE: ${STARTDATE}, STOPDATE: ${STOPDATE}"
    if [ "${OS}" == "Darwin" ]; then
        STARTDATESECS=$(date -j -f "%Y-%m-%d" "${STARTDATE}" "+%s")
        STOPDATESECS=$(date -j -f "%Y-%m-%d" "${STOPDATE}" "+%s")
    else
        STARTDATESECS=$(date -d "${STARTDATE}" "+%s")
        STOPDATESECS=$(date -d "${STOPDATE}" "+%s")
    fi
}

#-------------------------------------------------------------------------------
#  Today  -  set the start and stop dates to pull today's information
#-------------------------------------------------------------------------------
Today () {
    Trace "Today"
    STOPYEAR=$(date "+%Y")
    STOPMONTH=$(date "+%m")
    STOPDAY=$(date "+%d")
    STOPDATE="${STOPYEAR}-${STOPMONTH}-${STOPDAY}"

    STARTYEAR="${STOPYEAR}"
    STARTMONTH="${STOPMONTH}"
    STARTDAY="${STOPDAY}"
    STARTDATE="${STARTYEAR}-${STARTMONTH}-${STARTDAY}"

    SetDateSecs
    STARTDATESECS=$((STARTDATESECS-OFFSET))
    DATESECS=${STARTDATESECS}
    SetDateValues
    STARTDATE="${YEAR}-${MONTH}-${DAY}"
    Trace "STARTDATESECS: ${STARTDATESECS}, STOPDATESECS: ${STOPDATESECS}"
}

#-------------------------------------------------------------------------------
#  GetAllData  -  set start and end dates for data gathering
#-------------------------------------------------------------------------------
GetAllData () {
    Trace "GetAllData"
    Today     # initialize STOP values

    # earlies date is 01-02-2011
    STARTDAY=02
    STARTMONTH=01
    STARTYEAR=2011
    STARTDATE="${STARTYEAR}-${STARTMONTH}-${STARTDAY}"

    # STOPDAY=03
    # STOPMONTH=10
    # STOPYEAR=2021
    STOPDATE="${STOPYEAR}-${STOPMONTH}-${STOPDAY}"
}

#-------------------------------------------------------------------------------
#  SetDateValues  -  set YEAR, MONTH, DAY based on DATASECS
#       Note: commands used are os dependent
#-------------------------------------------------------------------------------
SetDateValues () {
    Trace "SetDateValues   DATESECS = ${DATESECS}"
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
    Trace "YEAR: ${YEAR}, MONTH: ${MONTH}, DAY: ${DAY}"
}

#-------------------------------------------------------------------------------
#  clean  -  remove unneeded files from this directory
#-------------------------------------------------------------------------------
clean () {
    rm -rf ./*.txt __pycache__ ./*.zip
}

#-------------------------------------------------------------------------------
#  usage  -  Display information explaining how to use this script
#-------------------------------------------------------------------------------
usage() {
    PROGNAME="edb.sh"
    cat <<ZZEOF

Foreign Exchange Database Creator

    Usage:   ${PROGNAME} [OPTIONS] CMD

    This command removes a mysql database named "plato" and create a new one
    based on the configuration parameters in Initialize. If no options are
    provided then

OPTIONS:
    (currently there are no options)

CMD:
    CMD is one of the following:

    all
        Update the database with all the exchange information using the internal
        start and stop dates for this program.  Could run for many hours.

    clean
        Use this command to remove any temporary files that the script
        creates during a run operation.

    help
        Prints this text.

    kdf
        Do not remove (keep) the downloaded file.  Used for debugging.

    newdb
        Delete the old database and start a new one.  Note this will destroy
        the old database completely, including anything in Item table. Make sure
        you know what you're doing if you use this command. Otherwise you may
        destroy information that you didn't mean to destroy.

    today
        Update the database with today's information. For table Exch, this means
        adding all the exchange rate information for yesterday.

EXAMPLES:
    Command to update plato database with today's information:

        bash$  ./${PROGNAME}

    Command to start ${PROGNAME}, remove the old exch database and create a new
    one:

    	bash$  ./${PROGNAME} newdb

    Command to remove any temporary files that may be in this directory due
    to stopping the program earlier or due to an error:

    	bash$  ./${PROGNAME} clean

ZZEOF
}


#-------------------------------------------------------------------------------
#  DisplaySettings  -  Display the parameters that are being used for this run
#-------------------------------------------------------------------------------
DisplaySettings() {
    Trace "DisplaySettings"
    echo "Start Date:  ${STARTDATE}"
    echo " Stop Date:  ${STOPDATE}"
}

#-------------------------------------------------------------------------------
#  CheckCreateNewDB  -  if NEWDB was indicated, then recreate the db from scratch
#-------------------------------------------------------------------------------
CheckCreateNewDB () {
    Trace "CheckCreateNewDB"
    if [ "${NEWDB}" -eq 1 ]; then
        echo "Creating new plato database... "
        mysql --no-defaults < schema.sql
    fi
}

#-------------------------------------------------------------------------------
#  ProcessExch  -  Pull information for DAY, MONTH, YEAR. Information
#       for all Tickers is provided in the file we get from the URL. The
#       Python program process.py extracts the information of interest.
#-------------------------------------------------------------------------------
ProcessExch () {
    Trace "ProcessExch"
    #---------------------------------------------------------------------
    # build a URL of the form:                        YYYY MM DDMMYY
    #      https://www.forexite.com/free_forex_quotes/2001/11/011101.zip
    #---------------------------------------------------------------------
    y="${YEAR:2:2}"
    FROOT="${DAY}${MONTH}${y}"
    FNAME="${FROOT}.zip"
    FTEXT="${FROOT}.txt"
    rm -f "${FNAME}" "${FTEXT}"

    URL="https://www.forexite.com/free_forex_quotes/${YEAR}/${MONTH}/${FNAME}"
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
    if (( KEEP != 1 )); then
        rm -f "${FNAME}" "${FTEXT}"
    fi
    echo "done!"
}

#-------------------------------------------------------------------------------
#  Main  -  Pull data STARTDATE to ENDDATE. Information
#       for all Tickers is provided in the files we get from the URL. The
#       Python program process.py extracts the information of interest.
#-------------------------------------------------------------------------------
Main () {
    Trace "Main   STARTDATESECS: ${STARTDATESECS}, STOPDATESECS: ${STOPDATESECS}"
    DATESECS="${STARTDATESECS}"
    clean
    CheckCreateNewDB
    DisplaySettings

    while [ "${DATESECS}" -lt "${STOPDATESECS}" ];
    do
        SetDateValues
        echo -n "${YEAR}-${MONTH}-${DAY} (${DATESECS}) :: "
        # echo "DATESECS = ${DATESECS}, STOPDATESECS = ${STOPDATESECS}"
        ProcessExch
        DATESECS=$((DATESECS + OFFSET))
    done
}

#===========================================================================

#---------------------------------------------------------------------
# build a URL of the form:
#      https://www.forexite.com/free_forex_quotes/2001/11/011101.zip
#---------------------------------------------------------------------

for arg do
	# echo '--> '"\`$arg'"
	cmd=$(echo "${arg}" |tr "[:upper:]" "[:lower:]")
    case "$cmd" in
	"clean")
		clean
		;;
    "debug" | "-debug" )
        DEBUG=1
        ;;
    "help" | "h" | "-h" | "-help")
        usage
        exit 0
        ;;
    "kdf" | "-kdf")
        KEEP=1
        ;;
    "newdb")
        NEWDB=1
        ;;
    "all" )
        MODE="${cmd}"
        ;;
    "today")
        MODE="${cmd}"
        ;;
	*)  #invalid argument
		echo "Unrecognized command: $arg"
		usage
		exit 1
		;;
    esac
done

if [ "${MODE}" == "all" ]; then
    GetAllData
elif [ "${MODE}" == "today" ]; then
    Today
fi

Main

if [ -f "missing.txt" ]; then
    echo "--------------------------------------------------"
    echo "               **** NOTICE ****"
    echo "--------------------------------------------------"
    echo "There are unhandled tickers:"
    cat missing.txt
    echo "--------------------------------------------------"
fi
