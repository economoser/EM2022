********************************************************************************
* DESCRIPTION: Prepares data, calls MATLAB file FUN_AKM.m to run the two-way
*              fixed effects (AKM) estimation estimation, and processes output.
********************************************************************************


*** load baseline RAIS data
* store passed arguments in local macros
local drop_mw = `1' // whether to drop job spells with earnings = MW
local drop_less_than_mw = `2' // whether to drop job spells with earnings < MW
local drop_below_min_fsize = `3' // whether to drop employers with fewer than `3' employees
local drop_below_min_switchers = `4' // whether to drop employers with fewer than `4' switchers
local akm_covariates = `5' // whether to include covariates (edu x time, edu x age, hours, occupation, tenure, actual experience) in AKM wage equation

* define list of variables to load
local use_vars = "persid year ${empid_var} inc id_unique"
if `akm_covariates' {
	if (${edu_inter} & (${akm_year_dummies} | ${akm_age_poly_order})) | ${akm_tenure} | ${akm_exp_act} local use_vars = "`use_vars' edu"
	if ${akm_age_poly_order} local use_vars = "`use_vars' age"
	if ${akm_hours} local use_vars = "`use_vars' hours"
	if ${akm_occ} local use_vars = "`use_vars' occ02_6"
	if ${akm_tenure} local use_vars = "`use_vars' tenure"
	if ${akm_exp_act} local use_vars = "`use_vars' exp_act"
}

* load data
use `use_vars' using "${DIR_TEMP}/RAIS/rais_baseline_unique_${year_est_min}_${year_est_max}.dta", clear

* coarsen occupation
// if $akm_occ replace occ02_6 = floor(occ02_6/10) // Note from 01/16/2021: need this in order for KSS corrections to avoid -ichol()- error


*** selection
* keep only job spells with earnings not equal to the MW
if "`drop_mw'" != "" {
	if `drop_mw' keep if inc != 1
}

* keep only job spells with earnings weakly above the MW
if "`drop_less_than_mw'" != "" {
	if `drop_less_than_mw' keep if inc >= 1
}

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

*** clean appended data
* counts before merging with connected set
qui count
local N_worker_years = r(N)
bys persid: gen byte ind_worker = 1 if _n == 1
label var ind_worker "Ind: unique worker?"
qui count if ind_worker < .
local N_workers = r(N)
drop ind_worker
bys ${empid_var}: gen byte ind_employer = 1 if _n == 1
label var ind_employer "Ind: unique employer?"
qui count if ind_employer < .
local N_employers = r(N)
drop ind_employer

* merge data with connected set
merge m:1 id_unique using "${DIR_TEMP}/RAIS/connected_akm_workers_${year_est_min}_${year_est_max}_`drop_mw'_`drop_less_than_mw'_`drop_below_min_fsize'_`drop_below_min_switchers'.dta", keep(match) keepusing(id_unique) nogen
drop id_unique

* counts after merging with connected set
qui count
local N_worker_years_connected = r(N)
bys persid: gen byte ind_worker = 1 if _n == 1
label var ind_worker "Ind: unique worker?"
qui count if ind_worker < .
local N_workers_connected = r(N)
drop ind_worker
bys ${empid_var}: gen byte ind_employer = 1 if _n == 1
label var ind_employer "Ind: unique employer?"
qui count if ind_employer < .
local N_employers_connected = r(N)
drop ind_employer

* display shares in connected set
local share_worker_years_connected = 100*`N_worker_years_connected'/`N_worker_years'
local share_worker_years_connected : di %4.1f `share_worker_years_connected'
local share_workers_connected = 100*`N_workers_connected'/`N_workers'
local share_workers_connected : di %4.1f `share_workers_connected'
local share_employers_connected = 100*`N_employers_connected'/`N_employers'
local share_employers_connected : di %4.1f `share_employers_connected'

* convert earnings to natural logarithm
gen float inc_ln = ln(inc)
label var inc_ln "Mean monthly earnings (log multiples of MW)"
rename inc inc_lvl
label var inc_lvl "Mean monthly earnings (multiples of MW)"

* create potential experience (= years of age - years of education - 6)
if ($akm_tenure | $akm_exp_act) & `akm_covariates' {
	recode edu (1=0) (2=3) (3=5) (4=7) (5=9) (6=11) (7=12) (8=14) (9=16) (nonmissing=.), generate(edu_y) // codes: 1 "Illiterate (0 years)" 2 "Some primary school (1-5 years)" 3 "Primary school degree (5 years)" 4 "Some middle school (6-9 years)" 5 "Middle school degree (9 years)" 6 "Some high school (10-12 years)" 7 "High school degree (12 years)" 8 "Some college (13-15 years)" 9 "Bachelor's or higher degree (16+ years)"
	label var edu_y "Years of education"
	gen byte exp_pot = age - edu_y - 6
	drop edu_y
	label var exp_pot "Potential experience (years of age - years of education - 6)"
	replace exp_pot = max(min(exp_pot, age - 6), 0)
}

* transform actual experience
if $akm_exp_act & `akm_covariates' {
	replace exp_act = min(floor(exp_act/12), exp_pot)
	label var exp_act "Actual experience (years in formal sector)"
}

* transform tenure
if $akm_tenure & `akm_covariates' {
	if $akm_exp_act replace tenure = min(floor(tenure/12), exp_pot, exp_act)
	else replace tenure = min(floor(tenure/12), exp_pot)
	label var tenure "Tenure (years at current employer)"
}

* drop potential experience, since collinear with year FE and person FE
if ($akm_tenure | $akm_exp_act) & `akm_covariates' drop exp_pot


*** prepare data to be used for AKM estimation in MATLAB
* rename variables
rename ${empid_var} empid

* format year so it can be read by MATLAB
replace year = year - ${year_est_min} + 1 // generate numerical year starting from 1
rename year year_akm
label var year_akm "Year (AKM format)"

* prepare to outsheet age variable if higher-order age terms are to be included
if $akm_age_poly_order & `akm_covariates' global age_outsheet = "age" // if AKM estimation includes higher-order age terms
else global age_outsheet = ""
if $edu_inter & `akm_covariates' global edu_outsheet = "edu" // if AKM estimation includes year effects and age effects (or higher-order age terms) interacted with education
else global edu_outsheet = ""

* check that all variables are nonmissing
sum, sep(0)
foreach var of varlist * {
	assert `var' < .
}

* coarsen variables
if $akm_coarsen & `akm_covariates' {
	if $akm_hours prog_coarsen "hours" ${N_coarsen}
	if $akm_occ prog_coarsen "occ02_6" ${N_coarsen}
	if $akm_tenure prog_coarsen "tenure" ${N_coarsen}
	if $akm_exp_act prog_coarsen "exp_act" ${N_coarsen}
}

* save
sort persid year_akm
if $akm_hours & `akm_covariates' global hours_outsheet = "hours"
else global hours_outsheet = ""
if $akm_occ & `akm_covariates' global occ_outsheet = "occ02_6"
else global occ_outsheet = ""
if $akm_tenure & `akm_covariates' global tenure_outsheet = "tenure"
else global tenure_outsheet = ""
if $akm_exp_act & `akm_covariates' global exp_act_outsheet = "exp_act"
else global exp_act_outsheet = ""
order inc_ln inc_lvl persid empid year_akm ${age_outsheet} ${edu_outsheet} ${hours_outsheet} ${occ_outsheet} ${tenure_outsheet} ${exp_act_outsheet} // list of variables currently used: year persid edu age ${empid_var} inc; list of variables currently not used: hours occ02_6 tenure exp_act
compress
prog_desc_sum_comp_save "${DIR_TEMP}/RAIS/temp_akm_${year_est_min}_${year_est_max}_${ext}.dta"


*** run AKM estimation in MATLAB
* format variables for file export
local vars_format = "inc_ln persid empid year_akm"

if `akm_covariates' {
	if $akm_age_poly_order local vars_format = "`vars_format' age"
	if $edu_inter local vars_format = "`vars_format' edu"
	if $akm_hours local vars_format = "`vars_format' hours"
	if $akm_occ local vars_format = "`vars_format' occ02_6"
	if $akm_tenure local vars_format = "`vars_format' tenure"
	if $akm_exp_act local vars_format = "`vars_format' exp_act"
}
foreach var of local vars_format {
	sum `var', meanonly
	if "`var'" == "inc_ln" format `var' %`=ceil(max(log10(abs(r(min))),log10(abs(r(max))))) + 6'.6f
	else format `var' %`=ceil(max(log10(abs(r(min))),log10(abs(r(max)))))'.0f
}

* outsheet list of wages, worker IDs, employer IDs, year IDs (and possibly age)
sum inc_ln persid empid year_akm ${age_outsheet} ${edu_outsheet} ${hours_outsheet} ${occ_outsheet} ${tenure_outsheet} ${exp_act_outsheet}, sep(0)
export delim inc_ln persid empid year_akm ${age_outsheet} ${edu_outsheet} ${hours_outsheet} ${occ_outsheet} ${tenure_outsheet} ${exp_act_outsheet} using "${DIR_TEMP}/RAIS/tomatlab_${year_est_min}_${year_est_max}_${ext}.csv", delim(tab) novarnames nolabel replace

* delete earlier output so as not to cause confusion
cap rm "${DIR_TEMP}/RAIS/tostata_${year_est_min}_${year_est_max}_${ext}.txt"

* prepare file with parameters
clear
set obs 1
gen int year_est_min = ${year_est_min}
gen int year_est_max = ${year_est_max}
gen byte akm_age_poly_order = ${akm_age_poly_order}*`akm_covariates'
gen int age_flat_min = ${age_flat_min}
gen int age_flat_max = ${age_flat_max}
gen int age_norm = ${age_norm}
gen int age_min = ${age_min}
gen int age_max = ${age_max}
gen byte year_dummies = ${akm_year_dummies}*`akm_covariates'
gen byte edu_inter = ${edu_inter}*`akm_covariates'
gen byte akm_hours = ${akm_hours}*`akm_covariates'
gen byte akm_occ = ${akm_occ}*`akm_covariates'
gen byte akm_tenure = ${akm_tenure}*`akm_covariates'
gen byte akm_exp_act = ${akm_exp_act}*`akm_covariates'
gen double ext = ${ext}
format year_est_min year_est_max %4.0f
format akm_age_poly_order edu_inter akm_hours akm_occ akm_tenure akm_exp_act %1.0f
format age_flat_min age_flat_max age_norm age_min age_max %3.0f
format ext %12.0f
cap confirm file "${DIR_TEMP}/RAIS/parameters_EIMW_akm.csv"
local parameters_exist = !_rc
if `parameters_exist' disp as error "USER WARNING: Parameters file (${DIR_TEMP}/RAIS/parameters_EIMW_akm.csv) already exists -- entering sleep loop."
while `parameters_exist' {
	cap confirm file "${DIR_TEMP}/RAIS/parameters_EIMW_akm.csv"
	local parameters_exist = !_rc
	if `parameters_exist' sleep 60000 // sleep for 60s
}
compress
// outsheet year_est_min year_est_max akm_age_poly_order age_flat_min age_flat_max age_norm age_min age_max edu_inter akm_hours akm_occ akm_tenure akm_exp_act ext using "${DIR_TEMP}/RAIS/parameters_EIMW_akm.csv", nonames nolabel // Note: in the future, replace -outsheet- command with -export delim- command.
export delim ///
	year_est_min year_est_max akm_age_poly_order age_flat_min age_flat_max age_norm age_min age_max year_dummies edu_inter akm_hours akm_occ akm_tenure akm_exp_act ext ///
	using "${DIR_TEMP}/RAIS/parameters_EIMW_akm.csv", delim(tab) novarnames nolabel replace
clear

* call MATLAB via shell to run AKM estimation
!${APP_MATLAB} -nojvm -nodesktop -nodisplay <"${DIR_DO}/FUN_AKM.m"

* read MATLAB output
import delim using "${DIR_TEMP}/RAIS/tostata_${year_est_min}_${year_est_max}_${ext}.txt", asdouble varnames(1) delim(tab) clear
rename y year
if $akm_year_dummies & `akm_covariates' rename xb_y xb_year
if $akm_age_poly_order & `akm_covariates' rename xb_a xb_age
if $akm_hours & `akm_covariates' rename xb_h xb_hours
if $akm_occ & `akm_covariates' rename xb_o xb_occ
if $akm_tenure & `akm_covariates' rename xb_ten xb_tenure
if $akm_exp_act & `akm_covariates' rename xb_exp xb_exp_act
label var persid "Worker ID (deidentified)"
label var year "Year"
label var pe "Predicted AKM worker FE"
if "${empid_var}" == "empid_est" local emp_type = "establishment"
else if "${empid_var}" == "empid_firm" local emp_type = "firm"
else local emp_type = "employer"
label var fe "Predicted AKM `emp_type' FE"
if `akm_covariates' {
	if !$edu_inter & $akm_year_dummies & `akm_covariates' label var xb_year "Predicted AKM year FE"
	else if $edu_inter & $akm_year_dummies & `akm_covariates' label var xb_year "Predicted AKM education-year FE"
	if $akm_age_poly_order == 1 {
		if !$edu_inter label var xb_age "Predicted AKM age FE"
		else label var xb_age "Predicted AKM education-age FE"
	}
	else if $akm_age_poly_order >= 2 {
		if !$edu_inter label var xb_age "Predicted AKM higher-order age terms"
		else label var xb_age "Predicted AKM higher-order education-age terms"
	}
	if $akm_hours label var xb_hours "Predicted AKM hours FE"
	if $akm_occ label var xb_occ "Predicted AKM occupation FE"
	if $akm_tenure label var xb_tenure "Predicted AKM tenure FE"
	if $akm_exp_act label var xb_exp_act "Predicted AKM actual-experience FE"
}

* recast AKM estimates to float data types
foreach var in pe fe xb_year xb_age xb_hours xb_occ xb_tenure xb_exp_act {
	cap confirm var `var', exact
	if !_rc recast float `var', force
}

* add other variables from temp file
rename year year_akm
merge 1:1 persid year_akm using "${DIR_TEMP}/RAIS/temp_akm_${year_est_min}_${year_est_max}_${ext}.dta", keep(match master) nogen
rm "${DIR_TEMP}/RAIS/temp_akm_${year_est_min}_${year_est_max}_${ext}.dta"
replace year_akm = year_akm + ${year_est_min} - 1
rename year_akm year
rename empid ${empid_var}

* generate residual
gen float resid = inc_ln
foreach var in pe fe xb_year xb_age xb_hours xb_occ xb_tenure xb_exp_act {
	cap confirm var `var', exact
	if !_rc replace resid = resid - `var'
}
label var resid "Predicted AKM residual"

* compute variance-covariance matrix and variance decomposition
local cov_list = ""
foreach var in inc_ln pe fe xb_year xb_age xb_hours xb_occ xb_tenure xb_exp_act resid {
	cap confirm var `var', exact
	if !_rc local cov_list = "`cov_list' `var'"
}
corr pe fe
local rho = r(rho)
corr `cov_list'
corr pe fe, cov
local cov_pe_fe = r(cov_12)
corr `cov_list', cov
matrix C = r(C)
local cov_counter = 1
foreach var of local cov_list {
	local var_`var' = C[`cov_counter',`cov_counter']
	local var_`var' : di %4.3f `var_`var''
	local ++cov_counter
	if "`var'" == "inc_ln" local cov = `var_inc_ln'
	else local cov = `cov' - `var_`var''
}
local cov : di %4.3f `cov'
foreach var of local cov_list {
	local var_share_`var' = 100*`var_`var''/`var_inc_ln'
	local var_share_`var' : di %4.1f `var_share_`var''
}
local var_share_cov = 100*`cov'/`var_inc_ln'
local var_share_cov : di %4.1f `var_share_cov'
local first = 1
foreach var in `cov_list' cov resid2 {
	if `first' {
		disp _newline(3)
		disp "--> variance decomposition:"
	}
	if !inlist("`var'", "cov", "resid", "resid2") disp "Var(`var') = `var_`var'' (`var_share_`var''%)"
	else if "`var'" == "cov" disp "2*sum(Cov(.)) = `cov' (`var_share_cov'%)"
	else if "`var'" == "resid2" disp "Var(resid) = `var_resid' (`var_share_resid'%)"
	local first = 0
}
disp "Corr(worker FE, employer FE) = `rho'"
disp "Cov(worker FE, employer FE) = `cov_pe_fe'"
disp "Number of observations = `N_worker_years_connected'"
disp "Share of worker-years in connected set = `share_worker_years_connected'%"
disp "Share of workers in connected set = `share_workers_connected'%"
disp "Share of employers in connected set = `share_employers_connected'%"


*** save
* save largest connected set including AKM estimates
if !`drop_mw' & !`drop_less_than_mw' & !`drop_below_min_fsize' & !`drop_below_min_switchers' & !`akm_covariates' {
	order persid year ${empid_var} inc_ln inc_lvl pe fe
	sort persid year
	compress
	prog_desc_sum_comp_save "${DIR_TEMP}/RAIS/lset_${year_est_min}_${year_est_max}.dta"
}

* save smaller dataset for estimation
if `drop_mw' & !`drop_less_than_mw' & !`drop_below_min_fsize' & !`drop_below_min_switchers' & !`akm_covariates' {
	keep persid ${empid_var} inc_ln inc_lvl pe fe resid
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/est_rais_akm_estimates_${year_est_min}_${year_est_max}.dta", replace // if directory exists
}

* compute AKM variance components for estimation
if `drop_mw' & !`drop_less_than_mw' & !`drop_below_min_fsize' & !`drop_below_min_switchers' & !`akm_covariates' {
	keep inc_ln pe fe resid
	rename inc_ln wage
	corr pe fe
	local pe_fe_corr = r(rho)
	corr pe fe, cov
	local pe_fe_cov = 2*r(cov_12)
	${gtools}collapse ///
		(sd) wage_var=wage pe_var=pe fe_var=fe resid_var=resid ///
		, fast
	foreach var of varlist wage_var pe_var fe_var resid_var {
		replace `var' = `var'^2
	}
	gen float pe_fe_corr = `pe_fe_corr'
	gen float pe_fe_cov = `pe_fe_cov'
	label var wage_var "Variance of log earnings (${year_est_min}-${year_est_max})"
	label var pe_var "Variance of AKM person FEs (${year_est_min}-${year_est_max})"
	label var fe_var "Variance of AKM employer FEs (${year_est_min}-${year_est_max})"
	label var pe_fe_cov "2*Cov b/w AKM person & employer FEs (${year_est_min}-${year_est_max})"
	label var resid_var "Variance of AKM residual (${year_est_min}-${year_est_max})"
	label var pe_fe_corr "Correlation b/w AKM person & employer FEs (${year_est_min}-${year_est_max})"
	order wage_var pe_var fe_var pe_fe_cov resid_var pe_fe_corr
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/est_rais_akm_decomposition_${year_est_min}_${year_est_max}.dta", replace
}

* prepare the same file with parameters again
clear
set obs 1
gen int year_est_min = ${year_est_min}
gen int year_est_max = ${year_est_max}
gen byte akm_age_poly_order = ${akm_age_poly_order}*`akm_covariates'
gen int age_flat_min = ${age_flat_min}
gen int age_flat_max = ${age_flat_max}
gen int age_norm = ${age_norm}
gen int age_min = ${age_min}
gen int age_max = ${age_max}
gen byte year_dummies = ${akm_year_dummies}*`akm_covariates'
gen byte edu_inter = ${edu_inter}*`akm_covariates'
gen byte akm_hours = ${akm_hours}*`akm_covariates'
gen byte akm_occ = ${akm_occ}*`akm_covariates'
gen byte akm_tenure = ${akm_tenure}*`akm_covariates'
gen byte akm_exp_act = ${akm_exp_act}*`akm_covariates'
gen double ext = ${ext}
format year_est_min year_est_max %4.0f
format akm_age_poly_order edu_inter akm_hours akm_occ akm_tenure akm_exp_act %1.0f
format age_flat_min age_flat_max age_norm age_min age_max %3.0f
format ext %12.0f
cap confirm file "${DIR_TEMP}/RAIS/parameters_EIMW_akm_kss.csv"
local parameters_exist = !_rc
if `parameters_exist' disp as error "USER WARNING: Parameters file (${DIR_TEMP}/RAIS/parameters_EIMW_akm_kss.csv) already exists -- entering sleep loop."
while `parameters_exist' {
	cap confirm file "${DIR_TEMP}/RAIS/parameters_EIMW_akm_kss.csv"
	local parameters_exist = !_rc
	if `parameters_exist' sleep 60000 // sleep for 60s
}
compress
// outsheet year_est_min year_est_max akm_age_poly_order age_flat_min age_flat_max age_norm age_min age_max edu_inter akm_hours akm_occ akm_tenure akm_exp_act ext using "${DIR_TEMP}/RAIS/parameters_EIMW_akm.csv", nonames nolabel // Note: in the future, replace -outsheet- command with -export delim- command.
export delim ///
	year_est_min year_est_max akm_age_poly_order age_flat_min age_flat_max age_norm age_min age_max year_dummies edu_inter akm_hours akm_occ akm_tenure akm_exp_act ext ///
	using "${DIR_TEMP}/RAIS/parameters_EIMW_akm_kss.csv", delim(tab) novarnames nolabel replace
clear

* call MATLAB via shell to run KSS correction of AKM estimation
!${APP_MATLAB} -nodesktop -nodisplay <"${DIR_DO}/FUN_AKM_KSS.m"

* delete old data files used in AKM estimation
rm "${DIR_TEMP}/RAIS/tomatlab_${year_est_min}_${year_est_max}_${ext}.csv"
rm "${DIR_TEMP}/RAIS/tostata_${year_est_min}_${year_est_max}_${ext}.txt"


********************************************************************************
* END OF FUNCTION FUN_AKM.do
********************************************************************************
