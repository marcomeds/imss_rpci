/*******************************************************************************
@Name: sal_cierre_sd_rpci.do

@Author: Marco Medina

@Date: 30/10/2022

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

* Keep one observation per year
duplicates drop idnss periodo_year, force

* Keep relevant variables
keep idnss idrfc periodo_* download_year sal_*_yr base_*

* Create variables treatment and sal_cierre_sd. Replace with the values according to the year
gen treatment = 0
replace treatment = 1 if download_year == 2021 & periodo_year >= 2021
replace treatment = 1 if download_year == 2022 & periodo_year >= 2022

* Labels
label var treatment "RPCI"
label var sal_cierre_sd_yr "Wage SD"
label var sal_diff_yr "Wage Changes"
label var sal_mayor_yr "Wage Raises"
label var sal_menor_yr "Wage Cuts"

* Define decimals for regressions		
local dec_b = 2
local dec_se = 2

* Define variables
local vars sal_cierre_sd_yr sal_diff_yr sal_mayor_yr sal_menor_yr



********
* TWFE *
********

eststo clear
foreach depvar in `vars' {
	
	* TWFE + (age, firm ind., state, wage decile) x year
	eststo: reghdfe `depvar' treatment if periodo_year <= 2021, ///
	absorb(periodo_year idnss i.base_rango#i.periodo_year i.base_div_final#i.periodo_year ///
	i.base_cve_ent_final#i.periodo_year i.base_sal_decile#i.periodo_year) ///
	cluster(idnss)
	gen reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	drop reg_sample
}

esttab using "03_Tables/$muestra/twfe_sal_yr.tex", replace label nonotes b(`dec_b') se(`dec_se') $star ///
stats(N dep_mean unique_idnss unique_idrfc, fmt(%12.0fc %12.2fc %12.0fc %12.0fc) label("Observations" "Mean" "Workers" "Firms" "Period FE" "Worker ID FE" "Linear Trends FE"))
eststo clear



******************
* did_multiplegt *
******************

foreach depvar in `vars' {
	
	* did_multiplegt
	did_multiplegt `depvar' download_year periodo_year treatment if periodo_year <= 2021, ///
	placebo(2) breps(25) cluster(idnss) seed(541314)

	event_plot e(estimates)#e(variances), default_look ///
	graph_opt(xtitle("Years since the RPCI launch") ytitle("Average causal effect") ///
		title("") xlabel(-2(1)0)) stub_lag(Effect_#) stub_lead(Placebo_#) together
		
	graph export "04_Figures/$muestra/event_study_`depvar'_chaisemartin.pdf", replace
}
