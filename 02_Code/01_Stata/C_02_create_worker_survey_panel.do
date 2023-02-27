/*******************************************************************************
@Name: create_worker_survey_panel.do

@Author: Marco Medina

@Description: Get a sample for IMSS to create a panel with RPCI data. The sample
			  has two parts. First, workers in a random sample of all the emails
			  in the original randomization. Second, the complete list of all
			  workers associated with emails that answered the worker survey.

@Date: 03/01/2023

@In: - Group1_All_workers_links_wo_repeated.csv
	 - Group1_All_workers_repeated.csv
	 - rpci_altas.dta
	 - clean_worker_survey.dta
	 
@Out: worker_survey_panel_sample.dta
	  base_encuestados.csv
*******************************************************************************/

********************
version 17.0
clear all
cd "$directory"
********************

*****************
* Random Sample * 
*****************

* This database is unique at worker email level, and contains the randomization.
use "01_Data/01_Raw/02_Randomization/IMSS_Final_grupo1.dta", clear

* Set seed
set seed 51982438

* Sort by correo_persona_1
sort correo_persona_1

* Generate the random number variable.
generate random = runiform()

* Create a 10% random sample of emails
generate random_sample = 0
replace random_sample = 1 if random <= 0.1

* Keep relevant variables
keep idnss correo_persona_1 Arm_worker random_sample

* Create tempfile
tempfile randomization
save `randomization'



*************************
* Worker Survey Answers * 
*************************

* This database is contains the worker survey answers
use "01_Data/02_Clean/clean_worker_survey.dta", clear

* Keep the idnss that answered the survey
keep idnss
duplicates drop idnss, force

* Create tempfile
tempfile survey_idnss
save `survey_idnss'



*****************
* Workers IDNSS * 
*****************

* The randomization has unique emails and an idnss for each email. The worker 
* survey registered this idnss. Repeated emails are associated with multiple 
* idnss, not only the one that ended in the randomization. 

* Import Group1_All_workers_repeated.csv
* Note: this database is unique at idnss level, but has repeated emails.
import delimited "01_Data/01_Raw/02_Randomization/Group1_All_workers_repeated.csv", clear

* Keep idnss and emails
keep idnss correo_persona_1

* Create tempfile
tempfile worker_idnss
save `worker_idnss'



*****************
* Actual Sample * 
*****************

* First, we merge the randimization with the actual survey answers.
* Note: a few answers don't merge since the worker may have modified the link
use `randomization', clear
merge 1:1 idnss using `survey_idnss', keep(1 3)
gen survey = [_merge == 3]
drop _merge

* Merge using the email to the worker_idnss database to retrieve ALL the workers
* associated witht the emails.
merge 1:m correo_persona_1 using `worker_idnss', nogen

* Create a dummy for unique emails
duplicates tag correo_persona_1, gen(dup)
gen unique_email = [dup == 0]
drop dup

* Keep all emails in the random sample or in the survey answers
keep if random_sample == 1 | survey == 1

* Save the sample
save "01_Data/03_Working/worker_survey_panel_sample.dta", replace

* Keep variables to give the database to IMSS
keep idnss
export delimited using "01_Data/03_Working/base_encuestados.csv", replace
