* this file generates wage path plots of the return workers and non return workers in 1991-1995
* it uses average monthly wage that workers receive from the firms at which they are employed
* Part 1) makes sample restrictions
* Part 2) generates wide panel

clear
cd "C:\Users\leejo\Dropbox\Joohyun\Research\Recall\data"
global overleaf "C:\Users\leejo\Dropbox\Apps\Overleaf\Recall_proposal"
use cleandata\final_genvariables, replace 
* use cleandata\final_genvariables_compressed, replace

* QUESTION (run the next line for ex): * workers with multiple jobs dropped? * end_spell == 1 when a spell with a firm ends? 
* list cod_pgr anno start_month end_month matr_az return new_spell end_spell if cod_pgr ==  29865809

gen end_yearmm = .
replace end_yearmm = end_month + anno*100 if end_spell==1

/* the four types of workers : 1) stayers, 2) return w/o other firm 3) return w/ other firm 4)leave for good */
keep if anno>=1986 & anno<=1988

/*only consider people that worked at least 50 weeks at their job in 1986*/
gen keep_0 = (sett_r>=50)*(anno==1986)
bys cod_pgr: egen keep = max(keep_0)
keep if keep==1

/*leavers: workers that leave at XX[1991 Dec]*/
gen leaver_0 = (end_spell==1)*(end_month==12)*(anno==1986)
bys cod_pgr: egen leaver = max(leaver_0) 

/*firm that leavers leave*/
gen leaver_firm0 = 0
replace leaver_firm0 = matr_az if (end_spell==1)&(end_month==12)&(anno==1986)
bys cod_pgr: egen leaver_firm = max(leaver_firm0)

**************************************************************
/*return_a ==1 if return to the firm left in the period above*/
sort cod_pgr matr_az anno start_month
gen return_a = 0
drop n
by cod_pgr matr_az: gen n = _n
by cod_pgr matr_az: replace return_a = 1 if (anno >anno[n-1]+1)&(leaver_0[n-1]==1)
by cod_pgr matr_az: replace return_a = 1 if (anno ==anno[n-1]+1) &  (start_month>1) &(leaver_0[n-1]==1)
by cod_pgr matr_az: replace return_a = 1 if (anno ==anno[n-1])& (start_month > end_month[n-1] +1 ) &(leaver_0[n-1]==1)

/* returner ==1 if this is person that leaves and comes back within 3 years to the firm they leave in XX*/
bys cod_pgr: egen returner = total(return_a)
count if returner==1
drop if returner==2

/*keep observations that do not leave before XX*/ 
gen end_spellbf0 = 0
replace end_spellbf0 = 1 if end_yearmm <198612 & end_spell==1
bys cod_pgr: egen end_spellbf = total(end_spellbf)
drop if end_spellbf>=1

/*non-leavers stay in same firm entire period*/
gen end_spellaf0 = 0
replace end_spellaf0 = 1 if end_yearmm > 198612 & end_spell==1 & leaver==0
bys cod_pgr: egen end_spellaf = total(end_spellaf0)
drop if end_spellaf >= 1 /*(239,650 observations deleted)*/

/******************************************************/

/*return to other firms?*/
bys cod_pgr: egen return_ttl = total(return)
count if return_ttl>=1 & leaver ==0 /*134,402 stayers are working at firm they returned to*/
count if return_ttl>=1 & returner==0 & leaver ==1 /*241 leavers */
*drop if return_ttl>0 & returner==0

/********worker types: ************/
gen stayer = (leaver==0) /*1,975,215*/
gen return_we0 = (worked_else* returner*leaver) 
bys cod_pgr: egen return_we = max(return_we0) 
gen return_wo = (1-return_we)*returner
gen leave_fg = leaver *(1-returner)

/* at most 1)one firm for non-leaver; 2)one firm for AUA; 3)two firms for ABA; 4)one for AU & two for AB  */
by cod_pgr matr_az: gen evals_11 = _n ==1
bys cod_pgr: egen contracts_s = total(evals_11)  /*total numb of unique firms workers work at*/

sum contracts_s if stayer==1
sum contracts_s if return_wo == 1
sum contracts_s if return_we==1
sum contracts_s if leave_fg==1

sum stayer return_wo return_we leave_fg 

drop if contracts_s>=2 & stayer==1
/*   keep if contracts_s*stayer<=1 /*1*/
keep if contracts_s*return_wo<=1/*2*/
keep if contracts_s*return_we<= 3 /*3*/ */

* dummy for returning before month 25 (added by Soojeong)
gen temp = 1 if return_a & anno == 1987 
bys cod_pgr: egen byte return_bf_m25 = max(temp)
drop temp
replace return_bf_m25 = 0 if return_bf_m25 == .

compress
save cleandata\final_fourgroups , replace 
use cleandata\final_fourgroups, replace
sum return_in if return_wo==1
sum return_in if return_we==1

* generate avg monthly wage
forvalues i=1/36 {
	generate earn_mth0_`i' = retrib03_month_new * (anno == 1986 + trunc((`i'-0.5)/12))* ((mod(`i', 12))<= end_month) * ((mod(`i', 12))>= start_month)
	replace earn_mth0_`i' = retrib03_month_new * (anno == 1986 + trunc((`i'-0.5)/12)) if (mod(`i', 12)==0)&(end_month==12)
	by cod_pgr : egen earn_mth`i' = max(earn_mth0_`i')
}

sort cod_pgr
quietly by cod_pgr:  gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
keep cod_pgr stayer return_we return_wo leave_fg return_bf_m25 earn_mth1 earn_mth2 earn_mth3 earn_mth4 earn_mth5 earn_mth6 earn_mth7 earn_mth8 earn_mth9 earn_mth10 ///
		earn_mth11 earn_mth12 earn_mth13 earn_mth14 earn_mth15 earn_mth16 earn_mth17 earn_mth18 earn_mth19 earn_mth20 ///
		earn_mth21 earn_mth22 earn_mth23 earn_mth24 earn_mth25 earn_mth26 earn_mth27 earn_mth28 earn_mth29 earn_mth30 ///
		earn_mth31 earn_mth32 earn_mth33 earn_mth34 earn_mth35 earn_mth36 /*earn_mth37 earn_mth38 earn_mth39 earn_mth40 ///
		earn_mth41 earn_mth42 earn_mth43 earn_mth44 earn_mth45 earn_mth46 earn_mth47 earn_mth48*/

reshape long earn_mth, i(cod_pgr stayer return_we return_wo leave_fg) j(mth)

save cleandata\final_long , replace 

*****************************************************************************************************
use cleandata\final_long, replace

{ /*Make plot for earnings: for comparing before leaving at Dec,92 or Jan,93 or month 24 or 25.*/
keep earn_mth stayer return_we return_wo leave_fg mth
collapse (mean) earn_mth, by(stayer return_we return_wo leave_fg mth)

replace stayer = earn_mth if stayer==1
replace return_we = earn_mth if return_we==1
replace return_wo = earn_mth if return_wo==1
replace leave_fg = earn_mth if leave_fg==1
drop earn_mth
collapse (sum) stayer return_we return_wo leave_fg, by(mth)
replace return_wo = . if mth==12
tsset mth
twoway ///
|| (tsline stayer, lcolor(black) lpattern("solid")) ///
|| (tsline return_we, lcolor(green) lpattern("longdash")) ///
|| (tsline return_wo, lcolor(blue) lpattern("dash")) ///
|| (tsline leave_fg, lcolor(red) lpattern("shortdash")) ///
	, xtitle("Month") ytitle("Average Monthly Earnings") xline(12)  ///
	legend(order(1 "Stayer" 2 "Return_W/" 3 "Return_W/O" 4 "Leave")) ///
	xlabel(0 (6) 36) ///
	graph export "$overleaf\images\trends_overtime.png"

}

********************************************************************************************************
use cleandata\final_long, replace
 /*Make plot for earnings excluding people that do not work: for comparing before leaving at Dec,92 or Jan,93 or month 24 or 25.*/
keep earn_mth stayer return_we return_wo leave_fg mth
drop if earn_mth==0
collapse (mean) earn_mth, by(stayer return_we return_wo leave_fg mth)

replace stayer = earn_mth if stayer==1 & earn_mth>0
replace return_we = earn_mth if return_we==1 & earn_mth>0
replace return_wo = earn_mth if return_wo==1 & earn_mth>0
replace leave_fg = earn_mth if leave_fg==1 & earn_mth>0
drop if earn_mth==0
drop earn_mth 
collapse (sum) stayer return_we return_wo leave_fg, by(mth)

tsset mth
twoway ///
|| (tsline stayer, lcolor(black) lpattern("solid")) ///
|| (tsline return_we, lcolor(green) lpattern("longdash")) ///
|| (tsline return_wo, lcolor(blue) lpattern("dash")) ///
|| (tsline leave_fg, lcolor(red) lpattern("shortdash")) ///
	, xtitle("Month") ytitle("Average Monthly Earnings") xline(12)	///
	legend(order(1 "Stayer" 2 "Return_W/" 3 "Return_W/O" 4 "Leave")) ///
	xlabel(0 (6) 36) ///
	graph export "$overleaf\images\trends_overtime_workers.png",  replace

*************************************************************
/*
gen end_spell_m0 = 0
gen end_spell_y0 = 0
replace end_spell_m0 = end_month if end_spell==1
replace end_spell_y0 = anno if end_spell==1
sort cod_pgr matr_az spell_count 
bys cod_pgr matr_az spell_count: egen end_spell_m = max(end_spell_m0)
bys cod_pgr matr_az spell_count: egen end_spell_y = max(end_spell_y0)
*/

*************************************************************************
******drop people who were unemployed (earned zero) for some period *****
use cleandata\final_long, replace
compress

gen byte earn_zero = earn_mth == 0
bys cod_pgr: egen int total_zero = total(earn_zero) /*sum of months with zero earning*/
tab return_wo
egen x = group(cod_pgr)
summ x
global numworker `r(max)'
drop x
drop if total_zero > 0 /* remove workers who had any month of zero earning */
{/* save the number of workers per each type */
egen x = group(cod_pgr) if stayer
summ x
global numstayer `r(max)'
drop x
egen x = group(cod_pgr) if leave_fg
summ x
global numleaver `r(max)'
drop x
egen x = group(cod_pgr) if return_we
summ x
global numreturn `r(max)'
drop x
}

/* 
leaver: by number of different firms they work at
*/

keep earn_mth stayer return_we return_wo leave_fg mth
collapse (mean) earn_mth, by(stayer return_we return_wo leave_fg mth)

replace stayer = earn_mth if stayer==1 & earn_mth>0
replace return_we = earn_mth if return_we==1 & earn_mth>0
replace return_wo = earn_mth if return_wo==1 & earn_mth>0
replace leave_fg = earn_mth if leave_fg==1 & earn_mth>0
drop earn_mth 
collapse (sum) stayer return_we return_wo leave_fg, by(mth)

tsset mth
twoway ///
	|| (tsline stayer, lcolor(black) lpattern("solid")) ///
	|| (tsline return_we, lcolor(green) lpattern("longdash")) ///
	|| (tsline leave_fg, lcolor(red) lpattern("shortdash")) ///
	, xtitle("Month") ytitle("Average Monthly Earnings") xline(12)	///
	legend(order(1 "Stayer" 2 "Return_W/" 3 "Leave")) ///
	xlabel(0 (6) 36) ///
	note("# staying workers: $numstayer, return_w/ workers: $numreturn, leave workers: $numleaver.")
	
graph export "trends_overtime_drop_unemp.png", replace
graph export "$overleaf\images\trends_overtime_drop_unemp.png",  replace

********************************************************
* only working people: further divide returners into two groups depending on whether workers return in 1 yr *****
use cleandata\final_long, replace
compress

gen byte earn_zero = earn_mth == 0
bys cod_pgr: egen int total_zero = total(earn_zero)
tab return_wo
egen x = group(cod_pgr)
summ x
global numworker `r(max)'
drop x
drop if total_zero > 0 /* remove workers who had any month of zero earning */
{/* save the number of workers per each type */
egen x = group(cod_pgr) if stayer
summ x
global numstayer `r(max)'
drop x
egen x = group(cod_pgr) if leave_fg
summ x
global numleaver `r(max)'
drop x
egen x = group(cod_pgr) if return_we
summ x
global numreturn `r(max)'
drop x
egen x = group(cod_pgr) if return_bf_m25
summ x
global numreturnbf `r(max)'
di $numreturn
di $numreturnbf
di $numreturn - $numreturnbf
global numreturnaf = $numreturn - $numreturnbf
di $numreturnaf
}


keep earn_mth stayer return_we return_wo leave_fg mth return_bf_m25
collapse (mean) earn_mth, by(stayer return_we return_wo leave_fg return_bf_m25 mth)

replace stayer = earn_mth if stayer==1 & earn_mth>0
replace return_we = earn_mth if return_we==1 & earn_mth>0
replace return_wo = earn_mth if return_wo==1 & earn_mth>0
replace leave_fg = earn_mth if leave_fg==1 & earn_mth>0
replace return_bf_m25 = earn_mth if return_bf_m25 & earn_mth > 0
gen return_af_m25 = earn_mth if !return_bf_m25 & return_we & earn_mth > 0
drop earn_mth 
collapse (sum) stayer return_af_m25 return_wo leave_fg return_bf_m25, by(mth)

tsset mth
twoway ///
	|| (tsline stayer, lcolor(black) lpattern("solid")) ///
	|| (tsline return_bf_m25, lcolor(green) lpattern("longdash")) ///
	|| (tsline return_af_m25, lcolor(blue) lpattern("longdash")) ///
	|| (tsline leave_fg, lcolor(red) lpattern("shortdash")) ///
	, xtitle("Month") ytitle("Average Monthly Earnings") xline(12)	///
	legend(order(1 "Stayer" 2 "Return_bf_m25/" 3 "Return_af_m25" 4 "Leave")) ///
	xlabel(0 (6) 36) ///
	note("# workers for stayer: $numstayer, return_bf_m25: $numreturnbf, return_af_m25: $numreturnaf, leave: $numleaver.")
	
graph export "trends_overtime_drop_unemp_1.png", replace
graph export "$overleaf\images\trends_overtime_drop_unemp_1.png",  replace


* by qualif?

