************
* Programs *
************

* Create TWFE / DiD tables with the mean, the number of workers and firms in each regression.
capt prog drop my_did
program my_did, eclass

syntax varlist [if] [in], treatment(varname) clus_id(varname) absorb(string) [ * ]
	
	marksample touse
	markout `touse' `by'
	*gettoken dep_var: varlist
	tempname p_1 obs dep_mean unique_idnss unique_idrfc
	
	foreach dep_var of local varlist {
		reghdfe `dep_var' `treatment' `if', absorb(`absorb') cluster(`clus_id')
		test (_b[`treatment']== 0)
		mat `p_1' = nullmat(`p_1'), r(p)
		mat `obs' = nullmat(`obs'), e(N)
		
		* Dependant variable mean in the sample used in the regression
		quietly summ `dep_var' if e(sample) == 1
		mat `dep_mean' = nullmat(`dep_mean'), r(mean)
	
		* Number of workers in the sample used in the regression
		distinct idnss if e(sample) == 1
		mat `unique_idnss' = nullmat(`unique_idnss'), r(ndistinct)
	
		* Number of firms in the sample used in the regression
		distinct idrfc if e(sample) == 1
		mat `unique_idrfc' = nullmat(`unique_idrfc'), r(ndistinct)
	}

	*foreach mat in p_1 obs dep_mean unique_idnss unique_idrfc {
	*	mat coln ``mat'' = `varlist'
	*}

	local cmd "my_did"
	foreach mat in p_1 obs dep_mean unique_idnss unique_idrfc {
		eret mat `mat' = ``mat''
		
	}
end


		syntax varlist 

		marksample touse
		markout `touse' `by'
		tempname c_1 t_1  cse_1 tse_1  cN_1 tN_1  p_1   

		foreach var of local varlist {
			***REG WITH strata FIXED EFFECTS ***
			reghdfe `var'  `treatment'   ,  vce(cluster `clus_id') abs(`strata')
			test (_b[`treatment']== 0)
			mat `p_1'  = nullmat(`p_1'),r(p)
			*Treatment effect and SD
			lincom (`treatment' )
			mat `t_1' = nullmat(`t_1'), r(estimate)
			mat `tse_1' = nullmat(`tse_1'), r(se)
			
			*Control mean and SD
			sum `var' if `treatment'==0 & e(sample)==1
			mat `c_1' = nullmat(`c_1'), r(mean)
			mat `cse_1' = nullmat(`cse_1'), r(sd)
			*Sample sizes
			count if `treatment'==0 & e(sample)==1
			mat `cN_1' = nullmat(`cN_1'), r(N)
			count if `treatment'==1 & e(sample)==1
			mat `tN_1' = nullmat(`tN_1'), r(N)
			
			
		}
		
		foreach mat in c_1 t_1  cse_1 tse_1  cN_1 tN_1  p_1   {
			mat coln ``mat'' = `varlist'
		}
		
		local cmd "my_ptest_strata"
		foreach mat in  c_1 t_1  cse_1 tse_1  cN_1 tN_1  p_1  {
			eret mat `mat' = ``mat''
		}
