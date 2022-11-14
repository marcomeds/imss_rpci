/*******************************************************************************
@Name: did_multiplegt_heterogeneity_rpci.do

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


**********************************
* did_multiplegt - heterogeneity *
**********************************

* Define variables
local vars sal_cierre log_sal_cierre
			
foreach depvar in `vars' {
	
	*******
	* Men *
	*******
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if sexo == 0, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_sexo_0.pdf", replace
	
	
	
	*********
	* Women *
	*********
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if sexo == 1, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_sexo_1.pdf", replace
	
	
	
	***************
	* Outsourcing *
	***************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_outsourcing == 1, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_outsourcing.pdf", replace
	
	
	
	*******************
	* Eventual Worker *
	*******************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_te == 1, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_eventual.pdf", replace
	
	
	
	****************
	* Ind. Transf. *
	****************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_div_final == 3, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_div_final_3.pdf", replace
	
	
	
	****************
	* Ind. Constr. *
	****************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_div_final == 4, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_div_final_4.pdf", replace
	
	

	************
	* Comercio *
	************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_div_final == 6, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_div_final_6.pdf", replace
	
	
	
	***************
	* Transportes *
	***************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_div_final == 7, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_div_final_7.pdf", replace
	
	
	
	***************
	* Serv. Pers. *
	***************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_div_final == 8, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_div_final_8.pdf", replace
	
	
	
	**************
	* Serv. Soc. *
	**************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_div_final == 9, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_div_final_9.pdf", replace
	
	
	
	********
	* PyME *
	********
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_size_cierre == 1 | size_cierre == 2 | size_cierre == 3 | size_cierre == 4, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_pyme.pdf", replace
	
	
	
	******************
	* Empresa Grande *
	******************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_size_cierre == 7, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_emp_grande.pdf", replace
	
}



**********************************************
* did_multiplegt - heterogeneity - firm size *
**********************************************
			
foreach depvar in `vars' {
	
	****************
	* S1: 1 worker *
	****************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_size_cierre == 1, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_firm_size_1.pdf", replace
	
	
	
	*******************
	* S2: 2-5 workers *
	*******************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_size_cierre == 2, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_firm_size_2.pdf", replace
	
	
	
	********************
	* S3: 6-50 workers *
	********************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_size_cierre == 3, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_firm_size_3.pdf", replace
	
	
	
	**********************
	* S4: 51-250 workers *
	**********************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_size_cierre == 4, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_firm_size_4.pdf", replace
	
	
	
	***********************
	* S5: 251-500 workers *
	***********************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_size_cierre == 5, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_firm_size_5.pdf", replace
	
	
	
	************************
	* S6: 501-1000 workers *
	************************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_size_cierre == 6, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_firm_size_6.pdf", replace
	
	
	
	*********************
	* S7: 1000+ workers *
	*********************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if base_size_cierre == 7, ///
	robust_dynamic dynamic(17) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_firm_size_7.pdf", replace
	
}



***********************************************************
* did_multiplegt - heterogeneity - early vs late adopters *
***********************************************************

* Define variables
local vars sal_cierre
			
foreach depvar in `vars' {
	
	********************************************************
	* Early adopters: first 9 months (before october 2021) *
	********************************************************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if download_monthly == 0 | download_monthly <= tm(2021m10), ///
	robust_dynamic dynamic(17) placebo(12) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-12(2)17)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_adopters_early.pdf", replace
	
	
	
	******************************************************
	* Late adopters: last 9 months (after november 2021) *
	******************************************************
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig ///
	if download_monthly == 0 | download_monthly >= tm(2021m11), ///
	robust_dynamic dynamic(8) placebo(24) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-24(2)8)) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_adopters_late.pdf", replace
	
	
	
	**************************
	* Early vs Late adopters *
	**************************
	
	preserve
	drop if treated == 0
	replace download_monthly = 0 if download_monthly >= tm(2021m11)
	
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig, ///
	robust_dynamic dynamic(6) placebo(18) breps(25) cluster(idnss) seed(541314)
	
	event_plot e(estimates)#e(variances), default_look ///
		graph_opt(xtitle("Months since registering for the RPCI") ytitle("Average causal effect") ///
		title("") xlabel(-18(2))) stub_lag(Effect_#) stub_lead(Placebo_#) together
	
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin_adopters_early_late.pdf", replace
	restore
}


