/*******************************************************************************
@Name: dcdh_heterogeneity_rpci.do

@Author: Marco Medina

@Date: 02/03/2023

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

* Gen heterogeneity variables
gen hombre = [sexo == 0]
gen mujer = [sexo == 1]

gen age_15_25 = [inlist(base_rango, 1, 2, 3)]
gen age_25_35 = [inlist(base_rango, 4, 5)]
gen age_35_45 = [inlist(base_rango, 6, 7)]
gen age_45_55 = [inlist(base_rango, 8, 9)]
gen age_55_65 = [inlist(base_rango, 10, 11)]
gen age_65 = [inlist(base_rango, 12, 13, 14)]

gen sal_min_1_2 = [inlist(base_num_sal_min, 1)]
gen sal_min_2_3 = [inlist(base_num_sal_min, 2)]
gen sal_min_3_5 = [inlist(base_num_sal_min, 3, 4)]
gen sal_min_5 = [base_num_sal_min >= 5]

gen frontera = [base_frontera == 1]
gen no_frontera = [base_frontera == 0]

gen reg_centro = [inlist(base_cve_ent_final, 9, 12, 13, 15, 17, 20, 21, 29)]
gen reg_centro_occ = [inlist(base_cve_ent_final, 1, 6, 11, 14, 16, 18, 22, 24, 32)]
gen reg_norte = [inlist(base_cve_ent_final, 2, 3, 5, 8, 10, 19, 25, 26, 28)]
gen reg_sur = [inlist(base_cve_ent_final, 4, 7, 23, 27, 30, 31)]

gen ind_agricul = [base_div_final == 0]
gen ind_transf = [base_div_final == 3]
gen ind_constr = [base_div_final == 4]
gen ind_commerce = [base_div_final == 6]
gen ind_transport = [base_div_final == 7]
gen ind_services = [base_div_final == 8 | base_div_final == 9]

gen size_1 = [base_size_cierre == 1]
gen size_2 = [base_size_cierre == 2]
gen size_6 = [base_size_cierre == 3]
gen size_51 = [base_size_cierre == 4]
gen size_251 = [base_size_cierre == 5]
gen size_501 = [base_size_cierre == 6]
gen size_1001 = [base_size_cierre == 7]

* Gen labels
label var hombre "Men"
label var mujer "Women"
label var base_outsourcing "Outsourcing"
label var base_te "Eventual"

label var age_15_25 "15 to 25 years old"
label var age_25_35 "25 to 35 years old"
label var age_35_45 "35 to 45 years old"
label var age_45_55 "45 to 55 years old"
label var age_55_65 "55 to 65 years old"
label var age_65 "65+ years old"

label var sal_min_1_2 "1 to 2 minimum wages"
label var sal_min_2_3 "2 to 3 minimum wages"
label var sal_min_3_5 "3 to 5 minimum wages"
label var sal_min_5 "More than 5 minimum wages"

label var frontera "MX-USA Border"
label var no_frontera "Away from MX-USA Border"

label var reg_centro "Central"
label var reg_centro_occ "Central-West"
label var reg_norte "North"
label var reg_sur "South-East"

label var ind_agricul "Agriculture"
label var ind_transf "Transformation"
label var ind_constr "Construction"
label var ind_commerce "Commerce"
label var ind_transport "Transportation & Communication"
label var ind_services "Services"

label var size_1 "1 worker"
label var size_2 "2-5 workers"
label var size_6 "6-50 workers"
label var size_51 "51-250 workers"
label var size_251 "251-500 workers"
label var size_501 "501-1000 workers"
label var size_1001 "1000+ workers"

* Define variables
local vars alta sal_formal sal_cierre log_sal_cierre cambio_cierre sal_diff
local hetero_vars hombre mujer base_outsourcing base_te ///
				  age_15_25 age_25_35 age_35_45 age_45_55 age_55_65 age_65 ///
				  sal_min_1_2 sal_min_2_3 sal_min_3_5 sal_min_5 ///
				  frontera no_frontera ///
				  reg_centro reg_centro_occ reg_norte reg_sur ///
				  ind_agricul ind_transf ind_constr ind_commerce ind_transport ind_services ///
				  size_1 size_2 size_6 size_51 size_251 size_501 size_1001

********************************************
* De Chaisemartin & d'Haultfoeuille (2020) *
********************************************

foreach dep_var in `vars' {
	
	foreach het_var in `hetero_vars' {
	
	did_multiplegt `dep_var' download_monthly periodo_monthly rpci_vig if `het_var', ///
				   first robust_dynamic dynamic(12) placebo(24) breps(250) cluster(idnss) seed(541314)
				   
	mat `dep_var'_b_dcdh  = nullmat(`dep_var'_b_dcdh), e(effect_average)
	mat `dep_var'_se_dcdh = nullmat(`dep_var'_se_dcdh), e(se_effect_average)
	
	
	* Event study	   
	event_plot e(didmgt_estimates)#e(didmgt_variances), stub_lag(Effect_#) stub_lead(Placebo_#) ///
	       together plottype("scatter") trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134"))

	graph export "04_Figures/$muestra/event_study_`depvar'_`het_var'_dcdh.pdf", replace
	
	* Connected event study	   
	event_plot e(didmgt_estimates)#e(didmgt_variances), stub_lag(Effect_#) stub_lead(Placebo_#) ///
		   together trimlead(12) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-12(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45"))

	graph export "04_Figures/$muestra/event_study_`depvar'_`het_var'_dcdh_connected.pdf", replace
	
	* Connected event study	- paper
	event_plot e(didmgt_estimates)#e(didmgt_variances), stub_lag(Effect_#) stub_lead(Placebo_#) ///
		   together trimlead(24) trimlag(12) ///
		   graph_opt(xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) ///
		   graphregion(color(white)) xlabel(-24(2)12) xsize(7.5) ///
		   xtitle("Months since registering for the RPCI") ytitle("Average effect") ///
		   title("")) ///
		   lag_opt1(msymbol(O) color("0 69 134")) lag_ci_opt1(color("0 69 134 %45"))

	graph export "04_Figures/$muestra/event_study_`depvar'_`het_var'_dcdh_connected_paper.pdf", replace
	
	}
	
	mat `dep_var'_b_dcdh_t = `dep_var'_b_dcdh'
	mat `dep_var'_se_dcdh_t = `dep_var'_se_dcdh'
	
	mat b_dcdh = nullmat(b_dcdh), `dep_var'_b_dcdh_t
	mat se_dcdh = nullmat(se_dcdh), `dep_var'_se_dcdh_t
}

foreach mat in b_dcdh se_dcdh {
	
	* Add column and row names
	mat coln `mat' = `vars'
	mat rown `mat' = `hetero_vars'
	
	* Make the matrix a dataset
	clear
	svmat `mat', names(col)
	
	* Create a column with the matrix rownames
	local rownames: rownames `mat'
	di "`rownames'"
	local rows = rowsof(`mat')
	di `rows'
	gen hetero_var = ""

	forvalues i = 1 / `rows' {
		local rowname = word("`rownames'", `i')
		replace hetero_var = "`rowname'" if _n == `i'
	}

	* Export the dataset
	export delimited using "01_Data/04_Temp/`mat'_heterogeneity.csv", replace delim("|")
}

*matrix list b_dcdh
*matrix list se_dcdh

