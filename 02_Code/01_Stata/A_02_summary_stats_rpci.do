/*******************************************************************************
@Name: summary_stats_rpci.do

@Author: Marco Medina

@Date: 27/03/2023

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

* Define variables
local vars treated alta sexo outsourcing te sal_cierre 

* Gen labels
label var sexo "Women"
label var outsourcing "Outsourcing"
label var te "Eventual"
label var treated "Registered for RPCI"
label var alta "Enrolled"



***********************
* Summary stats table *
***********************

est clear
estpost tabstat `vars', c(stat) stat(mean sd n)
   
esttab using "03_Tables/$muestra/summary_stats_rpci.tex", replace ////
 cells("mean(fmt(%12.2fc)) sd(fmt(%12.2fc)) count(fmt(%12.0fc))") nonumber ///
  nomtitle nonote noobs label booktabs fragment ///
  collabels("Mean" "SD" "N")
