#!/bin/sh
# Reseed the Linux kernel CSPRNG with data from NIST
SALT=$(dd if=/dev/urandom bs=64 count=1 2> /dev/null)
EPOCH=$(date --date="$(date +%H:%M:00)" +%s)
RESULTS=$(GET https://beacon.nist.gov/rest/record/"$EPOCH")
DATA=$(echo "${SALT}${RESULTS}" | rhash --sha3-512 - | cut -d ' ' -f 1)
echo "$DATA" > /dev/random
