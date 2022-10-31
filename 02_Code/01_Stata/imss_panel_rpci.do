/*******************************************************************************
@Name: imss_panel_rpci.do
*******************************************************************************/

********************
version 17.0
clear all
********************





//------------------//
// Clean Panel RPCI //
//------------------//

* Import muestra_100000_rpci_panel_24meses.csv
import delimited "muestra_100000_rpci_panel_24meses.csv", clear

* Keep relevant variables
keep idrfc periodo cve_ent_final sexo div_final sal_cierre gobierno outsourcing ///
	 fecha rpci_vig idnss

* Create monthly & quarterly dates
* Note: using monthly function directly doesn't work on string such as 202012
tostring periodo, gen(periodo_st)
replace periodo_st = periodo_st + "01"

gen periodo_date = date(periodo_st, "YMD")
format periodo_date %td

gen periodo_monthly = mofd(periodo_date)
format periodo_monthly %tm 

gen periodo_quarter = qofd(periodo_date)
format periodo_quarter %tq

drop periodo_st

* Create monthly & quarterly download dates
gen download_date = date(fecha, "DMY")
format download_date %td

gen download_monthly = mofd(download_date)
format download_monthly %tm

drop fecha download_date

* Recode sexo as 0 if men, 1 if woman
replace sexo = 0 if sexo == 1
replace sexo = 1 if sexo == 2

* Save as clean_panel_rpci.dta
compress
save "clean_panel_rpci.dta", replace

*******************
* Create features *
*******************
* Use clean_panel_rpci.dta
use "clean_panel_rpci.dta", clear

* Create a download variable if they ever downloaded the app
bysort idnss: egen treated = max(rpci_vig)

* Create time sice treated from treated units
gen time_since_treated = periodo_monthly - download_monthly if treated == 1

* Create dummy for baja_cierre
gen baja = 1 if idrfc == .
gen baja_aux = baja[_n-1]
gen idnss_aux = idnss[_n-1]
gen baja_cierre = [baja == 1 & baja_aux == . & idnss == idnss_aux]

* Create dummy for cambio_cierre
gen idrfc_aux = idrfc[_n-1]
gen cambio_cierre = [idrfc != idrfc_aux & idnss == idnss_aux & baja != 1 & baja_aux != 1]

* Create dummy for baja_permanente
bysort idnss: egen max_periodo_alta = max(periodo_date) if idrfc !=.
gen max_periodo_alta_aux = max_periodo_alta[_n-1]
gen baja_permanente = [baja_cierre == 1 & periodo_date > max_periodo_alta_aux]

* Drop auxiliar dummies
drop baja baja_aux idnss_aux idrfc_aux max_periodo_alta max_periodo_alta_aux

* Create log_sal_cierre
gen log_sal_cierre = log(sal_cierre)

* Generate number of worker obsertions per firm
bysort idrfc: gen num_workers = _N
replace num_workers = . if idrfc == .

* Create wage decil dummy
xtile decile = sal_cierre, nq(10)

* Save as panel_rpci.dta
compress
save "panel_rpci.dta", replace





//----------------//
// Balance Table  //
//----------------//

* Use panel_rpci.dta
use "panel_rpci.dta", clear

* Keep observations for 2020
keep if periodo_date <= date("31dec2020", "DMY")

* Create dummies for state and firm's industry
xi i.cve_ent_final, prefix(ent) noomit
xi i.div_final, prefix(div) noomit

*****************
* Balance table *
*****************

balancetable treated sexo sexo sal_cierre gobierno ent* div* outsourcing using "Panel_RPCI_Balance_Table.xlsx", replace
*iebaltab sexo sal_cierre gobierno ent* div* outsourcing, grpvar(treated) save("Panel_RPCI_Balance.xlsx") replace

********************
* Balance by state *
********************

* Graph for states
matrix results = J(32, 5, .)

forvalues s = 1(1)32{
	reg entcve_ent__`s' treated
	
	matrix results[`s',1] = `s'
	matrix results[`s',2] = _b[treated]
	matrix results[`s',3] = _se[treated]
	matrix results[`s',4] = `e(df_r)'
	matrix results[`s',5] = `e(N)'
}
	
matrix colnames results = "d" "beta" "se" "df" "obs"
clear
svmat results, names(col) 
gen rcap_lo_5 = beta - invttail(df,.025)*se
gen rcap_hi_5 = beta + invttail(df,.025)*se	
gen rcap_lo_10 = beta - invttail(df,.05)*se
gen rcap_hi_10 = beta + invttail(df,.05)*se	

* Gen manual label for each state
gen state = "AGS"
replace state = "BC" if d == 2
replace state = "BCS" if d == 3
replace state = "CAMP" if d == 4
replace state = "COAH" if d == 5
replace state = "COL" if d == 6
replace state = "CHIS" if d == 7
replace state = "CHIH" if d == 8
replace state = "CDMX" if d == 9
replace state = "DGO" if d == 10
replace state = "GTO" if d == 11
replace state = "GRO" if d == 12
replace state = "HGO" if d == 13
replace state = "JAL" if d == 14
replace state = "MEX" if d == 15
replace state = "MICH" if d == 16
replace state = "MOR" if d == 17
replace state = "NAY" if d == 18
replace state = "NL" if d == 19
replace state = "OAX" if d == 20
replace state = "PUE" if d == 21
replace state = "QUE" if d == 22
replace state = "QRO" if d == 23
replace state = "SLP" if d == 24
replace state = "SIN" if d == 25
replace state = "SON" if d == 26
replace state = "TAB" if d == 27
replace state = "TAMS" if d == 28
replace state = "TLAX" if d == 29
replace state = "VER" if d == 30
replace state = "YUC" if d == 31
replace state = "ZAC" if d == 32

twoway 	(scatter beta d, color(black) mlabel(state))  ///
	(rcap rcap_lo_5 rcap_hi_5 d, lcolor(navy)) ///
	(rcap rcap_lo_10 rcap_hi_10 d, lwidth(thick) lcolor(navy%70)), legend(off) scheme(s2mono) graphregion(color(white)) ///
	xlabel(none) title("Diferencias en descarga de RPCI por estado") xtitle("Estado") ytitle("Diferencia") yline(0) xsize(12)
	
graph export "balance_state_graph.pdf", replace	





//-----------------------//
// Two Way Fixed Effects //
//-----------------------//

* Use panel_rpci.dta
use "panel_rpci.dta", clear

********************
* TWFE Regressions *
********************

foreach depvar in "sal_cierre" "log_sal_cierre" "baja_cierre" "baja_permanente" "cambio_cierre" {
	reghdfe `depvar' rpci_vig, absorb(periodo idnss)
	quietly summ `depvar'
	outreg2 using "TE_IDNSSLvl_`depvar'.xls", replace addstat(Mean, r(mean))
}

***************************************
* State & Quarter Interaction Dummies *
***************************************

foreach depvar in "sal_cierre" "log_sal_cierre" "baja_cierre" "baja_permanente" "cambio_cierre" {
	reghdfe `depvar' rpci_vig, absorb(periodo idnss i.cve_ent_final##i.periodo_quarter)
	quietly summ `depvar'
	outreg2 using "TE_IDNSSLvl_`depvar'_ent.xls", replace addstat(Mean, r(mean))
}

********************************************
* Wage Decil & Quarter Interaction Dummies *
********************************************

foreach depvar in "sal_cierre" "log_sal_cierre" "baja_cierre" "baja_permanente" "cambio_cierre" {
	reghdfe `depvar' rpci_vig, absorb(periodo idnss i.decile##i.periodo_quarter)
	quietly summ `depvar'
	outreg2 using "TE_IDNSSLvl_`depvar'_sal_decil.xls", replace addstat(Mean, r(mean))
}





//-------------//
// Event Study //
//-------------//


* Use panel_rpci.dta
use "panel_rpci.dta", clear

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

* Save event study database
compress
save "event_study_panel_rpci.dta", replace



*****************************
* Create Event Study Graphs * 
*****************************

* Use event study database
use "event_study_panel_rpci.dta", clear

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

foreach depvar in "sal_cierre" "log_sal_cierre" "baja_cierre" "baja_permanente" "cambio_cierre" {
	preserve
	
	#delimit;
	reghdfe `depvar' _ItreXtim_1_`lo'-_ItreXtim_1_`=`increment'-2' 
			/* event study relative time dummies up to k=-2 */
		_ItreXtim_1_`increment'-_ItreXtim_1_`hi'
			/* event study relative time dummies starting at k=0 */, 
			absorb(periodo idnss)
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
	graph export "event_study_`depvar'_months_max.pdf", replace
	
	restore
}


***************************************
* State & Quarter Interaction Dummies *
***************************************


foreach depvar in "sal_cierre" "log_sal_cierre" "baja_cierre" "baja_permanente" "cambio_cierre" {
	preserve
	
	#delimit;
	reghdfe `depvar' _ItreXtim_1_`lo'-_ItreXtim_1_`=`increment'-2' 
			/* event study relative time dummies up to k=-2 */
		_ItreXtim_1_`increment'-_ItreXtim_1_`hi'
			/* event study relative time dummies starting at k=0 */, 
			absorb(periodo idnss i.cve_ent_final##i.periodo_quarter)
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
	graph export "event_study_`depvar'_months_max_ent.pdf", replace
	
	restore
}

********************************************
* Wage Decil & Quarter Interaction Dummies *
********************************************

foreach depvar in "sal_cierre" "log_sal_cierre" "baja_cierre" "baja_permanente" "cambio_cierre" {
	preserve
	
	#delimit;
	reghdfe `depvar' _ItreXtim_1_`lo'-_ItreXtim_1_`=`increment'-2' 
			/* event study relative time dummies up to k=-2 */
		_ItreXtim_1_`increment'-_ItreXtim_1_`hi'
			/* event study relative time dummies starting at k=0 */, 
			absorb(periodo idnss i.decile##i.periodo_quarter)
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
	graph export "event_study_`depvar'_months_max_sal_decil.pdf", replace
	
	restore
}


//----------//
// Matching //
//----------//


* Use panel_rpci.dta
use "panel_rpci.dta", clear

*********************
* Matching Database *
*********************

* Drop duplicate observations for idnss and periodo_monthly. Keep highest paying job.
gsort idnss periodo_monthly -sal_cierre
duplicates drop idnss periodo_monthly, force

* Gen sal_growth
gen sal_cierre_aux = sal_cierre[_n-12]
gen sal_cambio = sal_cierre - sal_cierre_aux
gen sal_growth = sal_cambio / sal_cierre
drop sal_cierre_aux sal_cambio

* For treated == 0, we keep observations between jan2021 and jul2021.
gen aux = [treated == 0 & periodo_date >= date("01jan2021", "DMY") & periodo_date <= date("01jul2021", "DMY")]

* For treated == 1, we keep observations between time_since_treated = -1 and time_since_treated = 6.
replace aux = 1 if treated == 1 & time_since_treated >= -1 & time_since_treated <= 6
keep if aux == 1
drop aux

* Drop any duplicates
duplicates drop idnss periodo_date, force

* Generate sal_prom
replace sal_cierre = 0 if sal_cierre == .
bysort idnss: egen sal_prom = mean(sal_cierre)

* Keep only observations in the limits of the time periods
gen aux = [treated == 0 & periodo_date == date("01jan2021", "DMY")]
replace aux = 1 if treated == 0 & periodo_date == date("01jul2021", "DMY")
replace aux = 1 if treated == 1 & time_since_treated == -1
replace aux = 1 if treated == 1 & time_since_treated == 6
keep if aux == 1
drop aux

* Make sure observations have a pair in the time frame
duplicates tag idnss, gen(dup)
keep if dup == 1
drop dup

* Gen sal_cambio
gen sal_cierre_aux = sal_cierre[_n+1]
gen sal_cambio = sal_cierre_aux - sal_cierre
drop sal_cierre_aux

* Keep only observations at the start of the time periods
gen aux = [treated == 0 & periodo_date == date("01jan2021", "DMY")]
replace aux = 1 if treated == 1 & time_since_treated == -1
keep if aux == 1
drop aux

* Rename sal_cierre a sal_inicial
rename sal_cierre sal_inicial

* Save as matching_panel_rpci.dta
compress
save "matching_panel_rpci.dta", replace

************
* Matching *
************

* Use matching_panel_rpci.dta
use "matching_panel_rpci.dta", clear

*********
* ipwra *
*********

* Gender + sal_inicial
teffects ipwra (sal_prom sexo sal_inicial) (treated sexo sal_inicial), atet
outreg2 using "03_Tables/Matching_ipwra_sal_prom_a.xls", replace
* Gender + sal_inicial + firm characteristics
teffects ipwra (sal_prom sexo sal_inicial num_workers i.div_final i.cve_ent_final) (treated sexo sal_inicial num_workers i.div_final i.cve_ent_final), atet
outreg2 using "03_Tables/Matching_ipwra_sal_prom_b.xls", replace
* Gender + sal_inicial + sal_growth
teffects ipwra (sal_prom sexo sal_inicial num_workers i.div_final i.cve_ent_final sal_growth) (treated sexo sal_inicial num_workers i.div_final i.cve_ent_final sal_growth), atet
outreg2 using "03_Tables/Matching_ipwra_sal_prom_c.xls", replace
	
* Balance table
tebalance summarize
matrix size_ipwra = r(size)
matrix balance_stats_ipwra = r(table)
estout matrix(balance_stats_ipwra) using "03_Tables/balance_ipwra_sal_prom.xls", replace

***********
* nnmatch *
***********

* Gender + sal_inicial
teffects nnmatch (sal_prom sexo sal_inicial) (treated), atet
outreg2 using "Matching_nnmatch_sal_prom_a.xls", replace
* Gender + sal_inicial + firm characteristics
teffects nnmatch (sal_prom sexo sal_inicial num_workers i.div_final i.cve_ent_final) (treated), atet
outreg2 using "Matching_nnmatch_sal_prom_b.xls", replace
* Gender + sal_inicial + sal_growth
teffects nnmatch (sal_prom sexo sal_inicial num_workers i.div_final i.cve_ent_final sal_growth) (treated), atet
outreg2 using "Matching_nnmatch_sal_prom_c.xls", replace
	
* Balance table
tebalance summarize
matrix size_nnmatch = r(size)
matrix balance_stats_nnmatch = r(table)
estout matrix(balance_stats_nnmatch) using "balance_nnmatch_sal_prom.xls", replace

