#!/usr/bin/env bash

TMPRSS="tmprss"

declare -a urls=(
    "https://rss.nytimes.com/services/xml/rss/nyt/US.xml"
    "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml"
    "https://rss.nytimes.com/services/xml/rss/nyt/Business.xml"
)

# process  -   process the rss feeds
# $1 = the url to process
#---------------------------------------------------------------------------
function process() {
    echo "retrieving from: ${1}"
    curl -s "${1}" -o "${TMPRSS}"
    python3 chomp.py "${TMPRSS}" nytimsrss.csv
}

# cleanup - remove temp files
#---------------------------------------------------------------------------
function cleanup() {
    rm -f "${TMPRSS}"
}

# process  -   process the rss feeds
# $1 = the url to process
#---------------------------------------------------------------------------
function main() {
    for url in "${urls[@]}"; do
        process "${url}"
    done
}

main
cleanup
