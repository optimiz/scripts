/*Update second BA field in Powerfaids from Jenzabar. - Created 12/8/08 by Fabian.*/
update newpf.dbo.stu_award_year
  set newpf.dbo.stu_award_year.second_ba = 'Y'
from newpf.dbo.student, tmseprd.dbo.degree_history 
where (newpf.dbo.student.student_token = newpf.dbo.stu_award_year.student_token 
  and newpf.dbo.student.alternate_id = tmseprd.dbo.degree_history.id_num)
  and (tmseprd.dbo.degree_history.degr_cde in ('BA','BS','MA','MS','JD') 
  and tmseprd.dbo.degree_history.dte_degr_conferred is not null)
  and newpf.dbo.stu_award_year.second_ba is null 
  and newpf.dbo.stu_award_year.award_year_token >= datepart(yyyy,tmseprd.dbo.degree_history.dte_degr_conferred)
