/* Monday, March 06 2023 - FE - This exports a CSV from an Oracle DB using SQLCL for rostering.
Use like this:  env JAVA_HOME='/usr/java/jdk1.8.0_211-amd64' /home/user/Downloads/sqlcl/bin/sql 'psnavigator/Spac3ly$prockets@psdb01.fcusd.org:1521:PSPRODDB' @export.sql
To execute an SQL subscript within this SQL script, @@ it like this: @@subscript_to_be_executed.sql
*/

SET SQLFORMAT csv
SET FEEDBACK off
SPOOL 'powerschool_active_students.csv';

/* Thursday, March 16 2023 - FE - Export active students for import into SQLITE for rostering.*/
SELECT students.first_name, students.last_name, students.student_number, students.student_web_id, students.grade_level, students.schoolid, students.enroll_status, to_char(students.entrydate,'RRRR-MM-DD') as "ENTRYDATE", to_char(students.exitdate,'RRRR-MM-DD') as "EXITDATE", students.psguid, to_char(students.dob,'RRRR-MM-DD') as "DOB", upper(home_room)
FROM students JOIN schools ON students.schoolid = schools.school_number
WHERE 1=1
AND students.enroll_status in ('0','-2')
/* Thursday, May 25 2023 - FE - Need between school years to be included for my particular database needs; conversely rostering needs may need to be limited by firstday clause.
AND students.schoolid IN (SELECT DISTINCT schoolid FROM terms WHERE firstday <= sysdate AND lastday > sysdate );*/
AND students.schoolid IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate );

SPOOL off;
EXIT
