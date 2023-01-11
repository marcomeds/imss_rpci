clear
set more off

local user "Marco"

global muestra = "muestra_1porciento"

global star "star(* 0.1 ** 0.05 *** 0.01)"
	
if "`user'" == "Marco" {
	global directory "/Users/marcomedina/ITAM Seira Research Dropbox/Marco Alejandro Medina/imss_rpci"
	cd "$directory"
	}

if "`user'" == "Marco Desktop" {
	global directory "C:/Users/Guest/ITAM Seira Research Dropbox/Marco Alejandro Medina/imss_rpci"
	cd "$directory"
}

if "`user'" == "Marco Remote" {
	global directory "E:\DATA\IMSS"
	cd "$directory"
}


*do "02_Code/01_Stata/A_01_clean_panel_rpci.do"
*do "02_Code/01_Stata/A_03_twfe_wage_rpci.do"
*do "02_Code/01_Stata/A_03_twfe_job_rpci.do"
*do "02_Code/01_Stata/A_04_twfe_wage_heterogeneity_rpci.do"
*do "02_Code/01_Stata/A_04_twfe_job_heterogeneity_rpci.do"
do "02_Code/01_Stata/A_05_did_multiplegt_rpci.do"
do "02_Code/01_Stata/A_05_did_multiplegt_heterogeneity_rpci.do"
do "02_Code/01_Stata/A_06_twfe_beta_cohort_rpci.do"
do "02_Code/01_Stata/hist_wage_time_since_treated.do.do"


do "02_Code/01_Stata/B_01_clean_panel_empi.do"
do "02_Code/01_Stata/B_02_peer_effects_empi_rpci.do"

do "02_Code/01_Stata/C_01_clean_worker_survey.do"

