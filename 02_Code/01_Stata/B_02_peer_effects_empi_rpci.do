/*******************************************************************************
@Name: peer_effects_empi_rpci.do

@Author: Marco Medina

@Description: Calculate peer effects on workers' firms.

@Date: 10/01/2023

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

* Labels
label var rpci "\$RPCI_{it}\$"
label var rfc_rpci_dum "\$RPCI_{jt}\$"
label var perc_rpci_exclu "\$RPCI_{jt}\$ (\%)"

* Define decimals for regressions		
local dec_b = 3
local dec_se = 3

***************************
* Effect on RPCI register *
***************************

* Specification: rpci_it = \alpha + \beta * rfc_rpci_it + \varepsilon

	* 1) Simple
	eststo: reghdfe rpci rfc_rpci_dum, noabsorb cluster(idnss)
	gen reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ rpci if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	* Time FE
	estadd local time_fe = "No"
	
	* Worker FE
	estadd local idnss_fe = "No"
	
	* Linear Trends FE
	estadd local lin_fe = "No"
	
	drop reg_sample
	
	
	* 2) Time FE
	eststo: reghdfe rpci rfc_rpci_dum, absorb(periodo) cluster(idnss)
		gen reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ rpci if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	* Time FE
	estadd local time_fe = "Yes"
	
	* Worker FE
	estadd local idnss_fe = "No"
	
	* Linear Trends FE
	estadd local lin_fe = "No"
	
	drop reg_sample
	
	
	* 3) TWFE
	eststo: reghdfe rpci rfc_rpci_dum, absorb(periodo idnss) cluster(idnss)
	gen reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ rpci if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	* Time FE
	estadd local time_fe = "Yes"
	
	* Worker FE
	estadd local idnss_fe = "Yes"
	
	* Linear Trends FE
	estadd local lin_fe = "No"
	
	drop reg_sample

	* 4) TWFE + (age, firm ind., state, wage decile) x year
	eststo: reghdfe rpci rfc_rpci_dum, ///
	absorb(periodo idnss i.base_rango#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.base_cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss)
	gen reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ rpci if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	* Time FE
	estadd local time_fe = "Yes"
	
	* Worker FE
	estadd local idnss_fe = "Yes"
	
	* Linear Trends FE
	estadd local lin_fe = "Yes"
	
	drop reg_sample

esttab using "03_Tables/$muestra/peer_rpci_rfc_rpci_dum.tex", replace label nonotes b(`dec_b') se(`dec_se') $star ///
stats(N dep_mean unique_idnss unique_idrfc time_fe idnss_fe lin_fe, fmt(%12.0fc %12.3fc %12.0fc %12.0fc) label("Observations" "Mean" "Workers" "Firms" "Period FE" "Worker ID FE" "Linear Trends FE")) substitute("\_" "_")
eststo clear



* Specification: rpci_it = \alpha + \beta * rfc_rpci_it + \gamma * perc_rpci_exclu_it + \varepsilon

	* 1) Simple
	eststo: reghdfe rpci rfc_rpci_dum perc_rpci_exclu, noabsorb cluster(idnss)
	gen reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ rpci if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	* Time FE
	estadd local time_fe = "No"
	
	* Worker FE
	estadd local idnss_fe = "No"
	
	* Linear Trends FE
	estadd local lin_fe = "No"
	
	drop reg_sample
	
	
	* 2) Time FE
	eststo: reghdfe rpci rfc_rpci_dum perc_rpci_exclu, absorb(periodo) cluster(idnss)
		gen reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ rpci if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	* Time FE
	estadd local time_fe = "Yes"
	
	* Worker FE
	estadd local idnss_fe = "No"
	
	* Linear Trends FE
	estadd local lin_fe = "No"
	
	drop reg_sample
	
	
	* 3) TWFE
	eststo: reghdfe rpci rfc_rpci_dum perc_rpci_exclu, absorb(periodo idnss) cluster(idnss)
	gen reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ rpci if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	* Time FE
	estadd local time_fe = "Yes"
	
	* Worker FE
	estadd local idnss_fe = "Yes"
	
	* Linear Trends FE
	estadd local lin_fe = "No"
	
	drop reg_sample

	* 4) TWFE + (age, firm ind., state, wage decile) x year
	eststo: reghdfe rpci rfc_rpci_dum perc_rpci_exclu, ///
	absorb(periodo idnss i.base_rango#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.base_cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss)
	gen reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ rpci if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	* Time FE
	estadd local time_fe = "Yes"
	
	* Worker FE
	estadd local idnss_fe = "Yes"
	
	* Linear Trends FE
	estadd local lin_fe = "Yes"
	
	drop reg_sample

esttab using "03_Tables/$muestra/peer_rpci_rfc_rpci_dum_perc_rpci_exclu.tex", replace label nonotes b(`dec_b') se(`dec_se') $star ///
stats(N dep_mean unique_idnss unique_idrfc time_fe idnss_fe lin_fe, fmt(%12.0fc %12.3fc %12.0fc %12.0fc) label("Observations" "Mean" "Workers" "Firms" "Period FE" "Worker ID FE" "Linear Trends FE")) substitute("\_" "_")
eststo clear
