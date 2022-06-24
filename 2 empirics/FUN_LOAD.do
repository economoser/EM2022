********************************************************************************
* DESCRIPTION: Function to load data in a consistent manner.
********************************************************************************


*** check global macros and arguments
* make sure the following arguments are passed:
forval i = 1/3 {
	assert "`i'" != ""
}

* store arguments in local macros
local y_min = `1'
local y_max = `2'
local vars_list = "`3'" // e.g., "year persid empid_est gender race edu age ind07_5 occ02_6 hours muni hours_year earn_mean_mw"

* if ext does not exist, then call it
// if "${ext}" == "" do "${DO_DIR}/FUN_EXTENSION.do"


*** read individual years
forval y = `y_min'/`y_max' {

	* load data
	if `y' < 1994 local vars_list_temp = subinstr("`vars_list'", "hours ", "", .)
	else local vars_list_temp = "`vars_list'"
	use `vars_list_temp' using "${DIR_WRITE}/`y'/${sample_prefix}clean`y'.dta", clear
	
	* keep only nonmissing observations satisfying selection criteria
// 	foreach var of varlist * {
	foreach var in persid $empid_var gender age earn_mean_mw {
// 	foreach var in persid $empid_var earn_mean_mw {
		cap confirm var `var', exact
		if !_rc {
			if "${`var'_min}" != "" { // if a minimum value is set
				if ${`var'_min} < . keep if `var' >= ${`var'_min}
			}
			if "${`var'_max}" != "" { // if a maximum value is set
				if ${`var'_max} < . keep if `var' <= ${`var'_max}
			}
		}
	}

	* save yearly data
	compress
	order `vars_list_temp'
	save "${DIR_TEMP}/RAIS/temp_load_y`y'_`y_min'_`y_max'_${ext}.dta", replace
}


*** append data across years
clear
forval y = `y_min'/`y_max' {
	append using "${DIR_TEMP}/RAIS/temp_load_y`y'_`y_min'_`y_max'_${ext}.dta", force
	rm "${DIR_TEMP}/RAIS/temp_load_y`y'_`y_min'_`y_max'_${ext}.dta"
}
compress


********************************************************************************
* END OF FUNCTION FUN_LOAD.do
********************************************************************************
