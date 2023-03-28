/*******************************************************************************
@Name: features_worker_survey.do

@Author: Marco Medina

@Date: 03/01/2023

@In: - clean_worker_survey.dta
	 - worker_survey_panel_sample.dta
	 
@Out: worker_survey.dta
*******************************************************************************/

********************
version 17.0
clear all
cd "$directory"
********************



*************************
* Merge with admin data *
*************************

* Use worker_survey_panel_sample.dta
* Each survey answer has an associated idnss.
* Each idnss is linked to an email.
* Emails could be duplicated. 
* We randomized at email level.
* In the final list of survey links we chose one idnss at random if email was duplicated.
* This database already merged survey (idnss)-> admin (email)-> admin.
use "01_Data/03_Working/worker_survey_panel_sample.dta", clear
keep if survey == 1
keep correo_persona_1 idnss Arm_worker unique_email
duplicates drop

* Create tempfile
tempfile worker_email_idnss
save `worker_email_idnss'



* Use rpci_anonimizada_202108.dta
* It's the original data given for the experiment randomization
use "01_Data/01_Raw/02_Randomization/rpci_anonimizada_202108.dta", clear

* Keep wages
keep correo_persona_1 idnss sal_mes
gsort -sal_mes
duplicates drop correo_persona_1 idnss, force

* Merge
merge 1:1 correo_persona_1 idnss using `worker_email_idnss', keep(3) nogen

* Make wage missing if it comes from a duplicated email
* This wages are not exact
replace sal_mes = . if unique_email == 0
drop correo_persona_1

* Merge with survey
merge 1:1 idnss using "01_Data/02_Clean/clean_worker_survey.dta", keep(3) nogen

*******************
* Create features *
*******************

* Survey Date 
gen survey_created = clock(date_created, "MDY hms")
gen survey_date = dofc(survey_created)
format survey_date %td
drop survey_created

* Complete Survey
* Note: the last question of control & treatment surveys is different
gen complete_survey_control = [treatment == 0 & used_private_medical_service != .]
gen complete_survey_treat = [treatment == 1 & knows_can_sue != .]
gen complete_survey = [complete_survey_treat == 1 | complete_survey_control == 1]
drop complete_survey_control complete_survey_treat

* Wage gaps
gen wage_daily_exact = sal_mes
gen perc_wage_reported = wage_daily_reported_approx / wage_daily_approx  
gen perc_wage_exact = wage_daily_exact / wage_daily_approx
gen perc_wage_rep_exact = wage_daily_exact / wage_daily_reported_approx

* Save database
save "01_Data/03_Working/worker_survey.dta", replace
export delimited using "01_Data/03_Working/worker_survey.csv", delim("|") replace
