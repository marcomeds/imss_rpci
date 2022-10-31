/*******************************************************************************
@Name: balance_panel_rpci.do

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

* Keep baseline variables and one observation per idnss
keep idnss treated sexo base*
duplicates drop

* Create dummies for state and firm's industry
xi i.base_mod, prefix(mod) noomit
xi i.base_cve_ent_final, prefix(ent) noomit
xi i.base_div_final, prefix(div) noomit
xi i.base_rango, prefix(ran) noomit
xi i.base_size_cierre, prefix(siz) noomit

*****************
* Balance table *
*****************

balancetable treated sexo base_sal_cierre base_te base_gobierno base_outsourcing mod* ent* div* ran* siz* using "03_Tables/$muestra/balance_table.xlsx", replace
*iebaltab sexo sal_cierre gobierno ent* div* outsourcing, grpvar(treated) save("03_Tables/Panel_RPCI_Balance.xlsx") replace

********************
* Balance by state *
********************

* Graph for states
matrix results = J(32, 5, .)

forvalues s = 1(1)32{
	reg entbase_cve_`s' treated
	
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
	(rcap rcap_lo_10 rcap_hi_10 d, lwidth(thick) lcolor(navy%70)), legend(off) scheme(s1manual) graphregion(color(white)) ///
	xlabel(none) title("Diferencias en descarga de RPCI por estado") xtitle("Estado") ytitle("Diferencia") yline(0) xsize(12) ysize(6)
	
graph export "04_Figures/$muestra/balance_ent_final_graph.pdf", replace	
