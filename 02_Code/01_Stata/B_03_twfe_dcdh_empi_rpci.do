/*******************************************************************************
@Name: twfe_dcdh_empi_rpci.do

@Author: Marco Medina

@Date: 20/03/2023

@In: panel_empi_rpci.dta
	 
@Out: 
*******************************************************************************/


********************
version 17.0
clear all
cd "$directory"
********************

* Use panel_empi_rpci.dta
use "01_Data/03_Working/panel_empi_rpci.dta", clear


*********************************
* Create database at firm level *
*********************************
collapse (max) rpci_vig (mean) perc_rpci_vig = rpci_vig (mean) sal_cierre, by(idrfc periodo)

label var rpci_vig "RPCI"
label var perc_rpci_vig "RPCI (\%)"
label var sal_cierre "Wage"

********
* TWFE *
********

local dec_b = 1
local dec_se = 2

eststo: reghdfe sal_cierre rpci_vig, ///
absorb(periodo_monthly idrfc) ///
cluster(idrfc)
	
* Dependant variable mean in the sample used in the regression
quietly summ sal_cierre if e(sample) == 1
estadd scalar dep_mean = r(mean)

* Number of firms in the sample used in the regression
distinct idrfc if e(sample) == 1
estadd scalar unique_idrfc = r(ndistinct)
	
esttab using "03_Tables/$muestra/twfe_sal_cierre_empi.tex", replace b(`dec_b') se(`dec_se') $stars nolines nomtitle ///
stats(N dep_mean unique_idrfc, ///
labels("\midrule Observations" "Dep. Var. Mean" "Firms") ///
fmt(%12.0fc %12.`dec_b'fc %12.0fc))
eststo clear



* Using perc_rpci_vig
eststo: reghdfe sal_cierre perc_rpci_vig, ///
absorb(periodo_monthly idrfc) ///
cluster(idrfc)
	
* Dependant variable mean in the sample used in the regression
quietly summ sal_cierre if e(sample) == 1
estadd scalar dep_mean = r(mean)

* Number of firms in the sample used in the regression
distinct idrfc if e(sample) == 1
estadd scalar unique_idrfc = r(ndistinct)
	
esttab using "03_Tables/$muestra/twfe_sal_cierre_perc_empi.tex", replace b(`dec_b') se(`dec_se') $stars nolines nomtitle ///
stats(N dep_mean unique_idrfc, ///
labels("\midrule Observations" "Dep. Var. Mean" "Firms") ///
fmt(%12.0fc %12.`dec_b'fc %12.0fc))
eststo clear


********************************************
* De Chaisemartin & d'Haultfoeuille (2020) *
********************************************

* did_multiplegt specification
did_multiplegt sal_cierre idrfc periodo rpci_vig, ///
			   first robust_dynamic dynamic(12) placebo(12) breps(50) cluster(idrfc) seed(541314)
		   
* Create matrix
matrix define mat1_dcdh = e(didmgt_estimates)
matrix define mat2_dcdh = e(didmgt_variances)
		   
* Save matrices with the average treatment effect, its standard error and p-value
mat b_dcdh  = e(effect_average)
matrix colnames b_dcdh = RPCI
estadd mat b_dcdh

mat se_dcdh = e(se_effect_average)
matrix colnames se_dcdh = RPCI
estadd mat se_dcdh

mat p_dcdh = 2*(1-normal(abs(e(effect_average)/e(se_effect_average))))
matrix colnames p_dcdh = RPCI
estadd mat p_dcdh

estadd scalar obs = e(N_effect_average) 
estadd scalar obs_switch = e(N_switchers_effect_average)

quietly summ sal_cierre
estadd scalar dep_mean = r(mean)

* Define decimals for output table
local dec_b = 1
local dec_se = 2
local num_se = 3

esttab using "03_Tables/$muestra/dcdh_sal_cierre_empi.tex", replace $stars nomtitle nolines ///
cells("b_dcdh(fmt(%12.`dec_b'fc) star pvalue(p_dcdh))" "se_dcdh(fmt(%`num_se'.`dec_se'fc) par)") ///
stats(obs obs_switch dep_mean, ///
labels("\midrule Observations" "Switchers" "Dep. Var. Mean") ///
fmt(%12.0fc %12.0fc %12.`dec_b'fc))

* Event study	   
event_plot mat1_dcdh#mat2_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
	   together plottype("scatter") trimlead(12) trimlag(12) ///
	   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
	   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
	   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
	   title("")) ///
	   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134"))

graph export "04_Figures/$muestra/event_study_sal_cierre_dcdh_empi.pdf", replace

* Connected event study	   
event_plot mat1_dcdh#mat2_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
	   together trimlead(12) trimlag(12) ///
	   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
	   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
	   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
	   title("")) ///
	   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45"))

graph export "04_Figures/$muestra/event_study_sal_cierre_dcdh_connected_empi.pdf", replace

* Connected event study	- paper
event_plot mat1_dcdh#mat2_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
	   together trimlead(24) trimlag(12) ///
	   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
	   graphregion(color(white)) xlabel(-24(2)12) xsize(7.5) ///
	   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
	   title("")) ///
	   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45"))

graph export "04_Figures/$muestra/event_study_sal_cierre_dcdh_connected_paper_empi.pdf", replace




********************************************
* De Chaisemartin & d'Haultfoeuille (2020) *
********************************************

* did_multiplegt specification
did_multiplegt sal_cierre idrfc periodo perc_rpci_vig, ///
			   first robust_dynamic dynamic(12) placebo(12) breps(50) cluster(idrfc) seed(541314)
		   
* Create matrix
matrix define mat1_dcdh = e(didmgt_estimates)
matrix define mat2_dcdh = e(didmgt_variances)
		   
* Save matrices with the average treatment effect, its standard error and p-value
mat b_dcdh  = e(effect_average)
matrix colnames b_dcdh = RPCI
estadd mat b_dcdh

mat se_dcdh = e(se_effect_average)
matrix colnames se_dcdh = RPCI
estadd mat se_dcdh

mat p_dcdh = 2*(1-normal(abs(e(effect_average)/e(se_effect_average))))
matrix colnames p_dcdh = RPCI
estadd mat p_dcdh

estadd scalar obs = e(N_effect_average) 
estadd scalar obs_switch = e(N_switchers_effect_average)

quietly summ sal_cierre
estadd scalar dep_mean = r(mean)

* Define decimals for output table
local dec_b = 1
local dec_se = 2
local num_se = 3

esttab using "03_Tables/$muestra/dcdh_sal_cierre_perc_empi.tex", replace $stars nomtitle nolines ///
cells("b_dcdh(fmt(%12.`dec_b'fc) star pvalue(p_dcdh))" "se_dcdh(fmt(%`num_se'.`dec_se'fc) par)") ///
stats(obs obs_switch dep_mean, ///
labels("\midrule Observations" "Switchers" "Dep. Var. Mean") ///
fmt(%12.0fc %12.0fc %12.`dec_b'fc))

* Event study	   
event_plot mat1_dcdh#mat2_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
	   together plottype("scatter") trimlead(12) trimlag(12) ///
	   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
	   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
	   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
	   title("")) ///
	   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134"))

graph export "04_Figures/$muestra/event_study_sal_cierre_dcdh_perc_empi.pdf", replace

* Connected event study	   
event_plot mat1_dcdh#mat2_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
	   together trimlead(12) trimlag(12) ///
	   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
	   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
	   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
	   title("")) ///
	   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45"))

graph export "04_Figures/$muestra/event_study_sal_cierre_dcdh_connected_perc_empi.pdf", replace

* Connected event study	- paper
event_plot mat1_dcdh#mat2_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
	   together trimlead(24) trimlag(12) ///
	   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
	   graphregion(color(white)) xlabel(-24(2)12) xsize(7.5) ///
	   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
	   title("")) ///
	   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45"))

graph export "04_Figures/$muestra/event_study_sal_cierre_dcdh_connected_paper_perc_empi.pdf", replace




