/*******************************************************************************
@Name: matching_panel_rpci.do

@Author: Marco Medina

@Date: 26/10/2022

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


*********************
* Matching Database *
*********************

* Keep observations with wage
keep if !missing(sal_cierre)

* Keep one observation per worker
duplicates drop idnss, force

* Keep workers with baseline variables
keep if !missing(base_sal_cierre)


* Drop control observations that have no exact matches with treatment observations
* and treatment / control observations with only one treated observation
egen exact_cov = group(base_div_final base_cve_ent_final sexo)
bysort exact_cov: egen mean_treat = mean(treated)
bysort exact_cov: egen sum_treat = sum(treated)
keep if mean_treat > 0 // this drops groups with no treated units
keep if sum_treat > 2 // this drops groups with one or two treated unit (impossible to get sd)


* nnmatch will order matches when there are ties by the order they appear in the database
* so we set a seed and order observations by a randome number to get a stable match
set seed 7384368
gen random = uniform()
sort random
gen match_id = _n


* Match the observation using exact match on firm industry, state and gender, nearest 
* neighbor matching for ordinal categorical variables & continous variables.
teffects nnmatch (sal_cierre base_sal_cierre base_sal_cierre_sd base_te ///
                  base_gobierno base_outsourcing i.base_rango i.base_size_cierre) ///
		 (treated), ematch(base_div_final base_cve_ent_final sexo) ///
		 osample(unmatched) gen(match)

* Keep relevant variables for the match
keep idnss match_id	match1	 

* Create a database with the worker id, the match id and the matched id
preserve
rename match1 matched_id
tempfile match_id
save `match_id'

* Create a database with the worker and match id. 
* Rename the match id as matched id to perform the merge.
restore
drop match1
rename idnss idnss_match
rename match_id matched_id
tempfile matched_id
save `matched_id'

* Merge the databases. Each worker can be matched to only one other worker, but
* several workers can be matched to the same worker.
use `match_id'
merge m:1 matched_id using `matched_id', keep(3)

* Keep the workers id
keep idnss idnss_match
sort idnss

* Save the database with the matching worker id's
save "01_Data/03_Working/matched_panel_rpci.dta", replace

