/*******************************************************************************
@Name: hist_wage_time_since_treated.do

@Author: Marco Medina

@Date: 29/10/2022

@In: panel_rpci.dta
	 
@Out: 
*******************************************************************************/


********************
version 17.0
clear all
cd "$directory"
********************


*************
* Treatment *
*************

* Use panel_rpci.dta
use "01_Data/03_Working/panel_rpci.dta", clear

* Keep treated workers
keep if treated == 1

* Keep observations after they were treated
keep if time_since_treated >= -1
replace time_since_treated = time_since_treated + 1

* Keep the worker id, wages and time_since_treated
keep idnss sal_cierre time_since_treated

* Make the database wider, having one observation per worker
reshape wide sal_cierre, i(idnss) j(time_since_treated)

* Create variables for the differences in wages after n months
forvalues i = 0/19 {
	gen diff_sal_cierre`i' = sal_cierre`i' - sal_cierre0
	gen zero_diff`i' = [diff_sal_cierre`i' == 0] if !missing(diff_sal_cierre`i')
}

* Get back to long
reshape long sal_cierre diff_sal_cierre zero_diff, i(idnss) j(time_since_treated)

* Collapse and get the percentage of worker with the same wage as the month
* before they registered for the RPCI, for each month after treatment.
collapse (mean) zero_diff, by(time_since_treated)
drop if time_since_treated == 0
drop if time_since_treated == 19
replace time_since_treated = time_since_treated - 1

* Create graph
graph bar zero_diff, over(time_since_treated) ///
      bar(1, color("0 69 134")) ///
	  ylabel(0(0.2)1) ///
	  title("") b1title("Months since registering for the RPCI") ///
	  ytitle("Percentage of workers" "without change in wage") ///
	  scheme(s2mono) graphregion(color(white))
	  
graph export "04_Figures/$muestra/hist_wage_time_since_treated_treat.pdf", replace

gen treated = 1
tempfile treated
save `treated'



***********
* Control *
***********

* Use panel_rpci.dta
use "01_Data/03_Working/panel_rpci.dta", clear

* Keep control workers
keep if treated == 0

* Label February 2021 as 0 in 'time_since_treated'
* Keep observations after February 2021
replace time_since_treated = periodo_monthly - tm(2021m2)
keep if time_since_treated >= -1
replace time_since_treated = time_since_treated + 1

* Keep the worker id, wages and time_since_treated
keep idnss sal_cierre time_since_treated

* Make the database wider, having one observation per worker
reshape wide sal_cierre, i(idnss) j(time_since_treated)

* Create variables for the differences in wages after n months
forvalues i = 1/18 {
	gen diff_sal_cierre`i' = sal_cierre`i' - sal_cierre0
	gen zero_diff`i' = [diff_sal_cierre`i' == 0] if !missing(diff_sal_cierre`i')
}

* Get back to long
reshape long sal_cierre diff_sal_cierre zero_diff, i(idnss) j(time_since_treated)

* Collapse and get the percentage of worker with the same wage as the month
* they registered for the RPCI for each month after treatment
collapse (mean) zero_diff, by(time_since_treated)
drop if time_since_treated == 0
drop if time_since_treated == 19
replace time_since_treated = time_since_treated - 1

* Create graph
graph bar zero_diff, over(time_since_treated) ///
      bar(1, color("197 0 11")) ///
	  ylabel(0(0.1)1) ///
	  title("") b1title("Months since the RPCI launch" "(February 2021)") ///
	  ytitle("Percentage of workers" "without change in wage") ///
	  scheme(s2mono) graphregion(color(white))
	  
graph export "04_Figures/$muestra/hist_wage_time_since_treated_control.pdf", replace



*******************
* Matched Control *
*******************

* Note: the objective is to atribute the time_since_treated of the matched
* treated unit to the control group

* Use panel_rpci.dta
use "01_Data/03_Working/panel_rpci.dta", clear

* Keep treated workers
keep if treated == 1

* Keep relevant variables
keep idnss periodo_monthly time_since_treated
rename idnss idnss_match

* Merge with matched_panel_rpci.dta
joinby idnss_match using "01_Data/03_Working/matched_panel_rpci.dta"

* Merge back with panel_rpci.dta, now that we have time_since_treated
drop idnss_match
merge 1:1 idnss periodo_monthly using "01_Data/03_Working/panel_rpci.dta", keep(3) nogen



* Now keep control workers and give them the coding as treatment workers
* Keep control workers
keep if treated == 0

* Keep observations after they were treated
keep if time_since_treated >= -1
replace time_since_treated = time_since_treated + 1

* Keep the worker id, wages and time_since_treated
keep idnss sal_cierre time_since_treated

* Make the database wider, having one observation per worker
reshape wide sal_cierre, i(idnss) j(time_since_treated)

* Create variables for the differences in wages after n months
forvalues i = 0/19 {
	gen diff_sal_cierre`i' = sal_cierre`i' - sal_cierre0
	gen zero_diff`i' = [diff_sal_cierre`i' == 0] if !missing(diff_sal_cierre`i')
}

* Get back to long
reshape long sal_cierre diff_sal_cierre zero_diff, i(idnss) j(time_since_treated)

* Collapse and get the percentage of worker with the same wage as the month
* before they registered for the RPCI, for each month after treatment.
collapse (mean) zero_diff, by(time_since_treated)
drop if time_since_treated == 0
drop if time_since_treated == 19
replace time_since_treated = time_since_treated - 1

* Create graph
graph bar zero_diff, over(time_since_treated) ///
      bar(1, color("197 0 11")) ///
	  ylabel(0(0.1)1) ///
	  title("") b1title("Months since the RPCI launch" "(February 2021)") ///
	  ytitle("Percentage of workers" "without change in wage") ///
	  scheme(s2mono) graphregion(color(white))
	  
graph export "04_Figures/$muestra/hist_wage_time_since_treated_control_matched.pdf", replace



****************************************************
* Difference between treatment and matched control *
****************************************************

* Append the data for the treated histogram
gen treated = 0
append using `treated'

* Reshape wide
reshape wide zero_diff, i(time_since_treated) j(treated)
gen perc_zero_diff = zero_diff0 - zero_diff1

* Create graph
graph bar perc_zero_diff, over(time_since_treated) ///
      bar(1, color("87 157 28")) ///
	  title("") b1title("Months since registering for the RPCI") ///
	  ytitle("Difference between the percentage" "of workers without change in wage" "(Control - Treatment)") ///
	  scheme(s2mono) graphregion(color(white))

graph export "04_Figures/$muestra/hist_wage_time_since_treated_diff_matched.pdf", replace
