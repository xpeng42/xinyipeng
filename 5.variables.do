clear
cd "C:\Users\leejo\Dropbox\Joohyun\Research\Recall\data"
use cleandata\final_firmsz, clear

/**** to make code run faster by taking a sample run the following two lines*/
keep cod_pgr anno matr_az mesi_r sett_u sett_r gior_r retrib03 start_month end_month anno_n ///
	d_cess qualif prov firm_size_y ///
	firm_size_q1 firm_size_q2 firm_size_q3 firm_size_q4 ///
	firm_size_1 firm_size_2 firm_size_3 firm_size_4 firm_size_5 firm_size_6 ///
	firm_size_7 firm_size_8 firm_size_9 firm_size_10 firm_size_11 firm_size_12 
keep if  cod_pgr<151713 

format %18.0g matr_az
*****************************************************
************ (1) generating variables ***************
************ return by spell ************************

gen byte return_gap0 = 0
sort cod_pgr matr_az anno start_month end_month
by cod_pgr matr_az: gen n = _n
by cod_pgr matr_az: replace return_gap0 = 1 if (anno >anno[n-1]+1) 
by cod_pgr matr_az: replace return_gap0 = 1 if (anno ==anno[n-1]+1) & ((end_month[n-1] <12 )| (start_month>1) )
gen byte return_gap1 = return_gap0
gen byte return_gap2 = return_gap0
gen byte return_gap3 = return_gap0
by cod_pgr matr_az: replace return_gap0 = 1 if (anno ==anno[n-1])& (start_month > end_month[n-1] ) 
by cod_pgr matr_az: replace return_gap1 = 1 if (anno ==anno[n-1])& (start_month > end_month[n-1] +1 ) 
by cod_pgr matr_az: replace return_gap2 = 1 if (anno ==anno[n-1])& (start_month > end_month[n-1] +2 ) 
by cod_pgr matr_az: replace return_gap3 = 1 if (anno ==anno[n-1])& (start_month > end_month[n-1] +3 ) 

* generate employment dummy variable for each month
forvalues i=1/12 {
    generate temp_`i'= mod(mesi_r/( 10^(12-`i') ),10)
	generate emp_`i' = floor(temp_`i')
	drop temp_`i'
	label variable emp_`i'  "whether/not employed in month `i' current year"
}

* returns within "spell"

gen sum_emp_months = emp_1 + emp_2 + emp_3 + emp_4 + emp_5 + emp_6 + emp_7 + emp_8 + emp_9 + emp_10 + emp_11 + emp_12

forvalues i=1/3 {
gen return_within_yr`i' = 0
replace return_within_yr`i' = 1 if (end_month - start_month + 1 - sum_emp_month) >= `i'
}

forvalues i=1/3 {
gen return_and_returnwithin`i' = return_gap`i' + return_within_yr /* MUST DO: drop people with return_and_returnwithin1>=2 ######################*/
}
replace return_gap1 = 1 if ((end_month - start_month + 1 - sum_emp_month) >= 1) & return_within_yr==1
replace return_gap2 = 1 if (end_month - start_month + 1 - sum_emp_month) >= 2  & return_within_yr==1
replace return_gap3 = 1 if (end_month - start_month + 1 - sum_emp_month) >= 3  & return_within_yr==1

gen emp_1_diff = (emp_2 - emp_1)>=1
gen emp_2_diff = (emp_3 - emp_2)>=1
gen emp_3_diff = (emp_4 - emp_3)>=1
gen emp_4_diff = (emp_5 - emp_4)>=1
gen emp_5_diff = (emp_6 - emp_5)>=1
gen emp_6_diff = (emp_7 - emp_6)>=1
gen emp_7_diff = (emp_8 - emp_7)>=1
gen emp_8_diff = (emp_9 - emp_8)>=1
gen emp_9_diff = (emp_10 - emp_9)>=1
gen emp_10_diff = (emp_11 - emp_10)>=1
gen emp_11_diff = (emp_12 - emp_11)>=1

** number of returns within a observation * MUST DO: drop people with return_withcount>=2 *********************************###################
gen return_withincount = emp_1_diff + emp_2_diff + emp_3_diff + emp_4_diff + emp_5_diff + emp_6_diff + emp_7_diff + emp_8_diff + emp_9_diff + emp_10_diff + emp_11_diff 

/*** return_overlap1 ?? what should we do with these people? options: combine or drop? currently not counted as return*/
by cod_pgr matr_az: gen return_overlap1 = (anno ==anno[n-1])*(start_month == end_month[n-1] ) 
by cod_pgr matr_az: gen return_overlap = (anno ==anno[n-1])*(start_month < end_month[n-1] ) 
bys cod_pgr: egen return_overlap_total = total(return_overlap) 
bys cod_pgr: egen return_and_returnwithin1_ttl = max(return_and_returnwithin1)
bys cod_pgr: egen return_and_returnwithin2_ttl = max(return_and_returnwithin2)
bys cod_pgr: egen return_and_returnwithin3_ttl = max(return_and_returnwithin3)
bys cod_pgr: egen return_withincount_ttl = max(return_withincount)


********* MUST DO IN SAMPLE SELECTION **********
*drop if return_and_returnwithin1_ttl>=2
*drop if return_and_returnwithin2_ttl>=2
*drop if return_and_returnwithin3_ttl>=3
*drop if return_withincount_ttl>=2
*****************************************************
*****************************************************
*****************************************************
******* SELECT WHICH GAP WE DEFINE AS RETURN ********
gen return = return_gap2
*****************************************************
*****************************************************
*****************************************************

gen overlap = 0
gen overlap_month = .
sort cod_pgr anno start_month end_month
by cod_pgr : gen nnn = _n
by cod_pgr: replace overlap = 1 if (anno ==anno[nnn-1]) & (start_month < end_month[nnn-1] ) 
by cod_pgr: replace overlap_month = end_month[nnn-1]-start_month + 1 if (end_month>=end_month[nnn-1] & overlap==1)
by cod_pgr: replace overlap_month = end_month - start_month + 1  if (end_month<end_month[nnn-1] & overlap==1)
by cod_pgr : egen overlap_total = total(overlap)
by cod_pgr: egen overlap_maxm = max(overlap_month)
replace overlap_maxm = 0 if overlap_total==0

** return_in: gap between previous spell and new spell in months
sort cod_pgr matr_az anno start_month
gen return_in = .
by cod_pgr matr_az: replace return_in = 12*(anno - anno[n-1]) + start_month - end_month[n-1]-1  if (return==1 & return_within_yr==0) 
replace return_in = end_month - start_month + 1 - sum_emp_month  if (return==1 & return_within_yr==1) 
** return_5y: 1 if worker returned within 60 months (by Soojeong )
gen byte return_5y = return
replace return_5y = 0 if (return_in > 60)

**************************************************************
replace return=return_5y 
**************************************************************
**************************************************************
*****************************************************
*****************************************************

** number of unique employers the worker has had up their current employment spell (including current)
sort cod_pgr matr_az anno start_month end_month
by cod_pgr matr_az: gen evals_1 = _n ==1
sort cod_pgr anno start_month
by cod_pgr: gen numb_emp = sum(evals_1)

** new_spell: new employer or post return
** (new spell bc new employment (first time being matched with a particular firm)
gen byte new_spell = 0
replace new_spell = 1 if evals_1==1
*  (new spell bc new spell with previous employer) 
replace new_spell = 1 if (return==1) 
/*This misses returns to same firm after 1year of leave & counts "returns" that are involve back to back spells 
*sort cod_pgr anno start_month end_month 
*gen new_spell00 = 0
*by cod_pgr: replace new_spell00 = 1 if matr_az != matr_az[_n-1] Added by Xinyi on jan 13th 2022*/ 

** end_spell: employment spell end
sort cod_pgr anno start_month end_month
gen byte end_spell = 0
by cod_pgr: replace end_spell = 1 if (new_spell[_n+1]==1)

** numb_emp_when_left: for returned worker, # of unique employers the worker had upto previous employment at the returned firm (by Soojeong)
gen byte numb_emp_when_left = .
by cod_pgr: gen byte leaver_numb_emp = numb_emp if end_spell == 1
sort cod_pgr matr_az anno start_month
by cod_pgr matr_az: replace numb_emp_when_left = leaver_numb_emp[_n-1] if return == 1
drop leaver_numb_emp

*********************************************************************************
** spell_count: spell count for current firm (cumulative including current period)
sort cod_pgr matr_az anno start_month 
by cod_pgr matr_az: gen spell_count = sum(new_spell)

****rep_return: 1 if worker ever returned more than or equal to 2 times to the same firm *********
bys cod_pgr: egen rep_return_0 = max(spell_count)
gen rep_return = (rep_return_0>=3)

** spell_length_ttl_spell: total length of current spell in weeks
sort cod_pgr matr_az spell_count anno start_month
by cod_pgr matr_az spell_count: egen spell_length_ttl_spell = total(sett_r)

** spell_length_ttl: total length of work at a firm in weeks
by cod_pgr matr_az : egen spell_length_ttl = total(sett_r)

** experience_ttl: total length of work
sort cod_pgr anno start_month
by cod_pgr : gen experience_ttl = sum(sett_r)

** spell_length_until: total length of spell before current spell
bys cod_pgr matr_az spell_count: gen spell_length_until = sum(sett_r)-sett_r

** tenure: cumulative weeks worked as up to last year at current firm
by cod_pgr matr_az: gen tenure = sum(sett_r)-sett_r
gen tenuresq = tenure*tenure

** future_tenure: total weeks that will be worked in following periods (including current) at the current firm
by cod_pgr matr_az spell_count: gen future_tenure_ttl = spell_length_ttl - tenure

** worked_else: did worker work at another firm before return?
sort cod_pgr anno start_month end_month matr_az
by cod_pgr: gen nn= _n
gen byte worked_else = 0
by cod_pgr: replace worked_else = (matr_az[nn] != matr_az[nn-1]) if (return==1 & return_within_yr==0)

by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_2[nn]<emp_2[nn+1]) if (return==1 & return_within_yr==1 & end_month>2)
by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_3[nn]<emp_3[nn+1]) if (return==1 & return_within_yr==1 & end_month>3)
by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_4[nn]<emp_4[nn+1]) if (return==1 & return_within_yr==1 & end_month>4)
by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_5[nn]<emp_5[nn+1]) if (return==1 & return_within_yr==1 & end_month>5)
by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_6[nn]<emp_6[nn+1]) if (return==1 & return_within_yr==1 & end_month>6)
by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_7[nn]<emp_7[nn+1]) if (return==1 & return_within_yr==1 & end_month>7)
by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_8[nn]<emp_8[nn+1]) if (return==1 & return_within_yr==1 & end_month>8)
by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_9[nn]<emp_9[nn+1]) if (return==1 & return_within_yr==1 & end_month>9)
by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_10[nn]<emp_10[nn+1]) if (return==1 & return_within_yr==1 & end_month>10)
by cod_pgr: replace worked_else =(matr_az[nn] != matr_az[nn+1])*(anno[nn]==anno[nn+1])*(emp_11[nn]<emp_11[nn+1]) if (return==1 & return_within_yr==1 & end_month>11)
drop nn

** return_total_byfirm: total # of return by firm & pid
bys cod_pgr matr_az: egen return_total_byfirm = total(return)

** return_total: total # of return by pid
bys cod_pgr: egen return_total = total(return)

** number of firms worked in between for worked-else workers (added by Xinyi on Jan 13th 2022)
sort cod_pgr anno start_month end_month 
by cod_pgr: gen spell_count_anno = sum(new_spell)
sort cod_pgr matr_az anno start_month 
by cod_pgr matr_az: gen return_else_firm = spell_count_anno - spell_count_anno[_n-1] - 1 if (worked_else == 1)
order return, after(matr_az)
order worked_else, after(return)
order spell_count_anno, after(worked_else)
order return_else_firm, after(spell_count_anno)
sum return_else_firm // counts number of employer changes in between

** return_else_firm_unique: number of unique firms worked in between for worked-else workers (by Soojeong)
sort cod_pgr matr_az anno start_month end_month
by cod_pgr matr_az: gen return_else_firm_unique = numb_emp - numb_emp[_n-1] if (worked_else == 1)
*list cod_pgr anno matr_az start_month end_month return return_in return_5y return_else_firm return_else_firm_unique if cod_pgr ==  4681696
sum return_else_firm_unique // counts number of unique employers in between

** age
gen age = anno-anno_n

** retrib03_week: average weekly earnings
gen retrib03_week = retrib03/sett_r
** retrib03_month: average monthly earnings
gen retrib03_month = retrib03_week * 4.3333
** log weekly earnings
gen log_earn = log(retrib03_week)
**********************************************
**trimming outliers
winsor retrib03_week, p(.01) gen(retrib03_week_new)
gen retrib03_month_new = retrib03_week_new * 4.3333
gen log_earn_new = log(retrib03_week_new)
**********************************************

** qualif**********************************
** qualif_new: 1 if qualif starts with 1, 2 if qualif starts with 2, 3 if qualif starts with 3, and *0 if qualif is other value (added by Soojeong, fixed by JL)
gen byte qualif_new = 0 
replace qualif_new = 1 if strpos(qualif, "1") == 1 
replace qualif_new = 2 if strpos(qualif, "2") == 1
replace qualif_new = 3 if strpos(qualif, "3") == 1

** qualif_seasonal: 1 if seasonal worker according to quaif
gen byte qualif_seasonal = 0
replace qualif_seasonal = 1 if  strpos(qualif, "FS") !=0
replace qualif_seasonal = 1 if  strpos(qualif, "PS") !=0
by cod_pgr: egen byte qualif_seasonal_max = max(qualif_seasonal)

sort cod_pgr matr_az anno start_month
gen earn_diff_new = .
gen log_earn_diff_new = 0
gen exp_diff = .
replace log_earn_diff_new=. if return==0
by cod_pgr matr_az: replace earn_diff_new = retrib03_week_new - retrib03_week_new[n-1] if return==1
by cod_pgr matr_az: replace log_earn_diff_new = log_earn_new - log_earn_new[n-1] if return==1
by cod_pgr matr_az: replace exp_diff = experience_ttl - experience_ttl[n-1] if return==1

gen byte qualif_diff = 0
by cod_pgr matr_az: replace qualif_diff = 1 if (qualif_new != qualif_new[n-1]) & (return==1)

** locn_chgd: 1 if firm location changed from previous employment (by Soojeong)
egen prov_id = group(prov)
gen byte locn_chgd = 0 if prov_id != .
sort cod_pgr anno start_month end_month 
by cod_pgr: replace locn_chgd = 1 if (prov_id != prov_id[_n-1]) & (prov_id != .) & (prov_id[_n-1] != .)
**********************************************
**********************************************
save cleandata\final_genvariables0, replace 

cd "C:\Users\leejo\Dropbox\Joohyun\Research\Recall\data"
use cleandata\final_genvariables0, replace 
keep if qualif_seasonal_max==0 & rep_return==0 & overlap_total<=2 & overlap_maxm<7

sum return if overlap_total==0
replace retrib03_week = retrib03_week_new
/* we can either use the following and drop all workers with such kind of observation
replace retrib03_week = . if retrib03_week != retrib03_week_new */


*keep if rep_return==0 & qualif_seasonal_max==0 /* about 80 percent of entire sample*/
*keep if anno >=1989

compress
save cleandata\final_genvariables_sample, replace 

count if return_and_returnwithin1>=2
count if return_and_returnwithin2>=2
count if return_and_returnwithin3>=2
*save cleandata\final_genvariables, replace 
