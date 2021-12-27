#!/usr/bin/env bash

declare -a urls=(
#  "https://feeds.a.dj.com/rss/RSSOpinion.xml"
  # "https://feeds.a.dj.com/rss/RSSWorldNews.xml"
  # "https://feeds.a.dj.com/rss/WSJcomUSBusiness.xml"
  # "https://feeds.a.dj.com/rss/RSSMarketsMain.xml"
  # "https://feeds.a.dj.com/rss/RSSWSJD.xml"
  # "https://feeds.a.dj.com/rss/RSSLifestyle.xml"
  #
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

DEST="/Volumes/Plato/rss"
DTSTART="20110202"
DOWNLOADED="completed.txt"
echo "URLS downloaded to disk during this run:" > ${DOWNLOADED}

for url in "${urls[@]}"; do
    rm -rf "${DEST}"
    mkdir -p "${DEST}"
    RETRIES=0
    while (( RETRIES < 3 )); do
        waybackpack "${url}" --max-retries 3 --from-date "${DTSTART}" -d "${DEST}"
        if [ $? -eq 0 ]; then
            RETRIES=3
        else
            ((RETRIES += 1))
            sleep 10
        fi
    done
    echo -n "${url} " >> ${DOWNLOADED}
    echo "Ready to call unpack.sh \"${url}\" \"${DEST}\""
    # exit 0    # this is temporary... just need to debug and make sure everything works.
    ./unpack.sh "${url}" "${DEST}"
    echo "finished" >> ${DOWNLOADED}
done
