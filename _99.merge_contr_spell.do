/* This do file is to do the bisic cleaning of data contr */


clear
set mem 2g
set more off
cd "C:\Users\xpeng\Dropbox\Research\Recall\data"
use rawdata\contr, clear

log using merge_contr_spell, replace

*** Variables recode: including qualif



************** (1): generate job starting month and end month of each obs based on mesi_r
gen byte start_month = 0
order start_month, before(d_cess)
tostring mesi_r, generate(month) force format(%14.0g)
replace start_month = 13 - length(month)

* end_month is the largest digit of the last 1 
gen byte end_month = 0
order end_month, after(start_month)
replace end_month = 12 if substr(month,-1,1) == "1"
replace end_month = 11 if substr(month,-2,.) == "10" 
replace end_month = 10 if substr(month,-3,.) == "100" 
replace end_month = 9 if substr(month,-4,.) == "1000" 
replace end_month = 8 if substr(month,-5,.) == "10000" 
replace end_month = 7 if substr(month,-6,.) == "100000" 
replace end_month = 6 if substr(month,-7,.) == "1000000" 
replace end_month = 5 if substr(month,-8,.) == "10000000" 
replace end_month = 4 if substr(month,-9,.) == "100000000" 
replace end_month = 3 if substr(month,-10,.) == "1000000000" 
replace end_month = 2 if substr(month,-11,.) == "10000000000" 
replace end_month = 1 if substr(month,-12,.) == "100000000000" 

/*** compare with d_cess
duplicates tag cod_pgr anno matr_az, gen(multi_tag)
preserve
keep if multi_tag == 0
restore
gen d = substr(d_cess, 3,2)
order d, after(d_cess)
destring d, force replace
replace d_cess = "0000" if d == 0

* generate a new end variable representing
gen end = d
replace end = d-1 if substr(d_cess, 1,2) == "01" 
*replace end_month = end_month+1 if substr(d_cess, 1,2) == "31"

gen diff = end - end_month 
order diff, after(end)
*bys cod_pgr anno matr_az: egen diff_m = max(diff)
*order diff_m, after(diff)


** Some weird cases
replace end = end_month if d > 12
replace end = end_month if diff < 0 & d_cess == "0000" & multi_tag == 0
replace end = end_month if diff == 0 & d_cess != "0000" & multi_tag == 0


****** First, I deal with multi_tag == 0
** In some cases in which end_month is not equal to d_cess, but d_cess = end_month+1. I treat these cases to be normal because it d_cess is the date the worker officially left the firm while end_month is the month he stopped working
*drop if d == end_month+1 & d_cess != "0000" & multi_tag == 0

* Next, there are still some weird cases left. I try to match the end_month with sett_r (working weeks)
gen duration1 = end_month - start_month + 1
gen duration2 = d - start_month + 1
gen min_week = 4*(duration2-2)+2
replace end = end_month if sett_r < min_week & multi_tag == 0
*drop if d == .

gen max_week = 4*duration2
replace end = end_month if sett_r > max_week & multi_tag == 0
*drop if d == .

drop min_week max_week
gen min_week = 4*(duration1-2)+2
replace end = d if sett_r < min_week & multi_tag == 0
*drop if end_month == .

gen max_week = 4*duration1
replace end = end_month if sett_r > max_week & multi_tag == 0
*drop if d == .

drop min_week max_week
replace d = . if sett_r == duration1*4 & multi_tag == 0
*drop if d == .

* Finally, the rest of obs are those abs(duration1 - duration2) == 1. The way I deal with this is that choose end_month if sett_r < max_week
replace d = . if sett_r < max_week & multi_tag == 0
*drop if d == .





****** Next, I deal with multi_tag == 1
use cleandata\contr_clean, clear
duplicates tag cod_pgr anno matr_az, gen(multi_tag)
keep if multi_tag == 1

* deal with interrupted cases
do dofiles\seasonal
forvalues i = 2/12 {
    gen mid_end = `i' if S_`i' == 1 & S_`i-1' == 0
}
/* don't need to worry about
bys cod_pgr anno: gen dd = start_month - end_month[_n-1]
bys cod_pgr anno: replace dd = dd[_n+1] if dd == .
drop if dd >= 0 */

** combine the cases 
forvalues i = 1/12 {
    bys cod_pgr anno: gen total_working`i' = E_`i' + E_`i'[_n-1]
	bys cod_pgr anno: replace total_working`i' = total_working`i'[_n+1] if total_working`i' == .
}
bys cod_pgr anno: gen total_hours = sett_r + sett_r[_n-1]
bys cod_pgr anno: replace total_hours = total_hours[_n+1] if total_hours == .

drop if total_hours == 52 & total_working1 == 1 & total_working2 == 1 & total_working3 == 1 & total_working4 == 1 & total_working5 == 1 & total_working6 == 1 & total_working7 == 1 & total_working8 == 1 & total_working9 == 1 & total_working10 == 1 & total_working11 == 1 & total_working12 == 1

drop if total_hours == 53 & total_working1 == 1 & total_working2 == 1 & total_working3 == 1 & total_working4 == 1 & total_working5 == 1 & total_working6 == 1 & total_working7 == 1 & total_working8 == 1 & total_working9 == 1 & total_working10 == 1 & total_working11 == 1 & total_working12 == 1

gen total = total_working1
forvalues i = 2/12 {
    replace total = total_working`i' if total_working`i' > total_working`i-1'
}



*** generate a new end variable representing
gen end = d
replace end = d-1 if substr(d_cess, 1,2) == "01" 
gen diff = end - end_month 
bys cod_pgr anno matr_az: egen diff_m = max(diff)

*** Some weird cases
replace end = end_month if d > 12
replace end = end_month if diff < 0 & d_cess == "0000" & multi_tag == 0
replace end = end_month if diff == 0 & d_cess != "0000" & multi_tag == 0*/



***** (2): generate working variable of each month within a year
forvalues i=1/12 {
    generate temp_`i'= mod(mesi_r/( 10^(12-`i') ),10)
	generate byte E_`i' = floor(temp_`i')
	drop temp_`i'
	label variable E_`i'  "whether/not employed in month `i' current year"
}

************** (3): combine duplications (same person, same year, same firm)
* Caes 1: There are some obs like "111000" and "111"
* Case 2: There are some obs like "1100011" and "11100"
sort cod_pgr matr_az anno start_month end_month
forvalues i = 1/12 {
	by cod_pgr matr_az anno: egen byte E`i' = sum(E_`i')
} 
sort cod_pgr matr_az anno E1-E12 contrat livello qualif tipo_rap prov_l uff_zon inter 
by cod_pgr matr_az anno E1-E12 contrat livello qualif tipo_rap prov_l uff_zon inter : egen earnings_total = sum(retrib03) if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
by cod_pgr matr_az anno: egen days_total = sum(gior_r)
by cod_pgr matr_az anno: egen weeks_total = sum(sett_r)

duplicates drop cod_pgr matr_az anno E1-E12 contrat livello qualif tipo_rap prov_l uff_zon inter if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1


duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 0
replace end_month = 11 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 2 if E1 == 0 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1


duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 0 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 0 & E12 == 0
replace end_month = 10 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 0 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 0 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 3 if E1 == 0 & E2 == 0 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 0 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1


duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 0 & E11 == 0 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 0 & E11 == 0 & E12 == 0
replace end_month = 9 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 0 & E11 == 0 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 4 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1


duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0
replace end_month = 8 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 5 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1


duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0
replace end_month = 7 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 1 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 6 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 1 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1


duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0
replace end_month = 6 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 1 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 7 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 1 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1



duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0
replace end_month = 5 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 8 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 1 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1



duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 1 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0
replace end_month = 4 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 1 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 9 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 1 & E10 == 1 & E11 == 1 & E12 == 1



duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0
replace end_month = 3 if E1 == 1 & E2 == 1 & E3 == 1 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 1 & E11 == 1 & E12 == 1, force
replace start_month = 10 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 1 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 1 & E11 == 1 & E12 == 1



duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 1 & E2 == 1 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0, force
replace start_month = 1 if E1 == 1 & E2 == 1 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0
replace end_month = 2 if E1 == 1 & E2 == 1 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 0 & E12 == 0

duplicates drop cod_pgr matr_az anno E1-E12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 0 & E10 == 0 & E11 == 1 & E12 == 1, force
replace start_month = 11 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 1 & E10 == 0 & E11 == 1 & E12 == 1
replace end_month = 12 if E1 == 0 & E2 == 0 & E3 == 0 & E4 == 0 & E5 == 0 & E6 == 0 & E7 == 0 & E8 == 0 & E9 == 1 & E10 == 0 & E11 == 1 & E12 == 1







************** (4): drop duplications
** These records are duplications. I keep the obs with higher paid week. 
by cod_pgr anno matr_az start_month end_month, sort: ge N=_N 
tab N /* Only 1920 out of 45983648 obs have duplications*/
by cod_pgr anno matr_az start_month end_month, gen n=_n
bys cod_pgr anno matr_az start_month end_month: gen week_diff = mesi_r - mesi_r[_n+1]
drop if week_diff <= 0
bys cod_pgr anno matr_az start_month end_month: gen week_diff2 = mesi_r - mesi_r[_n-1]
drop if n==2
drop if week_diff2 <= 0
drop week_diff week_diff2 N n 
* make sure there is one obs for each job spell 
bys cod_pgr anno matr_az start_month end_month: assert _N == 1

* drop some unreliable variable
drop contrat livello 

compress

save cleandata\contr_clean, replace 







/************** (3): drop some weird cases (not complete)
bys cod_pgr anno matr_az: gen spell = _n
order spell, after(end_month)
bys cod_pgr anno matr_az: gen total_spell = _N 
order total_spell, after(end_month)
tab total_spell /* around 91.5% of them have 1 spells, around 7.8% of them have 2 spells, and 6% of them have 3 spells;
the max number is 21, which means that there are repeated spells*/
/* we mainly focus on the cases with more than 1 spell*/
sort cod_pgr anno matr_az start_month 
gen start_rep = 0
bys cod_pgr anno matr_az: replace start_rep = 1 if start_month < end_month[_n-1]
bys cod_pgr anno matr_az: replace start_rep = 0 if spell == 1 /* 133,803/3,870,889 = 3.45% have repeats*/
order start_rep, after(total_spell)

/* Browsing the data, for those obs with start_rep == 1, most of the cases are, for example, "1100011" and "11100". We deal with them first.*/

/*Among "1100011" and "11100":
Case 1: we don't need to worry about the workers who change qualif. (accounts for around 35%) */
bys cod_pgr anno matr_az: gen qq_diff = (qualif == qualif[_n-1])
order qq_diff, after(qualif)

/*Case 2: contitonal on everything else equal, we combine them if the total number of week worked is 52. (accounts for around 35%) */
bys cod_pgr anno matr_az:if qualif == qualif[_n-1] */






log close
