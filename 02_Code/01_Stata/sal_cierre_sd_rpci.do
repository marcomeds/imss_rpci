/*******************************************************************************
@Name: sal_cierre_sd_rpci.do

@Author: Marco Medina

@Date: 30/10/2022

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

* Keep one observation per year, one for 2020 and one for 2021
duplicates drop idnss periodo_year, force

* Define treatment by the year registering to the RPCI
gen treatment_22 = [download_monthly >= tm(2022m1) & download_monthly <= tm(2022m12)]
gen treatment_21 = [download_monthly >= tm(2021m1) & download_monthly <= tm(2021m12)]
gen treatment_20 = 0

* Keep relevant variables
rename base_sal_cierre_sd sal_cierre_sd_20
keep idnss periodo_year sal_cierre_sd_2* treatment_2*

* Create variables treatment and sal_cierre_sd. Replace with the values according to the year
gen treatment = treatment_20
replace treatment = 1 if treatment_21 == 1 & periodo_year >= 2021
replace treatment = 1 if treatment_22 == 1 & periodo_year >= 2022

gen sal_cierre_sd = sal_cierre_sd_20
replace sal_cierre_sd = sal_cierre_sd_21 if periodo_year == 2021
replace sal_cierre_sd = sal_cierre_sd_21 if periodo_year == 2021

* Create cohort variable for did_multiplegt
gen download_year = 0
replace download_year = 2021 if treatment_21 == 1
replace download_year = 2022 if treatment_22 == 1


* TWFE
reghdfe sal_cierre_sd treatment, absorb(periodo_year idnss) cluster(idnss)

* did_multiplegt
did_multiplegt sal_cierre_sd download_year periodo_year treatment, ///
average_effect robust_dynamic dynamic(1) placebo(1) breps(25) cluster(idnss) seed(541314)
