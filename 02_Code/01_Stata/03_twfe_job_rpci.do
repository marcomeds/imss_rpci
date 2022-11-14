/*******************************************************************************
@Name: twfe_job_rpci.do

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
local vars alta alta_cierre baja_cierre baja_permanente cambio_cierre ///
		   sal_diff cambio_sal_mayor cambio_sal_menor cambio_sal_igual

* Define decimals for regressions		
local dec_b = 3
local dec_se = 3

********************
* TWFE Regressions *
********************

foreach depvar in `vars' {	
	
	*********************************************************
	* TWFE + (age, firm ind., state, wage decile) x quarter *
	*********************************************************

	eststo: reghdfe `depvar' rpci_vig, ///
	absorb(periodo idnss i.base_rango#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.base_cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
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
	
	
	
	esttab using "03_Tables/$muestra/twfe_`depvar'.csv", replace plain  b(`dec_b') se(`dec_se') $star ///
	scalars(dep_mean unique_idnss unique_idrfc)
	eststo clear
	
	drop reg_sample
	
}
