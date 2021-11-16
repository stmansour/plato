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
        Trace "STARTDATE = ${STARTDATE}, STOPDATE = ${STOPDATE}"
        STARTDATESECS=$(date -j -f "%Y-%m-%d" "${STARTDATE}" "+%s")
        STOPDATESECS=$(date -j -f "%Y-%m-%d" "${STOPDATE}" "+%s")
    else
        STARTDATESECS=$(date -d "${STARTDATE}" "+%s")
        STOPDATESECS=$(date -d "${STOPDATE}" "+%s")
    fi
}

#-------------------------------------------------------------------------------
#  ExtractYMD  - Extract year, month, day values from a string formatted as:
#                  "YYYY-MM-DD"
#
#-------------------------------------------------------------------------------
ExtractYMD () {
    Trace "ExtractYMD"
    YEAR="${d:0:4}"
    MONTH="${d:5:2}"
    DAY="${d:8:2}"

    Trace "YEAR = ${YEAR}, MONTH = ${MONTH}, DAY = ${DAY}"
}

#-------------------------------------------------------------------------------
#  QueryUserForNumber  -  Ask the user for a number and provide limits if needed.
#
#  $1 = prompt string
#  $2 = default value
#  $3 = lower limit
#  $4 = upper limit
#
#  caller does this:
#       resp=$(QueryUserForNumber "month" 3 1 12)
#-------------------------------------------------------------------------------
QueryUserForNumber () {
    DONE=0
    while [ ${DONE} -eq 0 ]; do
        read -rp "${1} [${2}]: " a
        DONE=1
        if [[ "${3}x" != "x" ]]; then
            if (( a < ${3} )); then
                echo "the value must be at least ${3}"
                DONE=0
            fi
        fi
        if [[ "${4}x" != "x" ]]; then
            if (( a > ${4} )); then
                echo "the value must not be larger than ${4}"
                DONE=0
            fi
        fi
    done
    echo "${a}"
}

#-------------------------------------------------------------------------------
#  QueryUserForDateString  -  Ask the user for a date string.
#
#  $1 = prompt string
#  $2 = default value
#
#  Example:
#       resp=$(QueryUserForNumber "Start date" "2018-02-27")
#-------------------------------------------------------------------------------
QueryUserForDateString () {
    DONE=0
    while [ ${DONE} -eq 0 ]; do
        read -rp "${1} [${2}]: " a
        DONE=1
        if [[ "${a}x" == "x" ]]; then
            a="${2}"
        fi
    done
    echo "${a}"
}

#-------------------------------------------------------------------------------
#  SetDateValues  -  set YEAR, MONTH, DAY based on DATASECS.
#
#  Example Usage:
#       [ set STARTDATESECS to whatever ]
#       DATESECS=${STARTDATESECS}
#       SetDateValues
#       STARTDATE=${DAY}
#       STARTMONTH=${MONTH}
#       STARTYEAR=$YEAR
#
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
#  SetEarliestStart  -  set the starting date to the earliest known data
#                       collection time.
#-------------------------------------------------------------------------------
SetEarliestStart () {
    Trace "SetEarliestStart"
    # earlies date is 01-02-2011
    STARTDAY=02
    STARTMONTH=01
    STARTYEAR=2011
    STARTDATE="${STARTYEAR}-${STARTMONTH}-${STARTDAY}"
}

#-------------------------------------------------------------------------------
#  SetTodayAsStop  -  set today's date as the stop time
#-------------------------------------------------------------------------------
SetTodayAsStop () {
    Trace "SetEarliestStart"
    # earlies date is 01-02-2011
    STOPYEAR=$(date "+%Y")
    STOPMONTH=$(date "+%m")
    STOPDAY=$(date "+%d")
    STOPDATE="${STOPYEAR}-${STOPMONTH}-${STOPDAY}"
}


#-------------------------------------------------------------------------------
#  FinalizeDateRange  -  set values needed by Main
#-------------------------------------------------------------------------------
FinalizeDateRange () {
    Trace "FinalizeDateRange  MODE = ${MODE}"
    SetDateSecs
    Trace "STARTDATESECS: ${STARTDATESECS}"
    if [ "${MODE}" == "today" ]; then
        STARTDATESECS=$((STARTDATESECS-OFFSET))
        Trace "STARTDATESECS: ${STARTDATESECS}"
    fi
    DATESECS=${STARTDATESECS}
    SetDateValues
    STARTDATE="${YEAR}-${MONTH}-${DAY}"
    Trace "STARTDATESECS: ${STARTDATESECS}, STOPDATESECS: ${STOPDATESECS}"
}
#-------------------------------------------------------------------------------
#  Today  -  set the start and stop dates to pull today's information
#-------------------------------------------------------------------------------
Today () {
    Trace "Today"
    SetTodayAsStop

    STARTYEAR="${STOPYEAR}"
    STARTMONTH="${STOPMONTH}"
    STARTDAY="${STOPDAY}"
    STARTDATE="${STARTYEAR}-${STARTMONTH}-${STARTDAY}"
    FinalizeDateRange
}


SetGetAllDates () {
    Trace "SetGetAllDates"
    SetEarliestStart
    SetTodayAsStop
    FinalizeDateRange
}

#-------------------------------------------------------------------------------
#  GetAllData  -  query the user for the date range to collect
#-------------------------------------------------------------------------------
GetRangeDates () {
    Trace "GetRangeDates"
    SetEarliestStart
    SetTodayAsStop
    STARTDATE=$(QueryUserForDateString "Start date" "${STARTDATE}")
    STOPDATE=$(QueryUserForDateString "Stop date" "${STOPDATE}")
    FinalizeDateRange
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

    all, a, -all, -a
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

    range, r, -range, -r
        Query for the date range of exchange rate extraction.

    today, t, -today, -t
        Update the database with today's information. For table Exch, this means
        adding all the exchange rate information for yesterday.

EXAMPLES:
    Command to update plato database with today's information:

        bash$  ./${PROGNAME}

    Command to start ${PROGNAME}, remove the old exch database and create a new
    one:

    	bash$  ./${PROGNAME} newdb

    Command to start ${PROGNAME}, remove the old exch database and create a new
    one with all exchange information available online:

    	bash$  ./${PROGNAME} newdb all

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
#  Init - Perform all initialization needed.
#       To connect to the "plato" database, we need to have SonicWall running.
#-------------------------------------------------------------------------------
Init () {
    Trace "Entering Init"
    SONIC=$(ps -ef | grep "SonicWall Mobile Connect" | grep -vc grep)
    if (( SONIC < 2 )); then
        "/Applications/SonicWall Mobile Connect.app/Contents/MacOS/SonicWall Mobile Connect" &
        echo "Please open the connection to Accord's Mariadb, then try again"
        exit 0
    fi
    Trace "Exiting Init"
}
#-------------------------------------------------------------------------------
#  Main  -  Pull data STARTDATE to ENDDATE. Information
#       for all Tickers is provided in the files we get from the URL. The
#       Python program process.py extracts the information of interest.
#-------------------------------------------------------------------------------
Main () {
    Trace "Main   MODE: ${MODE}"

    if [ "${MODE}" == "today" ]; then
        Today
    elif [[ "${MODE}" == "range" ]]; then
        GetRangeDates
    elif [[ "${MODE}" == "all" ]]; then
        SetGetAllDates
    else
        echo "Unrecognized mode:  \"${MODE}\""
        exit 1
    fi

        #statements
    Trace "Main  STARTDATESECS: ${STARTDATESECS}, STOPDATESECS: ${STOPDATESECS}"

    #-------------------------
    # Quick sanity check...
    #-------------------------
    if [ "${STARTDATESECS}x" == "x" ]; then
        echo "*** ERROR ***  STARTDATESECS = \"${STARTDATESECS}\""
        exit 1
    fi
    if [ "${STOPDATESECS}x" == "x" ]; then
        echo "*** ERROR ***  STOPDATESECS = \"${STOPDATESECS}\""
        exit 1
    fi

    #-----------------
    # On with it...
    #-----------------
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
    "debug" | "-debug" | "-d" )
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
    "all" | "a" | "-all" | "-a")
        MODE="all"
        DONE=0
        ans=""
        while [ ${DONE} -eq 0 ]; do
            echo "This will pull all data from ${STARTDATE} to today."
            echo "It will take a long time."
            read -rp 'Continue?  [y/n]: ' a
            ans=$(echo "${a}" | tr "[:upper:]" "[:lower:]")
            if [[ "${ans}" == "y" || "${ans}" == "n" ]]; then
                if [[ "${ans}" == "y" ]]; then
                    MODE="all"
                    DONE=1
                else
                    exit 0
                fi
            else
                echo "you must enter y or n. y = yes, n = no"
            fi
        done
        ;;
    "today" | "t" | "-t" | "-today")
        MODE="today"
        ;;
    "range" | "r" | "-range" | "-r")
        MODE="range"
        ;;
	*)  #invalid argument
		echo "Unrecognized command: $arg"
		usage
		exit 1
		;;
    esac
done

Init
Main

if [ -f "missing.txt" ]; then
    echo "--------------------------------------------------"
    echo "               **** NOTICE ****"
    echo "--------------------------------------------------"
    echo "There are unhandled tickers:"
    cat missing.txt
    echo "--------------------------------------------------"
fi
