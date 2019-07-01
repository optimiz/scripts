# 2019-06-21 - FE - Create student accounts in AD directly from PowerSchool SQL extract.
#
# 2019-07-01 - FE - Important prerequisite!  Run "ID/Password Assignment" process in PowerSchool first!
#
# Example: Switch to 'district office', search for "/classof=2023", goto "Group Function" > 'Functions' > 'ID/Password Assignment'.
# Be sure "Don't overwrite any existing ID's or passwords" is selected!

Import-Module SimplySql

# 2019-06-14 - FE - Variabilize SQL connection criteria and other useful data.

$dbpswd = '***********'
$dbuser = 'PSNavigator'
$dbport = 1521
$dbname = 'PSPRODDB'
$dbsource = 'Powerschool'

$LogonWorkstations = 'class,instant,adfs,azure'
$memberOf = 'CN=All Students,OU=Security,DC=example,DC=org' 
$now = Get-Date -Format 'yyyy-MM-dd-HH.mm.ss.fff'
$ExportPath = "$($env:USERPROFILE)\Desktop\$now-export.csv"

Open-OracleConnection -ServiceName $dbname -DataSource $dbsource -Port $dbport -UserName $dbuser -Password $dbpswd -WarningAction SilentlyContinue

# 2019-07-01 - FE - External non-resident summer school students are class of 0.

$students=Invoke-SqlQuery -query "
SELECT first_name, last_name, TRIM(CONCAT(dbms_random.STRING('a',3),dbms_random.STRING('x',5))) PASSWORD, student_web_id, psguid, CASE classof WHEN 0 THEN 9999 ELSE classof END CLASS 
FROM students 
WHERE (classof >= '2020' OR (classof = '0' AND student_number >= 100000)) AND student_web_id IS NOT NULL AND psguid IS NOT NULL AND exitcode IS NULL ORDER BY classof, last_name, first_name"

# 2019-06-21 - FE - Original array splatting method from https://4sysops.com/archives/sync-active-directory-users-with-a-sql-database/

foreach ($line in $students) {
    ## Use PowerSchool web ID as username
    $proposedUsername = $line.student_web_id
    ## Check if the username exists in Active Directory; uncomment if confirmation notice is desired.
    if (Get-AdUser -Filter "sAMAccountName -eq '$($proposedUsername)'") {
 #       "The AD user [$proposedUsername] already exists."
    } else { "ATTEMPTING TO CREATE [$proposedUsername]."
        ## Otherwise, populate parameters using data from SQL extract, then splat into New-AdUser.
        $newUserParams = @{
            Name        = $line.first_name +' '+ $line.last_name
            DisplayName = $line.first_name +' '+ $line.last_name
            Path        = $("OU=$($line.class),OU=Students,OU=Classrooms,DC=example,DC=org")
            Enabled     = $true
            GivenName   = $line.first_name
            Surname     = $line.last_name
            EmployeeNumber    = $line.psguid
            AccountPassword   = ConvertTo-SecureString -String $line.PASSWORD -AsPlainText –Force
            LogonWorkstations = $LogonWorkstations
            UserPrincipalName = $proposedUsername
            SamAccountName    = $proposedUsername
        }
    ## Capture passwords to CSV for later mailmerge.
        $line | Export-Csv -Path $ExportPath -NoTypeInformation -Append
        New-AdUser @newUserParams #-WhatIf
        Add-ADGroupMember -Identity $memberOf -Members $($proposedUsername) #-WhatIf
    }
}
