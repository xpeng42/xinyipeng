clear
*cd "C:\Users\Soo\Dropbox\Recall\data"
*use cleandata\final_genvariables, replace

use final_genvariables, clear
/*to make code run faster by taking a sample run the following two lines*/
*keep if  cod_pgr<3525171

keep cod_pgr anno start_month end_month matr_az return worked_else prov firm_size_y firm_size_* end_spell new_spell spell_count numb_emp numb_emp_when_left leaver_numb_emp retrib03_month d_cess return_else_firm return_in

compress


merge m:m matr_az using cleandata\region.dta // to get region_id and prov_id
drop if _merge == 2
drop _merge


* masslayoff: valid for Veneto firms because firm_size reliable for Veneto firms

{//generate region var
* generate region variable using prov
gen region = prov
replace region = "Veneto" if region == "BL" | region == "PD" | region == "RO" | region == "TV" | region == "VE" | region == "VR" | region == "VI"
replace region = "Umbria" if region == "TR" | region == "PG" 
replace region = "Tuscany" if region == "AR" | region == "FI" | region == "GR" | region == "LI" | region == "LU" | region == "MS" | region == "PI" | region == "PT" | region == "PO" | region == "SI" 
replace region = "Trentino-South Tyrol" if region == "BZ" | region == "TN" 
replace region = "Sicily" if region == "AG" | region == "CL" | region == "CT" | region == "EN" | region == "ME" | region == "PA" | region == "RG" | region == "SR" | region == "TP"
replace region = "Sardinia" if region == "CA" | region == "NU" | region == "OR" | region == "SS" | region == "SU" 
replace region = "Piedmont" if region == "AL" | region == "AT" | region == "BI" | region == "CN" | region == "NO" | region == "TO" | region == "VB" | region == "VC"
replace region = "Molise" if region == "CB" | region == "IS" 
replace region = "Marche" if region == "AN" | region == "AP" | region == "FM" | region == "MC" | region == "PU" 
replace region = "Lombardy" if region == "BG" | region == "BS" | region == "CO" | region == "CR" | region == "LC" | region == "LO" | region == "MN" | region == "MI" | region == "MB" | region == "PV" | region == "SO" | region == "VA"
replace region = "Liguria" if region == "GE" | region == "IM" | region == "SP" | region == "SV" 
replace region = "Lazio" if region == "FR" | region == "LT" | region == "RI" | region == "RM" | region == "VT" 
replace region = "Friuli-Venezia Giulia" if region == "GO" | region == "PN" | region == "TS" | region == "UD"
replace region = "Emilia-Romagna" if region == "BO" | region == "FE" | region == "FC" | region == "MO" | region == "PR" | region == "PC" | region == "RA" | region == "RE" | region == "RN" 
replace region = "Campania" if region == "AV" | region == "BN" | region == "CE" | region == "NA" | region == "SA" 
replace region = "Calabria" if region == "CZ" | region == "CS" | region == "KR" | region == "RC" | region == "VV" 
replace region = "Basilicata" if region == "MT" | region == "PZ"
replace region = "Apulia" if region == "BA" | region == "BT" | region == "BR" | region == "FG" | region == "LE" | region == "TA"
replace region = "Aosta Valley" if region == "AO"
replace region = "Abruzzo" if region == "CH" | region == "AQ" | region == "PE" | region == "TE" 
* EE, FO, PS? 
replace region = "Marche" if region == "PS" // 	Pesaro and Urbino recorded as PS not PU
replace region = "Emilia-Romagna" if region == "FO" // Forlì-Cesena recorded as FO not FC
* EE: abroad
replace region = "Abroad" if region == "EE"

encode region, gen(region_id)
drop region
encode prov, gen(prov_id) 
drop prov
}

save cleandata\final_genvariables_layoff, replace
use cleandata\final_genvariables_layoff, clear


tab region_id
* 74 percents of observations are in VE. 




* recode of region: Veneto/ Adjacent region/ Else
recode region_id (22 = 1 Veneto) (9 10 13 19 = 2 Adjacent) (else = 3 Else), gen(region_id_3)
tabulate region_id region_id_3

* labelbook region_id
gen firm_in_VE = region_id == 22

* dummy for worker staying in Veneto the entire work history
bys cod_pgr: egen worker_in_VE = min(firm_in_VE) 

* firm size median is around 10
summ firm_size_y
bys region_id_3: summ firm_size_y, detail

* fweights: worker and firm
bys cod_pgr: gen w_worker = 1/_N
bys matr_az: gen w_firm = 1/_N
bys matr_az anno: gen w_firm_year = 1/_N


* 49 % of (firm-year) observations are in VE
preserve
duplicates drop matr_az anno, force
tab region_id_3
restore

* 33 % of firms are in VE
preserve
duplicates drop matr_az, force
tab region_id_3
restore

/*
preserve
collapse (mean) firm_in_VE, by(matr_az anno)
summ firm_in_VE
collapse (mean) firm_in_VE, by(matr_az)
summ firm_in_VE
restore
*/


****************************************************************
** identify mass layoffs (10 percent) by year, quarter, month **
****************************************************************
* masslayoff = 1 if firm size decreased by more than 10 percent in year/quarter/month

/* generated in genvariables file
egen firm_size_q1 = rmean(firm_size_1 firm_size_2 firm_size_3)
label variable firm_size_q1  "average number of employees first quarter current year"
egen firm_size_q2 = rmean(firm_size_4 firm_size_5 firm_size_6)
label variable firm_size_q2  "average number of employees second quarter current year"
egen firm_size_q3 = rmean(firm_size_7 firm_size_8 firm_size_9)
label variable firm_size_q3  "average number of employees third quarter current year"
egen firm_size_q4 = rmean(firm_size_10 firm_size_11 firm_size_12)
label variable firm_size_q4  "average number of employees fourth quarter current year"
*/

sort matr_az anno firm_size_y
* firm_size by year
gen byte masslayoff_y = 0
by matr_az anno: gen temp1 = _n
by matr_az: replace masslayoff_y = 1 if firm_size_y[_n] < 0.9*firm_size_y[_n-1] & temp1 == 1 & firm_size_y[_n-1] != .
* 3.5 percent

* quarter
* q1: 2.2p, q2: 2.4p, q3: 2.7p, q4: 3.2p
gen byte masslayoff_q1 = 0
gen byte masslayoff_q2 = 0
gen byte masslayoff_q3 = 0
gen byte masslayoff_q4 = 0
by matr_az: replace masslayoff_q1 = 1 if firm_size_q1[_n] < 0.9*firm_size_q4[_n-1] & temp1 == 1 & firm_size_q4[_n-1] != .
forvalues j=2/4 {
	local j_ = `j'-1
	by matr_az: replace masslayoff_q`j' = 1 if firm_size_q`j'[_n] < 0.9*firm_size_q`j_'[_n] & temp1 == 1 & firm_size_`j_'[_n] != .

}

* month 
* about 1 percent
gen byte masslayoff_m1 = 0
by matr_az: replace masslayoff_m1 = 1 if firm_size_1[_n] < 0.9*firm_size_12[_n-1] & temp1 == 1 & firm_size_12[_n-1] != .

forvalues j=2/12 {
	gen byte masslayoff_m`j' = 0
	local j_ = `j'-1
	by matr_az: replace masslayoff_m`j' = 1 if firm_size_`j'[_n] < 0.9*firm_size_`j_'[_n] & temp1 == 1 & firm_size_`j_'[_n] != .
}
drop temp1

tab region_id_3 masslayoff_y, row // It makes more sense to only look at Veneto firms.
sum masslayoff_y if firm_in_VE // 1.8 percent

* dummy for working in Veneto at least one time
bys cod_pgr: egen byte worker_ever_in_VE = max(firm_in_VE) 
/* 92.65 % of workers were employed at least once by Veneto firm
summ worker_ever_in_VE [iweight = w_worker]
preserve
collapse (mean) worker_ever_in_VE, by (cod_pgr)
tab worker_ever_in_VE
restore
*/



tab worker_ever_in_VE

* firm size mean is 456, but median is 21
preserve
collapse (mean) firm_size_y, by(matr_az anno)
summ firm_size_y, detail
collapse (mean) firm_size_y, by(matr_az)
summ firm_size_y, detail
drop if firm_size_y > 9000
summ firm_size_y, detail
restore
*summ firm_size_y [iweight = w_firm]


gen firm_size_group = 0
replace firm_size_group = 1 if firm_size_y < 10
replace firm_size_group = 2 if firm_size_y >= 10 & firm_size_y < 20
replace firm_size_group = 3 if firm_size_y >= 20
label define firm_sz_3g 1 "<10" 2 "10-20" 3 ">=20"
label values firm_size_group "firm_sz_3g"

compress

* restrict by firm_size < 10, between 10 and 20, bigger than 20
summ masslayoff* if firm_size_y < 10 & firm_in_VE // yearly rate: 5.5% 
summ masslayoff* if firm_size_y < 20 & firm_size_y >= 10 & firm_in_VE // 0.6% 
summ masslayoff* if firm_size_y >= 20 & firm_in_VE // 0.09%

table firm_size_group, stat(mean masslayoff_y)
tabout firm_size_group using "masslayoff.tex", replace ///
    style(tex) sum  ///
    c(mean masslayoff_y) f(4) body


bys matr_az: egen firm_had_masslayoff = max(masslayoff_y) 

bys anno: egen ratio_masslayoff_worker = mean(masslayoff_y) if firm_in_VE & anno != 1984

* by firm-year observations
preserve
duplicates drop matr_az anno, force
summ masslayoff* if firm_in_VE
summ masslayoff* if firm_size_y < 10 & firm_in_VE // yearly rate: 0.11% 
summ masslayoff* if firm_size_y < 20 & firm_size_y >= 10 & firm_in_VE // 0.67% 
summ masslayoff* if firm_size_y >= 20 & firm_in_VE // 0.19%

bys anno: egen ratio_masslayoff_firm = mean(masslayoff_y) if firm_in_VE & anno != 1984
twoway line ratio_masslayoff_firm anno, ytitle("Ratio of Mass Layoff Firms") ///
|| line ratio_masslayoff_worker anno, yaxis(2) ytitle("Ratio of Workers having Mass Layoff", axis(2)) ///
xtitle("Year")  title("Ratio of Mass Layoff") xlabel(1985 (2) 2000)
graph export "over time mass layoff rate.png", as(png) replace


* percentage of firm which ever had mass layoff
duplicates drop matr_az, force
summ firm_had_masslayoff // yearly rate: 55%
summ firm_had_masslayoff if firm_in_VE // yearly rate: 65.4%
summ firm_had_masslayoff if firm_size_y < 10 & firm_in_VE // yearly rate: 65%
summ firm_had_masslayoff if firm_size_y < 20 & firm_size_y >= 10 & firm_in_VE // 78% 
summ firm_had_masslayoff if firm_size_y >= 20 & firm_in_VE // 73%

restore

* check if masslayoff happens from closing down

****** generate location change dummies *********
gen byte locn_chgd_prov = 0 if prov_id != .
sort cod_pgr anno start_month end_month 
by cod_pgr: replace locn_chgd_prov = 1 if (prov_id != prov_id[_n-1]) & (prov_id != .) & (prov_id[_n-1] != .)

by cod_pgr: gen byte locn_chgd_reg = (region_id != region_id[_n-1]) & (region_id != .) & (region_id[_n-1] != .)
by cod_pgr: gen byte locn_chgd_reg_3 = (region_id_3 != region_id_3[_n-1]) & (region_id_3 != .) & (region_id_3[_n-1] != .)

by cod_pgr: gen prov_id_lag = prov_id[_n-1]
by cod_pgr: gen region_id_lag = region_id[_n-1]
by cod_pgr: gen region_id_3_lag = region_id_3[_n-1]
by cod_pgr: gen region_id_3_for = region_id_3[_n+1]
label values region_id_3_lag "region_id_3"
label values region_id_3_for "region_id_3"


label variable region_id_3_lag "previous location"
label variable region_id_3 "location"

compress

********** location change *********************
label variable locn_chgd_prov "province changed"
label variable locn_chgd_reg "region changed"
eststo clear
local listvar "locn_chgd_prov locn_chgd_reg"
estpost summ `listvar' if new_spell & return & worked_else
eststo return_worked_else
/*
esttab  return_worked_else  return_wo new_spell_not_return new_spell, cell(mean (fmt(3))) ///
		mtitles("Return w/" "Return w/o" "Move to new employer" "Any move") ///
	    replace label nostar unstack nonote nonumber compress nogaps
*/
esttab  return_worked_else using "locn_chgd.tex", cell(mean (fmt(3))) ///
		mtitles("Return w/") ///
		title("Ratio of returns involving location change") ///
	    replace label nostar unstack nonote nonumber compress nogaps nofloat
****** compare return_else_firm and return_in ************
eststo clear
estpost summ return_else_firm return_in if return & worked_else & locn_chgd_prov
eststo changed
estpost summ return_else_firm return_in if return & worked_else & !locn_chgd_prov
eststo notchanged
label variable return_else_firm "n. of employers in between"
label variable return_in "gap in months"
esttab  changed notchanged using "locn_chg_gap.tex", cell(mean (fmt(2)) sd (fmt(2))) ///
		mtitles("w/ location change" "w/o location change") ///
		title("Comparison in return properties") ///
	    replace label nostar unstack nonote nonumber compress nogaps nofloat
preserve
keep if worked_else
ttest return_else_firm, by(locn_chgd_prov)
ttest return_in, by(locn_chgd_prov)
restore


bys locn_chgd_prov: summ return_else_firm return_in if return & worked_else

/* check
summ locn_chgd_prov locn_chgd_reg locn_chgd_reg_3 
summ locn_chgd_prov locn_chgd_reg locn_chgd_reg_3 if new_spell
summ locn_chgd_prov locn_chgd_reg locn_chgd_reg_3 if new_spell & !return
summ locn_chgd_prov locn_chgd_reg locn_chgd_reg_3 if new_spell & return & worked_else
summ locn_chgd_prov locn_chgd_reg locn_chgd_reg_3 if new_spell & return & !worked_else

summ locn_chgd_prov locn_chgd_reg locn_chgd_reg_3 if !new_spell
summ locn_chgd_prov locn_chgd_reg locn_chgd_reg_3 if return & worked_else
summ locn_chgd_reg locn_chgd_reg_3 return_else_firm if return & worked_else & locn_chgd_prov
summ locn_chgd_reg locn_chgd_reg_3 return_else_firm if return & worked_else & locn_chgd_reg
summ locn_chgd_prov locn_chgd_reg return_else_firm if return & !worked_else
list cod_pgr if return & !worked_else & locn_chgd_prov
list cod_pgr anno matr_az start_month end_month prov_id return if cod_pgr == 396934 // multiple jobs
list cod_pgr anno matr_az start_month end_month prov_id region_id region_id_3 return locn_chgd_prov if cod_pgr == 573513 // multiple jobs
list cod_pgr anno matr_az start_month end_month prov_id region_id region_id_3 return locn_chgd_prov worked_else if cod_pgr == 38889876 // multiple jobs

list cod_pgr anno matr_az start_month end_month prov_id region_id region_id_3 return locn_chgd_prov if temp2

gen temp = return & !worked_else & locn_chgd_prov
bys cod_pgr : egen temp2 = max(temp)
*/

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

compress


* for leavers
preserve
keep if leaver_0 == 1
eststo clear
eststo: estpost tab region_id_3_lag region_id_3	
esttab est1 using "location_change_leaver.tex", cell(b rowpct) unstack noobs ///
    replace nonum collabels(none) eqlabels(, lhs("current location")) ///
    mtitles("next location")
restore

* for worked else workers
preserve
keep if return == 1
keep if return_we == 1
eststo clear
eststo: estpost tab region_id_3_lag region_id_3	
esttab est1 using "location_change_return_we.tex", cell(b rowpct) unstack noobs ///
    replace nonum collabels(none) eqlabels(, lhs("previous location")) ///
    mtitles("current location")
restore

* for just return workers: zero
preserve
keep if return == 1
keep if return_wo == 1
eststo clear
eststo: estpost tab region_id_3_lag region_id_3	
esttab est1 using "location_change_return_wo.tex", cell(b rowpct) unstack noobs ///
    replace nonum collabels(none) eqlabels(, lhs("previous location")) ///
    mtitles("current location")
restore


sort cod_pgr anno start_month end_month matr_az



