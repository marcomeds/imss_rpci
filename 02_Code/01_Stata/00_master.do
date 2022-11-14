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


*do "02_Code/01_Stata/01_clean_panel_rpci.do"
*do "02_Code/01_Stata/03_twfe_wage_rpci.do"
*do "02_Code/01_Stata/03_twfe_job_rpci.do"
*do "02_Code/01_Stata/04_twfe_wage_heterogeneity_rpci.do"
*do "02_Code/01_Stata/04_twfe_job_heterogeneity_rpci.do"
do "02_Code/01_Stata/05_did_multiplegt_rpci.do"
do "02_Code/01_Stata/05_did_multiplegt_heterogeneity_rpci.do"
do "02_Code/01_Stata/hist_wage_time_since_treated.do.do"
