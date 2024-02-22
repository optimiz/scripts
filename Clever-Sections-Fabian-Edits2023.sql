/* Thursday, September 28 2023 - FE - Clever sections.csv rewrite to include co-teachers.
** The other teacher categories work, but there were not multiples, so they are aggregated under the co-teacher category.
** If multiple teacher categories are assigned, the highest employee ID is selected.*/

SELECT school_id, section_id, MAX(teacher) AS teacher_id, MAX(coteacher) AS teacher_2_id, 
MAX(jobshareteacher) AS teacher_3_id, MAX(teacheraide) AS teacher_4_id, 
MAX(classobserver) AS teacher_5_id, MAX(studentteacher) AS teacher_6_id,

/* Friday, January 26 2024 - FE - Add MIN clauses to capture additional co-teachers. */
CASE WHEN MIN(coteacher) <> MAX(coteacher) THEN MIN(coteacher) ELSE NULL END AS teacher_7_id, 
CASE WHEN MIN(jobshareteacher) <> MAX(jobshareteacher) THEN MIN(jobshareteacher) ELSE NULL END AS teacher_8_id, 
CASE WHEN MIN(teacheraide) <> MAX(teacheraide) THEN MIN(teacheraide) ELSE NULL END AS teacher_9_id, 
CASE WHEN MIN(studentteacher) <> MAX(studentteacher) THEN MIN(studentteacher) ELSE NULL END AS teacher_10_id,

NAME, section_number, grade, course_name, course_number, course_description, PERIOD, subject, term_name, term_start, term_end
FROM
(
SELECT DISTINCT
    to_char(sec.schoolid) school_id,
    to_char(sec.ID) section_id,
    CASE WHEN to_char(sctc.roleid) = '25' THEN to_char(te.teachernumber) END AS teacher,
/* Wednesday, January 10 2024 - FE - SIS team wants all defined co-teacher categories included.*/
    CASE WHEN to_char(sctc.roleid) = '26' THEN to_char(te.teachernumber) END AS coteacher,
    CASE WHEN to_char(sctc.roleid) = '27' THEN to_char(te.teachernumber) END AS jobshareteacher,
    CASE WHEN to_char(sctc.roleid) = '28' THEN to_char(te.teachernumber) END AS teacheraide,
    CASE WHEN to_char(sctc.roleid) = '29' THEN to_char(te.teachernumber) END AS classobserver,
    CASE WHEN to_char(sctc.roleid) = '41' THEN to_char(te.teachernumber) END AS studentteacher,

    NULL AS teacher_7_id,    NULL AS teacher_8_id,    NULL AS teacher_9_id,    NULL AS teacher_10_id,
    C.course_name || '-' || sec.section_number || '-' || sec.expression NAME,
    sec.section_number,
    CASE
        WHEN sec.grade_level = 0 THEN 'Kindergarten'
        WHEN sec.grade_level = '-5' THEN 'TransitionalKindergarten'
        WHEN sec.grade_level IN ('-1','-2') THEN 'Prekindergarten'
        WHEN sec.grade_level > 13 THEN 'Postgraduate'
    ELSE to_char(sec.grade_level)
    END AS grade,
    C.course_name AS course_name, 
    sec.course_number,
    NULL AS course_description,
    sec.expression PERIOD,
    NULL AS subject,
    T.NAME term_name,
   to_char(T.firstday,'mm/dd/yyyy') term_start,
   to_char(T.lastday,'mm/dd/yyyy') term_end   
FROM sections sec
    JOIN courses C ON sec.course_number=C.course_number
    JOIN cc ON sec.ID=ABS(cc.sectionid) 
    JOIN terms T ON sec.termid=T.ID AND sec.schoolid=T.schoolid 
/* Monday, February 12 2024 - FE - Limit teacher selection to those currently active in a section. */
    JOIN sectionteacher sctc ON sctc.sectionid = sec.ID AND sctc.end_date >= sysdate
/* Thursday, January 25 2024 - FE - Add long term substitute (4) code. */
    JOIN teachers te ON te.ID = sctc.teacherid AND te.status = 1 AND te.staffstatus in (1,4)
WHERE 1=1
    AND sec.schoolid IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate AND schoolid NOT IN ('800','999','999999','950','951','955','981','982','983'))
    AND sctc.start_date >= (SELECT DISTINCT MIN(firstday) FROM terms WHERE lastday >= sysdate )
/* Thursday, February 22 2024 - FE - Don't include sections that have no students.*/
    AND sec.no_of_students > '0'
)  
GROUP BY school_id, section_id, NAME, section_number, grade, course_name, course_number, course_description, PERIOD, subject, term_name, term_start, term_end
ORDER BY 1,2,3,4 ;
