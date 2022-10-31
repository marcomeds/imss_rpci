/*******************************************************************************
@Name: twfe_wage_rpci.do

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

* Define variables
local vars sal_cierre log_sal_cierre 			

********************
* TWFE Regressions *
********************

foreach depvar in `vars' {

	* Define decimals for regressions
	if "`depvar'" == "sal_cierre" {
		local dec_b = 1
		local dec_se = 2
	}
	if "`depvar'" == "log_sal_cierre" {
		local dec_b = 2
		local dec_se = 3 
	}

	***************
	* Simple TWFE *
	***************
	
	eststo: reghdfe `depvar' rpci_vig, absorb(periodo idnss) ///
	cluster(idnss)
	gen reg_sample = [e(sample) == 1]
		
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	egen tag_idnss = tag(idnss) if reg_sample == 1
	quietly summ tag_idnss
	estadd scalar unique_idnss = r(sum)
	drop tag_idnss
	
	* Number of firms in the sample used in the regression
	egen tag_idrfc = tag(idrfc) if reg_sample == 1
	quietly summ tag_idrfc
	estadd scalar unique_idrfc = r(sum)
	drop tag_idrfc

	
	
	************************
	* TWFE + age x quarter *
	************************

	eststo: reghdfe `depvar' rpci_vig, absorb(periodo idnss i.base_rango#i.periodo_quarter) ///
	cluster(idnss)
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	egen tag_idnss = tag(idnss) if reg_sample == 1
	quietly summ tag_idnss
	estadd scalar unique_idnss = r(sum)
	drop tag_idnss
	
	* Number of firms in the sample used in the regression
	egen tag_idrfc = tag(idrfc) if reg_sample == 1
	quietly summ tag_idrfc
	estadd scalar unique_idrfc = r(sum)
	drop tag_idrfc
			
	
	
	**********************************
	* TWFE + firm industry x quarter *
	**********************************

	eststo: reghdfe `depvar' rpci_vig, absorb(periodo idnss i.base_div_final#i.periodo_quarter) ///
	cluster(idnss)
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	egen tag_idnss = tag(idnss) if reg_sample == 1
	quietly summ tag_idnss
	estadd scalar unique_idnss = r(sum)
	drop tag_idnss
	
	* Number of firms in the sample used in the regression
	egen tag_idrfc = tag(idrfc) if reg_sample == 1
	quietly summ tag_idrfc
	estadd scalar unique_idrfc = r(sum)
	drop tag_idrfc
	
	
	
	**************************
	* TWFE + state x quarter *
	**************************

	eststo: reghdfe `depvar' rpci_vig, absorb(periodo idnss i.base_cve_ent_final#i.periodo_quarter) ///
	cluster(idnss)
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	egen tag_idnss = tag(idnss) if reg_sample == 1
	quietly summ tag_idnss
	estadd scalar unique_idnss = r(sum)
	drop tag_idnss
	
	* Number of firms in the sample used in the regression
	egen tag_idrfc = tag(idrfc) if reg_sample == 1
	quietly summ tag_idrfc
	estadd scalar unique_idrfc = r(sum)
	drop tag_idrfc
	
	
	
	*****************************************
	* TWFE + baseline wage decile x quarter *
	*****************************************
	
	eststo: reghdfe `depvar' rpci_vig, absorb(periodo idnss i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss)
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	egen tag_idnss = tag(idnss) if reg_sample == 1
	quietly summ tag_idnss
	estadd scalar unique_idnss = r(sum)
	drop tag_idnss
	
	* Number of firms in the sample used in the regression
	egen tag_idrfc = tag(idrfc) if reg_sample == 1
	quietly summ tag_idrfc
	estadd scalar unique_idrfc = r(sum)
	drop tag_idrfc
	
	
	
	*********************************************************
	* TWFE + (age, firm ind., state, wage decile) x quarter *
	*********************************************************

	eststo: reghdfe `depvar' rpci_vig, ///
	absorb(periodo idnss i.base_rango#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss)
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	egen tag_idnss = tag(idnss) if reg_sample == 1
	quietly summ tag_idnss
	estadd scalar unique_idnss = r(sum)
	drop tag_idnss
	
	* Number of firms in the sample used in the regression
	egen tag_idrfc = tag(idrfc) if reg_sample == 1
	quietly summ tag_idrfc
	estadd scalar unique_idrfc = r(sum)
	drop tag_idrfc
	
	
	
	esttab using "03_Tables/$muestra/twfe_`depvar'.csv", replace plain  b(`dec_b') se(`dec_se') $star ///
	scalars(dep_mean unique_idnss unique_idrfc)
	eststo clear
	
	drop reg_sample
	
}


/*
********************************************************
* TWFE Regressions - Same employer in the whole sample *
********************************************************

* Define variables
local vars log_sal_cierre sal_cierre

preserve 

keep if same_idrfc == 1

foreach depvar in `vars' {
	
	* Define decimals for regressions
	if "`depvar'" == "sal_cierre" {
		local dec_b = 1
		local dec_se = 2
	}
	if "`depvar'" == "log_sal_cierre" {
		local dec_b = 2
		local dec_se = 3 
	}
	
	
	*********************************************************
	* TWFE + (age, firm ind., state, wage decile) x quarter *
	*********************************************************

	eststo: reghdfe `depvar' rpci_vig, ///
	absorb(periodo idnss i.base_rango#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss)
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	egen tag_idnss = tag(idnss) if reg_sample == 1
	quietly summ tag_idnss
	estadd scalar unique_idnss = r(sum)
	drop tag_idnss
	
	* Number of firms in the sample used in the regression
	egen tag_idrfc = tag(idrfc) if reg_sample == 1
	quietly summ tag_idrfc
	estadd scalar unique_idrfc = r(sum)
	drop tag_idrfc
	
	
	
	esttab using "03_Tables/$muestra/twfe_`depvar'_same_idrfc.csv", replace plain  b(`dec_b') se(`dec_se') $star ///
	scalars(dep_mean unique_idnss unique_idrfc)
	eststo clear
	
	drop reg_sample
}

restore
