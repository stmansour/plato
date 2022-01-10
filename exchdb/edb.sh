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
URLERRLIST="urlerrlist.txt"

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
#  GetRangeDates  -  query the user for the date range to collect
#-------------------------------------------------------------------------------
GetRangeDates () {
    Trace "GetRangeDates"
    SetEarliestStart
    SetTodayAsStop
    STARTDATE=$(QueryUserForDateString "Start date" "${STARTDATE}")
    STOPDATE=$(QueryUserForDateString "Stop date (up-to-but-not-including)" "${STOPDATE}")
    FinalizeDateRange
}

#-------------------------------------------------------------------------------
#  GetUpdateDates  -  query the database for the latest date in the Exch table
#                     then set the range to cover from that date to the current
#                     date
#-------------------------------------------------------------------------------
GetUpdateDates () {
    Trace "GetUpdateDates"
    SetTodayAsStop
    STARTDATE=$(echo "SELECT Dt FROM Exch ORDER BY Dt DESC limit 1;" | ${MYSQL} plato | grep -v Dt | sed 's/ .*//')
    STARTYEAR=$(echo "${STARTDATE}" | sed 's/\(....\).*/\1/')
    STARTMONTH=$(echo "${STARTDATE}" | sed 's/....-\([^-][^-]*\)-.*/\1/')
    STARTDAY=$(echo "${STARTDATE}" | sed 's/....-..-\(..\).*/\1/')
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

    This command updates a mysql database named "plato" based on the
    CMD and OPTIONS provided on the run command. If no options are provided then
    the "today" option is assumed.

    The newdb option will wipe out an existing database, so use it with
    caution.

OPTIONS:
    d, debug, -d, -debug
        Set debug m ode. Trace statements output to the screen.

    kdf
        Do not remove (keep) the downloaded file.  Used for debugging.

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

    -u, -update, u, update
        Bring the database up-to-date by filling in all the data starting from
        the latest date found in the Exch table and ending on today's date.

EXAMPLES:
    Command to update plato database with today's information:

        bash$  ./${PROGNAME}

    Command to update plato database with all information since the last time
    this script was run:

        bash$  ./${PROGNAME} update

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
    # Use a simple retry 3 times algorithm. I have seen curl fail on
    # these sites only to succeed the next try.
    #---------------------------------------------------------------------
    SUCCESS=0
    for (( retries=0; retries<3; retries++ )); do
        if curl --fail -s "${URL}" -o "${FNAME}"; then
            retries=3
            SUCCESS=1
        else
            attempt=$(( 1 + retries ))
            echo "Retry attempt ${attempt}"
            sleep 2
        fi
    done
    if (( SUCCESS != 1 )); then
        echo "Problem downloading ${URL}.  Attempted to download 3 times"
        echo "Logging this URL to ${URLERRLIST}"
        echo "${MONTH}/${DAY}/${YEAR}  :  ${URL}" >> "${URLERRLIST}"
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
    if [ ! -f config.json ]; then
        jfrog rt dl accord/misc/confdev.json
        mv misc/confdev.json .; cp confdev.json config.json
        rm -rf misc
    fi

    MYSQL=$(which mysql)
    if [ "x" == "${MYSQL}x" ]; then
        echo "mysql command not found. Ensure that mysql is installed an in your PATH then try again."
        exit 1
    fi
    MYSQL="${MYSQL} --no-defaults"
    # AccordNAS=$(grep PlatoDbhost config.json | sed 's/"PlatoDbhost": "//' | sed 's/",//' | grep "10.101.0.13" | wc -l)
    # if (( AccordNAS > 0 )); then
    #     SONIC=$(ps -ef | grep "SonicWall Mobile Connect" | grep -vc grep)
    #     if (( SONIC < 2 )); then
    #         "/Applications/SonicWall Mobile Connect.app/Contents/MacOS/SonicWall Mobile Connect" &
    #         echo "Please open the connection to Accord's Mariadb, then try again"
    #         exit 0
    #     fi
    # fi
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
    elif [[ "${MODE}" == "update" ]]; then
        GetUpdateDates
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

    #------------------------------------------------------------------------
    # if there were exchange currencies we haven't seen before, speak up
    #------------------------------------------------------------------------
    if [ -f "missing.txt" ]; then
        echo "--------------------------------------------------"
        echo "               **** NOTICE ****"
        echo "--------------------------------------------------"
        echo "There are unhandled tickers:"
        cat missing.txt
        echo "--------------------------------------------------"
    fi
}

#===========================================================================

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
    "-u" | "-update" | "u" | "update")
            MODE="update"
            ;;
	*)  #invalid argument
		echo "Unrecognized command: $arg"
		usage
		exit 1
		;;
    esac
done

T0=$(date "+%Y-%m-%d %H:%M:%S")
Init
Main
T1=$(date "+%Y-%m-%d %H:%M:%S")

if [ "${OS}" == "Darwin" ]; then
    T0SECS=$(date -j -f "%Y-%m-%d %H:%M:%S" "${T0}" "+%s")
    T1SECS=$(date -j -f "%Y-%m-%d %H:%M:%S" "${T1}" "+%s")
else
    T0SECS=$(date -d "${T0}" "+%s")
    T1SECS=$(date -d "${T1}" "+%s")
fi
# echo "T0SECS = ${T0SECS}     T1SECS = ${T1SECS}"
DUR=$(( T1SECS - T0SECS ))
DAYS=$(( DUR/(24*60*60) ))
DUR=$(( DUR - (DAYS*24*60*60) ))
HOURS=$(( DUR/(60*60) ))
DUR=$(( DUR - HOURS*60*60 ))
MINS=$(( DUR/60 ))
SECS=$(( DUR - MINS*60 ))
echo "Start Time:  ${T0}"
echo "Stop Time:   ${T1}"
echo "Duration:    ${DAYS} days, ${HOURS} hours, ${MINS} min, ${SECS} sec"
