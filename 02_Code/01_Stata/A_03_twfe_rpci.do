/*******************************************************************************
@Name: twfe_rpci.do

@Author: Marco Medina

@Date: 22/02/2023

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

* Define variables
local vars alta sal_formal sal_cierre log_sal_cierre cambio_cierre sal_diff

********************
* TWFE Regressions *
********************

foreach depvar in `vars' {

	* Define decimals for regressions
	if "`depvar'" == "sal_cierre" | "`depvar'" == "sal_formal" {
		local dec_b = 1
		local dec_se = 2
	}
	if "`depvar'" == "log_sal_cierre" {
		local dec_b = 2
		local dec_se = 3 
	}
	if "`depvar'" != "sal_cierre" & "`depvar'" != "sal_formal" & "`depvar'" != "log_sal_cierre"{
		local dec_b = 3
		local dec_se = 3
	}	
	
	***************
	* Simple TWFE *
	***************
	
	eststo: reghdfe `depvar' rpci_vig, ///
	absorb(periodo_monthly idnss) ///
	cluster(idnss)
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if e(sample) == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if e(sample) == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if e(sample) == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	*estadd local gender_fe = ""
	*estadd local age_fe = ""
	*estadd local industry_fe = ""
	*estadd local state_fe = ""
	*estadd local decile_fe = ""
	*estadd local cohort_fe = ""
	estadd local extended = ""
	
	esttab using "03_Tables/$muestra/twfe_`depvar'.tex", replace b(`dec_b') se(`dec_se') $stars nolines nomtitle ///
	stats(N dep_mean unique_idnss unique_idrfc extended, ///
	labels("\midrule Observations" "Dep. Var. Mean" "Workers" "Firms" "\midrule Extended") ///
	fmt(%12.0fc %12.`dec_b'fc %12.0fc %12.0fc %15s))
	
	esttab using "03_Tables/$muestra/twfe_`depvar'_wo_extended.tex", replace b(`dec_b') se(`dec_se') $stars nolines nomtitle ///
	stats(N dep_mean unique_idnss unique_idrfc, ///
	labels("\midrule Observations" "Dep. Var. Mean" "Workers" "Firms") ///
	fmt(%12.0fc %12.`dec_b'fc %12.0fc %12.0fc))
	eststo clear
	
	*****************
	* Extended TWFE *
	*****************

	eststo: reghdfe `depvar' rpci_vig, ///
	absorb(periodo_monthly idnss ///
	i.download_monthly#i.sexo i.periodo_monthly#i.sexo ///
	i.download_monthly#i.base_rango i.periodo_monthly#i.base_rango ///
	i.download_monthly#i.base_div_final i.periodo_monthly#i.base_div_final ///
	i.download_monthly#i.base_cve_ent_final i.periodo_monthly#i.base_cve_ent_final ///
	i.download_monthly#i.base_sal_decile i.periodo_monthly#i.base_sal_decile) ///
	cluster(idnss)
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if e(sample) == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if e(sample) == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if e(sample) == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	*estadd local gender_fe = "\checkmark"
	*estadd local age_fe = "\checkmark"
	*estadd local industry_fe = "\checkmark"
	*estadd local state_fe = "\checkmark"
	*estadd local decile_fe = "\checkmark"
	*estadd local cohort_fe = "\checkmark"
	estadd local extended = "\checkmark"
	
	esttab using "03_Tables/$muestra/etwfe_`depvar'.tex", replace b(`dec_b') se(`dec_se') $stars nolines nomtitle ///
	stats(N dep_mean unique_idnss unique_idrfc extended, ///
	labels("\midrule Observations" "Dep. Var. Mean" "Workers" "Firms" "\midrule Extended") ///
	fmt(%12.0fc %12.`dec_b'fc %12.0fc %12.0fc %15s))
	*stats(N dep_mean unique_idnss unique_idrfc l_fe gender_fe age_fe industry_fe state_fe decile_fe cohort_fe, ///
	*labels("\midrule Observations" "Dep. Var. Mean" "Workers" "Firms" "\midrule \emph{Linear Time Trends FE}" ///
	*"\hspace{0.25cm}Gender" "\hspace{0.25cm}Age" "\hspace{0.25cm}Industry" "\hspace{0.25cm}State" ///
	*"\hspace{0.25cm}Wage Decile" "\hspace{0.25cm}Cohort") ///
	*fmt(%12.0fc %12.`dec_b'fc %12.0fc %12.0fc %15s %15s %15s %15s %15s %15s %15s))
	
	esttab using "03_Tables/$muestra/etwfe_`depvar'_wo_extended.tex", replace b(`dec_b') se(`dec_se') $stars nolines nomtitle ///
	stats(N dep_mean unique_idnss unique_idrfc, ///
	labels("\midrule Observations" "Dep. Var. Mean" "Workers" "Firms") ///
	fmt(%12.0fc %12.`dec_b'fc %12.0fc %12.0fc))
	eststo clear
}
