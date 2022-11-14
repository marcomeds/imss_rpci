*ssc install find
*ssc install rcd
 
*******************************************************************************/
clear
set more off
 
 
rcd "$directory/02_Code/01_Stata"  : find *.do , match(i.cve) show
