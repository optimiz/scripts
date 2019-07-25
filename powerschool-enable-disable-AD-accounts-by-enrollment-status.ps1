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
$activestudents=Invoke-SqlQuery -query "SELECT student_web_id FROM students WHERE enroll_status <= 0 AND entrydate >= sysdate AND schoolid in (1234567,0) AND student_web_id IS NOT NULL AND psguid IS NOT NULL"

# 2019-06-14 - JB - Add enabled check and pipe to disable command.

foreach ($user in $exitedstudents)
{
    Get-ADUser -Identity $($user.STUDENT_WEB_ID) | ? { $_.ENABLED -eq "True" } | Disable-ADAccount #-WhatIf
}

foreach ($user in $activestudents)
{
    Get-ADUser -Identity $($user.STUDENT_WEB_ID) | ? { $_.ENABLED -ne "True" } | Enable-ADAccount #-WhatIf
}

# 2019-06-21 - FE Actually delete inactive AD student accounts:
# Get-ADUser -Filter * -SearchBase "OU=Students,OU=Classrooms,DC=example,DC=org" -Property Enabled | Where-Object {$_.Enabled -like “false”} | Remove-ADUser -WhatIf #| FT Name, Enabled -Autosize
