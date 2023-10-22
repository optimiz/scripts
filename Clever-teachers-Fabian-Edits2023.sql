/* Tuesday, September 19 2023 - FE - Clever teachers.csv export rewrite.*/

SELECT DISTINCT
    schoolid AS school_id,
    teachers.ID AS teacher_number,
    teachernumber AS teacher_id,
    sif_stateprid AS state_teacher_id,
    LOWER(email_addr) AS teacher_email,
    first_name AS first_name,
    middle_name AS middle_name,
    last_name AS last_name,
    nvl(title,'Teacher') AS title,
    NULL AS username,
    NULL AS PASSWORD
FROM teachers
    JOIN sectionteacher ON teachers.ID = teacherid 
WHERE 1=1
    AND status = 1
    AND staffstatus = 1 
    AND schoolid IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate ) 
    AND schoolid NOT IN ('800','999','999999','950','951','955','981','982','983')
    AND email_addr IS NOT NULL
ORDER BY teachernumber;


--select * from sectionteacher where teacherid in ('57153','57156');
--select * from sections;
--select * from RoleDef;

--AND sectionid IN ( SELECT DISTINCT ID FROM sections WHERE start_date >= (SELECT DISTINCT MIN(firstday) FROM terms WHERE lastday >= sysdate ) ) 