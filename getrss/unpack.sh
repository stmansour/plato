#!/bin/bash
#
#=============================================================================

TMPRSS="tmprss"
OUTFILE="nytimesrss.csv"
DEBUG=0
CHOMPFILE=""
CHOMPDIR=""

# prints the first arg if DEBUG == 1
function dprint() {
    if (( DEBUG == 1 )); then
        echo "${1}"
    fi
}

function usage() {
   cat << FEOF

unpack.sh [OPTIONS] basedir

   This routine processes a directory structure of .xml files produced from
   waybackpack. It finds all the xml files starting from basedir. It creates
   a script call doit.sh to actually do the processing.

OPTIONS

   -d  debug mode
   -h  Prints out this documentation


Examples:

$ ./unpack.sh "/Volumes/Extreme Pro/rss/nytimes"
  Find all xml files under "/Volumes/Extreme Pro/rss/nytimes" and process them.
FEOF
}

pause() {
	echo
	read -p "Press [Enter] to continue" x
    echo "you entered: ${x}"
}

# chomp  -   chomp the rss feeds.  File to process should be in CHOMPFILE
#---------------------------------------------------------------------------
function chomp() {
    dprint "Entered chomp, CHOMPFILE = ${CHOMPFILE}"
    # pause
    python3 chomp.py "${CHOMPFILE}"
}


###############################################################################

#----------------------------------------------------------------
# Process any URLs that were passed in on the command line...
#----------------------------------------------------------------
if [[ "#{@}" == "0" ]]; then
    echo "You must supply the root directory"
    exit 1
fi

while getopts "dh" o; do
	# echo "o = ${o}"
	case "${o}" in
        d | D)
            DEBUG=1
            ;;
		h | H)
			usage
			exit 1
			;;
		*) 	usage
			exit 1
			;;
	esac
done
shift $((OPTIND-1))

echo "arg = ${1}"
urls=$(find "${1}" -name "*.xml")
for i in "${urls[@]}"; do
    echo "i = ${i}"
    # pause
    python3 chomp.py "${i}"
done

OUT="doit.sh"

cat >${OUT} <<EOF
#!/bin/bash
declare a=(
EOF

find "${1}" -name "*.xml" | sed 's/^/"/' | sed 's/$/"/' >> ${OUT}

echo ')'  >> ${OUT}
echo 'for i in "${a[@]}"; do' >> ${OUT}
echo 'echo $i' >> ${OUT}
echo 'xmllint --format - < "${i}"  >x' >> ${OUT}
echo 'python3 chomp.py x' >> ${OUT}
echo 'done' >> ${OUT}

chmod +x ${OUT}

# When we have the disk space... uncomment the next line...
./doit.sh
