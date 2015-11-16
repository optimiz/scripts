#!/bin/bash
# Mon, 16 Sep 2013 - Automate Spam Assassin whitelist export from Mailenable Enterprise.
# Set as cronjob on system with Mailenable drive mounted.

# Collect contact information from client-generated VCF; remember to exclude localdomain(s), i.e., 'example.com'
find /mnt/svr03/Program\ Files/Mail\ Enable/Postoffices/**/MAILROOT/**/Contacts/ -type f -iname *VCF -exec grep EMAIL {} \; |tr [:upper:] [:lower:] |grep -v 'example.com' |sort -iu |tr -d ' ' |sed 's/email;pref;internet:/whitelist_from /g' > ~/exported_whitelist.txt

# Collect "RedirectAddress" from all downlevel postoffice forwarding config files.
find /mnt/svr03/Program\ Files/Mail\ Enable/Config/Postoffices/ -type f -name MAILBOX.TAB -exec grep SMTP {} \; |cut -f 5 |tr [:upper:] [:lower:] |sort -iu |tr -d ' ' |sed 's/\[smtp\:/whitelist_from /g' |sed 's/\]//g' >> ~/exported_whitelist.txt

# Collect from outgoing logs in current month; assumes addresses not appearing within a month are no longer relevant, since important addresses appear daily.
# FIXME - egrep clause is a cludge for away-messages, else spam addresses get added to whitelist when auto-responded.
grep 'SMTP-OU' /mnt/svr03/Program\ Files/Mail\ Enable/Logging/SMTP/SMTP-Activity-$(date +%y%m)*.log |grep 'TO:' |egrep '(@yahoo.com|@gmail.com|@hotmail.com|@msn.com|@comcast.net|att.net|sbcglobal.net|.org|.edu$)' |cut -f 7 |tr [:upper:] [:lower:] |sort -iu |sed 's/rcpt to:</whitelist_from /g' |sed 's/>//g' >> ~/exported_whitelist.txt

egrep '([[:alnum:]_.-]+@[[:alnum:]_-]+?\.[[:alpha:].]{2,6})' ~/exported_whitelist.txt |sort -iu |grep -v '[@.]example.com' > ~/exported_whitelist.cf

scp ~/exported_whitelist.cf svr05:/var/log/copfilter/default/etc/cp_spam_whitelist/
