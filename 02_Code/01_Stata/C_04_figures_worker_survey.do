/*******************************************************************************
@Name: figures_worker_survey.do

@Author: Marco Medina

@Date: 03/01/2023

@In: - worker_survey.dta
	 
@Out: 
*******************************************************************************/

********************
version 17.0
clear all
cd "$directory"
********************

use "01_Data/03_Working/worker_survey.dta", clear


******************
* Wage subreport *
******************

twoway (histogram perc_wage_reported if perc_wage_reported <= 1.1, width(0.1) start(0) color("0 69 134 %50")) ///        
       (histogram perc_wage_exact if perc_wage_exact <= 1.1, width(0.1) start(0) color("255 211 32 %50") ///
       legend(order(1 "Wage perc. believed to be reported at IMSS" 2 "Wage perc. reported at IMSS" ) cols(1)) graphregion(color(white)))

graph export "04_Figures/worker_survey/hist_perc_sal_survey.pdf", replace
