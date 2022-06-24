********************************************************************************
* DESCRIPTION: Construct full monthly panel data based on RAIS data.
********************************************************************************


*** macros
if "${year_est_min}" == "" | "${year_est_max}" == "" {
	global year_est_min = ${year_est_default_min}
	global year_est_max = ${year_est_default_max}
}


*** load baseline RAIS data
* define list of variables to load
local use_vars = "persid year ${empid_var} inc hire_month months_worked"

* load data
use `use_vars' using "${DIR_TEMP}/RAIS/rais_baseline_${year_est_min}_${year_est_max}.dta", clear

* take sample
if $sample_share_flows < 1.0 keep if mod(persid, round(1/${sample_share_flows})) == 0


*** create monthly panel
* create spell number -- note: important to create this before -expand- command!
gen double n_spell = _n
label var n_spell "Spell number"
compress n_spell

* replicate each employment spell observation so that it appears the number of times that it lasted in months
expand months_worked

* create month
bys n_spell: gen byte month = _n
drop n_spell
replace month = month + hire_month - 1
label var month "Month"

* generate date variable as year-month combination
gen int date = ym(year, month)
label var date "Date (year-month combination)"
format date %tm
drop year month

* select job with highest income in each set of worker-months
gen float rand = runiform()
replace hire_month = -hire_month
bys date persid (months_worked hire_month rand): keep if _n == _N // Note: use random noise with fixed initial seed in order for this to yield a deterministic outcome.
drop months_worked hire_month rand

* set panel
xtset persid date, monthly
tsfill, full

* replace missing values for time-invariant variables
gen int year = yofd(dofm(date))
label var year "Year"

* balance the panel by filling in missing observations
// gen int yob = year - age
// label var yob "Year of birth"
// foreach var of varlist yob {
// 	bys persid (`var'): replace `var' = `var'[1]
// }
// replace age = year - yob
// drop yob

* classify employment state
gen byte empstat = .
replace empstat = 0 if ${empid_var} == . // i.e., if informally employed, working as self-employed or employer, or unemployed
replace empstat = 1 if ${empid_var} < . & inc != 1
replace empstat = 2 if ${empid_var} < . & inc == 1
label var empstat "Employment status"

* format variables
label define emp_l 0 "Nonemployed (Informal, unemployed, searching)" 1 "Formally empl., != MW" 2 "Formally empl., == MW", replace
label val empstat emp_l

* order and sort
order persid date year empstat ${empid_var} inc
sort persid date

* save
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/est_rais_monthly_${year_est_min}_${year_est_max}.dta", replace
