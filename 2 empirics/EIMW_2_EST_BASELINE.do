********************************************************************************
* DESCRIPTION: Construct baseline data based on RAIS data.
********************************************************************************


*** macros
if "${year_est_min}" == "" | "${year_est_max}" == "" {
	global year_est_min = ${year_est_default_min}
	global year_est_max = ${year_est_default_max}
}


*** create file containing person ID, year, and age
* create list of first and last years
global y1_list = "${year_est_default_min} ${year_sim_default_min}" // "${year_est_min} ${year_sim_min}"
global y2_list = "${year_est_default_max} ${year_sim_default_max}" // "${year_est_max} ${year_sim_max}"

* compute number of start/end years to loop through 
local N_list: word count ${y1_list}

* loop through start and end years
forval n = 1/`N_list' {
	local y1: word `n' of ${y1_list} // first year
	local y2: word `n' of ${y2_list} // last year

	* call user-defined function to load all data (including MW spells)
	do "${DIR_DO}/FUN_LOAD.do" `y1' `y2' "gender persid year age"

	* drop variables that are no longer needed
	drop gender
	
	* keep single observation per person-year
	bys persid year: keep if _n == 1

	* save
	order persid year age
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", replace
	
	* keep single observation per person
	bys persid (year): keep if _n == 1
	
	* compute year of birth
	gen int yob = year - age
	label var yob "Year of birth"
	drop year age
	
	* save
	order persid yob
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/yob_`y1'_`y2'.dta", replace
}


*** load data
* call user-defined function to load all data (including MW spells)
do "${DIR_DO}/FUN_LOAD.do" $year_est_min $year_est_max "persid ${empid_var} gender age earn_mean_mw edu year yob occ02_6 hours tenure exp_act hire_month sep_month id_unique"


*** sample selection
* keep only individuals with nonmissing key variables in all job spells and assert that time-invariant worker characteristics indeed are time-invariant
if $year_est_max < 1994 gen byte hours = 44
foreach var of varlist year persid $empid_var gender edu age yob occ02_6 hours tenure exp_act earn_mean_mw hire_month sep_month id_unique {
	disp _newline(1)
	disp "--> dropping individuals with missing observations of variable `var'"
	qui count if `var' == .
	local N_missing = r(N)
	if !inlist("`var'", "year", "persid", "${empid_var}", "earn_mean_mw") & (`N_missing' > 0) bys persid (`var'): keep if `var'[_N] < .
	disp "--> asserting that variable `var' is time-invariant within individuals"
	if inlist("`var'", "gender", "edu", "yob") bys persid (`var'): assert `var'[1] == `var'[_N]
}

* rename income variable
rename earn_mean_mw inc

* keep only men
keep if inrange(gender, ${gender_min}, ${gender_max})
drop gender

* keep only relevant birth cohorts
// condition 1: year - yob = age >= ${age_min} in ${year_est_min}  iff.  ${year_est_min} - ${age_min} >= yob
// condition 2: year - yob = age <= ${age_max} in ${year_est_max}  iff.  ${year_est_max} - ${age_max} <= yob
keep if ${year_est_min} - ${age_min} >= yob & ${year_est_max} - ${age_max} <= yob
drop yob

* apply time-invariant upper-income winsorizing
replace inc = min(inc, 120) if inc < .

* compute months worked in a given spell
replace sep_month = 12 if sep_month == 0
replace hire_month = 1 if hire_month == 0
gen byte months_worked = sep_month - hire_month + 1
label var months_worked "Months worked in job spell during current year"
drop sep_month


*** format variables
* recast income variable to lower precision
// recast float inc, force

* replace income by mean income during worker-firm match
gen float inc_year = inc*months_worked
label var inc_year "Total yearly earnings (multiples of MW)"
drop inc
if "${gtools}" == "" bys persid ${empid_var}: egen inc_sum = total(inc_year)
else gegen inc_sum = total(inc_year), by(persid ${empid_var})
label var inc_sum "Spell-level total earnings (multiples of current MW)"
drop inc_year
if "${gtools}" == "" bys persid ${empid_var}: egen months_worked_sum = total(months_worked)
else gegen months_worked_sum = total(months_worked), by(persid ${empid_var})
label var months_worked_sum "Spell-level total months worked"
gen float inc_mean = inc_sum/months_worked_sum
label var inc_mean "Spell-level mean earnings (multiples of current MW)"
rename inc_mean inc
drop inc_sum months_worked_sum


*** coarsen variables if doing a test run
if $sample {
	// critical variables: empid_est edu age hours occ02_6 tenure exp_act
	replace empid_est = mod(_n, 100) + 1
	recode edu (1/4=4) (5/9=5)
	if $age_flat_min >= 25 | $age_flat_max <= 51 {
		replace age = age + 20 if age <= 24
		replace age = age - 5 if age >= 51
	}
	recode hours (0/43=1) (44/168=2)
	replace occ02_6 = ceil(occ02_6/10^5)
	replace tenure = min(ceil(tenure/12), 10)
	replace exp_act = min(ceil(exp_act/12), 10)
}



*** save baseline RAIS data
* keep only relevant variables
// LOADED: year persid ${empid_var} inc edu age yob hours occ02_6 tenure exp_act hire_month sep_month months_worked id_unique
keep       year persid ${empid_var} inc edu age     hours occ02_6 tenure exp_act hire_month           months_worked id_unique

* order and sort
order persid year ${empid_var} inc edu age hours occ02_6 tenure exp_act hire_month months_worked id_unique
sort persid year

* save
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/rais_baseline_${year_est_min}_${year_est_max}.dta"


*** save baseline RAIS data with at most one observation per worker-year
* load data
use "${DIR_TEMP}/RAIS/rais_baseline_${year_est_min}_${year_est_max}.dta", clear

* keep only highest-paid among longest jobs per worker-year. AKM selection criterion -- consider this the main job per person-year.
gen float rand = runiform()
replace hire_month = -hire_month
bys persid year (months_worked hire_month rand): keep if _n == _N // Note: use random noise with fixed initial seed in order for this to yield a deterministic outcome.
drop months_worked hire_month rand

* order and sort
order persid year ${empid_var} inc edu age hours occ02_6 tenure exp_act id_unique
sort persid year

* save
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/rais_baseline_unique_${year_est_min}_${year_est_max}.dta"
