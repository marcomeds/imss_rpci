/*******************************************************************************
@Name: clean_panel_empi_rpci.do

@Author: Marco Medina

@Date: 10/01/2023

@In: panelempi_2018_2022_1_10porciento.csv
	 
@Out: clean_panel_empi_rpci.dta
	  panel_empi_rpci.dta
*******************************************************************************/


********************
version 17.0
clear all
cd "$directory"
********************

* Import panelempi_2018_2022_1_10porciento.csv
use "01_Data/01_Raw/01_IMSS/panelempi_2018_2022_1_01porciento.dta", clear

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

* Replace the cohort value for those individuals that were never treated
* Useful for did_multiplegt and csdid
replace download_monthly = 0 if descarga == .
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

* Save as clean_panel_rpci.dta
save "01_Data/02_Clean/clean_panel_empi_rpci.dta", replace



**********************
* Baseline variables *
**********************

* Use clean_panel_rpci.dta
use "01_Data/02_Clean/clean_panel_empi_rpci.dta", clear


* Create baseline variable for numeric variables

* Baseline mean wage
bysort idnss: egen base_sal_cierre_aux = mean(sal_cierre) if periodo_year == 2020
bysort idnss: egen base_sal_cierre = max(base_sal_cierre_aux)
xtile base_sal_decile = base_sal_cierre, nq(10)

* Baseline wage standard deviation
bysort idnss: egen base_sal_cierre_sd_aux = sd(sal_cierre) if periodo_year == 2020
bysort idnss: egen base_sal_cierre_sd = max(base_sal_cierre_sd_aux)
replace base_sal_cierre_sd = 0 if missing(base_sal_cierre_sd) & !missing(base_sal_cierre)

* Baseline eventual job dummy
bysort idnss: egen base_te_aux = mean(te) if periodo_year == 2020
bysort idnss: egen base_te = max(base_te_aux)
replace base_te = round(base_te)

* Baseline government job dummy
bysort idnss: egen base_gobierno_aux = mean(gobierno) if periodo_year == 2020
bysort idnss: egen base_gobierno = max(base_gobierno_aux)
replace base_gobierno = round(base_gobierno)

* Baseline outsourcing job dummy
bysort idnss: egen base_outsourcing_aux = mean(outsourcing) if periodo_year == 2020
bysort idnss: egen base_outsourcing = max(base_outsourcing_aux)
replace base_outsourcing = round(base_outsourcing)



* Create baseline variable for numeric categoric variables
* Keep the values of the last available observation from 2020 and backwards
bysort idnss: egen base_periodo_alta = max(periodo_monthly) if idreg !=. & periodo_year <= 2020

* Baseline modality variable
*bysort idnss: gen base_mod_aux = mod if periodo_monthly == base_periodo_alta & base_periodo_alta < tm(2021m1)
*bysort idnss: egen base_mod = max(base_mod_aux)

* Baseline state variable
bysort idnss: gen base_cve_ent_final_aux = cve_ent_final if periodo_monthly == base_periodo_alta & base_periodo_alta < tm(2021m1)
bysort idnss: egen base_cve_ent_final = max(base_cve_ent_final_aux)

* Baseline industry variable
bysort idnss: gen base_div_final_aux = div_final if periodo_monthly == base_periodo_alta & base_periodo_alta < tm(2021m1)
bysort idnss: egen base_div_final = max(base_div_final_aux)

* Baseline age group
bysort idnss: gen base_rango_aux = rango if periodo_monthly == base_periodo_alta & base_periodo_alta < tm(2021m1)
bysort idnss: egen base_rango = max(base_rango_aux)

* Baseline firm size group
bysort idnss: gen base_size_cierre_aux = size_cierre if periodo_monthly == base_periodo_alta & base_periodo_alta < tm(2021m1)
bysort idnss: egen base_size_cierre = max(base_size_cierre_aux)

* Resort database
gsort idnss periodo_monthly



*******************
* Create features *
*******************

* Create a download dummy if a worker ever downloaded the app
bysort idnss: egen treated_nss = max(rpci_vig)

* Create a download dummy if any worker within a firm ever downloaded the app
bysort idrfc: egen treated_rfc = max(rpci_vig)


* Count the number of workers at each firm at each period
bysort idrfc periodo: gen rfc_nss = _N 

* Count the total number and percentage of workers that have downloaded the app 
* till month t at firm j, and a dummy where 1 means the firm had at least one worker
* download the app till month t.
bysort idrfc periodo: egen rfc_rpci_vig_tot = total(rpci_vig)
gen perc_rpci_vig = rfc_rpci_vig_tot / rfc_nss
gen perc_rpci_vig_exclu = (rfc_rpci_vig_tot - rpci_vig) / (rfc_nss - 1)
gen rfc_rpci_vig_dum = [perc_rpci_vig_exclu != 0]

* Gen a dummy if the worker downloaded the dummy during that month
gen rpci = [periodo_monthly == download_monthly]

* Count the total number and percentage of workers that have downloaded the app 
* during month t at firm j, and a dummy where 1 means the firm had at least one worker
* download the app during month t.
bysort idrfc periodo: egen rfc_rpci_tot = total(rpci)
gen perc_rpci = rfc_rpci_tot / rfc_nss
gen perc_rpci_exclu = (rfc_rpci_tot - rpci) / (rfc_nss - 1)
gen rfc_rpci_dum = [perc_rpci_exclu != 0]

* Create log_sal_cierre
gen log_sal_cierre = log(sal_cierre)



***********************
* Filter the database *
***********************

* Drop observations for periods before the RPCI launch
drop if periodo_monthly <= tm(2021m1)


* Drop auxiliar dummies
drop *_aux base_periodo_alta

* Save as panel_rpci.dta
save "01_Data/03_Working/panel_empi_rpci.dta", replace
