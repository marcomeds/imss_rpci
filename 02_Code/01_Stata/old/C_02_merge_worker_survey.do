/*******************************************************************************
@Name: merge_worker_survey.do

@Author: Marco Medina

@Date: 09/02/2022

@In: - Group1_All_workers_links_wo_repeated.csv
	 - Group1_All_workers_repeated.csv
	 - rpci_altas.dta
	 - worker_surveymonkey.dta
	 
@Out: worker_survey.dta
	  worker_surveymonkey_initials.dta
*******************************************************************************/

********************
version 17.0
clear all
cd "$directory"
********************

**********************************
* Worker Survey All Observations * 
**********************************

* Import Group1_All_workers_repeated.csv
* Note: this database is unique at idnss level, but has repeated emails.
import delimited "01_Data/01_Raw/02_Randomization/Group1_All_workers_repeated.csv", clear

* Keep relevant variables
keep correo_persona_1 correo_persona_2 idnss

* Merge with IMSS_Final_grupo1.dta
* Note: this database is unique at worker email level, and contains the randomization.
merge m:1 correo_persona_1 using "01_Data/01_Raw/02_Randomization/IMSS_Final_grupo1.dta", gen(merge_final)

* Note: all observations from both master and using should match, since 
* IMSS_Final_grupo1 is a subset of Group1_All_workers_repeated.
tab merge_final

* Merge with rpci_altas.dta to know who downloaded the app. 
merge 1:1 idnss using "01_Data/02_Clean/rpci_descargas.dta", gen(merge_rpci)

* Note: all observations from master and using should match, since 
* Group1_All_workers_repeated is the same  set as rpci_descargas.
tab merge_rpci

* Merge with worker_surveymonkey.dta
merge 1:1 idnss using "01_Data/02_Clean/worker_surveymonkey.dta", gen(merge_surveymonkey)

* Note: not all observations from master should match, since not all answer the 
* survey. Some observations from using don't match since some idnss are modified
keep if merge_surveymonkey == 1 | merge_surveymonkey == 3

* Keep relevant variables
keep correo_persona_1 correo_persona_2 idnss index correo_empresa_1 correo_empresa_2 ///
	idrfc Arm_worker Arm_firm Strata download_date download treatment survey_date  ///
	complete_survey merge_surveymonkey fired_last_3_years received_compensation ///
	filed_lawsuit lawsuit_outcome
	
* Save database
save "01_Data/03_Working/worker_survey.dta", replace

******************************
* Worker Survey Only Answers *
******************************

* Use worker_survey.dta
use "01_Data/03_Working/worker_survey.dta", clear

* Merge with rpci_anonimizada.dta
merge 1:1 idnss using "01_Data/02_Clean/rpci_anonimizada.dta", keep(3) nogen

* Save database with worker characteristics
save "01_Data/03_Working/worker_surveymonkey_initials.dta", replace
