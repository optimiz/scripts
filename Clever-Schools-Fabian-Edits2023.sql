/* Monday, September 18 2023 - FE - Script no longer relies on hardcoded school IDs. Includes latest TK grade classification introduced in the 2023-2024 school year.*/

SELECT
  to_char(S.school_number) school_id,
  S.NAME school_name,
  to_char(S.school_number) school_number,
  to_char(S.sif_stateprid) state_id,
  NULL AS nces_id,
  CASE WHEN S.low_grade = 0 THEN 'Kindergarten'
       WHEN S.low_grade = '-5' THEN 'TransitionalKindergarten'
       WHEN S.low_grade IN ('-1','-2') THEN 'Prekindergarten'
       WHEN S.low_grade > 13 THEN 'Postgraduate'
       ELSE to_char(S.low_grade) END AS low_grade,
  CASE WHEN S.high_grade = 0 THEN 'Kindergarten'
       WHEN S.high_grade = '-5' THEN 'TransitionalKindergarten'
       WHEN S.high_grade IN ('-1','-2') THEN 'Prekindergarten'
       WHEN S.high_grade > 13 THEN 'Postgraduate'
       ELSE to_char(S.high_grade) END AS high_grade,
  S.principal,
  LOWER(S.principalemail) principal_email,
  S.schooladdress school_address,
  S.schoolcity school_city,
  S.schoolstate school_state,
  regexp_replace(S.schoolzip,'[^0-9]*', '') school_zip,
  regexp_replace(S.schoolphone,'[^0-9]*', '') school_phone
FROM schools S
WHERE 1=1
AND school_number IN (SELECT DISTINCT schoolid FROM terms WHERE lastday >= sysdate )
AND school_number NOT IN ('800','999','999999','950','951','955','981','982','983')
ORDER BY school_number;
