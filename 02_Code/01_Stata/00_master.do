clear
set more off

local user "Marco"

global muestra = "muestra_1porciento"

global star "star(* 0.1 ** 0.05 *** 0.01)"
global stars "label nogaps fragment nonumbers noobs star(* 0.10 ** 0.05 *** 0.01) collabels(none) booktabs"
	
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

log using "02_Code/01_Stata/imss_rpci.txt", replace

do "02_Code/01_Stata/A_01_clean_panel_rpci.do"
do "02_Code/01_Stata/A_02_summary_stats_rpci.do"
do "02_Code/01_Stata/A_03_twfe_rpci.do"
do "02_Code/01_Stata/A_04_dcdh_heterogeneity_rpci.do"
do "02_Code/01_Stata/A_05_event_study_rpci.do"
do "02_Code/01_Stata/A_06_twfe_beta_cohort_rpci.do"
do "02_Code/01_Stata/A_07_yearly_volatility_rpci.do"
do "02_Code/01_Stata/A_08_hist_time_since_treated.do"

do "02_Code/01_Stata/B_01_clean_panel_empi.do"
do "02_Code/01_Stata/B_02_peer_effects_empi_rpci.do"
do "02_Code/01_Stata/B_03_twfe_dcdh_empi_rpci.do"

*do "02_Code/01_Stata/C_01_clean_worker_survey.do"

log close

