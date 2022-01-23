#! /bin/bash
# Monday, April 11 2016 - Import Mozilla Focus disconnect.me blocklist into PDNS-recursor v3.1+ (Fedora 20-23 use v3.7) via hosts file.
# Original idea (using lua) from https://blog.powerdns.com/2016/01/19/efficient-optional-filtering-of-domains-in-recursor-4-0-0/
# Be sure to set "etc-hosts-file=/etc/pdns-recursor/pdns.hosts" and "export-etc-hosts=on" in /etc/pdns-recursor/recursor.conf

# Thursday, November 09 2017 - Add user agent string to resolve mdl timeouts.
agent='Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0'
# Tuesday, October 01 2019 - Variablize PDNS Recursor location cause install folder on Ubuntu LTS differs from Fedora; only one change needed.
pdnslocation=/etc/pdns-recursor
blackholeaddr='0.0.0.0'
localhostaddr='127.0.0.1'

# Tuesday, October 01 2019 - Don't assume a current hosts file exists; only backup when exists and is not empty.
if [ -s "$pdnslocation/pdns.hosts" ]; then xz -c "$pdnslocation/pdns.hosts" > /var/log/$(date +%Y%m%d)-pdns.hosts.xz; else echo 'nope'; fi

tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP
pushd "$tmpdir" || cd "$tmpdir"

# Monday, December 20 2021 - AWS Disconnect.me downloads no longer updating as of mid-2020, download and parse raw JSON direct from github instead…
curl -sOA "$agent" --compressed  'https://raw.githubusercontent.com/disconnectme/disconnect-tracking-protection/master/services.json'
for each in $(jq -r '.categories| keys| .[]' 'services.json') ;do jq -r ".categories.$each[]|.[]|.[]|.[0]" 'services.json' |grep -v '^jq: error' > "simple_$each.txt" ; done
sort -ifu simple_{Advertising,Analytics,Cryptomining,Disconnect,FingerprintingGeneral,FingerprintingInvasive,Social}.txt > 'disconnectme'

# Need additional lists because Firefox Electrolysis (e10s) disables userContent.css see: https://bugzilla.mozilla.org/show_bug.cgi?id=1046166
curl -sA "$agent" --compressed 'https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts' -o 'yoyo'

# Create hosts file from blocklist...
if [ -s 'disconnectme' ]; then while read each; do echo $blackholeaddr $each; done < 'disconnectme' > "$pdnslocation/disconnect.hosts"; fi
if [ -s 'yoyo' ]; then grep 127.0.0.1 'yoyo' > "$pdnslocation/yoyo.hosts"; fi

# Monday, September 20 2021 - Add adult websites list.
curl -sA "$agent" --compressed 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts' -o "$pdnslocation/adware.hosts"

popd || cd -

# Tuesday, June 16 2020 - Conform downloads to unix style line endings.
dos2unix $pdnslocation/{disconnect,yoyo,nocoin,adware}.hosts

# Tuesday, August 30 2016 - Add manual, intranet and adserver lists; combine into single input -- PDNS won't accept multiple "etc-hosts-file".
# Saturday, September 03 2016 - Normalize whitespace so sort can eliminate more duplicates.
# Friday, May 18 2018 - Add sed to change 0.0.0.0 to 127.0.0.1, on my systems, 127.0.0.1 is faster than 0.0.0.0
grep -Ehv "(127.0.0.1$|==|::|^#|^[[:space:]]|^$)" $pdnslocation/{disconnect,yoyo,nocoin,adware}.hosts |sed "s/${localhostaddr}/${blackholeaddr}/g" |cut -d ' ' -f 1,2 |grep -E '(^0.0.0.0)' |tr [:upper:] [:lower:] |tr -s [:blank:] |grep -vf "$pdnslocation/whitelist.hosts" |sort -ifu -o "$pdnslocation/pdns.hosts"

# If "reload-zones" fails, restart instead.  The following error seems be a longstanding issue (2008?), increasing timeout resolves.
# Error dealing with control socket request: Unable to send message over control channel '/var/run//lsock9CKhnj': No such file or directory
rec_control --timeout=60 reload-zones || systemctl restart pdns-recursor || service pdns-recursor restart
