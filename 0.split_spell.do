use "$rawdata\contr.dta", replace

* gior_r has a lot of zeros when sett_r is not zero. also drop d_cess because it is weird
drop d_cess  gior_r

* from Xinyi's code 
* drop some unreliable variable
drop contrat livello


/* change type to string */
tostring mesi_r, generate(month) force format(%14.0g)   
/* reformat month so that length is 12 */
replace month = "0"*(12-strlen(month)) + month if strlen(month) < 12  

/* haszero is 1 if current spell has break between employments
find spells that includes  101, 1001, 10001, .... */
gen haszero = regexm(month,"([0-9]*)(10+1)([0-9]*)")  

/* how many spells of an worker have break in the middle */
by cod_pgr: egen totalhaszero = total(haszero)  
order haszero totalhaszero, after (month)
qui sum totalhaszero 
global numzero `r(max)'
display $numzero

gen str12 c1 = ""
gen str12 c2 = ""
order c1 c2, after (month)
global iter = 1
gen byte is_split_spell = 0
label variable is_split_spell "split from a spell that contains break"

* generate variables
gen byte months_total = .
label variable months_total "months worked"
gen earn_avg_month = .
label variable earn_avg_month "average monthly earning"
gen earn_avg_week = .
label variable earn_avg_week "average weekly earning"
gen earnings = .
label variable earnings "earnings (split spell)"
gen months_total_temp = .	
forvalues i=1/12 {
	generate byte E_`i' = .
	label variable E_`i'  "whether/not employed in month `i' current year"
	gen temp_`i' = .	
	gen byte temp_E_`i' = .
}

order earnings earn_avg_month earn_avg_week is_split_spell, after (matr_az)

while $numzero > 0 {
	
	* 1 if it is a split spell
	replace is_split_spell = 1 if haszero
	
	* get the chunk before break, and replace the following months with 0
	replace c1 = regexs(1)+"1" if regexm(month,"([0-9]*)(10+1)([0-9]*)")  
	replace c1 = c1 + (12-strlen(c1))*"0" if strlen(c1) < 12 & haszero
	
	* get the chunk after break, and replace the previous months with 0
	replace c2 = "1"+regexs(3) if regexm(month,"([0-9]*)(10+1)([0-9]*)")
	replace c2 = "0"*(12-strlen(c2)) + c2 if strlen(c2) < 12 & haszero

	* duplicate observation if spell has break
	expand 2 if haszero, gen(dupindicator)
	sort cod_pgr anno
	
	* destring into numeric
	destring c1, gen (c1_n)
	destring c2, gen (c2_n)
	destring month, gen(month_n)
	
	* monthly employment for a spell that includes break
	forvalues i=1/12 {
		replace temp_`i'= mod(month_n/( 10^(12-`i') ),10) if haszero
		replace temp_E_`i' = floor(temp_`i') if haszero		
	}
	* monthly employment for the first chunk before break
	forvalues i=1/12 {
		replace temp_`i'= mod(c1_n/( 10^(12-`i') ),10) if dupindicator == 0 & haszero
		replace E_`i' = floor(temp_`i') if dupindicator == 0 & haszero		
	}
	* monthly employment for the second chunk after break
	forvalues i=1/12 {
		replace temp_`i'= mod(c2_n/( 10^(12-`i') ),10) if dupindicator & haszero
		replace E_`i' = floor(temp_`i') if dupindicator & haszero		
	}
	
	* total months worked for a spell that includes break
	replace months_total = E_1 + E_2 + E_3 + E_4 + E_5 + E_6 + E_7 + E_8 + E_9 + E_10 + E_11 + E_12 if haszero 
	* total months worked for first and second chunks
	replace months_total_temp = temp_E_1 + temp_E_2 + temp_E_3 + temp_E_4 + temp_E_5 + temp_E_6 + temp_E_7 + temp_E_8 + temp_E_9 + temp_E_10 + temp_E_11 + temp_E_12 if haszero 
	
	* average monthly earnings for the first and second chunk are the same (only calculated in first iteration)
	replace earn_avg_month = retrib03/months_total_temp if haszero & earnings == .
	* average weekly earnings are the same for the first employment chunk and the second one (only calculated in first iteration)
	replace earn_avg_week = retrib03/sett_r if haszero & earnings == .
	
	* total earnings of the spell is divided proportionally among first and second chunks based on number of months worked
	replace earnings = earn_avg_month*months_total if haszero
	
	* split a spell with break into two
	replace month = c1 if dupindicator == 0 & haszero
	replace month = c2 if dupindicator & haszero
	
	* find spells with break between employments
	replace haszero = regexm(month,"([0-9]*)(10+1)([0-9]*)") 
	drop totalhaszero
	by cod_pgr: egen totalhaszero = total(haszero)
	order totalhaszero, after (haszero)
	qui sum totalhaszero 
	global numzero `r(max)'
	display $numzero
	
	drop dupindicator
	drop c1_n c2_n month_n
	display "iteration: " + $iter
	global iter $iter + 1
	
}

* monthly employment for spells that do not need to be split
forvalues i=1/12 {
		replace temp_`i'= mod(mesi_r/( 10^(12-`i') ),10) if is_split_spell == 0
		replace E_`i' = floor(temp_`i') if is_split_spell == 0
}
* total months worked for spells that do not need to be split
replace months_total = E_1 + E_2 + E_3 + E_4 + E_5 + E_6 + E_7 + E_8 + E_9 + E_10 + E_11 + E_12 if is_split_spell == 0
* average earnings for spells that do not need to be split
replace earn_avg_month = retrib03/months_total if is_split_spell == 0
replace earn_avg_week = retrib03/sett_r if is_split_spell == 0

replace earnings = retrib03 if is_split_spell == 0

drop temp_* months_total_temp
drop c1 c2 haszero totalhaszero 

* start_month: the position where 1 first appears in month
gen byte start_month = strpos(month, "1")
* end_month: the position where 1 last appears in month
gen byte end_month = strrpos(month, "1")

* change type to real
destring month, gen (month_n)


order start_month end_month earnings earn_avg_month earn_avg_week is_split_spell, after (matr_az)
order mesi_r retrib03 sett_u, last
compress

save "$cleandata\contr_clean.dta", replace



