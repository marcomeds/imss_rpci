/*******************************************************************************
@Name: clean_worker_survey.do

@Author: Marco Medina

@Date: 03/01/2023

@In: - Empleados_Tratamiento.csv
	 - Empleados_Control.csv
	 
@Out: clean_worker_survey.dta
*******************************************************************************/

********************
version 17.0
clear all
cd "$directory"
********************

* Last update date from Survey Monkey
local last_update_worker_survey = "20220511"

*************************
* Control Worker Survey *
*************************

* Import Control Worker Survey from Survey Monkey
import delimited "01_Data/01_Raw/03_SurveyMonkey/Empleados_Control_`last_update_worker_survey'.csv", clear

* Delete first observation from the database
drop if respondent_id == .

* Generate treatment dummy
gen treatment = 0

* Save temporal database
tempfile worker_control_survey
save `worker_control_survey'



***************************
* Treatment Worker Survey *
***************************

* Import Treatment Worker Survey from Survey Monkey
import delimited "01_Data/01_Raw/03_SurveyMonkey/Empleados_Tratamiento_`last_update_worker_survey'.csv", clear

* Delete first observation from the database
drop if respondent_id == .

* Generate treatment dummy
gen treatment = 1

* Save temporal database
*tempfile worker_treat_survey
*save `worker_treat_survey'



**********
* Append *
**********

* Append Control Worker Survey from Survey Monkey
append using `worker_control_survey'



********************
* Rename variables *
********************

rename enagosto2021ustedteníatrabajo had_job_august21

rename sigueteniendoesetrabajo still_has_job

rename tienetrabajoeldíadehoy has_job_today

rename hacecuántotiemposaliódesuúltimot date_last_job

rename enesetrabajosupatrónlotuvoregist registered_imss

rename supatrónreportóalimsselsalarioqu reported_complete_wage

rename enlosúltimos3años20192021locorri fired_last_3_years

rename laúltimavezquesucedióestolepagar received_compensation

rename legustaríatenerinformaciónsobrel would_like_information

rename laúltimavezquelodespidieronlosde filed_lawsuit

* Mutiple answer question. Answers are in variables v20-v24
rename porquénodemandóconunabogadoselec v20

rename cómoencontróasuabogado how_lawyer_was_found

rename cuálfueelresultadodelademanda lawsuit_outcome

rename cuántosempleadosaproximadamentet num_employees

rename conquefrecuencialepagabansusalar wage_frequency

rename cuálesofuesuúltimosalariodiarioe wage_daily

rename cuálcreequeeraelsalariodiarioque wage_daily_reported

rename cuálesofuesuúltimosalariosemanal wage_weekly

rename cuálcreequeeraelsalariosemanalqu wage_weekly_reported

rename cuálesofuesuúltimosalarioquincen wage_biweekly

rename cuálcreequeeraelsalarioquincenal wage_biweekly_reported

rename cuálesofuesuúltimosalariomensual wage_monthly

rename cuálcreequeeraelsalariomensualqu wage_monthly_reported

rename cuántosempleadosdesuempresacreeq perc_employees_registered

* This is a randomized pair of questions with multiple answers. This variable
* contains the question and v39 - v45 the answers.
rename cuálescreeustedquesonlosbenefici aux_benefits

* This is a randomized pair of questions. This variable contains the question
* and v45 the answers.
rename sabíaustedquealestarregistradoen aux_insurance_reported_wage

* This is a randomized pair of questions. This variable contains the question
* and v47 the answers.
rename sabíaustedquepartedelsalarioques aux_retiro_afore

rename sinotuvieraimssquémontoestaríadi annual_willing_imss_payment

rename preferiríanotenerimssyquesusalar prefers_imss_over_10_perc

rename del0al10dondeceroesmuymalacalida imss_service_quality

rename enlosúltimos12meseshausadolosser used_imss_medical_service

rename enlosúltimos12mesesusóunservicio used_private_medical_service

rename sabíaquesepuederealizarunadenunc knows_can_sue

rename id idnss



******************
* Code variables *
******************
* Note: using encode makes the final merged database too heavy, so we manually encode

gen aux = .
replace aux = 1 if had_job_august21 == "Sí"
replace aux = 0 if had_job_august21 == "No"
drop had_job_august21
rename aux had_job_august21


gen aux = .
replace aux = 1 if still_has_job == "Sí"
replace aux = 0 if still_has_job == "No"
drop still_has_job
rename aux still_has_job


gen aux = .
replace aux = 1 if has_job_today == "Sí"
replace aux = 0 if has_job_today == "No"
drop has_job_today
rename aux has_job_today


gen last_job_date = date(date_last_job, "MDY")
format last_job_date %td
drop date_last_job


gen aux = .
replace aux = 1 if registered_imss == "Sí"
replace aux = 0 if registered_imss == "No"
replace aux = -1 if registered_imss == "No sé"
drop registered_imss
rename aux registered_imss


gen aux = .
replace aux = 1 if reported_complete_wage == "Sí"
replace aux = 0 if reported_complete_wage == "No"
replace aux = -1 if reported_complete_wage == "No sé"
drop reported_complete_wage
rename aux reported_complete_wage


gen aux = .
replace aux = 1 if fired_last_3_years == "Sí"
replace aux = 0 if fired_last_3_years == "No"
drop fired_last_3_years
rename aux fired_last_3_years


gen aux = .
replace aux = 1 if received_compensation == "Sí"
replace aux = 0 if received_compensation == "No"
drop received_compensation
rename aux received_compensation


gen aux = . 
replace aux = 1 if would_like_information == "Sí"
replace aux = 0 if would_like_information == "No"
drop would_like_information
rename aux would_like_information


gen aux = .
replace aux = 1 if filed_lawsuit == "Sí"
replace aux = 0 if filed_lawsuit == "No"
drop filed_lawsuit
rename aux filed_lawsuit


* Mutiple answer question. Answers are in variables v20-v24
gen no_lawsuit_doesnt_work = .
replace no_lawsuit_doesnt_work = 1 if v20 == "No sirve de nada" & filed_lawsuit == 0
replace no_lawsuit_doesnt_work = 0 if v20 == "" & filed_lawsuit == 0

gen no_lawsuit_didnt_know = .
replace no_lawsuit_didnt_know = 1 if v21 == "No sabía que se podía" & filed_lawsuit == 0
replace no_lawsuit_didnt_know = 0 if v21 == "" & filed_lawsuit == 0

gen no_lawsuit_no_lawyer = .
replace no_lawsuit_no_lawyer = 1 if v22 == "No sabía que se podía" & filed_lawsuit == 0
replace no_lawsuit_no_lawyer = 0 if v22 == "" & filed_lawsuit == 0

gen no_lawsuit_expensive = .
replace no_lawsuit_expensive = 1 if v23 == "Me sale caro" & filed_lawsuit == 0
replace no_lawsuit_expensive = 0 if v23 == "" & filed_lawsuit == 0

gen no_lawsuit_innecessary = .
replace no_lawsuit_innecessary = 1 if v24 == "No fue necesario, me pagaron liquidación" & filed_lawsuit == 0
replace no_lawsuit_innecessary = 0 if v24 == "" & filed_lawsuit == 0

drop v20 v21 v22 v23 v24


gen aux = ""
replace aux = "internet" if how_lawyer_was_found == "En internet"
replace aux = "junta" if how_lawyer_was_found == "En la Junta de Conciliación"
replace aux = "recommendation" if how_lawyer_was_found == "Me lo recomendó un conocido"
replace aux = "other" if how_lawyer_was_found == "Otro"
drop how_lawyer_was_found
rename aux how_lawyer_was_found


gen aux = ""
replace aux = "won trial" if lawsuit_outcome == "La gané en juicio"
replace aux = "lost trial" if lawsuit_outcome == "La perdí en juicio"
replace aux = "paid agreement" if lawsuit_outcome == "Llegué a un acuerdo y me pagaron"
replace aux = "unpaid agreement" if lawsuit_outcome == "Llegué a un acuerdo y no me pagaron"
replace aux = "removed" if lawsuit_outcome == "Quité la demanda"
replace aux = "continues" if lawsuit_outcome == "Sigue la demanda"
drop lawsuit_outcome
rename aux lawsuit_outcome


destring num_employees, replace force


gen aux = ""
replace aux = "daily" if wage_frequency == "diario"
replace aux = "weekly" if wage_frequency == "semanal"
replace aux = "biweekly" if wage_frequency == "quincenal"
replace aux = "monthly" if wage_frequency == "mensual"
replace aux = "other" if wage_frequency == "Ninguna de las anteriores"
drop wage_frequency
rename aux wage_frequency


destring wage_daily* wage_weekly* wage_biweekly* wage_monthly*, replace force

gen wage_daily_approx = .
replace wage_daily_approx = wage_monthly/28 if wage_monthly != .
replace wage_daily_approx = wage_biweekly/14 if wage_biweekly !=.
replace wage_daily_approx = wage_weekly/7 if wage_weekly !=.
replace wage_daily_approx = wage_daily if wage_daily !=.

gen wage_daily_reported_approx = .
replace wage_daily_reported_approx = wage_daily_reported/28 if wage_monthly_reported != .
replace wage_daily_reported_approx = wage_biweekly_reported/14 if wage_biweekly_reported !=.
replace wage_daily_reported_approx = wage_weekly_reported/7 if wage_weekly_reported !=.
replace wage_daily_reported_approx = wage_daily_reported if wage_daily_reported !=.


* This is a randomized pair of questions with multiple answers.
gen aux_39 = .
replace aux_39 = 1 if strpos(aux_benefits, "Algunas prestaciones y beneficios que se tienen")
replace aux_39 = 0 if strpos(aux_benefits, "¿Cuáles cree usted que son los beneficios")

gen benefits_wage_aguinaldo = .
replace benefits_wage_aguinaldo = 1 if aux_39 == 1 & v39 == "Pago aguinaldo"
replace benefits_wage_aguinaldo = 0 if aux_39 == 1 & v39 == ""
gen benefits_wage_insurance = .
replace benefits_wage_insurance = 1 if aux_39 == 1 & v40 == "Seguros de incapacidad y riesgos de trabajo"
replace benefits_wage_insurance = 0 if aux_39 == 1 & v40 == "" 
gen benefits_wage_retirement = .
replace benefits_wage_retirement = 1 if aux_39 == 1 & v41 == "Ahorro para el retiro automático"
replace benefits_wage_retirement = 0 if aux_39 == 1 & v41 == ""
gen benefits_wage_medical = .
replace benefits_wage_medical = 1 if aux_39 == 1 & v42 == "Atención médica"
replace benefits_wage_medical = 0 if aux_39 == 1 & v42 == ""
gen benefits_wage_vacation = .
replace benefits_wage_vacation = 1 if aux_39 == 1 & v43 == "Más vacaciones"
replace benefits_wage_vacation = 0 if aux_39 == 1 & v43 == ""

gen benefits_imss_aguinaldo = .
replace benefits_imss_aguinaldo = 1 if aux_39 == 0 & v39 == "Pago aguinaldo"
replace benefits_imss_aguinaldo = 0 if aux_39 == 0 & v39 == ""
gen benefits_imss_insurance = .
replace benefits_imss_insurance = 1 if aux_39 == 0 & v40 == "Seguros de incapacidad y riesgos de trabajo"
replace benefits_imss_insurance = 0 if aux_39 == 0 & v40 == "" 
gen benefits_imss_retirement = .
replace benefits_imss_retirement = 1 if aux_39 == 0 & v41 == "Ahorro para el retiro automático"
replace benefits_imss_retirement = 0 if aux_39 == 0 & v41 == ""
gen benefits_imss_medical = .
replace benefits_imss_medical = 1 if aux_39 == 0 & v42 == "Atención médica"
replace benefits_imss_medical = 0 if aux_39 == 0 & v42 == ""
gen benefits_imss_vacation = .
replace benefits_imss_vacation = 1 if aux_39 == 0 & v43 == "Más vacaciones"
replace benefits_imss_vacation = 0 if aux_39 == 0 & v43 == ""

drop aux_benefits aux_39 v39 v40 v41 v42 v43


* This is a randomized pair of questions.
gen aux_45 = .
replace aux_45 = 1 if strpos(aux_insurance_reported_wage, "¿Sabía usted que al estar registrado en el IMSS")
replace aux_45 = 0 if strpos(aux_insurance_reported_wage, "¿En algún momento platicó con su patrón")
gen knows_accident_insurance = .
replace knows_accident_insurance = 1 if aux_45 == 1 & v45 == "Sí"
replace knows_accident_insurance = 0 if aux_45 == 1 & v45 == "No"
gen talked_reported_wage = .
replace talked_reported_wage = 1 if aux_45 == 0 & v45 == "Sí"
replace talked_reported_wage = 0 if aux_45 == 0 & v45 == "No"
drop aux_insurance_reported_wage aux_45 v45


* This is a randomized pair of questions.
gen aux_47 = .
replace aux_47 = 1 if strpos(aux_retiro_afore, "¿Sabía usted que parte del salario")
replace aux_47 = 0 if strpos(aux_retiro_afore, "¿Tiene AFORE (son las empresas")
gen has_afore = .
replace has_afore = 1 if aux_47 == 1 & v47 == "Sí"
replace has_afore = 0 if aux_47 == 1 & v47 == "No"
gen knows_wage_impact_savings = .
replace knows_wage_impact_savings = 1 if aux_47 == 0 & v47 == "Sí"
replace knows_wage_impact_savings = 0 if aux_47 == 0 & v47 == "No"
drop aux_retiro_afore aux_47 v47


destring annual_willing_imss_payment, replace


gen aux = .
replace aux = 1 if prefers_imss_over_10_perc == "Tener IMSS"
replace aux = 0 if prefers_imss_over_10_perc == "No tener IMSS y que mi salario aumentara 10%"
drop prefers_imss_over_10_perc
rename aux prefers_imss_over_10_perc


destring imss_service_quality, replace


gen aux = .
replace aux = 1 if used_imss_medical_service == "Sí"
replace aux = 0 if used_imss_medical_service == "No"
drop used_imss_medical_service
rename aux used_imss_medical_service


gen aux = .
replace aux = 1 if used_private_medical_service == "Sí"
replace aux = 0 if used_private_medical_service == "No"
drop used_private_medical_service
rename aux used_private_medical_service


gen aux = .
replace aux = 1 if knows_can_sue == "Sí sabía"
replace aux = 0 if knows_can_sue == "No sabía"
drop knows_can_sue
rename aux knows_can_sue


destring idnss, replace force

* Drop observations
drop if idnss == .


********
* Save *
********

* Keep relevant variables
drop respondent_id collector_id ip_address email_address first_name last_name custom_1 

* Drop duplicates
duplicates drop idnss, force

* Save database
save "01_Data/02_Clean/clean_worker_survey.dta", replace


