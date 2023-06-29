/*******************************************************************************
@Name: hist_download_rpci.do

@Author: Marco Medina

@Date: 07/10/2022

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

* Keep one observation per worker and count downloads by month
duplicates drop idnss, force
bysort download_monthly: gen downloads = _N

* Drop september observations, since they are incomplete
*drop if download_monthly == tm(2022m9)

* Keep one observation per month and sum cumulative downloads
duplicates drop download_monthly, force
gen cum_downloads = (sum(downloads)*100)/1000

twoway (hist download_monthly [fweight = downloads], ///
        discrete fraction yaxis(1) fcolor("0 69 134") lcolor(white) ///
		tlabel(2021m2(1)2022m8, format(%tmMon-YY) angle(45)) ///
		title("") ///
		xtitle("") ytitle("Fraction") ///
	    scheme(s2mono) graphregion(color(white))) ///
	   (line cum_downloads download_monthly, ///
	    yaxis(2) lcolor("197 0 11") lwidth(thick) ///
		ytitle("Cumulative registered workers" "(Thousands)", axis(2)) legend(off))

	 
graph export "04_Figures/$muestra/hist_download_month.pdf", replace
	 
