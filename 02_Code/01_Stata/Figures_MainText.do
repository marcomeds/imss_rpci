clear
include "$CODE/pathnames"

********************************************************************************
**** FIGURE 1: EFFECTS OF THE INTRODUCTION OF FACEBOOK ON STUDENT MENTAL HEALTH

use "$INTERMEDIATE/ACHA_clean.dta" if sample_main==1, clear

capture program drop generate_labeled_var
program generate_labeled_var
    syntax, yvar(string)

    capture gen T_`yvar' = T // Capture in case variable already exists
    local label: variable label `yvar'
    label var T_`yvar' "`label'"
end

* Controls excluding the fbexpgrp and survey_wave fixed-effects
global controls i.region age age_sq female i.year_in_school white black hispanic asian indian other_race i.international // could also use the winsorized version of age

* Outcome variables
local mentalhealth_all q40a q40b q40c q40d q40e q40f q40g q43a2 q43a3 q43a5 q43a7 q43a17 q41a q41b q41c
local mentalhealth_noserv q40a q40b q40c q40d q40e q40f q40g q43a2 q43a3 q43a5 q43a7 q43a17
local depression_symptoms q40a q40b q40c q40d q40e q40f q40g q43a7 
local allelse_mental_symptoms q43a2 q43a3 q43a5 q43a17
local physicalhealth_all q43a1 q43a4 q43a6 q43a8 q43a9 q43a10 q43a11 q43a12 q43a13 q43a14 q43a15 q43a16 q43a19 q43a20 q43a21 q43a22 q43a23 q43a24 q43a25 q43a26 q43a27 q43a28 q43a29 
local depression_services q41a q41b q41c
local all_var_group `mentalhealth_all' `physicalhealth_all'

foreach i in  mh_risk {
	summ `i' if T==0
	gen std_`i'=(`i'-r(mean))/r(sd)
}

foreach yvar in `all_var_group' {
	generate_labeled_var, yvar(`yvar')
	
	gen T_std_`yvar' = T 
	local label: variable label `yvar'
    label var T_std_`yvar' "`label'"
}

foreach yvar in eq_index_mh_all eq_index_dep eq_index_aem eq_index_ph_all eq_index_dep_serv eq_index_mh_noserv internet_not_applicable std_mh_risk {
	generate_labeled_var, yvar(`yvar')
}

* Generate expansion group dummies to add to regression
tab fbexp, gen(fbexp_dummy)
drop fbexp_dummy1 // make the earliest expansion group the left-out category

* Regression (main specification)
foreach y in eq_index_mh_all eq_index_dep eq_index_aem eq_index_ph_all eq_index_dep_serv eq_index_mh_noserv std_mh_risk {
	if "`y'" == "eq_index_ph_all" {
		qui reg eq_index_mh_all T i.uni_id i.survey_wave $controls
		est store eqn1
		qui reg eq_index_ph_all T i.uni_id i.survey_wave $controls
		est store eqn2
		suest eqn1 eqn2 , cluster(uni_id)
		test [eqn2_mean]T=[eqn1_mean]T
		local diff_pv = `r(p)'
		display `diff_pv'
	}
	else {
		local diff_pv = 0
	}
	reg `y' T_`y' i.uni_id i.survey_wave $controls, vce(cluster uni_id)
	est store `y'_spec3
	estwrite _all using "$TEMP/`y'_spec3", replace
	sum `y' if T==0
	estadd local y_mean = 0, replace
	estadd local fbexp_fe "", replace
	estadd local survey_fe "$\checkmark$", replace
	estadd local has_controls "$\checkmark$", replace
	estadd local uni_fe "$\checkmark$", replace
	estadd local tv_baseline_controls "", replace
	estadd scalar p1 = `diff_pv' , replace
	estadd local linear_trends = "" , replace
	estadd local quadratic_trends = "" , replace
}

* Run regressions using main specification
* Standardized
foreach outcome_group in mentalhealth_all physicalhealth_all depression_services {
	foreach y in ``outcome_group'' {
		reghdfe std_`y' T_std_`y' $controls, a(survey_wave uni_id) vce(cluster uni_id)
		est store std_`y'
	}

	estwrite _all using "$TEMP/`outcome_group'_st", replace
	est clear
}

label var T_eq_index_mh_all "{bf:Index Poor Mental Health}"
label var T_eq_index_dep "{bf:Index Symptoms Depression}"
label var T_eq_index_aem "{bf:Index Symptoms Other Conditions}"
label var T_eq_index_ph_all "{bf:Index Poor Physical Health}"
label var T_eq_index_dep_serv "{bf:Index Depression Services}"

estread _all using "$TEMP/mentalhealth_all_st"
estread _all using "$TEMP/eq_index_mh_all_spec3"
estread _all using "$TEMP/eq_index_dep_spec3"
estread _all using "$TEMP/eq_index_aem_spec3"

estread _all using "$TEMP/physicalhealth_all_st"
estread _all using "$TEMP/eq_index_ph_all_spec3"

estread _all using "$TEMP/depression_services_st"
estread _all using "$TEMP/eq_index_dep_serv_spec3"

coefplot (std_q40a, keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(std_q40b, keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(std_q40c , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(std_q40d , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(std_q40e , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(std_q40f , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(std_q40g , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(std_q43a7 , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(eq_index_dep_spec3 , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(std_q43a2 , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(std_q43a3 , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(std_q43a5 , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(std_q43a17 , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(eq_index_aem_spec3 , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(std_q41a, keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(std_q41b, keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(std_q41c , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(eq_index_dep_serv_spec3, keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(eq_index_mh_all_spec3, keep(T_*) mcolor(navy) ciopts(lcolor(navy))), ///
		bgcolor(white) plotregion(color(white)) graphregion(color(white)) ///
		groups(T_std_q40a T_std_q40b T_std_q40c T_std_q40d T_std_q40e T_std_q40f T_std_q40g T_std_q43a7 T_eq_index_dep = `""Depression" "Symptoms""'  T_std_q43a2 T_std_q43a2 T_std_q43a3 T_std_q43a5 T_std_q43a17 T_eq_index_aem = `""Other" "Symptoms""' T_std_q41a T_std_q41b T_std_q41c T_eq_index_dep_serv = `""Depression" "Services""' T_eq_index_mh_all = `" "', labcolor(black) labsize(small)) ///
		yline(10, lcolor(gs7%40) lwidth(medthin) lpattern(longdash)) ///
		yline(16, lcolor(gs7%40) lwidth(medthin) lpattern(longdash)) ///
		yline(21, lcolor(gs7%40) lwidth(medthin) lpattern(longdash)) ///
		xline(0, lwidth(thin)) nooffsets grid(w) ///
		xtitle("Treatment effect" "(standard deviations)") legend(off) coeflabels(, labsize(vsmall)) ///
		xscale(r(-0.15 0.15)) xtick(-0.15(0.05)0.15) xlabel(-0.15 -0.10 -0.05 0 0.05 0.10 0.15, labsize(small))

graph export "$REPLICATION/Figure 1.pdf", replace

********************************************************************************
**** FIGURE 2: EFFECTS OF FACEBOOK ON THE INDEX OF POOR MENTAL HEALTH BASED ON 
**** DISTANCE TO/FROM FACEBOOK INTRODUCTION

* TWFE OLS

use "$INTERMEDIATE/ACHA_clean.dta" if sample_main==1, clear

global controls i.region age age_sq female i.year_in_school white black hispanic asian indian other_race i.international

preserve

drop if time_intro_semester_with_zero<-8 | time_intro_semester_with_zero>5

summ time_intro_semester_with_zero
replace time_intro_semester_with_zero=time_intro_semester_with_zero-r(min)

reg eq_index_mh_all ib7.time_intro_semester_with_zero i.fbexpgrp i.survey_wave , vce(cluster uni_id)

forvalues i=1(1)11 {
	local b_`i'=e(b)[1,`i']
}

matrix define mat1_ols= (`b_1',`b_2',`b_3',`b_4',`b_5',`b_6',`b_7',`b_8',`b_9',`b_10',`b_11')
mat colnames mat1_ols =  T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2

forvalues i=1(1)11 {
	local v_`i'=e(V)[`i',`i']
}

matrix input mat2_ols = (`v_1',`v_2',`v_3',`v_4',`v_5',`v_6',`v_7',`v_8',`v_9',`v_10',`v_11')
mat colnames mat2_ols = T-8 T-7 T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2

gen t=_n
replace t=t-9
replace t=. if t>5
gen b=.
gen se=.

foreach x in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 {
	local z=`x'+1
	replace b=_b[`x'.time_intro_semester_with_zero] in `z'
	replace se=_se[`x'.time_intro_semester_with_zero] in `z'
}

gen upper95=b+1.96*se
gen lower95=b-1.96*se

twoway  (rcap upper95 lower95 t , lcolor(black)) ///
		(scatter b t , msymbol(D) mcolor(black)), ///
		bgcolor(white) plotregion(color(white)) graphregion(color(white)) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) legend(off) ///
		yline(0, lpattern(solid) lcolor(gs12) lwidth(thin)) legend(off) ///
		yscale(r(-0.2 0.2)) ytick(-0.2(0.1)0.2) ///
		ylabel(-0.2 -0.1 0 0.1 0.2) ///
		xscale(r(-8.5 5.5)) xtick(-8(1)5) xlabel(-8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5) ///
		ytitle("Coefficient", height(6) size(medlarge)) title("Two Way Fixed Effect Model") ///
		xtitle("Semester to/from FB Introduction", height(6) size(medlarge)) xsize(5) ysize(4)
		
graph save "$TEMP/event_study_TWFE", replace

restore

***********************
*** Borusyak et al. ***
*********************** 

* For this estimator, it's important to notice that the more pre-periods one adds, the more the standard errors on the pre-period coefficients explode. So, we can't use all pre-periods. We need to use only a subset of them.

preserve

drop if time_intro_semester_with_zero<-8 | time_intro_semester_with_zero>5

gen respondent_id=1
replace respondent_id=sum(respondent_id)

gen time_treated=9 if fbexpgrp==1 
replace time_treated=10  if fbexpgrp==2
replace time_treated=11  if fbexpgrp==3
replace time_treated=12  if fbexpgrp==4

did_imputation eq_index_mh_all respondent_id survey_wave time_treated, fe(fbexpgrp survey_wave) autosample horizons(0 1 2) pretrends(4) cluster(uni_id)

matrix define mat1_bor=e(b)
mat colnames mat1_bor= T+0 T+1 T+2 T-1 T-2 T-3 T-4

forvalues i=1(1)7 {
	local v_`i'=e(V)[`i',`i']
}

matrix input mat2_bor= (`v_1',`v_2',`v_3',`v_4',`v_5',`v_6',`v_7')
mat colnames mat2_bor= T+0 T+1 T+2 T-1 T-2 T-3 T-4 

event_plot mat1_bor#mat2_bor, stub_lag(T+#) stub_lead(T-#) trimlag(2) ciplottype(rcap) plottype(scatter)  ///
		graph_opt(bgcolor(white) plotregion(color(white)) graphregion(color(white)) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) legend(off) ///
		yline(0, lpattern(solid) lcolor(gs12) lwidth(thin)) legend(off) ///
		yscale(r(-0.3 0.6)) ytick(-0.2(0.2)0.6) ///
		ylabel(-0.2 0 0.2 0.4 0.6, labsize(small)) ///
		xscale(r(-8.5 2.5)) xtick(-8(1)2) xlabel(-8 -7 -6 -5 -4 -3 -2 -1 0 1 2, labsize(small)) ///
		ytitle("Coefficient", height(6) size(small)) title("Borusyak, Jaravel, and Spiess (2021)", size(small)) ///
		xtitle("Semester to/from FB Introduction", height(6) size(small)) xsize(5) ysize(4)) ///
		lag_opt(msymbol(D) mcolor(black) msize(small)) lead_opt(msymbol(D) mcolor(black) msize(small)) ///
		lag_ci_opt(lcolor(black) lwidth(medthin)) lead_ci_opt(lcolor(black) lwidth(medthin))

graph save "$TEMP/event_study_BJS", replace

******************************
*** Callaway and Sant'Anna ***
******************************

csdid eq_index_mh_all, time(survey_wave) gvar(time_treated) agg(event) method(dripw) notyet long rseed(1) cluster(uni_id)

estat all

matrix define mat1_cs=e(b)
mat colnames mat1_cs= T-6 T-5 T-4 T-3 T-2 T-1 T+0 T+1 T+2

matrix define mat2_cs = e(V)

event_plot mat1_cs#mat2_cs , stub_lag(T+#) stub_lead(T-#) trimlag(2) ciplottype(rcap) plottype(scatter) ///
		graph_opt(bgcolor(white) plotregion(color(white)) graphregion(color(white)) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) legend(off) ///
		yline(0, lpattern(solid) lcolor(gs12) lwidth(thin)) legend(off) ///
		yscale(r(-0.3 0.6)) ytick(-0.2(0.2)0.6) ///
		ylabel(-0.2 0 0.2 0.4 0.6, labsize(small)) ///
		xscale(r(-8.5 2.5)) xtick(-8(1)2) xlabel(-8 -7 -6 -5 -4 -3 -2 -1 0 1 2, labsize(small)) ///
		ytitle("Coefficient", height(6) size(small)) title("Callaway and Sant'Anna (2021)", size(small)) ///
		xtitle("Semester to/from FB Introduction", height(6) size(small)) xsize(5) ysize(4)) ///
		lag_opt(msymbol(D) mcolor(black) msize(small)) lead_opt(msymbol(D) mcolor(black) msize(small)) ///
		lag_ci_opt(lcolor(black) lwidth(medthin)) lead_ci_opt(lcolor(black) lwidth(medthin))

graph save "$TEMP/event_study_CS", replace		

*****************************************
*** DeChaisemartin and D'Haultfeuille ***
*****************************************

gen T_DCDH=0
replace T_DCDH=1 if fbexpgrp==1 & survey_wave>=9
replace T_DCDH=1 if fbexpgrp==2 & survey_wave>=10
replace T_DCDH=1 if fbexpgrp==3 & survey_wave>=11
replace T_DCDH=1 if fbexpgrp==4 & survey_wave>=12

did_multiplegt eq_index_mh_all fbexpgrp survey_wave T_DCDH, robust_dynamic dynamic(2) placebo(6) breps(500) cluster(uni_id) jointtestplacebo seed(1) covariances controls(age age_sq) // Adding controls to produce SE on the t+2 estimate

forvalues i=1(1)9 {
	local m_`i'=e(estimates)[`i',1]
	display `m_`i''
	local v_`i'=e(variances)[`i',1]
	display `v_`i''
}

matrix input mat1_dcdh= (`m_1',`m_2',`m_3',0,`m_4',`m_5',`m_6',`m_7',`m_8',`m_9')
mat colnames mat1_dcdh= T+0 T+1 T+2 T-1 T-2 T-3 T-4 T-5 T-6

matrix input mat2_dcdh= (`v_1',`v_2',`v_3',0,`v_4',`v_5',`v_6',`v_7',`v_8',`v_9')
mat colnames mat2_dcdh= T+0 T+1 T+2 T-1 T-2 T-3 T-4 T-5 T-6

event_plot mat1_dcdh#mat2_dcdh, stub_lag(T+#) stub_lead(T-#) ciplottype(rcap) plottype(scatter) ///
		graph_opt(bgcolor(white) plotregion(color(white)) graphregion(color(white)) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) legend(off) ///
		yline(0, lpattern(solid) lcolor(gs12) lwidth(thin)) legend(off) ///
		yscale(r(-0.3 0.6)) ytick(-0.2(0.2)0.6) ///
		ylabel(-0.2 0 0.2 0.4 0.6, labsize(small)) ///
		xscale(r(-8.5 2.5)) xtick(-8(1)2) xlabel(-8 -7 -6 -5 -4 -3 -2 -1 0 1 2, labsize(small)) ///
		ytitle("Coefficient", height(6) size(small)) title("De Chaisemartin and D'Haultfeuille (2020)", size(small)) ///
		xtitle("Semester to/from FB Introduction", height(6) size(small)) xsize(5) ysize(4)) ///
		lag_opt(msymbol(D) mcolor(black) msize(small)) lead_opt(msymbol(D) mcolor(black) msize(small)) ///
		lag_ci_opt(lcolor(black) lwidth(medthin)) lead_ci_opt(lcolor(black) lwidth(medthin))

graph save "$TEMP/event_study_DCDH", replace		

restore

***********************
*** Sun and Abraham ***
***********************

preserve

drop if survey_wave>=12 // Block situations when all units have been treated

gen time_treated_sa=9 if fbexpgrp==1 
replace time_treated_sa=10  if fbexpgrp==2
replace time_treated_sa=11  if fbexpgrp==3
replace time_treated_sa=.  if fbexpgrp==4

gen time_to_treat_sa = survey_wave - time_treated_sa
replace time_to_treat_sa = 0 if missing(time_treated_sa)

gen treat = !missing(time_treated_sa)
gen never_treat = missing(time_treated_sa)

forvalues t = -8(1)2 {
	if `t' < -1 {
		local tname = abs(`t')
		g g_m`tname' = time_to_treat_sa == `t'
	}
	else if `t' >= 0 {
		g g_`t' = time_to_treat_sa == `t'
	}
}

eventstudyinteract eq_index_mh_all g_*, cohort(time_treated_sa) control_cohort(never_treat) absorb(i.survey_wave i.fbexpgrp) vce(cluster uni_id)

forvalue i=1(1)10 {
	local m_`i'=e(b_iw)[1,`i']
	local v_`i'=e(V_iw)[1,`i']
}

matrix input mat1_sa= (`m_1',`m_2',`m_3',`m_4',`m_5',`m_6',`m_7',0,`m_8',`m_9',`m_10')
mat colnames mat1_sa= g_m8 g_m7 g_m6 g_m5 g_m4 g_m3 g_m2 g_m1 g_0 g_1 g_2

matrix input mat3_sa= (`v_1',`v_2',`v_3',`v_4',`v_5',`v_6',`v_7',0,`v_8',`v_9',`v_10')
mat colnames mat3_sa= g_m8 g_m7 g_m6 g_m5 g_m4 g_m3 g_m2 g_m1 g_0 g_1 g_2

event_plot mat1_sa#mat3_sa, stub_lag(g_#) stub_lead(g_m#) trimlag(2) ciplottype(rcap) plottype(scatter) ///
		graph_opt(bgcolor(white) plotregion(color(white)) graphregion(color(white)) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) legend(off) ///
		yline(0, lpattern(solid) lcolor(gs12) lwidth(thin)) legend(off) ///
		yscale(r(-0.3 0.6)) ytick(-0.2(0.2)0.6) ///
		ylabel(-0.2 0 0.2 0.4 0.6, labsize(small)) ///
		xscale(r(-8.5 2.5)) xtick(-8(1)2) xlabel(-8 -7 -6 -5 -4 -3 -2 -1 0 1 2, labsize(small)) ///
		ytitle("Coefficient", height(6) size(small)) title("Sun and Abraham (2021)", size(small)) ///
		xtitle("Semester to/from FB Introduction", height(6) size(small)) xsize(5) ysize(4)) ///
		lag_opt(msymbol(D) mcolor(black) msize(small)) lead_opt(msymbol(D) mcolor(black) msize(small)) ///
		lag_ci_opt(lcolor(black) lwidth(medthin)) lead_ci_opt(lcolor(black) lwidth(medthin))

graph save "$TEMP/event_study_SA", replace

restore

* Combining	  
event_plot mat1_bor#mat2_bor mat1_dcdh#mat2_dcdh mat1_cs#mat2_cs mat1_sa#mat3_sa mat1_ols#mat2_ols , stub_lag(T+# T+# T+# g_# T+#) stub_lead(T-# T-# T-# g_m# T-#) plottype(scatter) ciplottype(rcap) together trimlag(2) noautolegend graph_opt(title("Event study estimators", size(medlarge)) xtitle("Periods since the event") ytitle("Average effect (std. dev.)") xlabel(-8 -7 -6 -5 -4 -3 -2 -1 0 1 2, labsize(small)) ylabel(-0.2 0 0.2 0.4 0.6, labsize(small)) legend(order(1 "Borusyak et al." 3 "de Chaisemartin-D'Haultfoeuille" 5 "Callaway-Sant'Anna" 7 "Sun-Abraham" 9 "TWFE OLS") rows(3) region(style(none))) xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal))) lag_opt1(msymbol(O) color(dkorange)) lag_ci_opt1(color(dkorange)) lag_opt2(msymbol(+) color(cranberry)) lag_ci_opt2(color(cranberry)) lag_opt3(msymbol(Dh) color(navy)) lag_ci_opt3(color(navy)) 	lag_opt4(msymbol(Th) color(forest_green)) lag_ci_opt4(color(forest_green)) lag_opt5(msymbol(Sh) color(black)) lag_ci_opt5(color(black)) perturb(-0.325(0.13)0.325)

graph export "$REPLICATION/Figure 2.pdf", replace

********************************************************************************
**** FIGURE 3: HETEROGENEOUS EFFECTS BY PREDICTED SUSCEPTIBILITY TO MENTAL ILLNESS

use "$INTERMEDIATE/ACHA_clean.dta" if sample_main==1, clear

global controls i.region age age_sq female i.year_in_school white black hispanic asian indian other_race i.international

foreach i in mh_noserv dep_serv ds {
	if "`i'"=="mh_noserv" {
		local title = "Index Symptoms Poor Mental Health"
	}
	if "`i'"=="dep_serv" {
		local title = "Index Depression Services"
	}
	if "`i'"=="ds" {
		local title = "Index Downstream Effects"
	}
	
	local lasso_type = "mh_risk_quintile"
	local lasso_name = "predictedMH"
	local x_title = "Quintile of Predicted Susceptibility to Mental Illness"

	* Regression
	qui reg eq_index_`i' T#i.`lasso_type' i.`lasso_type' i.uni_id i.survey_wave $controls, vce(cluster uni_id)
		
	* Store coeffs
	capture drop A1-A5
	matrix A = J(5,3,1)
	forval k = 1/5 {
		matrix A[`k', 1] = _b[1.T#`k'.`lasso_type'] 
		matrix A[`k', 2] = _se[1.T#`k'.`lasso_type'] 
		matrix A[`k', 3] = `k'
	}
	svmat A
	gen A4 = A1-1.96*A2
	gen A5 = A1+1.96*A2

	* Plot
	twoway (scatter A1 A3 if A1!=., mc(black)) (rcap A5 A4 A3 if A1!=., lc(black)), /// 
		graphr(c(white)) xtitle("`x_title'", ///
		height(6) size(small)) ytitle("Coefficient", height(6) size(small)) title(`title') ///
		yscale(r(-0.05 0.20)) ytick(-0.05(0.05)0.20) ylabel(-0.05 0 0.05 0.1 0.15 0.20, labsize(small)) ///
		xscale(r(0.5 5.5)) xtick(1(1)5) xlabel(1 2 3 4 5, labsize(small)) yline(0, lc(gs10)) legend(off)
	
	graph save "$TEMP/HTE`lasso_name'_`i'.gph", replace
}

* Combine graph - predicted using even been diagnosed
graph combine "$TEMP/HTEpredictedMH_mh_noserv.gph" "$TEMP/HTEpredictedMH_dep_serv.gph" ///
	"$TEMP/HTEpredictedMH_ds.gph", graphr(c(white)) xsize(11) ysize(9) scale(0.8)
graph export "$REPLICATION/Figure 3.pdf", replace

********************************************************************************
**** FIGURE 4: EFFECT ON POOR MENTAL HEALTH BY LENGTH OF EXPOSURE TO FACEBOOK

use "$INTERMEDIATE/ACHA_clean.dta" if sample_main==1, clear

* Controls excluding the fbexpgrp and survey_wave fixed-effects
global controls i.region age age_sq female i.year_in_school white black hispanic asian indian other_race i.international

* Outcome variables
local mentalhealth_all q40a q40b q40c q40d q40e q40f q40g q43a2 q43a3 q43a5 q43a7 q43a17 q41a q41b q41c
local mentalhealth_noserv q40a q40b q40c q40d q40e q40f q40g q43a2 q43a3 q43a5 q43a7 q43a17
local depression_symptoms q40a q40b q40c q40d q40e q40f q40g q43a7 
local allelse_mental_symptoms q43a2 q43a3 q43a5 q43a17
local physicalhealth_all q43a1 q43a4 q43a6 q43a8 q43a9 q43a10 q43a11 q43a12 q43a13 q43a14 q43a15 q43a16 q43a19 q43a20 q43a21 q43a22 q43a23 q43a24 q43a25 q43a26 q43a27 q43a28 q43a29 
local depression_services q41a q41b q41c
local all_var_group `mentalhealth_all' `physicalhealth_all'

gen num_semesters_in_college=.
replace num_semesters_in_college=2*year_in_school-1 if fall_survey==1
replace num_semesters_in_college=2*year_in_school if fall_survey==0

drop time_intro_semester // We need to re-create time into semester because the observations that should be assigned a value of missing in this specification are different from the observations that had to be assigned a value of missing in the previous specification
gen time_intro_semester=.

replace time_intro_semester=survey_wave-9 if fbexpgrp==1
replace time_intro_semester=survey_wave-10 if fbexpgrp==2
replace time_intro_semester=survey_wave-11 if fbexpgrp==3
replace time_intro_semester=survey_wave-12 if fbexpgrp==4

capture drop dist_fb_introduction
gen dist_fb_introduction=time_intro_semester+1
replace dist_fb_introduction=0 if dist_fb_introduction<0

capture drop num_treated_semesters
gen num_treated_semesters=.
replace num_treated_semesters=dist_fb_introduction if dist_fb_introduction<=num_semesters_in_college & dist_fb_introduction!=. & num_semesters_in_college!=.
replace num_treated_semesters=num_semesters_in_college if dist_fb_introduction>num_semesters_in_college & dist_fb_introduction!=. & num_semesters_in_college!=.

* Replace with missings observations that might have been exposed to Facebook prior to college
replace num_treated_semesters=. if survey_wave>=14 & year_in_school==1 // might have been exposed to FB before entering college (including because FB was rolled out to high schools)
replace num_treated_semesters=. if survey_wave>=16 & year_in_school==2 // might have been exposed to FB before entering college

* Replace with missings observations for which we observe only a subset of FB expansion groups
replace num_treated_semesters=. if num_treated_semesters>6

reg eq_index_mh_all i.num_treated_semesters i.uni_id i.survey_wave $controls, vce(cluster uni_id)

preserve

gen t=_n
replace t=t-1
replace t=. if t>5
gen b=.
gen se=.

foreach x in 0 1 2 3 4 5 {
	local z=`x'+1
	if `x'!=0 {
		replace b=_b[`x'.num_treated_semesters] in `z'
		replace se=_se[`x'.num_treated_semesters] in `z'
	}
	else {
		replace b=0 in `z'
		*replace se=_se[_cons] in `z'
	}
}

gen upper=b+1.96*se
gen lower=b-1.96*se

* Figure
twoway  (rcap upper lower t, lcolor(gs4) lwidth(thin)) ///
		(scatter b t, msymbol(D) mcolor(dknavy) msize(small)) ///
		(qfit b t, lpattern(dash) lwidth(thin) lcolor(gs12)), ///
		bgcolor(white) plotregion(color(white)) graphregion(color(white)) legend(off) ///
		yscale(r(-0.02 0.2)) ytick(0(0.5)0.2) ylabel(0 0.1 0.2, labsize(small)) ///
		xscale(r(-0.5 5)) xtick(0(1)5) xlabel( 0 1 2 3 4 5, labsize(small)) ///
		ytitle("Coefficient", height(6) size(small)) ///
		xtitle("Treatment Length in Semesters", height(6) size(small))

graph export "$REPLICATION/Figure 4.pdf", replace	

********************************************************************************
**** FIGURE 5: DOWNSTREAM EFFECTS ON ACADEMIC PERFORMANCE

use "$INTERMEDIATE/ACHA_clean.dta" if sample_main==1, clear

global controls i.region age age_sq female i.year_in_school white black hispanic asian indian other_race i.international

global downstream_effects q44e q44k q44m q44w q44x
global std_downstream_effects std_q44e std_q44k std_q44m std_q44w std_q44x

capture program drop generate_labeled_var
program generate_labeled_var
    syntax, yvar(string)

    capture gen T_`yvar' = T
    local label: variable label `yvar'
    label var T_`yvar' "`label'"
end

foreach yvar in $downstream_effects {
	generate_labeled_var, yvar(`yvar')
	
	gen T_std_`yvar' = T 
	local label: variable label `yvar'
    label var T_std_`yvar' "`label'"
}
generate_labeled_var, yvar(eq_index_ds)
label var T_eq_index_ds "{bf:Index Downstream Effects}"

foreach y in "eq_index_ds" $std_downstream_effects {
	reghdfe `y' T_`y' $controls, a(survey_wave uni_id) vce(cluster uni_id)
	est store reg_`y'
}

* Figure
coefplot (reg_std_q44e, keep(T_*) mcolor(navy) ciopts(lcolor(navy))) ///
		(reg_std_q44k, keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(reg_std_q44m , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(reg_std_q44w , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(reg_std_q44x , keep(T_*) mcolor(navy) ciopts(lcolor(navy))) /// 
		(reg_eq_index_ds, keep(T_*) mcolor(navy) ciopts(lcolor(navy))), ///
		bgcolor(white) plotregion(color(white)) graphregion(color(white)) ///
		xline(0, lwidth(thin)) nooffsets grid(w) ///
		xtitle("Treatment effect" "(standard deviations)") legend(off) ///
		coeflabels("T_std_q44k"=`" "Academic perform depression/anxiety/" "seasonal affect disorder" "', ///
			labsize(normal)) ///	
		xscale(r(-0.15 0.15)) xtick(-0.15(0.05)0.15) xlabel(-0.15 -0.10 -0.05 0 0.05 0.10 0.15, labsize(normal))
graph export "$REPLICATION/Figure 5.pdf", replace

********************************************************************************
**** FIGURE 6: HETEROGENEOUS EFFECTS AS EVIDENCE OF UNFAVORABLE SOCIAL COMPARISONS

use "$INTERMEDIATE/ACHA_clean.dta" if sample_main==1, clear

capture program drop addMainFE
program addMainFE
	estadd local survey_fe "$\checkmark$", replace
	estadd local uni_fe "$\checkmark$", replace
	estadd local has_controls "$\checkmark$", replace
end

global controls age age_sq female i.year_in_school white black hispanic asian indian other_race i.international

* Outcome variables
local mentalhealth_all q40a q40b q40c q40d q40e q40f q40g q43a2 q43a3 q43a5 q43a7 q43a17 q41a q41b q41c

* Background color for graphs
global graph_bgcolor white
global graph_base_settings bgcolor($graph_bgcolor) plotregion(color($graph_bgcolor)) graphregion(color($graph_bgcolor)) ///
	xline(0, lwidth(thin)) nooffsets mcolor(navy) ciopts(lcolor(navy)) grid(w) ///
	xtitle("Interaction Coefficient" "(standard deviations)") legend(off)

* Labels 
label variable T post
gen debt = credit_card_debt > 2 if !missing(credit_card_debt)

* Variables
gen work = work_hrs_week > 1 if !missing(work_hrs_week)
gen volunteer = volunteer_hrs_week > 1 if !missing(work_hrs_week)

gen first_year = 1 if year_in_school==1 
replace first_year = 0 if 1<year_in_school & year_in_school<5
replace first_year = . if missing(year_in_school)
gen first_two_years = 1 if year_in_school==1 | year_in_school==2
replace first_two_years  = 0 if year_in_school==3 | year_in_school==4
replace first_two_years  = . if missing(year_in_school)

* First year immediate
gen first_year_imm = first_year if time_intro_semester<=1

egen medianAge = median(age)
gen ageAboveMed = age > medianAge

* Race 
gen all_race_answers = white + black + hispanic + asian + indian + other_race
gen whiteOnly = white & all_race_answers==1

* Additional variables related to specific channels
gen notFratSor = 1-in_frat_sor
gen offCampusLiving = living_situation>=4 if !missing(living_situation)
egen medianHeight = median(height_inches) if female==0
gen heightAboveMed = height_inches < medianHeight  
gen overweight = rbmi>2 if !missing(rbmi)

gen ind_sc=notFratSor+offCampusLiving+debt+work+overweight

gen above_med_ind_sc=.
summ ind_sc
replace above_med_ind_sc=0 if ind_sc<r(mean)
replace above_med_ind_sc=1 if ind_sc>r(mean) & ind_sc!=.

* Baseline mental health at university level
egen baseUniMhTemp = mean(eq_index_mh_all) if T<9, by(uni_id)
egen baseUniMh = mean(baseUniMhTemp), by(uni_id)
summ baseUniMh, d
gen baseUniMhAboveMed = baseUniMh > r(p50)

* Run heterogeneity
local hetero first_year_imm first_year international ageAboveMed  whiteOnly female heightAboveMed work ///
	volunteer debt notFratSor offCampusLiving  overweight above_med_ind_sc baseUniMhAboveMed
foreach h in `hetero' { 
    quiet: eststo main_spec_`h': areg eq_index_mh_all i.T##i.`h' i.survey_wave $controls, vce(cluster uni_id) a(uni_id)
	quiet: sum eq_index_mh_all if T==0
	estadd scalar y_mean = `r(mean)', replace
	quiet: addMainFE
}

coefplot main_spec_offCampusLiving main_spec_notFratSor main_spec_debt main_spec_work main_spec_overweight main_spec_above_med_ind_sc, ///
	keep(*T#1.offCampusLiving *T#1.notFratSor *T#1.debt *T#1.work *T#1.overweight *T#1.above_med_ind_sc) $graph_base_settings ///
	coeflabels(*T#1.offCampusLiving = `""Post Facebook Introduction x" "Off-campus Living""' *T#1.notFratSor = `""Post Facebook Introduction x" "Not in Fraternity/Sorority""' ///
	*T#1.debt = `""Post Facebook Introduction x" "Credit-card Debt""' ///
	*T#1.work  = `""Post Facebook Introduction x" "Work""' ///
	*T#1.overweight= `""Post Facebook Introduction x" "Overweight""' ///
	*above_med_ind_sc= `""Post Facebook Introduction x" "{bf:Index Social Comparisons}""', labsize(normal)) ///
	xscale(r(-0.08 0.08)) xtick(-0.08(0.04)0.04) xlabel(-0.08 -0.04 0 0.04 0.08, labsize(normal))		 
graph export "$REPLICATION/Figure 6.pdf", replace
