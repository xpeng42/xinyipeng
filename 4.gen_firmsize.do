clear
cd "C:\Users\jaepi\Dropbox\Joohyun\Research\Recall\data"
use cleandata\final, replace
*log using firmsize.smcl, replace
keep if anno>=1984
drop com_n prov_n naz com_r tipo_rap rag_soc indirizzo att_econ cod_fis part_iva ateco91
compress // to save space
save cleandata\final_sampv, replace

* fix? firm_size underestimated if the firm is not in VE, as not all employees are tracked

* generate employment dummy variable for each month
forvalues i=1/12 {
    generate temp_`i'= mod(mesi_r/( 10^(12-`i') ),10)
	generate emp_`i' = floor(temp_`i')
	drop temp_`i'
	label variable emp_`i'  "whether/not employed in month `i' current year"
}

* add number of employees for each month, per firm corresponding year	
forvalues j=1/12 {
	bysort matr_az anno: egen int firm_size_`j' = sum(emp_`j')
	label variable firm_size_`j'  "number of employees in month `j' current year"
}
drop emp_*

* compute average number of employees across months
egen firm_size_y = rmean(firm_size_1 - firm_size_12)
label variable firm_size_y  "average number of employees current year"
egen firm_size_q1 = rmean(firm_size_1 firm_size_2 firm_size_3)
label variable firm_size_q1  "average number of employees first quarter current year"
egen firm_size_q2 = rmean(firm_size_4 firm_size_5 firm_size_6)
label variable firm_size_q2  "average number of employees second quarter current year"
egen firm_size_q3 = rmean(firm_size_7 firm_size_8 firm_size_9)
label variable firm_size_q3  "average number of employees third quarter current year"
egen firm_size_q4 = rmean(firm_size_10 firm_size_11 firm_size_12)
label variable firm_size_q4  "average number of employees fourth quarter current year"

compress // to save space

* compare with dip_in, dip_out

*log close
save cleandata\final_firmsz, replace

duplicates drop matr_az anno,force
* mean: 5.22; median: 1; 75 percentile: 3; 90 percentile: 8.6
sum firm_size_y , detail 



************ check firms with really big sizes *********
/* matr_az == 5100516567: the largest firm
NAME: S.P.A.      NAZIONALE PER L'ENERGIA ELETTRICA ENEL 
Private electricity and gas manufacturer and distributor (multinational)
DATA_IN: 197501
DATA_CESS: 19980101 (when it was privatized? In 1999-2001, there are very few workers)
DATA_OUT: 200112
LOCATION: Napoli, CAMPANIA
95 percent of workers who worked at this firm has not worked in Veneto area. Why are those workers followed??

SPLITED(?) IN 1999 INTO matr_az == 7041278119 (S.P.A.      ENEL DISTRIBUZIONE) 

To check some workers, run the following code:
sort cod_pgr anno
list cod_pgr anno matr_az region_id prov_id if cod_pgr == 14444996
list cod_pgr anno matr_az region_id prov_id if cod_pgr == 44769808
list cod_pgr anno matr_az region_id prov_id if cod_pgr == 63052741          
*/ 
  
/* matr_az == 5407920245: the second largest firm?
NAME: ISTITUTO BANCA ANTONIANA POPOLARE VENETA
Bank
DATA_IN: 199601 (merger of two banks Banca Antoniana and Banca Popolare Veneta)
DATA_CESS: 0
DATA_OUT: 200112
LOCATION: Padua, VENETO

To check some workers, run the following code:
sort cod_pgr anno
list cod_pgr anno matr_az region_id prov_id if cod_pgr == 53424566
list cod_pgr anno matr_az region_id prov_id if cod_pgr == 60607470 
*/  


