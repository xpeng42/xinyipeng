/* This do file is to identify seasonal workers */


clear
set mem 2g
set more off
cd "C:\Users\leejo\Dropbox\Joohyun\Research\Recall\data"
use cleandata\contr_clean, clear

log using seasonal, replace

***** (1): generate working variable of each month within a year
gen length = strlen(month)
forvalues i = 1/12 {
	gen E_`i' = 1 if substr(month,`i',1) == "1" & length == 12
	replace E_`i' = 0 if substr(month,`i',1) == "0" & length == 12
	replace E_`i' = 0 if `i' < 13 - length & length < 12
	replace E_`i' = 1 if `i' >= 13 - length & substr(month,`i'-(12-length),1) == "1" & length < 12
	replace E_`i' = 0 if `i' >= 13 - length & substr(month,`i'-(12-length),1) == "0" & length < 12
} 
drop length

***** (2): generate separation (EU) month within a year (missing the 12th-month)
sort cod_pgr anno matr_az 
forvalues i = 1/11 {
	local j = `i'+1
	gen S_`i' = 0
	replace S_`i' = 1 if E_`i' == 1 & E_`j' == 0 
}


save cleandata\final_s, replace


end log
