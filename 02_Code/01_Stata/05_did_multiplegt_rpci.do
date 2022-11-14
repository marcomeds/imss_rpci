/*******************************************************************************
@Name: did_multiplegt_rpci.do

@Author: Marco Medina

@Date: 02/03/2022

@In: panel_rpci.dta
	 
@Out: 
*******************************************************************************/


********************
version 17.0
clear all
cd "$directory"
********************

* Use panel_rpci.dta
use "01_Data/03_Working/panel_rpci.dta", clear

* Note: did_multiplegt takes a lot of time to run. If the treatment is binary
* and staggered, we can define a variable "cohort", that is the period in which
* each treatment group switched to treatment, and zero for all individuals which
* have never been treated. When running did_multiplegt, our "cohort" will be the
* group variable instead of the individual id.


******************
* did_multiplegt *
******************

* Define variables
local vars  sal_cierre log_sal_cierre alta alta_cierre baja_cierre baja_permanente ///
			cambio_cierre sal_diff cambio_sal_mayor cambio_sal_menor cambio_sal_igual
			
foreach depvar in `vars' {
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin.pdf", replace
}

/*
	did_multiplegt sal_cierre download_monthly periodo_monthly rpci_vig, robust_dynamic dynamic(18) placebo(24) breps(20) cluster(idnss) seed(541314)
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Meses desde la descarga del RPCI") ytitle("Efecto causal promedio") ///
		title("Efecto del RPCI en el salario") xlabel(-24(2)18)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/event_study_sal_cierre_chaisemartin.pdf", replace
*/
