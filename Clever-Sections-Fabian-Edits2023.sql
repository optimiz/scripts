/* Thursday, September 28 2023 - FE - Clever sections.csv rewrite to include co-teachers.
** The other teacher categories work, but there were not multiples, so they are aggregated under the co-teacher category.
** If multiple teacher categories are assigned, the highest employee ID is selected.*/

SELECT school_id, section_id, MAX(teacher) AS teacher_id, MAX(coteacher) AS teacher_2_id, 
--MAX(jobshareteacher) AS teacher_3_id, MAX(teacheraide) AS teacher_4_id, MAX(classobserver) AS teacher_5_id, MAX(studentteacher) AS teacher_6_id,
NAME, section_number, grade, course_name, course_number, course_description, PERIOD, subject, term_name, term_start, term_end
FROM
(
SELECT DISTINCT
    to_char(sec.schoolid) school_id,
    to_char(sec.ID) section_id,
    CASE WHEN to_char(sctc.roleid) = '25' THEN to_char(te.teachernumber) END AS teacher,
    CASE WHEN to_char(sctc.roleid) <> '25' THEN to_char(te.teachernumber) END AS coteacher,
/*
    CASE WHEN to_char(sctc.roleid) = '26' THEN to_char(te.teachernumber) END AS coteacher,
    CASE WHEN to_char(sctc.roleid) = '27' THEN to_char(te.teachernumber) END AS jobshareteacher,
    CASE WHEN to_char(sctc.roleid) = '28' THEN to_char(te.teachernumber) END AS teacheraide,
    CASE WHEN to_char(sctc.roleid) = '29' THEN to_char(te.teachernumber) END AS classobserver,
    CASE WHEN to_char(sctc.roleid) = '41' THEN to_char(te.teachernumber) END AS studentteacher,
*/
    /*NULL AS teacher_7_id,    NULL AS teacher_8_id,    NULL AS teacher_9_id,    NULL AS teacher_10_id,*/
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
    JOIN sectionteacher sctc ON sctc.sectionid = sec.ID 
    JOIN teachers te ON te.ID = sctc.teacherid AND te.status = 1 AND te.staffstatus = 1
WHERE 1=1
    AND sec.schoolid IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate ) 
    AND sec.schoolid NOT IN ('800','999','999999','950','951','955','981','982','983')
    AND sctc.start_date >= (SELECT DISTINCT MIN(firstday) FROM terms WHERE lastday >= sysdate )
)
GROUP BY school_id, section_id, NAME, section_number, grade, course_name, course_number, course_description, PERIOD, subject, term_name, term_start, term_end
ORDER BY 1,2,3,4 ;