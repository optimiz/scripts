#!/bin/sh
# Reseed the Linux kernel CSPRNG with data from NIST
SALT=$(dd if=/dev/urandom bs=64 count=1 2> /dev/null)
EPOCH=$(date --date="$(date +%H:%M:00)" +%s)
# 2014/11/10 - Use curl instead of GET to avoid CPAN dependencies for HTTPS; use only return value from XML output
# 2014/11/25 - Use "last" instead of date for intermittent HTTP 404 error when EPOCH unavailable.
# 2018/04/20 - Handle "Document is empty" warning from xmlstarlet. Handle 404 and disable buffer in curl.
RESULTS=$(curl -f -N -s https://beacon.nist.gov/rest/record/last |xmlstarlet sel -t -v "/_:record/_:outputValue")
# 2014/11/05 - Use sha512sum instead of rhash; no carriage return from echo
DATA=$(echo -n "${SALT}${RESULTS}" | sha512sum | cut -d ' ' -f 1)
echo "$DATA" > /dev/random
