#! /bin/bash
# FE - Saturday, May 28 2016 - Heat a cold DNS cache.
# Average query for top 2,000 in com/net/org/edu drops to ~8ms even 24hrs after heating PDNS-recursor's cache on AT&T U-verse.
# fping -C 4 -s 68.94.156.8 68.94.156.1 206.13.28.12 206.13.31.12 12.127.17.71 12.127.17.72 99.99.99.53 99.99.99.153 8.8.8.8 8.8.4.4
# for each in 7760 1850 7977 3801 1938 8507 3879 8363 ; do speedtest-cli --simple --server $each ; done
#
# Initial purpose to test-by-TLD for possible segregation in PDNS-recursor by forward-zones-recurse: com. to these, org. to those; etc.
# forward-zones-recurse=local.=192.168.4.1,thepiratebay.se.=185.56.187.149;87.238.35.136,.=99.99.99.153;12.127.17.72;99.99.99.53;68.94.156.8;68.94.156.1;12.127.17.71;206.13.31.12;206.13.28.12;68.94.157.1;68.94.157.8

# Download Alexa top 1 million sites...
wget -qN http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
# Recompressing with zopfli saves ~6%; may improve disk load and reduce latency during subsequent manipulation...
# advzip -kz4 top-1m.csv.zip

# Extract top 2000 sites by TLD...
for tld in com org net edu gov ; do zgrep -m 2000 -e ".$tld$" Download/ZIP/alexa-top-1m.csv.zip |cut -d',' -f2 > "tld$tld.txt" ; done
# Prime cache using the separate TLD extracts...
parallel -i dig @192.168.4.3 +multiline +keepopen +notcp -f {} -- tld*.txt

# Reformat TLD extract(s) for namebench (needs A record signifier and domain terminator)
while read each; do echo "A $each." ; done < tldedu.txt > data/fe-tld-by-edu.txt

# Test...
for tld in com org net edu ; do ./namebench.py -x -i "data/fe-tld-by-$tld.txt" -S ; done

# Prime cache directly from single TLD extract -- com. domain registrations account for ~49% of all registered domains.
for tld in com org net edu gov ; do zgrep -m 2000 -e ".$tld$" ~/Download/ZIP/alexa-top-1m.csv.zip |cut -d',' -f2 ;done > data/tld.txt
dig +multiline +keepopen +notcp -f tldedu.txt | awk /time/'{sum+=$4} END { print "Average query = ",sum/NR,"ms"}'
