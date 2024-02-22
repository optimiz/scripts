/* Tuesday, September 19 2023 - FE - Clever teachers.csv export from PowerSchool rewrite.  Specification:  https://schools.clever.com/files/clever-sftp.pdf */

SELECT DISTINCT
/* Thursday, January 25 2024 - FE - Home school field is better than schoolid field, but Clever documentation is unclear on whether the distinction for inclusion is for the teacher, or teacher in combination with school.*/
    case to_char(teachers.homeschoolid) when '0' then teachers.schoolid else teachers.homeschoolid end AS school_id,

/* Friday, January 19 2024 - FE - Use teachers.users_DCID instead of teachers.ID so Clever doesn't create a new teacher. */ 
    teachers.users_dcid AS teacher_number,
    teachers.teachernumber AS teacher_id,
    teachers.sif_stateprid AS state_teacher_id,
    LOWER(teachers.email_addr) AS teacher_email,
    teachers.first_name AS first_name,
    teachers.middle_name AS middle_name,
    teachers.last_name AS last_name,
    COALESCE(teachers.title,CASE teachers.staffstatus WHEN 4 THEN 'Substitute Teacher' ELSE NULL END, 'Teacher') AS title,

/* Friday, January 19 2024 - FE - Can't activate RoleID title translation as there is bad data in PS, such as the teacher and student teacher being the same, so it returns duplicated "unique" rows.*/
    --CASE to_char(nvl(roleid,'25')) WHEN '24' THEN 'Counselor' WHEN '25' THEN 'Teacher' WHEN '26' THEN 'Co-teacher' WHEN '41' THEN 'Student Teacher' WHEN '27' THEN 'Job Share Teacher' WHEN '28' THEN 'Teachers Aide' WHEN '29' THEN 'Class Observer' ELSE 'Teacher' END AS title,

    NULL AS username,
    NULL AS PASSWORD
FROM teachers
    
/* Thursday, January 25 2024 - FE - Sectionteacher table includes all rows ever assigned, so limit to assignments that are still active.*/
    JOIN sectionteacher ON (teachers.ID = sectionteacher.teacherid or teachers.users_DCID = sectionteacher.teacherid) AND sectionteacher.end_date >= sysdate 

WHERE 1=1
    AND teachers.status = 1
    
/* Thursday, January 25 2024 - FE - Add long term substitute (4) code. */
    AND teachers.staffstatus in (1,4)
    AND teachers.schoolid IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate AND schoolid NOT IN ('0','800','999','999999','950','951','955','981','982','983')) 

/* Wednesday, January 10 2024 - FE - SIS team wants generic no-email accounts included as placeholders for TBD teacher assignments.*/
    --AND email_addr IS NOT NULL

ORDER BY 1;
