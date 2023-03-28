/*******************************************************************************
@Name: event_study_panel_rpci.do

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

********************************
* Prepare Event Study Database *
********************************
local T = 30
summ time_since_treated
	// since time_since_treated ranges from -25 to 11,
	//  add T = 30 to it so they are all positive
	//  (since factor variables don't accept negatives)
local increment = `T' // 30 in this case
replace time_since_treated = time_since_treated + `increment'
	// now time_since_treated = 30 refers to the period of treatment
	//  (kind of annoying to have to do this; will need to 
	//   convert back when graphing)
	
// Because 'i.' notation doesn't accept negatives, create our 
//  treated interacted with time since treatment dummies 
//  manually the old-fashioned way using -xi-
xi i.treated*i.time_since_treated, noomit
describe _I* // look at the interaction variables created with xi

// Note the important vars are the _ItreXtim_1_* which are the
//  relative "event time" dummies interacted with treatment.
// (The name _ItreXtim_1_* is because -xi- cuts each variable
//  to three letters; see -help xi-)
// (The _1 indicates that treated==1, the * will be values for 
//  each time_since_treated. These go from 5 to 41 which correspond
//  to -25 to 11, since we had to add 30 to avoid negative factor vars)

// But since time_since_treated is missing for control, 
//  the _ItreXtim* dummies also missing for control; we want them 
//  to be 0
recode _ItreXtim* (. = 0) if treated == 0

* Drop duplicate observations for idnss and periodo_monthly. Keep highest paying job.
gsort idnss periodo_monthly -sal_cierre
duplicates drop idnss periodo_monthly, force

* Generate variables at baseline
* Baseline January 2021
bysort idnss: gen aux_sal_baseline = sal_cierre if periodo == 202101
bysort idnss: gen aux_edad_baseline = rango if periodo == 202101
bysort idnss: gen aux_num_workers_baseline = num_workers if periodo == 202101
bysort idnss: gen aux_size_baseline = size_cierre if periodo == 202101
xtile aux_sal_decile_baseline = aux_sal_baseline, nq(10)
bysort idnss: egen sal_baseline = max(aux_sal_baseline)
bysort idnss: egen sal_decile_baseline = max(aux_sal_decile_baseline)
bysort idnss: egen num_workers_baseline = max(aux_num_workers_baseline)
bysort idnss (aux_edad_baseline): gen edad_baseline = aux_edad_baseline[_N]
bysort idnss (aux_size_baseline): gen size_baseline = aux_size_baseline[_N]
encode edad_baseline, gen(grupo_edad_baseline)
encode size_baseline, gen(grupo_size_baseline)
drop aux*

* Save event study database
save "01_Data/04_Temp/event_study_panel_rpci.dta", replace

*****************************
* Create Event Study Graphs * 
*****************************

* Use event study database
use "01_Data/04_Temp/event_study_panel_rpci.dta", clear

// To omit the period just before treatment:
summ time_since_treated if treated
local lo = r(min)
local hi = r(max)
local T = 30
local increment = `T' // 30 in this case
//  And note that since k=0 is now =`increment', 
//   k=-1 is `=`increment'-1', etc., which I use below
	
// EVENT STUDY REGRESSION
// As recommended by Borusyak and Jaravel (2016), but 
//  unlike McCrary (2007) and most event study papers,
//  include all relative time dummies in the regression rather 
//  than "binning" periods below a or above b.
// Then we can just graph the periods from a to b if we want. 
// But binning can cause bias if the trend isn't flat for periods
//  less than a or greater than b (Borusyak and Jaravel, 2016)
// Note that when there is no pure control group, binning periods
//  less than a or greater than b (i.e. imposing flat trend for
//  those periods) is needed to pin down calendar time fixed effects,
//  which is why Borusyak and Jaravel (2016) recommend having
//  a pure control, which pin down the calendar time fixed effects
//  without having to make these additional assumptions.

foreach depvar in "sal_cierre" "log_sal_cierre" "baja_cierre" "baja_permanente" "cambio_cierre" "cambio_sal"{
	preserve
	
	#delimit;
	reghdfe `depvar' _ItreXtim_1_`lo'-_ItreXtim_1_`=`increment'-2' 
			/* event study relative time dummies up to k=-2 */
		_ItreXtim_1_`increment'-_ItreXtim_1_`hi'
			/* event study relative time dummies starting at k=0 */, 
			absorb(periodo idnss i.sal_decile_baseline##i.periodo_quarter i.grupo_edad_baseline##i.periodo_quarter i.grupo_size_baseline##i.periodo_quarter
			i.te##i.periodo_quarter i.outsourcing##i.periodo_quarter i.cve_ent_final##i.periodo_quarter i.div_final##i.periodo_quarter)
	;
	#delimit cr

	// Note the coefficients we want from the regression are 
	//  the coefficients on _ItreXtim_1_*.
	// Note that _ItreXtim_1_9 is missing since that corresponds
	//  to k=-1, the omitted period

	// Degrees of freedom for p-values and confidence intervals:
	local df = e(df_r)

	// PUT RESULTS IN A MATRIX
	local rows = `hi' - `lo' + 1
	matrix results = J(`rows', 4, .) // empty matrix for results
	//  4 cols are: (1) time period, (2) beta, (3) std error, (4) pvalue
	local row = 0
	forval p = `lo'/`hi' {
		local ++row
		local k = `p' - `increment' // original relative period (-6 to 7)
		matrix results[`row',1] = `k'
		if `p'==`=`increment'-1' /// the omitted period
			continue // break this iteration of loop; 
				// and leave remaining columns as missing
		// Beta (event study coefficient)
		matrix results[`row',2] = _b[_ItreXtim_1_`p']
		// Standard error
		matrix results[`row',3] = _se[_ItreXtim_1_`p']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', ///
			abs(_b[_ItreXtim_1_`p']/_se[_ItreXtim_1_`p']) ///
		)
	}
	matrix colnames results = "k" "beta" "se" "p"
	matlist results

	***************************
	** GRAPH THE EVENT STUDY **
	***************************
	// First, replace data in memory with results
	clear
	svmat results, names(col) 

	// Replace values for omitted period to graph a hollow circle there:
	replace beta = 0 if k==-1 
	replace se = 0 if k==-1
	replace p = 1 if k==-1 // just need to set p>.1 so it will be hollow
		// based on the different types of points I use for significant 
		// vs insignificant results

	// GRAPH FORMATTING
	// For graphs:
	local labsize small
	local bigger_labsize large
	local ylabel_options nogrid notick labsize(`labsize') angle(horizontal)
	local xlabel_options nogrid notick labsize(`labsize') angle(45)
	local xtitle_options size(`labsize') margin(top)
	local title_options size(`bigger_labsize') margin(bottom) color(black)
	local manual_axis lwidth(thin) lcolor(black) lpattern(solid)
	local plotregion plotregion(margin(sides) fcolor(white) lstyle(none) lcolor(white)) 
	local graphregion graphregion(fcolor(white) lstyle(none) lcolor(white)) 
	// To put a line right before treatment
	local T_line_options lwidth(thin) lcolor(gray) lpattern(dash)
	// To show significance: hollow gray (gs7) will be insignificant from 0,
	//  filled-in gray significant at 10%
	//  filled-in black significant at 5%
	local estimate_options_0  mcolor(gs7)   msymbol(Oh) msize(medlarge)
	local estimate_options_90 mcolor(gs7)   msymbol(O)  msize(medlarge)
	local estimate_options_95 mcolor(black) msymbol(O)  msize(medlarge)
	local rcap_options_0  lcolor(gs7)   lwidth(thin)
	local rcap_options_90 lcolor(gs7)   lwidth(thin)
	local rcap_options_95 lcolor(black) lwidth(thin)

	// We have from k=-25 to 11, but smaller sample at the ends
	//  since less observations were treated early/late enough to have
	//  k=-25 or k=11 for the full sample, for example.
	// Suppose we just want to graph from k=-5 to k=5. (This is 
	//  better than binning at k<=-5 and k>=5 in the regression itself;
	//  see discussion above.)
	local lo_graph = -24
	local hi_graph = 11
	keep if k >= `lo_graph' & k <= `hi_graph'

	// Confidence intervals (95%)
	local alpha = .05 // for 95% confidence intervals
	gen rcap_lo = beta - invttail(`df',`=`alpha'/2')*se
	gen rcap_hi = beta + invttail(`df',`=`alpha'/2')*se

	// GRAPH
	#delimit ;
	graph twoway 
		(scatter beta k if p<0.05,           `estimate_options_95') 
		(scatter beta k if p>=0.05 & p<0.10, `estimate_options_90') 
		(scatter beta k if p>=0.10,          `estimate_options_0' ) 
		(rcap rcap_hi rcap_lo k if p<0.05,           `rcap_options_95')
		(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10, `rcap_options_90')
		(rcap rcap_hi rcap_lo k if p>=0.10,          `rcap_options_0' )
		, 
		title("Treatment effects from event study: `depvar'", `title_options')
		ylabel(, `ylabel_options') 
		yline(0, `manual_axis')
		xtitle("Period relative to treatment", `xtitle_options')
		xlabel(`lo_graph'(1)`hi_graph', `xlabel_options') 
		xscale(range(`min_xaxis' `max_xaxis'))
		xline(-0.5, `T_line_options')
		xscale(noline) /* because manual axis at 0 with yline above) */
		`plotregion' `graphregion'
		legend(off) 
	;
	#delimit cr
	
	* Export the graph
	graph export "04_Figures/event_study_`depvar'_months_max_all_vars.pdf", replace
	
	restore
}
