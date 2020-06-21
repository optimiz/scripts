# 2019-06-13 - FE - Disable AD accounts for students who have exited (includes all types; e.g., transfers, moves, fails, graduates, etc.)
# 2019-07-24 - FE - Enable AD accounts for previously-disabled students who re-enroll.
# 2020-06-09 - FE - Modify script to run against SaaS hosted PowerSchool through F5 BigIP Edge Client VPN connection.
# NOTE: For F5 BigIP Edge VPN CLI client on Windows OS, convert user and password to HEX values; for example: <<<'datahere' xxd -ps

# 2020-06-19 - FE - Add task kill for problematic F5 VPN.
Stop-Process -Name "f5fpclient" -Force
Start-Sleep -Seconds 2

# 2020-06-09 - FE - Connect to VPN and capture session ID for later closure; 10 second wait is for connection to stabilize.
$vpnout = &"C:\Program Files (x86)\F5 VPN\f5fpc.exe" --% -start /h vpn.example.com /uh 000000000000000000000 /ph 0000000000000000000000
Start-Sleep -Seconds 10
$vpnsid = $vpnout |Where-Object {$_ -match 'session id:'} |ConvertFrom-String |Select -ExpandProperty p3 

Import-Module SimplySql

# 2019-06-14 - FE - Variabilize SQL connection criteria and date range

$dbpswd = '********'
$dbuser = 'PSNavigator'
$dbport = 1521
$dbname = 'PSPRODDB'
$dbsource = 'Powerschool'

Open-OracleConnection -ServiceName $dbname -DataSource $dbsource -Port $dbport -UserName $dbuser -Password $dbpswd -WarningAction SilentlyContinue

# 2020-06-19- FE - Change SQL to rely on enroll status in both clauses to catch students who unenroll, then reënroll back-to-back. 
$exitedstudents=Invoke-SqlQuery -query "SELECT student_web_id FROM students WHERE enroll_status > 0 AND exitdate BETWEEN sysdate - 90 AND sysdate AND exitcode IS NOT NULL AND schoolid in (1234567,0) AND student_web_id IS NOT NULL AND psguid IS NOT NULL"
$activestudents=Invoke-SqlQuery -query "SELECT student_web_id FROM students WHERE enroll_status <= 0 AND (entrydate >= sysdate OR transaction_date >= sysdate - 1) AND schoolid IN (1234567,0) AND student_web_id IS NOT NULL AND psguid IS NOT NULL AND transaction_date IS NOT NULL"

# 2019-06-14 - JB - Add enabled check and pipe to disable command.
# 2019-07-26 - JB - Set error action preference to ignore warning for student acccounts that have been completely deleted from AD.
$ErrorActionPreference = "SilentlyContinue"

# 2019-07-26 - FE - Rewrite foreach so that notification of changes can be emailed.
# 2019-07-29 - FE - Add conditionals to cmdlet processes; especially, do not send notification email if no changes were performed.
# 2019-07-31 - FE - Reselect student account to show status AFTER change performed, not from before.

$temp1 = $exitedstudents | ForEach-Object { Get-ADUser -Identity $($_.STUDENT_WEB_ID) | ? { $_.ENABLED -eq "True" } }
if ($temp1) {$temp1 | Disable-ADAccount; $body = $temp1 |Get-ADUser |Select-Object enabled,samaccountname,name } else {'No accounts to disable.'}
$temp2 = $activestudents | ForEach-Object { Get-ADUser -Identity $($_.STUDENT_WEB_ID) | ? { $_.ENABLED -ne "True" } }
if ($temp2) {$temp2 | Enable-ADAccount; $body += $temp2 |Get-ADUser |Select-Object enabled,samaccountname,name } else {'No accounts to reactivate.'}

# 2019-07-26 - FE - Combine results into variable then email notification.

if ($body) {
    $email = @{
        From = "cronjob@example.org"
        To = "it@example.org"
        Subject = "Student Accounts Enabled/Disabled"
        SMTPServer = "mx.example.org"
    }
    Send-MailMessage @email -Body ($body | Out-String)
} else {Clear-variable -Name 'body' ;}

&"C:\Program Files (x86)\F5 VPN\f5fpc.exe" -stop /s $vpnsid

exit 0;
# 2019-06-21 - FE Actually delete inactive AD student accounts:
# Get-ADUser -Filter * -SearchBase "OU=Students,OU=Classrooms,DC=example,DC=org" -Property Enabled | Where-Object {$_.Enabled -like “false”} | Remove-ADUser -WhatIf #| FT Name, Enabled -Autosize
