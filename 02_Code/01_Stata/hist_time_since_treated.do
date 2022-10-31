/*******************************************************************************
@Name: hist_time_since_treated.do

@Author: Marco Medina

@Date: 10/10/2022

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


* Keep only observations of treated workers
keep if treated == 1

* Keep observations after treatment & drop september 2022 cohort observations, since they are incomplete
drop if time_since_treated < 0 | time_since_treated == 18

* Count the workers observed for each time_since_treated
bysort time_since_treated: gen treated_workers = _N
keep time_since_treated treated_workers
duplicates drop

* Express the number of workers as the percentage of all treated workers
gen perc_treated_workers = treated_workers / treated_workers[1]

graph bar perc_treated_workers, over(time_since_treated) ///
      bar(1, color("0 69 134")) ///
	  title("") b1title("Months since registering for the RPCI") ///
	  ytitle("Percentage of workers who registered" "for the RPCI observed after t months") ///
	  scheme(s2mono) graphregion(color(white))

	 
graph export "04_Figures/$muestra/hist_time_since_treated.pdf", replace
	 
