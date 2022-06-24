********************************************************************************
* DESCRIPTION: Prepares data, calls MATLAB file FUN_CONNECTED.m to find largest
*              connected set, and saves data merged with largest connected set.
********************************************************************************


********************************************************************************
* MAIN CODE
********************************************************************************
*** load baseline RAIS data
* store passed arguments in local macros
local drop_mw = `1' // whether to drop job spells with earnings = MW
local drop_less_than_mw = `2' // whether to drop job spells with earnings < MW
local drop_below_min_fsize = `3' // whether to drop employers with fewer than `3' employees
local drop_below_min_switchers = `4' // whether to drop employers with fewer than `4' switchers

* define list of variables to load
if "`drop_mw'" == "1" | "`drop_less_than_mw'" == "1" local var_inc = "inc"
else local var_inc = ""
local use_vars = "persid year ${empid_var} `var_inc' id_unique"

* load data
use `use_vars' using "${DIR_TEMP}/RAIS/rais_baseline_unique_${year_est_min}_${year_est_max}.dta", clear


*** selection
* keep only job spells with earnings not equal to the MW
if "`drop_mw'" != "" {
	if `drop_mw' keep if inc != 1
}

* keep only job spells with earnings weakly above the MW
if "`drop_less_than_mw'" != "" {
	if `drop_less_than_mw' keep if inc >= 1
}

* drop variables no longer needed
if "`drop_mw'" == "1" | "`drop_less_than_mw'" == "1" drop inc

* keep only employers with enough employees
if "`drop_below_min_fsize'" != "" {
	if `drop_below_min_fsize' {
		bys ${empid_var} year: gen long fsize = _N
		label var fsize "Employer size (number of employees in a given year)"
		keep if fsize >= `drop_below_min_fsize'
		drop fsize
	}
}

* keep only employers with enough switchers -- note: technically, this should be imposed iteratively after finding the connected set and before re-computing the connected set, etc., but this is approximately equivalent
if "`drop_below_min_switchers'" != "" {
	if `drop_below_min_switchers' {
		bys persid (year): gen byte ind_switcher = (${empid_var}[_n] != ${empid_var}[_n + 1] & ${empid_var}[_n + 1] < .) | (${empid_var}[_n] != ${empid_var}[_n - 1] & ${empid_var}[_n - 1] < .)
		label var ind_switcher "Ind: switcher employers between current and previous job spells?"
		if "${gtools}" == "" bys ${empid_var}: egen long n_switcher = total(ind_switcher)
		else gegen long n_switcher = total(ind_switcher), by(${empid_var})
		label var n_switcher "Number of switchers at a given employer"
		keep if n_switcher >= `drop_below_min_switchers'
		drop n_switcher
	}
}

* save selection
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/temp_selection_${ext}.dta"

* keep only variables necessary to uniquely identify employers and jobs
keep ${empid_var} id_unique // i.e., drop persid year. Note: in yearly panel, id_unique automatically identifies year
sort ${empid_var} id_unique

* save combinations of employer IDs and unique job IDs that satisfy selection criteria
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/connected_akm_workers_${year_est_min}_${year_est_max}_`drop_mw'_`drop_less_than_mw'_`drop_below_min_fsize'_`drop_below_min_switchers'.dta"


*** find largest connected set
* load selection
use persid year ${empid_var} using "${DIR_TEMP}/RAIS/temp_selection_${ext}.dta", clear // i.e., do not load id_unique
rm "${DIR_TEMP}/RAIS/temp_selection_${ext}.dta"

* use original variable names from passed arguments to rename variables
rename year date
rename ${empid_var} id_employer
rename persid id_worker

* find maximum number of lags
sum date, meanonly
local n_lags = `=r(max)' - `=r(min)' // Note: assumes no gaps in years

* order and compress
order id_employer id_worker date
compress


*** find (weakly or strongly) connected set in MATLAB
* set panel
xtset id_worker date

* export list of current and previous employer IDs
if $connect_strong gen double lag_id_employer = L.id_employer // for strongly connected set, use only E-to-E transitions.
else { // for weakly connected set, use E-to-E and E-to-U-to-E transitions.
	gen double lag_id_employer = .
	forval l = 1/`n_lags' {
		replace lag_id_employer = L`l'.id_employer if lag_id_employer == .
	}
}
keep id_employer lag_id_employer // i.e., drop date id_worker
keep if !inlist(., id_employer, lag_id_employer) // i.e., drop observations only ever observed at one employer (when constructing weakly connected set), or observations never transitioning E-to-E (when constructing strongly connected set)
keep if id_employer != lag_id_employer // i.e., drop stayers -- for constructing connected set, without loss of generality drop self-referrals
bys id_employer lag_id_employer: keep if _n == 1 // for constructing connected set, always keep only one observation per link
format id_employer lag_id_employer %12.0f
compress
export delim id_employer lag_id_employer using "${DIR_TEMP}/RAIS/connected_input_${ext}.csv", novarnames nolabel datafmt delim(tab) replace
clear

* delete earlier output so as to not cause confusion
cap rm "${DIR_TEMP}/RAIS/connected_output_${ext}.txt"

* call MATLAB via shell
set obs 1
gen byte connect_strong = ${connect_strong}
gen double ext = ${ext}
format connect_strong %1.0f
format ext %12.0f
cap confirm file "${DIR_TEMP}/RAIS/parameters_EIMW_connected.csv"
local parameters_exist = !_rc
if `parameters_exist' disp as error "USER WARNING: Parameters file (${DIR_TEMP}/RAIS/parameters_EIMW_connected.csv) already exists -- entering sleep loop."
while `parameters_exist' {
	cap confirm file "${DIR_TEMP}/RAIS/parameters_EIMW_connected.csv"
	local parameters_exist = !_rc
	if `parameters_exist' sleep 60000 // sleep for 60s
}
compress
export delim connect_strong ext using "${DIR_TEMP}/RAIS/parameters_EIMW_connected.csv", novarnames nolabel datafmt delim(tab) replace
clear
!${APP_MATLAB} -nojvm <"${DIR_DO}/FUN_CONNECTED.m"

* read MATLAB output
import delim using "${DIR_TEMP}/RAIS/connected_output_${ext}.txt", varnames(1) asdouble clear
compress
label var id_employer "Employer ID (deidentified)"

* delete old data files
rm "${DIR_TEMP}/RAIS/connected_input_${ext}.csv"
rm "${DIR_TEMP}/RAIS/connected_output_${ext}.txt"

* restore original variable names
rename id_employer ${empid_var}


*** process output from MATLAB
* order and sort variables
order ${empid_var}
sort ${empid_var}

* save connected set of employer IDs
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/connected_akm_${year_est_min}_${year_est_max}_`drop_mw'_`drop_less_than_mw'_`drop_below_min_fsize'_`drop_below_min_switchers'.dta"


*** find job spell IDs in connected set
* trim down list of unique job IDs by removing employer IDs outside of largest connected set
foreach i in "" "_connected" {
	if "`i'" == "" use "${DIR_TEMP}/RAIS/connected_akm_workers_${year_est_min}_${year_est_max}_`drop_mw'_`drop_less_than_mw'_`drop_below_min_fsize'_`drop_below_min_switchers'.dta", clear
	else if "`i'" == "_connected" merge m:1 ${empid_var} using "${DIR_TEMP}/RAIS/connected_akm_${year_est_min}_${year_est_max}_`drop_mw'_`drop_less_than_mw'_`drop_below_min_fsize'_`drop_below_min_switchers'.dta", keep(match) keepusing(${empid_var}) nogen
}


*** save list of job spell IDs in connected set
* keep only relevant variables
keep id_unique // i.e., drop ${empid_var}
sort id_unique

* save connected set of job IDs
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/connected_akm_workers_${year_est_min}_${year_est_max}_`drop_mw'_`drop_less_than_mw'_`drop_below_min_fsize'_`drop_below_min_switchers'.dta"


********************************************************************************
* END OF FUNCTION FUN_CONNECTED.do
********************************************************************************
