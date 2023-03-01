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

* Define decimals for regressions		
local dec_b = 3
local dec_se = 3

***************************
* Effect on RPCI register *
***************************

* Specification: rpci_it = \alpha + \beta * rfc_rpci_it + \varepsilon
	
eststo: reghdfe rpci rfc_rpci_dum, absorb(idrfc periodo idnss) cluster(idnss)
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

* Firm FE
estadd local idrfc_fe = "\checkmark"

* Time FE
estadd local time_fe = "\checkmark"

* Worker FE
estadd local idnss_fe = "\checkmark"

drop reg_sample

* Specification: rpci_it = \alpha + \beta * rfc_rpci_it + \gamma * perc_rpci_exclu_it + \varepsilon

eststo: reghdfe rpci rfc_rpci_dum perc_rpci_exclu, absorb(idrfc periodo idnss) cluster(idnss)
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

* Firm FE
estadd local idrfc_fe = "\checkmark"

* Time FE
estadd local time_fe = "\checkmark"

* Worker FE
estadd local idnss_fe = "\checkmark"

drop reg_sample

* Specification: rpci_it = \alpha + \beta * rfc_rpci_vig_it + \varepsilon
	
eststo: reghdfe rpci rfc_rpci_vig_dum, absorb(idrfc periodo idnss) cluster(idnss)
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

* Firm FE
estadd local idrfc_fe = "\checkmark"

* Time FE
estadd local time_fe = "\checkmark"

* Worker FE
estadd local idnss_fe = "\checkmark"

drop reg_sample

* Specification: rpci_it = \alpha + \beta * rfc_rpci_it + \gamma * perc_rpci_vig_exclu_it + \varepsilon

eststo: reghdfe rpci rfc_rpci_vig_dum perc_rpci_vig_exclu, absorb(idrfc periodo idnss) cluster(idnss)
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

* Firm FE
estadd local idrfc_fe = "\checkmark"

* Time FE
estadd local time_fe = "\checkmark"

* Worker FE
estadd local idnss_fe = "\checkmark"

drop reg_sample

esttab using "03_Tables/$muestra/peer_rpci.tex", replace b(`dec_b') se(`dec_se') $stars nolines nomtitle ///
stats(N dep_mean unique_idnss unique_idrfc fe idrfc_fe time_fe idnss_fe, fmt(%12.0fc %12.3fc %12.0fc %12.0fc) labels("\midrule Observations" "Dep. Var. Mean" "Workers" "Firms" "\midrule \emph{FE}" "\hspace{0.25cm}Firm" "\hspace{0.25cm}Period" "\hspace{0.25cm}Worker")) substitute("\_" "_")
eststo clear
