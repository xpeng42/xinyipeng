* compare what percentage of workers leave returned firm for another firm, return w/o workers and worked else workers. 
* ratio of ABAC vs ratio of AUAC
* basic idea: if for returner, the number of unique employer increases afterwards, count this as return_then_leave


use cleandata\final_genvariables_layoff, clear

/*
keep cod_pgr anno start_month end_month matr_az return worked_else prov firm_size_y firm_size_* end_spell new_spell spell_count numb_emp numb_emp_when_left leaver_numb_emp retrib03_month d_cess


compress

save cleandata\final_ABAC.dta, replace
*/

****************************************


/* the four types of workers : 1) stayers, 2) return w/o other firm 3) return w/ other firm 4)leave for good */

/*look at just years 1991 to 1995*/
keep if anno>=1991 & anno<=1995

/*leavers: workers that leave at XX[1992  June or 1992 October]*/
gen leaver_0 = (end_spell==1)*(end_month>=6)*(end_month<=10)*(anno==1992)
bys cod_pgr: egen leaver = max(leaver_0) 
gen leaver_firm = 0
replace leaver_firm = matr_az if (end_spell==1)&(end_month>=6)&(end_month<=10)&(anno==1992)

/*return to the firm left in the period above*/
sort cod_pgr matr_az anno start_month
gen return_a = 0
by cod_pgr matr_az: gen n = _n
by cod_pgr matr_az: replace return_a = 1 if (anno >anno[n-1]+1)&(leaver_0[n-1]==1)
by cod_pgr matr_az: replace return_a = 1 if (anno ==anno[n-1]+1) & ((end_month[n-1] <12 )|(d_cess[n-1]!="0000")| (start_month>1) )&(leaver_0[n-1]==1)
by cod_pgr matr_az: replace return_a = 1 if (anno ==anno[n-1])& (start_month > end_month[n-1] +1 ) &(leaver_0[n-1]==1)

/*drop people that left in other period*/
bys cod_pgr: egen end_spell0 = total(end_spell)
drop if end_spell0>=1 & leaver==0  /* 1,975,215 dropped (about half)*/
sum start_month anno if end_spell0==1 & leaver==1 & return_a==1

/**************************************************/
bys cod_pgr: egen returner = total(return_a)
/******************************************************/
/*at most one return*/
bys cod_pgr: egen return_ttl = total(return)
keep if return_ttl < = 1 
* return to other firms are dropped
drop if return_ttl>returner
/*only returns to firms left during XX*/
/*about 7 percent of people that are returning are returning to a job they left other than at XX*/
sum leaver if return_ttl==1
drop if return_ttl==1 & leaver==0 


/********worker types: ************/
gen stayer = (end_spell0==0)*(leaver==0) /*1,975,215*/
bys cod_pgr: egen return_we = total(worked_else* returner*leaver) 
gen return_wo = return_ttl*(1-return_we)*returner
gen leave_fg = leaver * (1-return_ttl)*(1-returner)

bys cod_pgr: egen sum_newspell = total(new_spell)

sort cod_pgr matr_az anno start_month end_month
by cod_pgr matr_az: gen evals_111 = _n ==1
sort cod_pgr anno start_month end_month
by cod_pgr: gen numb_emp_1 = sum(evals_111) /* number of unique firms up to current spell */
sort cod_pgr matr_az anno start_month end_month
by cod_pgr matr_az: gen evals_11 = _n ==1
bys cod_pgr: egen contracts_s = total(evals_11)  /*total numb of unique firms workers work at*/


order contracts_s numb_emp_1 sum_newspell, after (end_month)

gen return_then_leave = (return) & (contracts_s != numb_emp_1)

bys cod_pgr: egen return_then_leaver = max(return_then_leave)

sum stayer return_wo return_we leave_fg if anno==1994
sum leaver if anno==1993
/*about 4.2 percent of workers in 1993 are leavers*/

sum return_then_leaver if return_wo == 1
sum return_then_leaver if return_we == 1

gen byte temp_ABCA = . 
replace temp_ABCA = 1 if return_else_firm > 1 & return_else_firm != .
replace temp_ABCA = 0 if return_else_firm <= 1 & return_else_firm !=.
bys cod_pgr: egen worker_ABCA = max(temp_ABCA) 
tab return_else_firm if return_we == 1
bys cod_pgr: egen return_else_firm_ = total(return_else_firm)
/*
gen gvar = .
replace gvar = 1 if worker_ABCA == 1 & return_we == 1
replace gvar = 2 if worker_ABCA == 0 & return_we == 1
replace gvar = 3 if return_wo == 1
*/
preserve
label variable return_then_leaver "return worker leaves again"
duplicates drop cod_pgr, force
keep if returner == 1
estpost summ return_then_leaver if worker_ABCA == 1 & return_we == 1
eststo ABCA
estpost summ return_then_leaver if worker_ABCA == 0 & return_we == 1
eststo ABA
estpost summ return_then_leaver if return_wo == 1
eststo AUA
/*
esttab AUA ABA ABCA, cell(mean (fmt(3))) unstack noobs ///
    replace nonum collabels(none) ///
    mtitles("return w/o" "return after one firm" "return after more firms") ///
	title("Ratio of return workers leaving again for another firm")
*/
esttab AUA ABA ABCA using "return_then_leave.tex", cell(mean (fmt(3))) unstack noobs ///
    replace nonum collabels(none) nofloat label///
    mtitles("return w/o" "return after one firm" "return after more firms") ///
	title("Ratio of return workers leaving again for another firm")
restore

preserve
duplicates drop cod_pgr, force
keep if returner == 1
sum return_then_leaver return_else_firm_ if worker_ABCA == 1 & return_we == 1
sum return_then_leaver return_else_firm_ if worker_ABCA == 0 & return_we == 1
sum return_then_leaver return_else_firm_ if return_wo == 1
ttest return_then_leaver, by (return_wo)
ttest return_then_leaver, by (worker_ABCA)
restore

sum return_then_leaver if return_wo == 1
sum return_then_leaver if return_we == 1
ttest return_then_leaver, by(return_we) unequal
ttest return_then_leaver, by(return_we) 
sum return_then_leaver return_else_firm if worker_ABCA == 1 & return_we == 1
sum return_then_leaver return_else_firm if worker_ABCA == 0 & return_we == 1
keep if return_we == 1
ttest return_then_leaver, by(worker_ABCA) unequal
restore
keep if returner == 1
tab return_wo return_then_leaver
*label define return_wo 0 "return w/e" 1 "return w/o"
*label values return_wo "return_wo"

/*
eststo clear
eststo: estpost tab return_wo return_then_leaver
	esttab AUA ABA ABCA using "return_then_leave.tex", cell(mean pct) unstack noobs ///
    replace nonum collabels(none) eqlabels(, lhs("return_wo")) ///
    mtitles("return_then_leaver")
*/


