#!/bin/bash
RSSFEED="https://rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
BASEDIR="/Volumes/Plato/rss"
declare a=(
"/Volumes/Plato/rss/20220104210224/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20220105223301/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
"/Volumes/Plato/rss/20220106222650/rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml"
)
for i in "${a[@]}"; do
echo $i
xmllint --format - < "${i}"  >x
python3 chomp.py "https://rss.nytimes.com/services/xml/rss/nyt/sunday-review.xml" x
done
