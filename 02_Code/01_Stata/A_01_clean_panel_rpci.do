/*******************************************************************************
@Name: clean_panel_rpci.do

@Author: Marco Medina

@Date: 02/03/2022

@In: muestra_100000_rpci_panel_24meses.csv
     muestra_1_1porciento_new.csv
	 
@Out: clean_panel_rpci.dta
	  panel_rpci.dta
	  panel_rpci_quarter.dta
*******************************************************************************/


********************
version 17.0
clear all
cd "$directory"
********************

* Import muestra_100000_rpci_panel_24meses.csv
*import delimited "01_Data/01_Raw/01_IMSS/muestra_100000_rpci_panel_24meses.csv", clear
*import delimited "01_Data/01_Raw/01_IMSS/muestra_1_1porciento_new.csv", clear
use "01_Data/01_Raw/01_IMSS/muestra_2018_2022_1_05porciento.dta", clear

* Recode sexo as 0 if men, 1 if woman
replace sexo = 0 if sexo == 1
replace sexo = 1 if sexo == 2

* Make all observations have a gender dummy
rename sexo sexo_aux
bysort idnss: egen sexo = max(sexo_aux)
drop sexo_aux

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

gen periodo_year = year(periodo_date)

gen periodo_t = periodo_monthly - tm(2020m1)

drop periodo_st

* Create monthly & quarterly download dates
gen download_date = date(fecha, "DMY")
format download_date %td

gen download_monthly = mofd(download_date)
format download_monthly %tm

gen download_quarter = qofd(download_date)
format download_quarter %tq

gen download_year = year(download_date)

* Replace the cohort value for those individuals that were never treated
* Useful for did_multiplegt and csdid
replace download_monthly = 0 if descarga == .
replace download_quarter = 0 if descarga == .
replace download_year = 0 if descarga == .
drop fecha

* Clean age group variable to have numeric categories
replace rango = ustrregexra(rango, "E","")
destring rango, replace

* Clean firm size variable to have numeric categories
replace size_cierre = ustrregexra(size_cierre, "S","")
replace size_cierre = ustrregexra(size_cierre, "NA","")
destring size_cierre, replace


* Keep one observation for each worker per period
* If there are two observations (i.e. two jobs registered), keep the highest paying job
* If both jobs have the same wage, keep the one that is not an eventual job,
* is not outsourcing, and has the most days registered (días cotizados).
gsort idnss periodo_monthly -sal_cierre te outsourcing -dias
duplicates drop idnss periodo_monthly, force

* Keep workers that were registered at IMSS during January 2021 (a month before the RPCI launch)
gen muestra_aux = [periodo == 202101 & idregistro != .]
bysort idnss: egen muestra = max(muestra_aux)
keep if muestra == 1
drop muestra

* Save as clean_panel_rpci.dta
save "01_Data/02_Clean/clean_panel_rpci.dta", replace



**********************
* Baseline variables *
**********************

* Use clean_panel_rpci.dta
use "01_Data/02_Clean/clean_panel_rpci.dta", clear


* Create baseline variable for numeric variables
* Get the mean valye of the last available observations (January 2021 & 2020).

* Baseline mean wage
bysort idnss: egen base_sal_cierre_aux = mean(sal_cierre) if periodo_year == 2020 | periodo == 202101
bysort idnss: egen base_sal_cierre = max(base_sal_cierre_aux)
xtile base_sal_decile = base_sal_cierre, nq(10)

* Baseline wage standard deviation
bysort idnss: egen base_sal_cierre_sd_aux = sd(sal_cierre) if periodo_year == 2020 | periodo == 202101
bysort idnss: egen base_sal_cierre_sd = max(base_sal_cierre_sd_aux)
replace base_sal_cierre_sd = 0 if missing(base_sal_cierre_sd) & !missing(base_sal_cierre)

* Baseline eventual job dummy
bysort idnss: egen base_te_aux = mean(te) if periodo_year == 2020 | periodo == 202101
bysort idnss: egen base_te = max(base_te_aux)
replace base_te = round(base_te)

* Baseline government job dummy
bysort idnss: egen base_gobierno_aux = mean(gobierno) if periodo_year == 2020 | periodo == 202101
bysort idnss: egen base_gobierno = max(base_gobierno_aux)
replace base_gobierno = round(base_gobierno)

* Baseline outsourcing job dummy
bysort idnss: egen base_outsourcing_aux = mean(outsourcing) if periodo_year == 2020 | periodo == 202101
bysort idnss: egen base_outsourcing = max(base_outsourcing_aux)
replace base_outsourcing = round(base_outsourcing)



* Create baseline variable for numeric categoric variables
* Keep the values of the last available observation from January 2021 and backwards
bysort idnss: egen base_periodo_alta = max(periodo_monthly) if idregistro !=. & periodo_year <= 2020

* Baseline modality variable
bysort idnss: gen base_mod_aux = mod if periodo_monthly == base_periodo_alta & base_periodo_alta <= tm(2021m1)
bysort idnss: egen base_mod = max(base_mod_aux)

* Baseline state variable
bysort idnss: gen base_cve_ent_final_aux = cve_ent_final if periodo_monthly == base_periodo_alta & base_periodo_alta <= tm(2021m1)
bysort idnss: egen base_cve_ent_final = max(base_cve_ent_final_aux)

* Baseline industry variable
bysort idnss: gen base_div_final_aux = div_final if periodo_monthly == base_periodo_alta & base_periodo_alta <= tm(2021m1)
bysort idnss: egen base_div_final = max(base_div_final_aux)

* Baseline age group
bysort idnss: gen base_rango_aux = rango if periodo_monthly == base_periodo_alta & base_periodo_alta <= tm(2021m1)
bysort idnss: egen base_rango = max(base_rango_aux)

* Baseline firm size group
bysort idnss: gen base_size_cierre_aux = size_cierre if periodo_monthly == base_periodo_alta & base_periodo_alta < tm(2021m1)
bysort idnss: egen base_size_cierre = max(base_size_cierre_aux)

* Resort database
gsort idnss periodo_monthly



*******************
* Create features *
*******************

* Create a download variable if they ever downloaded the app
bysort idnss: egen treated = max(rpci_vig)


* Create time sice treated from treated units
gen time_since_treated = periodo_monthly - download_monthly if treated == 1


* Create dummy for alta_cierre
gen idnss_aux = idnss[_n-1]
gen alta = [idregistro != .]
gen alta_aux = alta[_n-1]
gen alta_cierre = [alta_aux == 0 & alta == 1 & idnss == idnss_aux]


* Create dummy for baja_cierre
gen baja_cierre = [alta_aux == 1 & alta == 0 & idnss == idnss_aux]

* Keep variables from the last register for regression controls
replace mod = mod[_n-1] if baja_cierre == 1
replace te = te[_n-1] if baja_cierre == 1
replace cve_ent_final = cve_ent_final[_n-1] if baja_cierre == 1
replace div_final = div_final[_n-1] if baja_cierre == 1
replace size_cierre = size_cierre[_n-1] if baja_cierre == 1
replace gobierno = gobierno[_n-1] if baja_cierre == 1
replace outsourcing = outsourcing[_n-1] if baja_cierre == 1


* Create dummy for cambio_cierre
* Note: cambio is defined only if I had a register this month and the last month
gen idrfc_aux = idrfc[_n-1]
gen cambio_cierre = [idrfc != idrfc_aux & idnss == idnss_aux] if alta == 1 & alta_aux == 1


* Create dummy for sal_mayor, sal_menor and sal_diff
gen sal_cierre_aux = sal_cierre[_n-1]
gen sal_mayor = [sal_cierre > sal_cierre_aux & !missing(sal_cierre)] if alta == 1 & alta_aux == 1
gen sal_menor = [sal_cierre < sal_cierre_aux & !missing(sal_cierre_aux)] if alta == 1 & alta_aux == 1
gen sal_igual = [sal_cierre == sal_cierre_aux] if alta == 1 & alta_aux == 1
gen sal_diff = [sal_mayor == 1 | sal_menor == 1] if alta == 1 & alta_aux == 1


* Create dummy for cambio_sal_mayor and cambio_sal_menor
gen cambio_sal_mayor = [cambio_cierre == 1 & sal_mayor == 1] if !missing(cambio_cierre)
gen cambio_sal_menor = [cambio_cierre == 1 & sal_menor == 1] if !missing(cambio_cierre)
gen cambio_sal_igual = [cambio_cierre == 1 & sal_igual == 1] if !missing(cambio_cierre)


* Create dummy for baja_permanente
bysort idnss: egen max_periodo_alta_aux = max(periodo_monthly) if idrfc !=.
bysort idnss: egen max_periodo_alta = max(max_periodo_alta_aux)
gen baja_permanente = [baja_cierre == 1 & periodo_monthly == max_periodo_alta + 1]


* Create log_sal_cierre
gen log_sal_cierre = log(sal_cierre)


* Create sal_formal. This variable is the same as sal_cierre, but is 0 if sal_cierre is missing.
clonevar sal_formal = sal_cierre
replace sal_formal = 0 if missing(sal_cierre)


* Create a dummy if you always had the same employer
egen tag = tag(idrfc idnss)
egen n_idrfc = total(tag), by(idnss)
gen same_idrfc = [n_idrfc == 1]



*******************
* Yearly Database *
*******************

* Wage standard deviation per year
bysort idnss periodo_year: egen sal_cierre_yr_aux = mean(sal_cierre)
bysort idnss periodo_year: egen sal_cierre_yr = max(sal_cierre_yr_aux)
bysort idnss periodo_year: egen sal_cierre_sd_yr_aux = sd(sal_cierre)
bysort idnss periodo_year: egen sal_cierre_sd_yr = max(sal_cierre_sd_yr_aux)
* Replace with zero if the worker had the same wage all year long
replace sal_cierre_sd_yr = 0 if missing(sal_cierre_sd_yr) & !missing(sal_cierre_yr) 


* Wage changes per year
bysort idnss periodo_year: egen sal_diff_yr = total(sal_diff)
* Replace with missing if the worker didn't have a registered wage that year
replace sal_diff_yr = . if missing(sal_cierre_yr)

* Wage raises per year
bysort idnss periodo_year: egen sal_mayor_yr = total(sal_mayor)
* Replace with missing if the worker didn't have a registered wage that year
replace sal_mayor_yr = . if missing(sal_cierre_yr)

* Wage cuts per year
bysort idnss periodo_year: egen sal_menor_yr = total(sal_menor)
* Replace with missing if the worker didn't have a registered wage that year
replace sal_menor_yr = . if missing(sal_cierre_yr)

preserve

	* Keep one observation per year
	duplicates drop idnss periodo_year, force

	* Keep relevant variables
	keep idnss idrfc periodo_year download_year sal_*_yr base_*

	* Create variables treatment and sal_cierre_sd. Replace with the values according to the year
	gen treatment = 0
	replace treatment = 1 if download_year == 2021 & periodo_year >= 2021
	replace treatment = 1 if download_year == 2022 & periodo_year >= 2022
	
	* Save yearly database as yearly_panel_rpci.dta
	save "01_Data/03_Working/yearly_panel_rpci.dta", replace
	
restore



***********************
* Filter the database *
***********************

* Keep observations for 2020, 2021 & 2022
keep if periodo_year >= 2020

* Drop auxiliar dummies
drop *_aux max_periodo_alta base_periodo_alta n_idrfc tag



*******************
* Label variables *
*******************

label var rpci_vig "RPCI"
label var sal_cierre "Wage"
label var log_sal_cierre "Log Wage"
label var sal_formal "Formal Wage"
label var alta "Enrolled"

* Save as panel_rpci.dta
save "01_Data/03_Working/panel_rpci.dta", replace


/*
**********************
* Quarterly Database *
**********************

* Use panel_rpci.dta
use "01_Data/03_Working/panel_rpci.dta", clear

* Create time sice treated from treated units
gen time_since_treated_quarter = periodo_quarter - download_quarter if treated == 1

* Generate quarterly rpci_vig
bysort idnss periodo_quarter: egen aux = max(rpci_vig)
replace rpci_vig = aux
drop aux

* Generate quarterly sal_cierre
bysort idnss periodo_quarter: egen aux = mean(dias)
replace dias = aux
drop aux

* Generate quarterly sal_cierre
bysort idnss periodo_quarter: egen aux = mean(sal_cierre)
replace sal_cierre = aux
drop aux

* Generate quarterly baja_cierre
bysort idnss periodo_quarter: egen aux = max(baja_cierre)
replace baja_cierre = aux
drop aux

* Generate quarterly cambio_cierre
bysort idnss periodo_quarter: egen aux = max(cambio_cierre)
replace cambio_cierre = aux
drop aux

* Keep one observation per idnss per quarter
duplicates drop idnss periodo_quarter, force

* Save as panel_rpci_quarter.dta
save "01_Data/03_Working/panel_rpci_quarter.dta", replace
*/

