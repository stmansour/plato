# grab nytimes rss page
curl https://archive.nytimes.com/www.nytimes.com/services/xml/rss/index.html -o x

# get to the list of rss xml files
grep "https://rss.nytimes.com/services/xml/rss/nyt" x | sed 's/^[^"][^"]*//' | sed 's/^"[ \t]*https://' | sed 's/\.xml.*$/.xml/' > x2
