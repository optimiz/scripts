/* Tuesday, September 19 2023 - FE - Clever teachers.csv export rewrite.*/

SELECT DISTINCT
    schoolid AS school_id,
    
/* Friday, January 19 2024 - FE - Use teachers.users_DCID instead of teachers.ID so Clever doesn't create a new teacher now that all teacher sections are being pulled. */ 
    users_dcid AS teacher_number,
    
    teachernumber AS teacher_id,
    sif_stateprid AS state_teacher_id,
    LOWER(email_addr) AS teacher_email,
    first_name AS first_name,
    middle_name AS middle_name,
    last_name AS last_name,
    nvl(title,'Teacher') As title,
    
/* Friday, January 19 2024 - FE - Can't activate RoleID title translation as there is bad data in PS, such as the teacher and student teacher being the same for the same class, so it returns duplicated "unique" rows.*/
    --CASE to_char(roleid) WHEN '24' THEN 'Counselor' WHEN '25' THEN 'Teacher' WHEN '26' THEN 'Co-teacher' WHEN '41' THEN 'Student Teacher' WHEN '27' THEN 'Job Share Teacher' WHEN '28' THEN 'Teachers Aide' WHEN '29' THEN 'Class Observer' ELSE 'Teacher' END AS title,
    
    NULL AS username,
    NULL AS PASSWORD
FROM teachers

/* Monday, January 22 2024 - FE - Use both DCID and ID on section matches after change to DCID above.*/
    JOIN sectionteacher ON teachers.ID = teacherid or teachers.users_DCID = teacherid
WHERE 1=1
    AND status = 1
    AND staffstatus = 1 
    AND schoolid IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate AND schoolid NOT IN ('800','999','999999','950','951','955','981','982','983')) 
    
/* Wednesday, January 10 2024 - FE - SIS team wants generic no-email accounts included as placeholders for TBD teacher assignments.*/
    --AND email_addr IS NOT NULL

ORDER BY 1;
