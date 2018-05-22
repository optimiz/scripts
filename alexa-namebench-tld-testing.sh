#! /bin/bash
# FE - Saturday, May 28 2016 - Heat a cold DNS cache.
# Average query for top 2,000 in com/net/org/edu drops to ~8ms even 24hrs after heating PDNS-recursor's cache on AT&T U-verse.
# fping -C 4 -s 68.94.156.8 68.94.156.1 206.13.28.12 206.13.31.12 12.127.17.71 12.127.17.72 99.99.99.53 99.99.99.153 8.8.8.8 8.8.4.4 9.9.9.9 149.112.112.112 9.9.9.10 149.112.112.10 1.1.1.1 1.0.0.1
# Friday, May 04 2018 - Tested QUAD9 https://www.quad9.net/ ; and, Cloudfare https://1.1.1.1/ DNS servers ; did NOT test https://www.opendns.com/ or https://cleanbrowsing.org/
# for each in 7760 1850 7977 3801 1938 8507 3879 8363 ; do speedtest-cli --simple --server $each ; done
#
# Initial purpose to test-by-TLD for possible segregation in PDNS-recursor by forward-zones-recurse: com. to these, org. to those; etc.
# forward-zones-recurse=local.=192.168.4.1,thepiratebay.se.=185.56.187.149;87.238.35.136,.=99.99.99.153;12.127.17.72;99.99.99.53;68.94.156.8;68.94.156.1;12.127.17.71;206.13.31.12;206.13.28.12;68.94.157.1;68.94.157.8

# Download Alexa top 1 million sites...
# wget -qN http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
# Recompressing with zopfli saves ~6%; may improve disk load and reduce latency during subsequent manipulation...
# advzip -kz4 top-1m.csv.zip
input="top-1m.csv.zip"
# Thursday, November 16 2017 - Alexa top 1 million no longer public as of November 22, 2016; switch to majestic million instead.
curl -O --compressed 'http://downloads.majestic.com/majestic_million.csv'

# Extract top 2000 sites by TLD...
for tld in com org net edu gov ; do zgrep -m 2000 -e ".$tld$" "$input" |cut -d',' -f2 > "tld$tld.txt" ; done
# Prime cache using the separate TLD extracts...
parallel -i dig @localhost +multiline +keepopen +notcp -f {} -- tld*.txt

# Reformat TLD extract(s) for namebench (needs A record signifier and domain terminator)
while read each; do echo "A $each." ; done < tldedu.txt > 'data/fe-tld-by-edu.txt'

# Test...
for tld in com org net edu ; do ./namebench.py -x -i "data/fe-tld-by-$tld.txt" -S ; done

# Prime cache directly from single TLD extract -- com. domain registrations account for ~49% of all registered domains.
for tld in com org net edu gov ; do zgrep -m 2000 -e ".$tld$" "~/Download/ZIP/$input" |cut -d',' -f2 ;done > 'data/tld.txt'
dig +multiline +keepopen +notcp -f ../../tldedu.txt | awk /time/'{sum+=$4} END { print "Average query = ",sum/NR,"ms"}'
