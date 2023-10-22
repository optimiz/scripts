/* Tuesday, September 19 2023 - FE - Clever enrollments.csv rewrite.  Runs faster than original BREED/RMILLER query after simplification of unnecessary clauses, and limiting in the JOINS instead of the WHERE clause. */ 

SELECT
    to_char(sec.schoolid) school_id,
    to_char(sec.ID) section_id,
    to_char(cc.studentid) student_id
FROM sections sec
    JOIN courses C ON sec.course_number=C.course_number
    JOIN cc ON sec.ID=ABS(cc.sectionid) AND cc.dateenrolled < cc.dateleft AND COALESCE(cc.dateleft, sysdate) >= (SELECT DISTINCT MIN(firstday) FROM terms WHERE lastday >= sysdate )
    JOIN students stu ON cc.studentid=stu.ID AND stu.enroll_status = 0 AND stu.allowwebaccess = 1 AND stu.student_web_id IS NOT NULL AND stu.state_excludefromreporting <> 1 
    JOIN terms T ON sec.termid=T.ID AND sec.schoolid=T.schoolid AND T.schoolid = stu.schoolid AND T.schoolid IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate ) 
WHERE 1=1
    AND sec.schoolid IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate ) 
    AND sec.schoolid NOT IN ('800','999','999999','950','951','955','981','982','983')
ORDER BY school_id, student_id;


