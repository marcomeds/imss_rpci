/*******************************************************************************
@Name: yearly_volatility_rpci.do

@Author: Marco Medina

@Date: 01/03/2022

@In: yearly_panel_rpci.dta
	 
@Out: 
*******************************************************************************/


********************
version 17.0
clear all
cd "$directory"
********************

* Use panel_rpci.dta
use "01_Data/03_Working/yearly_panel_rpci.dta", clear

* Labels
label var treatment "RPCI"
label var sal_cierre_sd_yr "Wage SD"
label var sal_diff_yr "Wage Changes"
label var sal_mayor_yr "Wage Raises"
label var sal_menor_yr "Wage Cuts"

* Define decimals for regressions		
local dec_b = 2
local dec_se = 2
local num_se = 3

* Define variables
local vars sal_cierre_sd_yr sal_diff_yr sal_mayor_yr sal_menor_yr

******************
* did_multiplegt *
******************

foreach depvar in `vars' {
	
	* did_multiplegt specification
	did_multiplegt `depvar' download_year periodo_year treatment if periodo_year <= 2021, ///
			   placebo(2) breps(250) cluster(idnss) seed(541314)
			   
	* Create matrix
	matrix define mat1_`depvar'_dcdh = e(didmgt_estimates)
	matrix define mat2_`depvar'_dcdh = e(didmgt_variances)
			   
	* Save matrices with the average treatment effect, its standard error and p-value
	mat b_dcdh  = e(effect_0)
	matrix colnames b_dcdh = RPCI
	estadd mat b_dcdh
	
	mat se_dcdh = e(se_effect_0)
	matrix colnames se_dcdh = RPCI
	estadd mat se_dcdh
	
	mat p_dcdh = 2*(1-normal(abs(e(effect_0)/e(se_effect_0))))
	matrix colnames p_dcdh = RPCI
	estadd mat p_dcdh

	estadd scalar obs = e(N_effect_0) 
	estadd scalar obs_switch = e(N_switchers_effect_0)
	
	quietly summ `depvar'
	estadd scalar dep_mean = r(mean)
	
	esttab using "03_Tables/$muestra/dcdh_`depvar'.tex", replace $stars nomtitle nolines ///
	cells("b_dcdh(fmt(%12.`dec_b'fc) star pvalue(p_dcdh))" "se_dcdh(fmt(%`num_se'.`dec_se'fc) par)") ///
	stats(obs obs_switch dep_mean, ///
	labels("\midrule Observations" "Switchers" "Dep. Var. Mean") ///
	fmt(%12.0fc %12.0fc %12.`dec_b'fc))

	* Event study	   
	event_plot mat1_`depvar'_dcdh#mat2_`depvar'_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
	       together plottype("scatter") ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-2(1)0) xsize(7.5) ///
		   xtitle("Years since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 211 32")) lag_ci_opt1(color("255 211 32"))

	graph export "04_Figures/$muestra/event_study_`depvar'_dcdh.pdf", replace
	
	* Connected event study	   
	event_plot mat1_`depvar'_dcdh#mat2_`depvar'_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
		   together ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-2(1)0) xsize(7.5) ///
		   xtitle("Years since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 211 32")) lag_ci_opt1(color("255 211 32 %45"))

	graph export "04_Figures/$muestra/event_study_`depvar'_dcdh_connected.pdf", replace
}
