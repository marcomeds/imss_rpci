********************
version 17.0
clear all
cd "$directory"
********************

* Use panel_rpci.dta
use "01_Data/03_Working/panel_rpci.dta", clear

keep if treated == 1

* Keep observations for 2020
*keep if periodo_date <= date("31dec2020", "DMY")

* Create dummies for state and firm's industry
xi i.cve_ent_final, prefix(ent) noomit
xi i.div_final, prefix(div) noomit

*****************
* Balance table *
*****************

gen download_t = download_monthly - tm(2021m1)

keep if periodo_monthly == download_monthly

reghdfe download_t sexo sal_cierre gobierno ent* div* outsourcing, noabsorb

*balancetable download_monthly sexo sal_cierre gobierno outsourcing ent* div* using "03_Tables/Panel_RPCI_Balance_Table_Download_Date.xlsx", replace
*iebaltab sexo sal_cierre gobierno ent* div* outsourcing, grpvar(download_monthly) save("03_Tables/Panel_RPCI_Balance_Download_Date.xlsx") replace
