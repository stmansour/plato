 #!/usr/bin/env bash
 #
 #=============================================================================

TMPRSS="tmprss"
OUTFILE="nytimesrss.csv"

declare -a urls=(
  "https://feeds.a.dj.com/rss/RSSOpinion.xml"
  "https://feeds.a.dj.com/rss/RSSWorldNews.xml"
  "https://feeds.a.dj.com/rss/WSJcomUSBusiness.xml"
  "https://feeds.a.dj.com/rss/RSSMarketsMain.xml"
  "https://feeds.a.dj.com/rss/RSSWSJD.xml"
  "https://feeds.a.dj.com/rss/RSSLifestyle.xml"

  "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/World.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Africa.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Americas.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/AsiaPacific.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Europe.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/MiddleEast.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/US.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Education.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Politics.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Upshot.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/NYRegion.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Business.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/EnergyEnvironment.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/SmallBusiness.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Economy.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Dealbook.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/MediaandAdvertising.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/YourMoney.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/PersonalTech.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Sports.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Baseball.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/CollegeBasketball.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/CollegeFootball.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Golf.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Hockey.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/ProBasketball.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/ProFootball.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Soccer.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Tennis.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Science.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Climate.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Space.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Well.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Arts.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/ArtandDesign.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Books.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/SundayBookReview.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Dance.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Movies.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Music.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Television.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Theater.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/FashionandStyle.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/DiningandWine.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/tmagazine.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Jobs.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/RealEstate.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Automobiles.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Lens.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/Obituaries.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/MostEmailed.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/MostShared.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/MostViewed.xml"
  "https://rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"

)

function usage() {
    cat << FEOF

collect.sh [OPTIONS] [url1] [url2] ... [urln]

    This routine copies the rss feed information from one or more urls that
    point to an xml rss feed into a local file and calls the python routine
    chomp.py to process each xml file.

    If called with no arguments, it will pull the feed information from an
    internal list of urls.

    If called with arguments, each argument is assumed to be a valid url to an
    xml rss feed. In this case, it will ignore the internal list of urls.

OPTIONS

    -h, -help  Prints out this documentation


Examples:

$ ./collect.sh
  Process the internal list of urls

$ ./collect.sh https://feeds.a.dj.com/rss/RSSMarketsMain.xml
  Process only https://feeds.a.dj.com/rss/RSSMarketsMain.xml
FEOF

}

# process  -   process the rss feeds
# $1 = the url to process
#---------------------------------------------------------------------------
function process() {
    echo "retrieving from: ${1}"
    curl -s "${1}" -o "${TMPRSS}"
    # echo "will execute:  python3 chomp.py ${1} ${TMPRSS} ${OUTFILE} "
    python3 chomp.py "${1}" "${TMPRSS}" "${OUTFILE}"
}

#-------------------------------------------------------------------------------
#  init - Perform all initialization needed.
#       To connect to the "plato" database, we need to have SonicWall running.
#-------------------------------------------------------------------------------
init () {
    Trace "Entering init"
    if [ ! -f config.json ]; then
        jfrog rt dl accord/misc/confdev.json
        mv misc/confdev.json .; cp confdev.json config.json
        rm -rf misc
    fi
    Trace "Exiting init"
}

# cleanup - remove temp files
#---------------------------------------------------------------------------
function cleanup() {
    # rm -f "${TMPRSS}"
    echo ""
}

# main routine...
#
#---------------------------------------------------------------------------
function main() {
    for url in "${urls[@]}"; do
        process "${url}"
    done
}

###############################################################################

#----------------------------------------------------------------
# Process any URLs that were passed in on the command line...
#----------------------------------------------------------------
DONE=0
if [[ "#{@}" != "0" ]]; then
    for url in "$@"; do
        case "${url}" in
        "help" | "h" | "-h" | "-help")
            usage
            exit 0
            ;;
        *)
            init
            process "${url}"
            DONE=1
            ;;
        esac
    done
    if (( DONE == 1 )); then
        cleanup
        exit 0
    fi
fi

#----------------------------------------------------------------
# If no urls were supplied, use our internal list
#----------------------------------------------------------------
init
main
cleanup
