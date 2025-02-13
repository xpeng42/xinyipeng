clear
cd "C:\Users\leejo\Dropbox\Joohyun\Research\Recall\data"
global overleaf "C:\Users\leejo\Dropbox\Apps\Overleaf\Recall_proposal"
use cleandata\final_genvariables, clear

************ (1) a. some summary statistics
/* Making summary statistics for return workers vs non-return workers*/
label var worked_else "Worked Elsewhere"
label var return_in    "Gap in Months"
label var return_total "Total Returns"
label var retrib03_week "Average Weekly Earnings"
label var tenure "Tenure in Weeks"
label var tenuresq "Tenure^2"
label var age "Age"
label var earn_diff_new "Difference in Weekly Earnings"
label var numb_emp "Total # Employers"
label var firm_size_y "Firm Size (Current)"
label var qualif_diff "Difference in Level"

eststo clear
local listvar "age retrib03_week earn_diff_new return_in numb_emp_when_left return_else_firm tenure numb_emp qualif_diff"
estpost tabstat `listvar' if anno == 1988 & return == 1 & worked_else == 1, stat(mean sd) col(stat)
eststo sum1988_r1
estpost tabstat `listvar' if anno == 1988 & return == 1 & worked_else == 0, stat(mean sd) col(stat)
eststo sum1988_r2
estpost tabstat `listvar' if anno == 1988 & return == 0, stat(mean sd) col(stat)
eststo sum1988_n
esttab  sum1988_r1 sum1988_r2 sum1988_n using "$overleaf\tables\sumstat.tex", ///
		mtitles("Worked elsewhere" "Just return" "Not return") ///
	    replace main(mean) aux(sd) label nostar unstack nonote nonumber compress nogaps

************ (1) b. graph of return and worked_else
** ratio of return workers over time
use cleandata\final_genvariables, clear
drop if anno<=1989 | anno>=2001
bys anno: egen ratio_return = mean(return)
bys anno: egen ratio_work_else = mean(worked_else) if return == 1
twoway line ratio_return anno, yaxis(2)   ytitle("Return Percentage") || line ratio_work_else anno, yaxis(1) ///
xtitle("Year") ytitle("Ratio") title("Ratio of Return workers") xlabel(1990 (2) 2000)
graph export "$overleaf\images\over time return rate.png", as(png) replace
/*
************ (1) c. difference in earnings after returning by firm size
twoway (scatter earn_diff firm_size if firm_size<1000 & earn_diff<3000 & earn_diff>-3000 &anno==1995, sort mcolor(%30)),  title(Difference in Earnings by Firm Size in 1995)
graph export "$overleaf\diff_in_earn_by_firmsz.png", as(png) replace

the worked_else and just return workers do not look different in their patters of earnings after returning by firm size
twoway (scatter earn_diff firm_size if firm_size<500 & earn_diff<1000 & earn_diff>-1000 &anno==1995 & worked_else==0 , sort), title(Difference in Earnings by Firm Size in 1995)
twoway (scatter earn_diff firm_size if firm_size<500 & earn_diff<1000 & earn_diff>-1000 &anno==1995 & worked_else==1 , sort), title(Difference in Earnings by Firm Size in 1995)
*/

************ (1) d. summary of repeated return and seasonal workers

sum return worked_else qualif_seasonal rep_return if qualif_seasonal_max==1
sum return worked_else rep_return if qualif_seasonal==1
sum return worked_else rep_return if qualif_seasonal==0

************ (1) e. summary of dual job holders


*********** (2) employment duration of workers before and after returning
twoway (hist spell_length_ttl if return_gap1==1 & anno==1995 & worked_else==1, start(0) width(10) color(red%30)) ///        
       (hist spell_length_ttl if return_gap1==1 & anno==1995 & worked_else==0, start(-2) width(10) color(green%30)), ///   
       legend(order(1 "Worked at Other Firm" 2 "Didn't Work at Other Firm" )) title(Return Workers' Duration of Work After Returning)
graph export "$overleaf\spell_length_postmove.png", as(png) replace

twoway (hist tenure if return_gap1==1 & anno==1995 & worked_else==1, start(0) width(10) color(red%30)) ///        
       (hist tenure if return_gap1==1 & anno==1995 & worked_else==0, start(-2) width(10) color(green%30)), ///   
       legend(order(1 "Worked at Other Firm" 2 "Didn't Work at Other Firm" )) title(Return Workers' Tenure at Firm Before Leaving)
graph export "$overleaf\tenure_pre_move.png", as(png) replace

*********** (3) wage path of workers before and after returning

*********** (4) regression 
replace exp_diff = exp_diff/4.3
replace tenure = tenure/4.3
drop tenuresq 
gen tenuresq = tenure*tenure
eststo clear
eststo reg1: reg log_earn_diff  worked_else exp_diff tenure tenuresq age i.anno c.matr_az if anno>=1984
estadd local firm_FE "Yes"
estadd local year_FE "Yes"
esttab reg1 using "$overleaf\tables\basic_reg.tex", replace ///
	se keep(worked_else exp_diff tenure tenuresq age )label starlevels(* 0.10 ** 0.05 *** 0.01) ///
	s(N firm_FE year_FE qualif_FE , label("N" "Firm FE" "Year FE" )) ///
	mtitle("Log Difference in Weekly Earnings")
	
	
	
