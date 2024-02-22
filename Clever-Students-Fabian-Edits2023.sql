/* Tuesday, September 26 2023 - FE - Minor cleanup from inherited original. Handle new (TK) grade level. Handle non-binary (X) gender.*/

SELECT
    to_char(S.schoolid) AS school_id,
    to_char(S.ID) AS student_id,
    to_char(S.student_number) AS student_number,
    to_char(S.state_studentnumber) AS state_id,
    S.last_name AS last_name,
    S.middle_name AS middle_name,
    S.first_name AS first_name,
    --to_char(S.grade_level) AS grade,
    CASE
        WHEN S.grade_level = 0 THEN 'Kindergarten'
        WHEN S.grade_level = '-5' THEN 'TransitionalKindergarten'
        WHEN S.grade_level IN ('-1','-2') THEN 'Prekindergarten'
        WHEN S.grade_level > 13 THEN 'Postgraduate'
        ELSE to_char(S.grade_level)
    END AS grade,
/* Thursday, January 11 2024 - FE - Gender in PS is already in compatible F/M/X form, change logic to reflect that.*/
    CASE WHEN S.gender IN ('F','M','X') THEN S.gender ELSE NULL END AS gender,
    to_char(S.dob,'MM/DD/YYYY') AS dob,
    NULL AS race,
    NULL AS hispanic_latino,
    NULL AS ell_status,
    NULL AS frl_status,
    NULL AS iep_status,
    NULL AS student_street,
    NULL AS student_city,
    NULL AS student_state,
    NULL AS student_zip,
    LOWER(S.student_web_id || '@student.example.org') AS student_email,
    NULL AS contact_relationship,
    NULL AS contact_type,
    NULL AS contact_name,
    NULL AS contact_phone,
    NULL AS contact_email,
    S.student_web_id || '@student.example.org' AS username,
    NULL AS "Password"
FROM students S
JOIN schools C ON S.schoolid = C.school_number AND C.school_number IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate AND schoolid NOT IN ('800','999','999999','950','951','955','981','982','983'))
WHERE 1=1
    AND S.enroll_status = 0 AND S.student_web_id IS NOT NULL
ORDER BY last_name, first_name;
