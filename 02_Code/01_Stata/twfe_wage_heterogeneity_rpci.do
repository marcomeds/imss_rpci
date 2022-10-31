/*******************************************************************************
@Name: twfe_wage_heterogeneity_rpci.do

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

************************************
* TWFE Regressions - heterogeneity *
************************************

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
	
	*******
	* Men *
	*******
	
	eststo: reghdfe `depvar' rpci_vig if sexo == 0, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
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
	
	
	
	*********
	* Women *
	*********
	
	eststo: reghdfe `depvar' rpci_vig if sexo == 1, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	

	
	***************
	* Outsourcing *
	***************
	
	eststo: reghdfe `depvar' rpci_vig if base_outsourcing == 1, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	*******************
	* Eventual Worker *
	*******************
	
	eststo: reghdfe `depvar' rpci_vig if base_te == 1, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	****************
	* Ind. Transf. *
	****************
	
	eststo: reghdfe `depvar' rpci_vig if base_div_final == 3, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
		
		
		
	****************
	* Ind. Constr. *
	****************
	
	eststo: reghdfe `depvar' rpci_vig if base_div_final == 4, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
		


	************
	* Comercio *
	************
	
	eststo: reghdfe `depvar' rpci_vig if base_div_final == 6, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
		


	***************
	* Transportes *
	***************
	
	eststo: reghdfe `depvar' rpci_vig if base_div_final == 7, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	***************
	* Serv. Pers. *
	***************
	
	eststo: reghdfe `depvar' rpci_vig if base_div_final == 8, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
		


	**************
	* Serv. Soc. *
	**************
	
	eststo: reghdfe `depvar' rpci_vig if base_div_final == 9, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	********
	* PyME *
	********
	
	eststo: reghdfe `depvar' rpci_vig ///
	if base_size_cierre == 1 | size_cierre == 2 | size_cierre == 3 | size_cierre == 4, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)


	
	******************
	* Empresa Grande *
	******************
	
	eststo: reghdfe `depvar' rpci_vig if base_size_cierre == 7, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	esttab using "03_Tables/$muestra/twfe_`depvar'_heterogeneity.csv", replace plain b(`dec_b') se(`dec_se') $star ///
	scalars(dep_mean unique_idnss unique_idrfc)
	eststo clear
	
	drop reg_sample
}

************************************************
* TWFE Regressions - heterogeneity - firm size *
************************************************

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
	
	****************
	* S1: 1 worker *
	****************
	
	eststo: reghdfe `depvar' rpci_vig if base_size_cierre == 1, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
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
	
	
	
	*******************
	* S2: 2-5 workers *
	*******************
	
	eststo: reghdfe `depvar' rpci_vig if base_size_cierre == 2, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	********************
	* S3: 6-50 workers *
	********************
	
	eststo: reghdfe `depvar' rpci_vig if base_size_cierre == 3, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	**********************
	* S4: 51-250 workers *
	**********************
	
	eststo: reghdfe `depvar' rpci_vig if base_size_cierre == 4, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	***********************
	* S5: 251-500 workers *
	***********************
	
	eststo: reghdfe `depvar' rpci_vig if base_size_cierre == 5, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	************************
	* S6: 501-1000 workers *
	************************
	
	eststo: reghdfe `depvar' rpci_vig if base_size_cierre == 6, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	*********************
	* S7: 1000+ workers *
	*********************
	
	eststo: reghdfe `depvar' rpci_vig if base_size_cierre == 7, ///
	absorb(periodo idnss i.cve_ent_final#i.periodo_quarter i.base_div_final#i.periodo_quarter ///
	i.cve_ent_final#i.periodo_quarter i.base_sal_decile#i.periodo_quarter) ///
	cluster(idnss) 
	replace reg_sample = [e(sample) == 1]
	
	* Dependant variable mean in the sample used in the regression
	quietly summ `depvar' if reg_sample == 1
	estadd scalar dep_mean = r(mean)
	
	* Number of workers in the sample used in the regression
	distinct idnss if reg_sample == 1
	estadd scalar unique_idnss = r(ndistinct)
	
	* Number of firms in the sample used in the regression
	distinct idrfc if reg_sample == 1
	estadd scalar unique_idrfc = r(ndistinct)
	
	
	
	esttab using "03_Tables/$muestra/twfe_`depvar'_heterogeneity_firm_size.csv", ///
	replace plain b(`dec_b') se(`dec_se') $star ///
	scalars(dep_mean unique_idnss unique_idrfc)
	eststo clear
	
	drop reg_sample

}
