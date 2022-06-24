********************************************************************************
* DESCRIPTION: Compute employer size distribution.
********************************************************************************


*** macros
if "${year_est_min}" == "" | "${year_est_max}" == "" {
	global year_est_min = ${year_est_default_min}
	global year_est_max = ${year_est_default_max}
}


*** load baseline RAIS data
* define list of variables to load
local use_vars = "persid year ${empid_var} inc id_unique"

* load data
use `use_vars' using "${DIR_TEMP}/RAIS/rais_baseline_unique_${year_est_min}_${year_est_max}.dta", clear


*** compute employer size in a given year
* compute employer size
bys ${empid_var} year: gen long fsize = _N
label var fsize "Employer size (number of employees in a given year)"


*** save data for estimation
* keep only relevant variables
keep persid year ${empid_var} inc fsize

* order and sort
order persid year ${empid_var} inc fsize
sort persid year

* save
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/est_rais_fsize_${year_est_min}_${year_est_max}.dta"
