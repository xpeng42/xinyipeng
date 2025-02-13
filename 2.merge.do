/* This do file merge 3 datasets */


clear
set mem 2g
set more off
cd "C:\Users\jaepi\Dropbox\Joohyun\Research\Recall\data"
use cleandata\contr_clean, clear

log using merge, replace

***************(1): merge with aizen
merge m:1 matr_az using rawdata\azien
keep if _merge == 3
drop _merge


***************(2): merge with anagr
merge m:1 cod_pgr using rawdata\anagr
merge m:1 cod_pgr using rawdata\anagr
keep if _merge == 3
drop _merge

save cleandata\final, replace


log close
