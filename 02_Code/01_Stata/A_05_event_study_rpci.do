/*******************************************************************************
@Name: event_study_rpci.do

@Author: Marco Medina

@Date: 24/02/2023

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
local vars alta sal_formal sal_cierre log_sal_cierre

	********
	* TWFE *
	********

	preserve

	* Make time_since_treated positive for the dummies in the event study regression
	summ time_since_treated
	local increment = r(min)
	local omitted =  - r(min) - 1 // the omitted dummy is time_since_treated == -1
	replace time_since_treated = time_since_treated - `increment' // make the variable positive
	xi i.time_since_treated, noomit
	disp `omitted'
	drop _Itime_sinc_`omitted' // drop the omitted dummy
	recode _Itime_sinc_* (. = 0) if treated == 0 // make the dummies 0 for controls
	
* Loop inside since creating the dummies for the event study is really heavy, specially on the remote server database
foreach depvar in `vars' {
	
	* TWFE regression
	reghdfe `depvar' _Itime_sinc_*, ///
	absorb(periodo_monthly idnss i.base_rango##i.periodo_quarter i.base_div_final##i.periodo_quarter ///
	i.base_cve_ent_final##i.periodo_quarter i.base_sal_decile##i.periodo_quarter i.download_monthly##i.periodo_quarter) ///
	cluster(idnss) baselevels
	*absorb(periodo_monthly idnss) 

	* Create mat
	forvalues i = 31(-1)8 {
	local b_`i' = e(b)[1,`i']
	local v_`i '= e(V)[`i',`i']
	}
	forvalues i = 33(1)49 {
	local b_`i' = e(b)[1,`i']
	local v_`i '= e(V)[`i',`i']
	}

	matrix define mat1_`depvar'_ols= (`b_9',`b_10',`b_11',`b_12',`b_13',`b_14',`b_15',`b_16',`b_17',`b_18',`b_19',`b_20',`b_21',`b_22',`b_23',`b_24',`b_25',`b_26',`b_27',`b_28',`b_29',`b_30',`b_31',0,`b_33',`b_34',`b_35',`b_36',`b_37',`b_38',`b_39',`b_40',`b_41',`b_42',`b_43',`b_44',`b_45',`b_46',`b_47',`b_48',`b_49')
	mat colnames mat1_`depvar'_ols = T-24 T-23 T-22 T-21 T-20 T-19 T-18 T-17 T-16 T-15 T-14 T-13 T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12 T+13 T+14 T+15 T+16
	matrix input mat2_`depvar'_ols = (`v_9',`v_10',`v_11',`v_12',`v_13',`v_14',`v_15',`v_16',`v_17',`v_18',`v_19',`v_20',`v_21',`v_22',`v_23',`v_24',`v_25',`v_26',`v_27',`v_28',`v_29',`v_30',`v_31',0,`v_33',`v_34',`v_35',`v_36',`v_37',`v_38',`v_39',`v_40',`v_41',`v_42',`v_43',`v_44',`v_45',`v_46',`v_47',`v_48',`v_49')
	mat colnames mat2_`depvar'_ols = T-24 T-23 T-22 T-21 T-20 T-19 T-18 T-17 T-16 T-15 T-14 T-13 T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12 T+13 T+14 T+15 T+16

	* Event study
	event_plot mat1_`depvar'_ols#mat2_`depvar'_ols, stub_lag(T+#) stub_lead(T-#) ///
		   together plottype("scatter") trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(1)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134"))

	graph export "04_Figures/$muestra/event_study_`depvar'_twfe.pdf", replace
	
	* Connected event study
	event_plot mat1_`depvar'_ols#mat2_`depvar'_ols, stub_lag(T+#) stub_lead(T-#) together ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-24(2)16) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45"))
		   
	graph export "04_Figures/$muestra/event_study_`depvar'_twfe_connected.pdf", replace
}

	restore


* Loop for the other methods

foreach depvar in `vars' {
	
	********************************************
	* De Chaisemartin & d'Haultfoeuille (2020) *
	********************************************

	preserve
	
	* did_multiplegt specification
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig, ///
			   first robust_dynamic dynamic(16) placebo(24) breps(250) cluster(idnss) seed(541314)
			   
	* Define decimals for regressions
	if "`depvar'" == "sal_cierre" | "`depvar'" == "sal_formal" {
		local dec_b = 1
		local dec_se = 2
		local num_se = 4
	}
	if "`depvar'" == "log_sal_cierre" {
		local dec_b = 2
		local dec_se = 3 
		local num_se = 4
	}
	if "`depvar'" != "sal_cierre" & "`depvar'" != "sal_formal" & "`depvar'" != "log_sal_cierre"{
		local dec_b = 3
		local dec_se = 3
		local num_se = 4
	}
	
	* Save average treatment effect in a TeX
	local ate_dcdh: display %12.`dec_b'fc e(didmgt_estimates)[rownumb(e(didmgt_estimates),"Average"),1]
	file open ate_dcdh using "03_Tables/$muestra/ate_dcdh_`depvar'.tex", write replace
	file write ate_dcdh "`ate_dcdh'"
	file close ate_dcdh
	
	local ate_se_dcdh: display %`num_se'.`dec_se'fc e(didmgt_estimates)[rownumb(e(didmgt_variances),"Average"),1]
	file open ate_se_dcdh using "03_Tables/$muestra/ate_se_dcdh_`depvar'.tex", write replace
	file write ate_se_dcdh "(`ate_se_dcdh')"
	file close ate_se_dcdh
			   
	* Create matrix
	matrix define mat1_`depvar'_dcdh = e(didmgt_estimates)
	matrix define mat2_`depvar'_dcdh = e(didmgt_variances)

	* Event study	   
	event_plot mat1_`depvar'_dcdh#mat2_`depvar'_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
	       together plottype("scatter") trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(1)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 211 32")) lag_ci_opt1(color("255 211 32"))

	graph export "04_Figures/$muestra/event_study_`depvar'_dcdh.pdf", replace
	
	* Connected event study	   
	event_plot mat1_`depvar'_dcdh#mat2_`depvar'_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) together ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-24(2)16) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 211 32")) lag_ci_opt1(color("255 211 32 %45"))

	graph export "04_Figures/$muestra/event_study_`depvar'_dcdh_connected.pdf", replace
		   
	restore

		   

	************************
	* Sun & Abraham (2021) *
	************************
	
// 	sort idnss
// 	preserve
// 	tempfile tmp
// 	bysort idnss: keep if _n == 1
// 	sample 2
// 	sort idnss
// 	save `tmp'
// 	restore
// 	merge m:1 idnss using `tmp', gen(sample_merge)
// 	keep if sample_merge == 3
// 	drop sample_merge
	
// 	preserve
//
// 	* Create dummies for each lag and lead
// 	forvalues k = 12(-1)2 {
// 	gen g_`k' = time_since_treated == -`k'
// 	}
// 	forvalues k = 0/12 {
// 	 gen g`k' = time_since_treated == `k'
// 	}
//
// 	* Gen dummy to identify controls
// 	gen control = 1 - treated
// 	replace download_monthly = . if control == 1
//
// 	* eventstudyinteract specification
// 	eventstudyinteract `depvar' g_* g0-g12, cohort(download_monthly) control_cohort(control) absorb(i.idnss i.periodo_monthly) vce(cluster idnss)
//
// 	* Create mat
// 	forvalue i=1(1)24 {
// 	local b_`i'=e(b_iw)[1,`i']
// 	local v_`i'=e(V_iw)[`i',`i']
// 	}
//
// 	matrix input mat1_`depvar'_sa = (`b_1',`b_2',`b_3',`b_4',`b_5',`b_6',`b_7',`b_8',`b_9',`b_10',`b_11', 0,`b_12',`b_13',`b_14',`b_15',`b_16',`b_17',`b_18',`b_19',`b_20',`b_21',`b_22',`b_23',`b_24')
// 	mat colnames mat1_`depvar'_sa = T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12
//
// 	matrix input mat2_`depvar'_sa= (`v_1',`v_2',`v_3',`v_4',`v_5',`v_6',`v_7',`v_8',`v_9',`v_10',`v_11', 0,`v_12',`v_13',`v_14',`v_15',`v_16',`v_17',`v_18',`v_19',`v_20',`v_21',`v_22',`v_23',`v_24')
// 	mat colnames mat2_`depvar'_sa= T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12
//		   
// 	* Event study	   
// 	event_plot mat1_`depvar'_sa#mat2_`depvar'_sa, stub_lag(T+#) stub_lead(T-#) together plottype("scatter") ///
// 		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
// 		   graphregion(color(white)) xlabel(-12(1)12) xsize(7.5) ///
// 		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
// 		   title("")) ///
// 		   lag_opt1(msymbol(O) color("87 157 28")) lag_ci_opt1(color("87 157 28"))
//
// 	graph export "04_Figures/$muestra/event_study_`depvar'_sa.pdf", replace
//		   
// 	restore
	
	
		   
	*******************************
	* Callaway & Sant'Anna (2021) *
	*******************************

// 	preserve
//	
// 	* csdid specification
// 	csdid `depvar' rpci_vig, time(periodo_monthly) gvar(download_monthly) agg(event) method(dripw) notyet long reps(250) rseed(624522) cluster(idnss)
//
// 	* Create matrix
// 	matrix define mat1_`depvar'_cs = e(b)
// 	matrix define mat2_`depvar'_cs = e(V)
//
// 	* Event study	   
// 	event_plot mat1_`depvar'_cs#mat2_`depvar'_cs, stub_lag(T+#) stub_lead(T-#) trimlead(12) trimlag(12) together plottype("scatter") ///
// 		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
// 		   graphregion(color(white)) xlabel(-12(1)12) xsize(7.5) ///
// 		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
// 		   title("")) ///
// 		   lag_opt1(msymbol(O) color("255 211 32")) lag_ci_opt1(color("255 211 32"))
//		   
// 	graph export "04_Figures/$muestra/event_study_`depvar'_cs.pdf", replace
//	
// 	restore

	***************
	* Event Study *
	****************

	* Event study
// 	event_plot mat1_`depvar'_ols#mat2_`depvar'_ols mat1_`depvar'_dcdh#mat2_`depvar'_dcdh mat1_`depvar'_sa#mat2_`depvar'_sa mat1_`depvar'_cs#mat2_`depvar'_cs, ///
// 		   stub_lag(T+# Effect_# T+# T+#) stub_lead(T-# Placebo_# T-# T-#) ///
// 		   trimlead(12) trimlag(12) together plottype("scatter") noautolegend ///
// 		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
// 		   graphregion(color(white)) xlabel(-12(1)12) xsize(7.5) ///
// 		   legend(order(1 "TWFE" 3 "de Chaisemartin & d'Haultfoeuille" 5 "Sun & Abraham" 7 "Callaway & Sant'Anna")) ///
// 		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
// 		   title("")) ///
// 		   lag_opt1(msymbol(Oh) color("0 69 134")) lag_ci_opt1(color("0 69 134")) ///
// 		   lag_opt2(msymbol(Dh) color("255 211 32")) lag_ci_opt2(color("255 211 32")) ///
// 		   lag_opt3(msymbol(Th) color("87 157 28")) lag_ci_opt3(color("87 157 28")) ///
// 		   lag_opt4(msymbol(Sh) color("255 66 14")) lag_ci_opt4(color("255 66 14")) ///
// 		   perturb(-0.3(0.2)0.3)
//		   
// 	graph export "04_Figures/$muestra/event_study_`depvar'.pdf", replace
	
	* Connected event study
		event_plot mat1_`depvar'_ols#mat2_`depvar'_ols mat1_`depvar'_dcdh#mat2_`depvar'_dcdh, ///
		   stub_lag(T+# Effect_#) stub_lead(T-# Placebo_#) ///
		   together noautolegend ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-24(2)16) xsize(7.5) ///
		   legend(order(1 "TWFE" 3 "de Chaisemartin & d'Haultfoeuille")) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(Oh) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45")) ///
		   lag_opt2(msymbol(Dh) color("255 211 32")) lag_ci_opt2(color("255 211 32 %45"))
		   
	graph export "04_Figures/$muestra/event_study_`depvar'_connected.pdf", replace
			   
}
		   