/*This do file deals with same workers at same firm in same year with multiple obs.
I provide two methods. */

clear
set mem 2g
set more off
use "$cleandata\contr_clean", clear

*** First, check how many workers have duplicates cod_pgr anno matr_za
duplicates tag cod_pgr anno matr_az, gen(multi_tag)
sum multi_tag /* About 9.2% obs are duplicates*/
unique cod_pgr if multi_tag > 0 


************ Methods 1: Coarse cleaning
/* The main logic is that we sum up the total numbe of working weeks of a worker within same firm in same year. If the total number is large than 53, we drop this person.*/
bys cod_pgr anno matr_az: egen total_weeks = sum(sett_r)
drop if total_weeks > 53 /*48698 deleted*/
drop total_weeks
sort cod_pgr anno matr_az


***** Detect seasonal workers
gen S = 1 if strpos(qualif, "S")> 0
replace S = 0 if S == .
bys cod_pgr: egen seasonal = max(S) 
drop if seasonal == 1

save cleandata\clean_data, replace



*** Only use 1984 and after
keep if anno >= 1984
save cleandata\clean_data_1984, replace



***** Drop seasonal workers
drop if S == 1
save "$cleandata\clean_data_1984_S", replace
drop if seasonal == 1
save "$cleandata\clean_data_1984_Seasonal", replace
