* date Jan 24, 2022
* this file makes sample restrictions

clear
cd "C:\Users\jaepi\Dropbox\Joohyun\Research\Recall\data"
use cleandata\final_genvariables0, replace 
keep if qualif_seasonal_max==0 & rep_return==0 & overlap_total<=2 & overlap_maxm<7


replace retrib03_week = retrib03_week_new
/* we can either use the following and drop all workers with such kind of observation
replace retrib03_week = . if retrib03_week != retrib03_week_new */


*keep if rep_return==0 & qualif_seasonal_max==0 /* about 80 percent of entire sample*/
*keep if anno >=1989

save cleandata\final_genvariables, replace 


/* 1. EXCLUDING REPEAT REHIRES AND SEASONAL WORKERS

THEY SHOULD BE EXCLUDED BECAUSE THEIR REHIRES ARE VERY DIFFERENT FROM THE STORY WE ARE INTERESTED IN
THEY HAVE VERY HIGH RETURN RATES BUT IT IS NOT OF OUR INTEREST

. sum return worked_else retrib03_week if rep_return==0 & qualif_seasonal_max==0

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      return | 28,177,689     .025239    .1568504          0          1
 worked_else | 28,177,689    .0071866    .0844687          0          1
retrib03_w~k | 28,094,797    733.3483    2747.107          0    8686908

. sum return worked_else retrib03_week if qualif_seasonal_max==1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      return |  1,150,401    .2526024     .434505          0          1
 worked_else |  1,150,401     .074295    .2622504          0          1
retrib03_w~k |  1,102,325    614.7096    3079.808          0   836581.3

. sum return worked_else retrib03_week if rep_return==1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      return |  4,345,627    .2762547    .4471444          0          1
 worked_else |  4,345,627    .0777582    .2677907          0          1
retrib03_w~k |  4,180,049    674.8046     4125.39          0    3027859


  2. EXCLUDING WORKERS WITH OVERLAPPING SPELLS
  
ABOUT 1 PERCENT OF OVSERVATIONS INVOLVE OVERLAPPING SPELLS. THE OVERLAP IS BETWEEN 1-12 MONTHS
. sum overlap overlap_month

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
     overlap | 32,991,819    .0109472    .1040544          0          1
overlap_mo~h |    361,167    3.944369    3.787794          0         12
  
VIEW HIST OVERLAP AND HIST OVERLAP_MONTH TO SEE THE DISTRIBUTION OF THESE OVERLAPS.

OVERLAP_MAXM IS THE MAXIMUM MONTHS OF OVERLAPPING SPELLS A WORKER HAS IN HIS WORKING HISTORY.

*/
