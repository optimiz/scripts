#! /bin/bash
# Monday, April 11 2016 - Import Mozilla Focus disconnect.me blocklist into PDNS-recursor v3.1+ (Fedora 20-23 use v3.7) via hosts file.
# Original idea (using lua) from https://blog.powerdns.com/2016/01/19/efficient-optional-filtering-of-domains-in-recursor-4-0-0/
# Be sure to set "etc-hosts-file=/etc/pdns-recursor/pdns.hosts" and "export-etc-hosts=on" in /etc/pdns-recursor/recursor.conf

xz -c /etc/pdns-recursor/pdns.hosts > /var/log/$(date +%Y%m%d)-pdns.hosts.xz
tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP
pushd "$tmpdir"

# Retrieve lists from Mozilla Focus (disconnect.me); https://disconnect.me/trackerprotection/blocked; https://disconnect.me/trackerprotection/unblocked
wget -qN --header="Accept-Encoding: gzip" \
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt \
https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt \
https://s3.amazonaws.com/lists.disconnect.me/simple_malware.txt || exit 1

# Skip headers, remove duplicates and blank lines...
tail -n +5 simple*.txt |sort -ifu |grep -v ^$ > disconnect.txt

# Create hosts file from blocklist...
while read each; do echo 127.0.0.1 $each ; done < disconnect.txt > /etc/pdns-recursor/disconnect.hosts

popd

# Tuesday, August 30 2016 - Add manual, intranet and adserver lists; combine into single input -- PDNS won't accept multiple "etc-hosts-file".
# Need additional lists because Firefox Electrolysis (e10s) disables userContent.css see: https://bugzilla.mozilla.org/show_bug.cgi?id=1046166
# curl -s --compressed 'https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts' |grep 127.0.0.1 > /etc/pdns-recursor/yoyo.hosts
# curl -s --compressed 'https://www.malwaredomainlist.com/hostslist/hosts.txt' |grep -v localhost |grep 127.0.0.1 > /etc/pdns-recursor/mdl.hosts
# Saturday, September 03 2016 - Normalize whitespace so sort can eliminate more duplicates.
# sort -ifu /etc/pdns-recursor/{intranet,manual,disconnect,yoyo,mdl}.hosts -o /etc/pdns-recursor/pdns.hosts
egrep -hv '(127.0.0.1$|==)' /etc/pdns-recursor/{intranet,manual,disconnect,yoyo,mdl}.hosts |tr [:upper:] [:lower:] |tr -s [:blank:] |sort -ifu -o /etc/pdns-recursor/pdns.hosts

# If "reload-zones" fails, restart instead.  The following error seems be a londstanding issue (2008?), increasing timeout resolves.
# Error dealing with control socket request: Unable to send message over control channel '/var/run//lsock9CKhnj': No such file or directory
rec_control --timeout=60 reload-zones || systemctl restart pdns-recursor
