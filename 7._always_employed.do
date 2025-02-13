* this file generates figure 4 (wage path for always employed workers) for workers leaving each month, starting from 1986 Jan to 1998 Dec
* current version: checks leaving on Dec, for year 86-98

clear
global figure "D:\Dropbox\Recall\figures\workers"

/* restrict sample and generate four groups */
forvalues yy = 1986(1)1998{
	forvalues mm = 12(1)12{
		use cleandata\final_genvariables, replace 
		gen end_yearmm = .
		replace end_yearmm = end_month + anno*100 if end_spell==1
		
		
		di `yy'
		di `mm'
		local yymm = `yy'*100 + `mm'
		di `yymm'

		/*only keep three years*/
		keep if anno>=`yy' & anno<=`yy' + 2

		/*only consider people that worked at least 50 weeks at their job in 1986*/
		gen keep_0 = (sett_r>=50)*(anno==`yy')
		bys cod_pgr: egen keep = max(keep_0)
		keep if keep==1

		/*leavers: workers that leave at XX[1991 Dec]*/
		gen leaver_0 = (end_spell==1)*(end_month==`mm')*(anno==`yy')
		bys cod_pgr: egen leaver = max(leaver_0) 

		/*firm that leavers leave*/
		gen leaver_firm0 = 0
		replace leaver_firm0 = matr_az if (end_spell==1)&(end_month==`mm')&(anno==`yy')
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
		replace end_spellbf0 = 1 if end_yearmm <`yymm' & end_spell==1
		bys cod_pgr: egen end_spellbf = total(end_spellbf)
		drop if end_spellbf>=1

		/*non-leavers stay in same firm entire period*/
		gen end_spellaf0 = 0
		replace end_spellaf0 = 1 if end_yearmm > `yymm' & end_spell==1 & leaver==0
		bys cod_pgr: egen end_spellaf = total(end_spellaf0)
		drop if end_spellaf >= 1 

		/******************************************************/

		/*return to other firms?*/
		bys cod_pgr: egen return_ttl = total(return)
		count if return_ttl>=1 & leaver ==0 
		count if return_ttl>=1 & returner==0 & leaver ==1 
		*drop if return_ttl>0 & returner==0

		/********worker types: ************/
		gen stayer = (leaver==0) 
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
		gen temp = 1 if return_a & anno == `yy'+1 
 		bys cod_pgr: egen byte return_bf_m25 = max(temp)
		drop temp
		replace return_bf_m25 = 0 if return_bf_m25 == .
		
		/* qualif_diff for the three year window only
		defined for all workers if qualif changed from previous employment*/
		drop qualif_diff 
		sort cod_pgr matr_az anno start_month
		gen byte qualif_diff = 0
		by cod_pgr matr_az: replace qualif_diff = 1 if (qualif_new != qualif_new[n-1]) & (qualif_new[n-1] != .) 
		
		compress
		save cleandata\final_fourgroups_`yymm', replace 	
		
	}
}


/* generate monthly income and long data*/
forvalues yy = 1986(1)1998{
	forvalues mm = 12(1)12{
		di `yy'
		di `mm'
		local yymm = `yy'*100 + `mm'
		di `yymm'

		use cleandata\final_fourgroups_`yymm', replace
		sum return_in if return_wo==1
		sum return_in if return_we==1

		* generate avg monthly wage
		forvalues i=1/36 {
			generate earn_mth0_`i' = retrib03_month_new * (anno == `yy' + trunc((`i'-0.5)/12))* ((mod(`i', 12))<= end_month) * ((mod(`i', 12))>= start_month)
			replace earn_mth0_`i' = retrib03_month_new * (anno == `yy' + trunc((`i'-0.5)/12)) if (mod(`i', 12)==0)&(end_month==12)
			by cod_pgr : egen earn_mth`i' = max(earn_mth0_`i')
		}

		sort cod_pgr
		quietly by cod_pgr:  gen dup = cond(_N==1,0,_n)
		drop if dup>1
		drop dup
		keep cod_pgr stayer return_we return_wo leave_fg return_bf_m25 qualif_new qualif_diff ///
				earn_mth1 earn_mth2 earn_mth3 earn_mth4 earn_mth5 earn_mth6 earn_mth7 earn_mth8 earn_mth9 earn_mth10 ///
				earn_mth11 earn_mth12 earn_mth13 earn_mth14 earn_mth15 earn_mth16 earn_mth17 earn_mth18 earn_mth19 earn_mth20 ///
				earn_mth21 earn_mth22 earn_mth23 earn_mth24 earn_mth25 earn_mth26 earn_mth27 earn_mth28 earn_mth29 earn_mth30 ///
				earn_mth31 earn_mth32 earn_mth33 earn_mth34 earn_mth35 earn_mth36 /*earn_mth37 earn_mth38 earn_mth39 earn_mth40 ///
				earn_mth41 earn_mth42 earn_mth43 earn_mth44 earn_mth45 earn_mth46 earn_mth47 earn_mth48*/

		reshape long earn_mth, i(cod_pgr stayer return_we return_wo leave_fg) j(mth)

		save cleandata\final_long_`yymm', replace 		
		
	}
}


/* generate graphs */
forvalues yy = 1986(1)1998{
	forvalues mm = 12(1)12{

		di `yy'
		di `mm'
		local yymm = `yy'*100 + `mm'
		di `yymm'

		*****************************************************************************************************
		use cleandata\final_long_`yymm', replace	
		*************************************************************************
		******drop people who were unemployed (earned zero) for some period *****
		compress

		gen byte earn_zero = earn_mth == 0
		bys cod_pgr: egen int total_zero = total(earn_zero) /*sum of months with zero earning*/
		tab return_wo
		egen x = group(cod_pgr)
		qui summ x
		global numworker `r(max)'
		drop x
		drop if total_zero > 0 /* remove workers who had any month of zero earning */

		{/* save the number of workers per each type */
		egen x = group(cod_pgr) if stayer
		qui summ x
		global numstayer `r(max)'
		drop x
		egen x = group(cod_pgr) if leave_fg
		qui summ x
		global numleaver `r(max)'
		drop x
		egen x = group(cod_pgr) if return_we
		qui summ x
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
			
		graph export "$figure\trends_overtime_drop_unemp_`yymm'.png", replace	
		
		
		******** qualif **************
		use cleandata\final_long_`yymm', replace	
		gen byte earn_zero = earn_mth == 0
		bys cod_pgr: egen int total_zero = total(earn_zero) /*sum of months with zero earning*/
		tab return_wo
		egen x = group(cod_pgr)
		summ x
		global numworker `r(max)'
		drop x
		drop if total_zero > 0 /* remove workers who had any month of zero earning */
		
		capture log close
		log using "D:\recall\log_`yymm'.smcl", replace
		
		tab qualif_new qualif_diff if stayer
		tab qualif_new qualif_diff if return_we
		tab qualif_new qualif_diff if leave_fg
		
		log close
		
		keep qualif_new stayer return_we return_wo leave_fg mth
		collapse (mean) qualif_new, by(stayer return_we return_wo leave_fg mth)

		replace stayer = qualif_new if stayer==1 
		replace return_we = qualif_new if return_we==1 
		replace return_wo = qualif_new if return_wo==1 
		replace leave_fg = qualif_new if leave_fg==1 
		drop qualif_new
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
			
		graph export "$figure\trends_overtime_drop_unemp_`yymm'_qualif.png", replace	
		
	}
}



/* tests


forvalues yy = 1986(1)1986{
	forvalues mm = 12(1)12{
		di `yy'
		di `mm'
		local yymm = `yy'*100 + `mm'
		di `yymm'

		use cleandata\final_fourgroups_`yymm', replace
		sum return_in if return_wo==1
		sum return_in if return_we==1

		* generate avg monthly wage
		forvalues i=1/36 {
			generate earn_mth0_`i' = retrib03_month_new * (anno == `yy' + trunc((`i'-0.5)/12))* ((mod(`i', 12))<= end_month) * ((mod(`i', 12))>= start_month)
			replace earn_mth0_`i' = retrib03_month_new * (anno == `yy' + trunc((`i'-0.5)/12)) if (mod(`i', 12)==0)&(end_month==12)
			by cod_pgr : egen earn_mth`i' = max(earn_mth0_`i')
		}

		sort cod_pgr
		quietly by cod_pgr:  gen dup = cond(_N==1,0,_n)
		drop if dup>1
		drop dup
		keep cod_pgr stayer return_we return_wo leave_fg return_bf_m25 qualif_new qualif_diff ///
				earn_mth1 earn_mth2 earn_mth3 earn_mth4 earn_mth5 earn_mth6 earn_mth7 earn_mth8 earn_mth9 earn_mth10 ///
				earn_mth11 earn_mth12 earn_mth13 earn_mth14 earn_mth15 earn_mth16 earn_mth17 earn_mth18 earn_mth19 earn_mth20 ///
				earn_mth21 earn_mth22 earn_mth23 earn_mth24 earn_mth25 earn_mth26 earn_mth27 earn_mth28 earn_mth29 earn_mth30 ///
				earn_mth31 earn_mth32 earn_mth33 earn_mth34 earn_mth35 earn_mth36 /*earn_mth37 earn_mth38 earn_mth39 earn_mth40 ///
				earn_mth41 earn_mth42 earn_mth43 earn_mth44 earn_mth45 earn_mth46 earn_mth47 earn_mth48*/

		reshape long earn_mth, i(cod_pgr stayer return_we return_wo leave_fg) j(mth)

		save cleandata\final_long_`yymm', replace 		
	}
}

forvalues yy = 1986(1)1986{
	forvalues mm = 12(1)12{
		di `yy'
		di `mm'
		local yymm = `yy'*100 + `mm'
		di `yymm'

		local yy = 1986
		local mm = 12
		local yymm = `yy'*100 + `mm'
		

		*****************************************************************************************************
		use cleandata\final_long_`yymm', replace	
		*************************************************************************
		******drop people who were unemployed (earned zero) for some period *****
		compress

		gen byte earn_zero = earn_mth == 0
		bys cod_pgr: egen int total_zero = total(earn_zero) /*sum of months with zero earning*/
		tab return_wo
		egen x = group(cod_pgr)
		qui summ x
		global numworker `r(max)'
		drop x
		drop if total_zero > 0 /* remove workers who had any month of zero earning */

		{/* save the number of workers per each type */
		egen x = group(cod_pgr) if stayer
		qui summ x
		global numstayer `r(max)'
		drop x
		egen x = group(cod_pgr) if leave_fg
		qui summ x
		global numleaver `r(max)'
		drop x
		egen x = group(cod_pgr) if return_we
		qui summ x
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
			
		graph export "trends_overtime_drop_unemp_`yymm'.png", replace
		graph export "$figure\trends_overtime_drop_unemp_`yymm'.png", replace	
		
		
		******** qualif **************
		use cleandata\final_long_`yymm', replace	
		gen byte earn_zero = earn_mth == 0
		bys cod_pgr: egen int total_zero = total(earn_zero) /*sum of months with zero earning*/
		tab return_wo
		egen x = group(cod_pgr)
		summ x
		global numworker `r(max)'
		drop x
		drop if total_zero > 0 /* remove workers who had any month of zero earning */
		
		capture log close
		log using "D:\recall\log_`yymm'.smcl", replace
		
		tab qualif_new qualif_diff if stayer
		tab qualif_new qualif_diff if return_we
		tab qualif_new qualif_diff if leave_fg
		
		log close
		
		keep qualif_new stayer return_we return_wo leave_fg mth
		collapse (mean) qualif_new, by(stayer return_we return_wo leave_fg mth)

		replace stayer = qualif_new if stayer==1 
		replace return_we = qualif_new if return_we==1 
		replace return_wo = qualif_new if return_wo==1 
		replace leave_fg = qualif_new if leave_fg==1 
		drop qualif_new
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
			
		graph export "trends_overtime_drop_unemp_`yymm'_qualif.png", replace
		graph export "$figure\trends_overtime_drop_unemp_`yymm'_qualif.png", replace	
	}
}

forvalues yy = 1986(1)1986{
	forvalues mm = 12(1)12{
		di `yy'
		di `mm'
		local yymm = `yy'*100 + `mm'
		di `yymm'

		/*only keep three years*/
		keep if anno>=`yy' & anno<=`yy' + 2

		/*only consider people that worked at least 50 weeks at their job in 1986*/
		gen keep_0 = (sett_r>=50)*(anno==`yy')
		bys cod_pgr: egen keep = max(keep_0)
		keep if keep==1

		/*leavers: workers that leave at XX[1991 Dec]*/
		gen leaver_0 = (end_spell==1)*(end_month==`mm')*(anno==`yy')
		bys cod_pgr: egen leaver = max(leaver_0) 

		/*firm that leavers leave*/
		gen leaver_firm0 = 0
		replace leaver_firm0 = matr_az if (end_spell==1)&(end_month==`mm')&(anno==`yy')
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
		replace end_spellbf0 = 1 if end_yearmm <`yymm' & end_spell==1
		bys cod_pgr: egen end_spellbf = total(end_spellbf)
		drop if end_spellbf>=1

		/*non-leavers stay in same firm entire period*/
		gen end_spellaf0 = 0
		replace end_spellaf0 = 1 if end_yearmm > `yymm' & end_spell==1 & leaver==0
		bys cod_pgr: egen end_spellaf = total(end_spellaf0)
		drop if end_spellaf >= 1 

		/******************************************************/

		/*return to other firms?*/
		bys cod_pgr: egen return_ttl = total(return)
		count if return_ttl>=1 & leaver ==0 
		count if return_ttl>=1 & returner==0 & leaver ==1 
		*drop if return_ttl>0 & returner==0

		/********worker types: ************/
		gen stayer = (leaver==0) 
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
		gen temp = 1 if return_a & anno == `yy'+1 
 		bys cod_pgr: egen byte return_bf_m25 = max(temp)
		drop temp
		replace return_bf_m25 = 0 if return_bf_m25 == .
		
		/* qualif_diff for the three year window only
		defined for all workers if qualif changed from previous employment*/
		drop qualif_diff 
		sort cod_pgr matr_az anno start_month
		gen byte qualif_diff = 0
		by cod_pgr matr_az: replace qualif_diff = 1 if (qualif_new != qualif_new[n-1]) 
		
		compress
		save cleandata\final_fourgroups_`yymm', replace 		
	}
}



*/
