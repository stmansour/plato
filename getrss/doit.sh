#!/bin/bash
RSSFEED="https://rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
BASEDIR="/Volumes/Plato/rss"
declare a=(
"/Volumes/Plato/rss/20211223131717/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20211224135827/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20211225154201/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20211226134430/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20211227151628/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20211228141356/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20211229145750/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20211230153016/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20211231173232/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20220101182551/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20220102184606/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20220103202726/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
)
for i in "${a[@]}"; do
echo $i
xmllint --format - < "${i}"  >x
python3 chomp.py "https://rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml" x
done
