/*Updates expected graduation year and term.  Created 10/20/06 by Fabian. Updated 07/23/08 by Fabian.*/
PRINT 'Updating expected graduation year and term.'
update degree_history set EXPECT_GRAD_YR = case 
when (CURRENT_CLASS_CDE in ('FR','L1') or CURRENT_CLASS_CDE is null) and left(degr_cde,1) = 'A' then cast(cast(most_recnt_yr_enr as int) + 2 as char)
when (CURRENT_CLASS_CDE in ('FR','L1') or CURRENT_CLASS_CDE is null) and left(degr_cde,1) = 'C' then cast(cast(most_recnt_yr_enr as int) + 1 as char)
when (CURRENT_CLASS_CDE in ('FR','L1') or CURRENT_CLASS_CDE is null) and left(degr_cde,1) = 'J' then cast(cast(most_recnt_yr_enr as int) + 3 as char)
when (CURRENT_CLASS_CDE in ('FR','L1') or CURRENT_CLASS_CDE is null) and left(degr_cde,1) = 'B' then cast(cast(most_recnt_yr_enr as int) + 4 as char)
when CURRENT_CLASS_CDE in ('SO','L2') and left(degr_cde,1) = 'A' then cast(cast(most_recnt_yr_enr as int) + 1 as char)
when CURRENT_CLASS_CDE in ('SO','L2') and left(degr_cde,1) = 'C' then cast(cast(most_recnt_yr_enr as int) + 0 as char)
when CURRENT_CLASS_CDE in ('SO','L2') and left(degr_cde,1) = 'J' then cast(cast(most_recnt_yr_enr as int) + 3 as char)
when CURRENT_CLASS_CDE in ('SO','L2') and left(degr_cde,1) = 'B' then cast(cast(most_recnt_yr_enr as int) + 3 as char)
when CURRENT_CLASS_CDE in ('JR','L3') and left(degr_cde,1) = 'A' then cast(cast(most_recnt_yr_enr as int) + 0 as char)
when CURRENT_CLASS_CDE in ('JR','L3') and left(degr_cde,1) = 'C' then cast(cast(most_recnt_yr_enr as int) + 0 as char)
when CURRENT_CLASS_CDE in ('JR','L3') and left(degr_cde,1) = 'J' then cast(cast(most_recnt_yr_enr as int) + 2 as char)
when CURRENT_CLASS_CDE in ('JR','L3') and left(degr_cde,1) = 'B' then cast(cast(most_recnt_yr_enr as int) + 2 as char)
when CURRENT_CLASS_CDE in ('SR','L4') and left(degr_cde,1) = 'A' then cast(cast(most_recnt_yr_enr as int) + 0 as char)
when CURRENT_CLASS_CDE in ('SR','L4') and left(degr_cde,1) = 'C' then cast(cast(most_recnt_yr_enr as int) + 0 as char)
when CURRENT_CLASS_CDE in ('SR','L4') and left(degr_cde,1) = 'J' then cast(cast(most_recnt_yr_enr as int) + 1 as char)
when CURRENT_CLASS_CDE in ('SR','L4') and left(degr_cde,1) = 'B' then cast(cast(most_recnt_yr_enr as int) + 1 as char)
else null end, EXPECT_GRAD_TRM = case when most_recnt_trm_enr is not null and degr_cde = 'ND' then null
when CUR_STUD_DIV = 'LW' and degr_cde is not null then '33' else most_recnt_trm_enr end
from student_master where student_master.id_num = degree_history.id_num 
and (cur_degree = 'Y' and DTE_DEGR_CONFERRED is null) and (most_recnt_yr_enr is not null and most_recnt_trm_enr is not null)
and most_recnt_yr_enr >= (select cur_yr_dflt from reg_config) and (
(EXPECT_GRAD_YR is null or EXPECT_GRAD_TRM is null) or (most_recnt_yr_enr > EXPECT_GRAD_YR) or
(most_recnt_yr_enr <= EXPECT_GRAD_YR and EXPECT_GRAD_TRM <> case when most_recnt_trm_enr is not null and degr_cde = 'ND' then null
when CUR_STUD_DIV = 'LW' and degr_cde is not null then '33' else most_recnt_trm_enr end))

/*Added 10/20/06 by Fabian. Division code correlation added 07/23/08 by Fabian.*/
update student_div_mast set EXPECTED_GRAD_YR = EXPECT_GRAD_YR, EXPECTED_GRAD_TRM = EXPECT_GRAD_TRM
from degree_history where degree_history.id_num = student_div_mast.id_num
and (cur_degree = 'Y' and DTE_DEGR_CONFERRED is null) and degree_history.div_cde = student_div_mast.div_cde 
and (EXPECTED_GRAD_YR <> EXPECT_GRAD_YR or EXPECTED_GRAD_TRM <> EXPECT_GRAD_TRM)

/*Clear Exit Date for retro active withdraws--medical, etc.  Added 9/26/2008 by Fabian.*/
update student_div_mast set EXIT_DTE = null where EXIT_DTE is not null

/*Matches student LDA in course history to exit date field in div master. 
Added 5/24/2005 by Fabian, corrected 9/14/2005 by Fabian.*/
PRINT 'Updating Exit Date for students who have withdrawn.'

/*Replacement LDA update script by Fabian on 1/11/08.*/
update student_div_mast set EXIT_DTE = (select case when max(isnull(drop_dte,'1/1/1896')) >= max(isnull(withdrawal_dte,'1/1/1896')) 
and max(isnull(drop_dte,'1/1/1896')) >= max(isnull(begin_dte,'1/1/1896')) then max(isnull(drop_dte,'1/1/1896'))
when max(isnull(withdrawal_dte,'1/1/1896')) >= max(isnull(drop_dte,'1/1/1896'))
and max(isnull(withdrawal_dte,'1/1/1896')) >= max(isnull(begin_dte,'1/1/1896')) then max(isnull(withdrawal_dte,'1/1/1896'))
/*Added begin_dte comparison to getdate() for students who enroll then withdraw prior 
to a quarter actually beginning; otherwise, they get populated with the ELSE end_date,
giving them an extra unearned quarter of deferment eligibility. - Fabian on 9/26/2008*/
when max(isnull(begin_dte,'1/1/1896')) >= getdate() then max(isnull(drop_dte,'1/1/1896'))
else max(isnull(end_dte,'1/1/1896')) end from student_crs_hist 
where (student_crs_hist.id_num = student_div_mast.id_num and student_crs_hist.STUD_DIV = student_div_mast.DIV_CDE))
where student_div_mast.id_num not in (select distinct id_num from stud_term_sum_div where transaction_sts = 'C')

PRINT 'Removing Exit Date for pre-registrations in upcoming quarter.'
update student_div_mast set EXIT_DTE = null where (EXIT_DTE > getdate() and exit_reason <> 'G') or EXIT_DTE = '1/1/1896'
