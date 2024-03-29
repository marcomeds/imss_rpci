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
set graphics off
********************

* Use panel_rpci.dta
use "01_Data/03_Working/panel_rpci.dta", clear
compress

* Keep relevant variables
keep idnss rpci_vig sexo periodo_monthly periodo_t download_monthly treated time_since_treated ///
	base_rango base_div_final base_cve_ent_final base_sal_decile ///
	alta sal_formal sal_cierre log_sal_cierre cambio_cierre sal_diff
	
* Save the event_study database
save "01_Data/03_Working/event_study_rpci.dta", replace
	
* Make time_since_treated positive for the dummies in the event study regression
summ time_since_treated
local increment = r(min)
local omitted =  - r(min) - 1 // the omitted dummy is time_since_treated == -1
replace time_since_treated = time_since_treated - `increment' // make the variable positive
xi i.time_since_treated, noomit
disp `omitted'
drop _Itime_sinc_`omitted' // drop the omitted dummy
recode _Itime_sinc_* (. = 0) if treated == 0 // make the dummies 0 for controls

* Save the event_study database for reghdefe
save "01_Data/03_Working/event_study_rpci_reghdfe.dta", replace

* Define variables
local vars alta sal_formal sal_cierre log_sal_cierre cambio_cierre sal_diff //

foreach depvar in `vars' {
	

	* Use the compressed event_study_rpci_reghdfe.dta
	use "01_Data/03_Working/event_study_rpci_reghdfe.dta", clear
	
	***************
	* Simple TWFE *
	***************
	
	* TWFE regression
	reghdfe `depvar' _Itime_sinc_*, ///
	absorb(periodo_monthly idnss) ///
	cluster(idnss) baselevels compact pool(1)

	* Create mat
	forvalues i = 1(1)39 {
	local b_`i' = e(b)[1,`i']
	local v_`i '= e(V)[`i',`i']
	}

	matrix define mat1_twfe = (`b_1',`b_2',`b_3',`b_4',`b_5',`b_6',`b_7',`b_8',`b_9',`b_10',`b_11',`b_12',`b_13',`b_14',`b_15',`b_16',`b_17',`b_18',`b_19',`b_20',`b_21',`b_22',`b_23',`b_24',`b_25',0,`b_26',`b_27',`b_28',`b_29',`b_30',`b_31',`b_32',`b_33',`b_34',`b_35',`b_36',`b_37',`b_38',`b_39')
	mat colnames mat1_twfe = T-26 T-25 T-24 T-23 T-22 T-21 T-20 T-19 T-18 T-17 T-16 T-15 T-14 T-13 T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12 T+13
	matrix input mat2_twfe = (`v_1',`v_2',`v_3',`v_4',`v_5',`v_6',`v_7',`v_8',`v_9',`v_10',`v_11',`v_12',`v_13',`v_14',`v_15',`v_16',`v_17',`v_18',`v_19',`v_20',`v_21',`v_22',`v_23',`v_24',`v_25',0,`v_26',`v_27',`v_28',`v_29',`v_30',`v_31',`v_32',`v_33',`v_34',`v_35',`v_36',`v_37',`v_38',`v_39')
	mat colnames mat2_twfe = T-26 T-25 T-24 T-23 T-22 T-21 T-20 T-19 T-18 T-17 T-16 T-15 T-14 T-13 T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12 T+13

	* Event study
	event_plot mat1_twfe#mat2_twfe, stub_lag(T+#) stub_lead(T-#) ///
		   together plottype("scatter") trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 211 32")) lag_ci_opt1(color("255 211 32"))

	graph export "04_Figures/$muestra/event_study_`depvar'_twfe.pdf", replace
	
	* Connected event study
	event_plot mat1_twfe#mat2_twfe, stub_lag(T+#) stub_lead(T-#) ///
	       together trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 211 32")) lag_ci_opt1(color("255 211 32 %45"))
		   
	graph export "04_Figures/$muestra/event_study_`depvar'_twfe_connected.pdf", replace
	
	* Connected event study	- paper
	event_plot mat1_twfe#mat2_twfe, stub_lag(T+#) stub_lead(T-#) ///
	       together trimlead(24) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-24(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 211 32")) lag_ci_opt1(color("255 211 32 %45"))
		   
	graph export "04_Figures/$muestra/event_study_`depvar'_twfe_connected_paper.pdf", replace


	*****************
	* Extended TWFE *
	*****************
	
	* TWFE regression
	reghdfe `depvar' _Itime_sinc_*, ///
	absorb(periodo_monthly idnss ///
	i.download_monthly#i.sexo i.periodo_monthly#i.sexo ///
	i.download_monthly#i.base_rango i.periodo_monthly#i.base_rango ///
	i.download_monthly#i.base_div_final i.periodo_monthly#i.base_div_final ///
	i.download_monthly#i.base_cve_ent_final i.periodo_monthly#i.base_cve_ent_final ///
	i.download_monthly#i.base_sal_decile i.periodo_monthly#i.base_sal_decile) ///
	cluster(idnss) baselevels compact pool(1)

	* Create mat
	forvalues i = 1(1)39 {
	local b_`i' = e(b)[1,`i']
	local v_`i '= e(V)[`i',`i']
	}

	matrix define mat1_etwfe = (`b_1',`b_2',`b_3',`b_4',`b_5',`b_6',`b_7',`b_8',`b_9',`b_10',`b_11',`b_12',`b_13',`b_14',`b_15',`b_16',`b_17',`b_18',`b_19',`b_20',`b_21',`b_22',`b_23',`b_24',`b_25',0,`b_26',`b_27',`b_28',`b_29',`b_30',`b_31',`b_32',`b_33',`b_34',`b_35',`b_36',`b_37',`b_38',`b_39')
	mat colnames mat1_etwfe = T-26 T-25 T-24 T-23 T-22 T-21 T-20 T-19 T-18 T-17 T-16 T-15 T-14 T-13 T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12 T+13
	matrix input mat2_etwfe = (`v_1',`v_2',`v_3',`v_4',`v_5',`v_6',`v_7',`v_8',`v_9',`v_10',`v_11',`v_12',`v_13',`v_14',`v_15',`v_16',`v_17',`v_18',`v_19',`v_20',`v_21',`v_22',`v_23',`v_24',`v_25',0,`v_26',`v_27',`v_28',`v_29',`v_30',`v_31',`v_32',`v_33',`v_34',`v_35',`v_36',`v_37',`v_38',`v_39')
	mat colnames mat2_etwfe = T-26 T-25 T-24 T-23 T-22 T-21 T-20 T-19 T-18 T-17 T-16 T-15 T-14 T-13 T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12 T+13

	* Event study
	event_plot mat1_etwfe#mat2_etwfe, stub_lag(T+#) stub_lead(T-#) ///
		   together plottype("scatter") trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("87 157 28")) lag_ci_opt1(color("87 157 28"))

	graph export "04_Figures/$muestra/event_study_`depvar'_etwfe.pdf", replace
	
	* Connected event study
	event_plot mat1_etwfe#mat2_etwfe, stub_lag(T+#) stub_lead(T-#) ///
	       together trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("87 157 28")) lag_ci_opt1(color("87 157 28 %45"))
		   
	graph export "04_Figures/$muestra/event_study_`depvar'_etwfe_connected.pdf", replace
	
	* Connected event study	- paper
	event_plot mat1_etwfe#mat2_etwfe, stub_lag(T+#) stub_lead(T-#) ///
	       together trimlead(24) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-24(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("87 157 28")) lag_ci_opt1(color("87 157 28 %45"))
		   
	graph export "04_Figures/$muestra/event_study_`depvar'_etwfe_connected_paper.pdf", replace
	

	
	
	********************************************
	* De Chaisemartin & d'Haultfoeuille (2020) *
	********************************************

	use "01_Data/03_Working/event_study_rpci.dta", clear
	
	* did_multiplegt specification
	did_multiplegt `depvar' download_monthly periodo_monthly rpci_vig, ///
			   first robust_dynamic dynamic(12) placebo(24) breps(250) cluster(idnss) seed(541314)
	*did_multiplegt `depvar' idnss periodo_monthly rpci_vig, ///
	*		   first robust_dynamic dynamic(12) placebo(24) breps(250) cluster(idnss) seed(541314)
			   
	* Create matrix
	matrix define mat1_dcdh = e(didmgt_estimates)
	matrix define mat2_dcdh = e(didmgt_variances)
			   
	* Save matrices with the average treatment effect, its standard error and p-value
	mat b_dcdh  = e(effect_average)
	matrix colnames b_dcdh = RPCI
	estadd mat b_dcdh
	
	mat se_dcdh = e(se_effect_average)
	matrix colnames se_dcdh = RPCI
	estadd mat se_dcdh
	
	mat p_dcdh = 2*(1-normal(abs(e(effect_average)/e(se_effect_average))))
	matrix colnames p_dcdh = RPCI
	estadd mat p_dcdh

	estadd scalar obs = e(N_effect_average) 
	estadd scalar obs_switch = e(N_switchers_effect_average)
	
	quietly summ `depvar'
	estadd scalar dep_mean = r(mean)
	
	* Define decimals for output table
	if "`depvar'" == "sal_cierre" | "`depvar'" == "sal_formal" {
		local dec_b = 1
		local dec_se = 2
		local num_se = 3
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
	
	esttab using "03_Tables/$muestra/dcdh_`depvar'.tex", replace $stars nomtitle nolines ///
	cells("b_dcdh(fmt(%12.`dec_b'fc) star pvalue(p_dcdh))" "se_dcdh(fmt(%`num_se'.`dec_se'fc) par)") ///
	stats(obs obs_switch dep_mean, ///
	labels("\midrule Observations" "Switchers" "Dep. Var. Mean") ///
	fmt(%12.0fc %12.0fc %12.`dec_b'fc))
	
	
// 	* Save average treatment effect in a TeX
// 	local ate_dcdh: display %12.`dec_b'fc e(didmgt_estimates)[rownumb(e(didmgt_estimates),"Average"),1]
// 	file open ate_dcdh using "03_Tables/$muestra/ate_dcdh_`depvar'.tex", write replace
// 	file write ate_dcdh "`ate_dcdh'"
// 	file close ate_dcdh
//	
// 	local ate_se_dcdh: display %`num_se'.`dec_se'fc e(didmgt_estimates)[rownumb(e(didmgt_variances),"Average"),1]
// 	file open ate_se_dcdh using "03_Tables/$muestra/ate_se_dcdh_`depvar'.tex", write replace
// 	file write ate_se_dcdh "(`ate_se_dcdh')"
// 	file close ate_se_dcdh

	* Event study	   
	event_plot mat1_dcdh#mat2_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
	       together plottype("scatter") trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134"))

	graph export "04_Figures/$muestra/event_study_`depvar'_dcdh.pdf", replace
	
	* Connected event study	   
	event_plot mat1_dcdh#mat2_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
		   together trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45"))

	graph export "04_Figures/$muestra/event_study_`depvar'_dcdh_connected.pdf", replace
	
	* Connected event study	- paper
	event_plot mat1_dcdh#mat2_dcdh, stub_lag(Effect_#) stub_lead(Placebo_#) ///
		   together trimlead(24) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-24(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45"))

	graph export "04_Figures/$muestra/event_study_`depvar'_dcdh_connected_paper.pdf", replace
	

		   

	************************
	* Sun & Abraham (2021) *
	************************
	
	sort idnss
	preserve
	tempfile tmp
	bysort idnss: keep if _n == 1
	sample 10
	sort idnss
	save `tmp'
	restore
	merge m:1 idnss using `tmp', gen(sample_merge)
	keep if sample_merge == 3
	drop sample_merge
	
	*preserve

	* Create dummies for each lag and lead
	forvalues k = 26(-1)2 {
	gen g_`k' = time_since_treated == -`k'
	}
	forvalues k = 0/13 {
	 gen g`k' = time_since_treated == `k'
	}

	* Gen dummy to identify controls
	gen control = 1 - treated
	replace download_monthly = . if control == 1

	* eventstudyinteract specification
	eventstudyinteract `depvar' g_* g0-g13, cohort(download_monthly) control_cohort(control) absorb(i.idnss i.periodo_monthly) vce(cluster idnss)

	* Create mat
	forvalue i=1(1)39 {
	local b_`i'=e(b_iw)[1,`i']
	local v_`i'=e(V_iw)[`i',`i']
	}

	matrix input mat1_sa = (`b_1',`b_2',`b_3',`b_4',`b_5',`b_6',`b_7',`b_8',`b_9',`b_10',`b_11',`b_12',`b_13',`b_14',`b_15',`b_16',`b_17',`b_18',`b_19',`b_20',`b_21',`b_22',`b_23',`b_24',`b_25',0,`b_26',`b_27',`b_28',`b_29',`b_30',`b_31',`b_32',`b_33',`b_34',`b_35',`b_36',`b_37',`b_38',`b_39')
	mat colnames mat1_sa = T-26 T-25 T-24 T-23 T-22 T-21 T-20 T-19 T-18 T-17 T-16 T-15 T-14 T-13 T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12 T+13

	matrix input mat2_sa = (`v_1',`v_2',`v_3',`v_4',`v_5',`v_6',`v_7',`v_8',`v_9',`v_10',`v_11',`v_12',`v_13',`v_14',`v_15',`v_16',`v_17',`v_18',`v_19',`v_20',`v_21',`v_22',`v_23',`v_24',`v_25',0,`v_26',`v_27',`v_28',`v_29',`v_30',`v_31',`v_32',`v_33',`v_34',`v_35',`v_36',`v_37',`v_38',`v_39')
	mat colnames mat2_sa = T-26 T-25 T-24 T-23 T-22 T-21 T-20 T-19 T-18 T-17 T-16 T-15 T-14 T-13 T-12 T-11 T-10 T-9 T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2 T+3 T+4 T+5 T+6 T+7 T+8 T+9 T+10 T+11 T+12 T+13
		   
	* Event study	   
	event_plot mat1_sa#mat2_sa, stub_lag(T+#) stub_lead(T-#) ///
		   together plottype("scatter") trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 66 14")) lag_ci_opt1(color("255 66 14"))

	graph export "04_Figures/$muestra/event_study_`depvar'_sa.pdf", replace
	
	* Connected event study	   
	event_plot mat1_sa#mat2_sa, stub_lag(T+#) stub_lead(T-#) ///
		   together trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 66 14")) lag_ci_opt1(color("255 66 14 %45"))

	graph export "04_Figures/$muestra/event_study_`depvar'_sa_connected.pdf", replace
	
	* Connected event study	- paper
	event_plot mat1_sa#mat2_sa, stub_lag(T+#) stub_lead(T-#) ///
		   together trimlead(24) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-24(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("255 66 14")) lag_ci_opt1(color("255 66 14 %45"))

	graph export "04_Figures/$muestra/event_study_`depvar'_sa_connected_paper.pdf", replace
	
	
		   
	*******************************
	* Callaway & Sant'Anna (2021) *
	*******************************

// 	preserve
//	
// 	* csdid specification
// 	csdid `depvar' rpci_vig, time(periodo_monthly) gvar(download_monthly) agg(event) method(dripw) notyet long reps(250) rseed(624522) cluster(idnss)
//
// 	* Create matrix
// 	matrix define mat1_cs = e(b)
// 	matrix define mat2_cs = e(V)
//
// 	* Event study	   
// 	event_plot mat1_cs#mat2_cs, stub_lag(T+#) stub_lead(T-#) ///
// 		   together plottype("scatter") trimlead(12) trimlag(12) ///
// 		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
// 		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
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
// 	event_plot mat1_twfe#mat2_twfe mat1_dcdh#mat2_dcdh mat1_sa#mat2_sa mat1_cs#mat2_cs, ///
// 		   stub_lag(T+# Effect_# T+# T+#) stub_lead(T-# Placebo_# T-# T-#) ///
// 		   trimlead(12) trimlag(12) together plottype("scatter") noautolegend ///
// 		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
// 		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
// 		   legend(order(1 "TWFE" 3 "de Chaisemartin & d'Haultfoeuille" 5 "Sun & Abraham" 7 "Callaway & Sant'Anna")) ///
// 		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
// 		   title("")) ///
// 		   lag_opt1(msymbol(Oh) color("0 69 134")) lag_ci_opt1(color("0 69 134")) ///
// 		   lag_opt2(msymbol(Dh) color("255 211 32")) lag_ci_opt2(color("255 211 32")) ///
// 		   lag_opt3(msymbol(Th) color("87 157 28")) lag_ci_opt3(color("87 157 28")) ///
// 		   lag_opt4(msymbol(Sh) color("255 66 14")) lag_ci_opt4(color("255 66 14")) ///
// 		   perturb(-0.3(0.2)0.3)
		   
	* Event study
	event_plot mat1_dcdh#mat2_dcdh mat1_twfe#mat2_twfe mat1_etwfe#mat2_etwfe mat1_sa#mat2_sa, ///
		   stub_lag(Effect_# T+# T+# T+#) stub_lead(Placebo_# T-# T-# T-#) ///
		   trimlead(12) trimlag(12) together plottype("scatter") noautolegend ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   legend(order(1 "de Chaisemartin & d'Haultfoeuille" 3 "TWFE" 5 "ETWFE" 7 "Sun & Abraham")) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(Oh) color("0 69 134")) lag_ci_opt1(color("0 69 134")) ///
		   lag_opt2(msymbol(Dh) color("255 211 32")) lag_ci_opt2(color("255 211 32")) ///
		   lag_opt3(msymbol(Th) color("87 157 28")) lag_ci_opt3(color("87 157 28")) ///
		   lag_opt4(msymbol(Sh) color("255 66 14")) lag_ci_opt4(color("255 66 14")) ///
		   perturb(-0.3(0.2)0.3)
		   
	graph export "04_Figures/$muestra/event_study_`depvar'.pdf", replace
	
	* Event study withtout etwfe
	event_plot mat1_dcdh#mat2_dcdh mat1_twfe#mat2_twfe mat1_sa#mat2_sa, ///
		   stub_lag(Effect_# T+# T+#) stub_lead(Placebo_# T-# T-#) ///
		   trimlead(12) trimlag(12) together plottype("scatter") noautolegend ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   legend(order(1 "de Chaisemartin & d'Haultfoeuille" 3 "TWFE" 5 "Sun & Abraham")) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(Oh) color("0 69 134")) lag_ci_opt1(color("0 69 134")) ///
		   lag_opt2(msymbol(Dh) color("255 211 32")) lag_ci_opt2(color("255 211 32")) ///
		   lag_opt3(msymbol(Sh) color("255 66 14")) lag_ci_opt3(color("255 66 14")) ///
		   perturb(-0.3(0.2)0.3)
		   
	graph export "04_Figures/$muestra/event_study_`depvar'_wo_etwfe.pdf", replace
	
	* Connected event study
		event_plot mat1_dcdh#mat2_dcdh mat1_twfe#mat2_twfe, ///
		   stub_lag(Effect_# T+#) stub_lead(Placebo_# T-#) ///
		   together trimlead(12) trimlag(12) noautolegend ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   legend(order(1 "de Chaisemartin & d'Haultfoeuille" 3 "TWFE")) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(Oh) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45")) ///
		   lag_opt2(msymbol(Dh) color("255 211 32")) lag_ci_opt2(color("255 211 32 %45"))
		   
	graph export "04_Figures/$muestra/event_study_`depvar'_connected.pdf", replace
			   
}
		   