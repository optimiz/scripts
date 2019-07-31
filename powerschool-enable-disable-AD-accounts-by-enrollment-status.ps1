# 2019-06-13 - FE - Disable AD accounts for students who have exited (includes all types; e.g., transfers, moves, fails, graduates, etc.)
# 2019-07-24 - FE - Enable AD accounts for previously-disabled students who re-enroll.

Import-Module SimplySql

# 2019-06-14 - FE - Variabilize SQL connection criteria and date range

$dbpswd = '********'
$dbuser = 'PSNavigator'
$dbport = 1521
$dbname = 'PSPRODDB'
$dbsource = 'Powerschool'

Open-OracleConnection -ServiceName $dbname -DataSource $dbsource -Port $dbport -UserName $dbuser -Password $dbpswd -WarningAction SilentlyContinue

$exitedstudents=Invoke-SqlQuery -query "SELECT student_web_id FROM students WHERE exitdate BETWEEN sysdate - 90 AND sysdate AND exitcode IS NOT NULL AND schoolid in (1234567,0) AND student_web_id IS NOT NULL AND psguid IS NOT NULL"
$activestudents=Invoke-SqlQuery -query "SELECT student_web_id FROM students WHERE classof>=EXTRACT(YEAR FROM sysdate) and enroll_status <= 0 AND entrydate >= sysdate AND schoolid in (6938047,0) AND student_web_id IS NOT NULL AND psguid IS NOT NULL"

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
} else {Clear-variable -Name 'body' ; return}

# 2019-06-21 - FE Actually delete inactive AD student accounts:
# Get-ADUser -Filter * -SearchBase "OU=Students,OU=Classrooms,DC=example,DC=org" -Property Enabled | Where-Object {$_.Enabled -like “false”} | Remove-ADUser -WhatIf #| FT Name, Enabled -Autosize
