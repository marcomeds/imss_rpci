/*******************************************************************************
@Name: twfe_beta_cohort_rpci.do

@Author: Marco Medina

@Date: 18/10/2022

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

************************
* TWFE betas by cohort *
************************
	
matrix results = J(19, 5, .)

foreach depvar in `vars'{
	
	preserve
	
	forvalues s = 0(1)18 {	
		
		***********************************************************
		* TWFE + state x quarter + baseline wage decile x quarter *
		***********************************************************
		
		reghdfe `depvar' rpci_vig if download_monthly == . | download_monthly == tm(2021m2) + `s', ///
		absorb(periodo idnss i.base_sal_decile#i.periodo_quarter)
		
		local df = e(df_r)	
			
		matrix results[`s'+1,1] = tm(2021m2) + `s'
		matrix results[`s'+1,2] = _b[rpci_vig]
		matrix results[`s'+1,3] = _se[rpci_vig]
		matrix results[`s'+1,4] = `df'
		matrix results[`s'+1,5] = `e(N)'

	}
	
	matrix colnames results = "cohort" "beta" "se" "df" "obs"
	clear
	svmat results, names(col) 
	gen rcap_lo_5 = beta - invttail(df,.025)*se
	gen rcap_hi_5 = beta + invttail(df,.025)*se	
	gen rcap_lo_10 = beta - invttail(df,.05)*se
	gen rcap_hi_10 = beta + invttail(df,.05)*se	
	
	format cohort %tm

	twoway 	(scatter beta cohort, color("0 69 134"))  ///
		(rcap rcap_lo_5 rcap_hi_5 cohort, lcolor("0 69 134")) ///
		(rcap rcap_lo_10 rcap_hi_10 cohort, lwidth(thick) lcolor("0 69 134"%70)), ///
		legend(off) scheme(s2mono) graphregion(color(white)) ///
		tlabel(2021m2(1)2022m8, format(%tmMon-YY) angle(45)) ///
		xtitle("Month the worker registered for the RPCI" "(Cohort)") ytitle("Average causal effect") yline(0)
		
	graph export "04_Figures/$muestra/twfe_beta_cohort_`depvar'.pdf", replace	
	
	restore
}
