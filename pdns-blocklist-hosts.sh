#! /bin/bash
# Monday, April 11 2016 - Import Mozilla Focus disconnect.me blocklist into PDNS-recursor v3.1+ (Fedora 20-23 use v3.7) via hosts file.
# Original idea (using lua) from https://blog.powerdns.com/2016/01/19/efficient-optional-filtering-of-domains-in-recursor-4-0-0/
# Be sure to set "etc-hosts-file=/etc/pdns-recursor/blocklist.hosts" and "export-etc-hosts=on" in /etc/pdns-recursor/recursor.conf

tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP
pushd "$tmpdir"

# Retrieve lists from Mozilla Focus (disconnect.me); https://disconnect.me/trackerprotection/blocked; https://disconnect.me/trackerprotection/unblocked
wget -N \
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt \
https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt \
https://s3.amazonaws.com/lists.disconnect.me/simple_malware.txt

# Skip headers, remove duplicates and blank lines...
tail -n +5 simple*.txt |sort -u |grep -v ^$ > bl.txt

# Create hosts file from blocklist...
while read each; do echo 127.0.0.1 $each ; done < bl.txt > /etc/pdns-recursor/blocklist.hosts

popd

# If "reload-zones" fails, restart instead.  The following error seems be a londstanding issue (2008?), increasing timeout resolves.
# Error dealing with control socket request: Unable to send message over control channel '/var/run//lsock9CKhnj': No such file or directory

rec_control --timeout=60 reload-zones || systemctl restart pdns-recursor
