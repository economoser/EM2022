********************************************************************************
* DESCRIPTION: Investigate comparative statics in the data.
*
* NOTE:        Potentially need to edit years that are hard-coded in!
********************************************************************************


*** macros
* other parameters
global p_base = 50 // base quantile for computing earnings quantile ratios
global plot_year_base = 1996 // year to keep as base year on x-axis
global loop_year_min = 1994
global loop_year_max = 2014

* automatically set macros
global loop_year_min_plus_4 = ${loop_year_min} + 4
global loop_year_max_plus_4 = ${loop_year_max} + 4

*** generate bridge between establishment ID and state / mesoregion / microregion / municipality
* loop through years
foreach y1 in $loop_year_min $loop_year_max {
	local y2 = `y1' + 4
	
	* load data
	do "${DIR_DO}/FUN_LOAD.do" `y1' `y2' "state persid $empid_var gender age earn_mean_mw" // meso micro muni
	drop persid gender age earn_mean_mw

	* collapse to establishment level
	${gtools}collapse ///
		(firstnm) state /// meso micro muni
		, by(${empid_var}) fast
	foreach var of varlist state { // meso micro muni
		local l: variable label `var'
		local l = subinstr("`l'", "(firstnm) ", "", .)
		label var `var' "`l'"
	}
	
	* save bridge
	sort ${empid_var}
	order ${empid_var} state // meso micro muni
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/${empid_var}_state_meso_micro_muni_`y1'_`y2'.dta"
}


*** read model-simulated data
foreach file in ///
	"Moments_vs_inequality_en" ///
	"Moments_vs_inequality_ne" ///
	"Moments_vs_inequality_ee" ///
	"Moments_vs_inequality_fe_var" ///
	"Moments_vs_inequality_wage_p50_min" ///
	{
	import delim using "${DIR_MODEL}/4 Version 11122021/2 Data/`file'.csv", delim(tab) varnames(1) clear
	destring *, force replace
	keep if moment < .
	if inlist("`file'", "Moments_vs_inequality_ne", "Moments_vs_inequality_ee", "Moments_vs_inequality_en") local var_name = upper(subinstr("`file'", "Moments_vs_inequality_", "", .))
	else if inlist("`file'", "Moments_vs_inequality_wage_p50_min") local var_name = "inc_median"
	else local var_name = subinstr("`file'", "Moments_vs_inequality_", "", .)
	rename moment `var_name'
	label var `var_name' "`var_name'"
	rename var inc_var_diff
	label var inc_var_diff "Long difference in variance of log earnings"
	rename emp emp_diff
	label var emp_diff "Long difference in employment"
	gen byte model = 1
	label var model "Ind: model-simulated data? (0 or . = real-world data, 1 = model-simulated data)"
	compress
	desc
	save "${DIR_RESULTS}/${section}/`var_name'.dta", replace
}


*** compute long differences in regional inequality statistics by state / mesoregion / microregion / municipality -- values to be put on y-axis
foreach sel in state { // meso micro muni
	
	* load data
	use ///
		year `sel' inc ///
		if inlist(year, ${year_min}, ${year_max}) ///
		using "${DIR_TEMP}/RAIS/rais_inc_${year_data_min}_${year_data_max}.dta", clear
	
	* generate log earnings
	gen float inc_ln = ln(inc)
	label var inc_ln "Monthly earnings (log multiples of MW)"
	drop inc
	
	* collapse to state / mesoregion / microregion / municipality level
	local collapse_str = ""
	foreach p in 10 25 50 75 90 {
		local collapse_str = "`collapse_str' (p`p') inc_p`p'=inc_ln"
	}
	${gtools}collapse ///
		(mean) inc_mean=inc_ln ///
		(p50) inc_median=inc_ln ///
		(sd) inc_var=inc_ln `collapse_str' ///
		(count) N=inc_ln ///
		, by(`sel' year) fast
	label var inc_mean "Mean log earnings"
	label var inc_median "Median of log earnings"
	replace inc_var = inc_var^2
	label var inc_var "Variance of log earnings"
	foreach p in 10 25 50 75 90 {
		label var inc_p`p' "P`p' of log earnings"
	}
	label var N "Number of observations"
	foreach p in 10 25 50 75 90 {
		if `p' < $p_base {
			gen float inc_p${p_base}_p`p' = inc_p${p_base} - inc_p`p'
			label var inc_p${p_base}_p`p' "P${p_base}/P`p' log earnings percentile ratio"
		}
		else if `p' > $p_base {
			gen float inc_p`p'_p${p_base} = inc_p`p' - inc_p${p_base}
			label var inc_p`p'_p${p_base} "P`p'/P${p_base} log earnings percentile ratio"
		}
	}
	gen float inc_p90_p10 = inc_p90 - inc_p10
	label var inc_p90_p10 "P90/P10 log earnings percentile ratio"
	drop inc_p??
	
	* create long differences
	foreach var of varlist inc_var inc_p??_p?? {
		gen float `var'_diff = .
		bys `sel' (year): replace `var'_diff = `var'[_n] - `var'[_n - 1] if `var'_diff == .
		bys `sel' (year): replace `var'_diff = `var'[_n + 1] - `var'[_n] if `var'_diff == .
		local l: variable label `var'
		label var `var'_diff "Long difference in `l'"
	}
	
	* save
	order `sel' year ///
		inc_mean inc_median inc_var inc_p50_p10 inc_p50_p25 inc_p75_p50 inc_p90_p50 inc_p90_p10 ///
		inc_var_diff inc_p50_p10_diff inc_p50_p25_diff inc_p75_p50_diff inc_p90_p50_diff inc_p90_p10_diff ///
		N
	sort `sel' year
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/inequality_`sel'.dta"
}


*** compute long differences in regional level and dispersion of AKM fixed effects by state / mesoregion / microregion / municipality -- values to be put on y-axis
* loop through years
foreach y1 in $loop_year_min $loop_year_max {
	local y2 = `y1' + 4
	
	* load
	use ${empid_var} pe fe using "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta", clear
	
	* merge in region info
	merge m:1 ${empid_var} using "${DIR_TEMP}/RAIS/${empid_var}_state_meso_micro_muni_`y1'_`y2'.dta", keepusing(state) keep(master match) nogen // meso micro muni
	drop ${empid_var}
	
	* generate mean and variance of AKM fixed effects
	foreach sel in state { // meso micro muni
		preserve
		keep pe fe `sel'
		keep if `sel' < .
		${gtools}collapse ///
			(mean) pe_mean=pe fe_mean=fe ///
			(sd) pe_var=pe fe_var=fe ///
			(p10) pe_p10=pe fe_p10=fe ///
			(p50) pe_p50=pe fe_p50=fe ///
			(p90) pe_p90=pe fe_p90=fe ///
			, by(`sel') fast
		label var pe_mean "Mean of AKM person FEs"
		label var fe_mean "Mean of AKM firm FEs"
		replace pe_var = pe_var^2
		label var pe_var "Variance of AKM person FEs"
		replace fe_var = fe_var^2
		label var fe_var "Variance of AKM firm FEs"
		label var pe_p10 "P10 of AKM person FEs"
		label var fe_p10 "P10 of AKM firm FEs"
		label var pe_p50 "P50 of AKM person FEs"
		label var fe_p50 "P50 of AKM firm FEs"
		label var pe_p90 "P90 of AKM person FEs"
		label var fe_p90 "P90 of AKM firm FEs"
		gen float pe_p50_p10 = pe_p50 - pe_p10
		label var pe_p50_p10 "P50-P10 ratio of AKM person FEs"
		gen float pe_p90_p50 = pe_p90 - pe_p50
		label var pe_p90_p50 "P90-P50 ratio of AKM person FEs"
		gen float fe_p50_p10 = fe_p50 - fe_p10
		label var fe_p50_p10 "P50-P10 ratio of AKM firm FEs"
		gen float fe_p90_p50 = fe_p90 - fe_p50
		label var fe_p90_p50 "P90-P50 ratio of AKM firm FEs"
		drop pe_p10 fe_p10 pe_p50 fe_p50 pe_p90 fe_p90
		gen int year = .
		if `y1' == $loop_year_min replace year = 1
		else if `y1' == $loop_year_max replace year = 2
		label var year "Year code (1 = ${loop_year_min}-${loop_year_min_plus_4}, 2 = ${loop_year_max}-${loop_year_max_plus_4})"
		order `sel' year pe_mean fe_mean pe_var fe_var pe_p50_p10 fe_p50_p10 pe_p90_p50 fe_p90_p50
		sort `sel' year
		compress
		save "${DIR_TEMP}/RAIS/akm_moments_by_`sel'_`y1'_`y2'.dta", replace
		restore
	}
}

* append years
foreach sel in state { // meso micro muni
	clear
	foreach y1 in $loop_year_min $loop_year_max {
		local y2 = `y1' + 4
		append using "${DIR_TEMP}/RAIS/akm_moments_by_`sel'_`y1'_`y2'.dta"
	}
	foreach var of varlist pe_var fe_var pe_p50_p10 fe_p50_p10 pe_p90_p50 fe_p90_p50 {
		gen float `var'_diff = .
// 		bys `sel' (year): replace `var'_diff = `var'[_n] - `var'[_n - 1] if `var'_diff == .
		bys `sel' (year): replace `var'_diff = `var'[_n + 1] - `var'[_n] if `var'_diff == . // Note: leave the variable "`var'_diff" as missing in the second of two years, since need only one nonmissing observation
		local l: variable label `var'
		label var `var'_diff "Long difference in `l'"
// 		if !inlist("`var'", "pe_var", "fe_var") drop `var'
	}
	drop year
	keep if pe_var_diff < . // Note: dropping based on one variable nonmissing = dropping based on all variables nonmissing
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/akm_moments_by_`sel'.dta"
}


*** compute long differences in employment rate by state / mesoregion / microregion / municipality -- values to be put on y-axis
* loop through years
foreach y1 in $loop_year_min $loop_year_max {
	local y2 = `y1' + 4
		
	* load data
	use persid date empstat ${empid_var} using "${DIR_TEMP}/RAIS/est_rais_monthly_`y1'_`y2'.dta", clear
	
	* carry forward employer IDs into next nonemployment spell
	bys persid (date): carryforward ${empid_var}, replace
	gen date_reversed = -date
	drop date
	bys persid (date_reversed): carryforward ${empid_var}, replace
	drop persid date_reversed
	
	* merge in state / mesoregion / microregion / municipality variables
	merge m:1 ${empid_var} using "${DIR_TEMP}/RAIS/${empid_var}_state_meso_micro_muni_`y1'_`y2'.dta", keepusing(state) keep(master match) nogen // meso micro muni
	foreach var of varlist state { // meso micro muni
		local l: variable label `var'
		local var_l_short = subinstr("`l'", "(firstnm) ", "", .)
		label var `var' "`var_l_short'"
	}
	drop ${empid_var}
	
	* generate indicators for labor market transitions
	gen byte E = (empstat > 0) if empstat < .
	label var E "Ind: employed this period"
	drop empstat
	
	* save temporary file
	compress
	save "${DIR_TEMP}/RAIS/temp_employment_by_state_meso_micro_muni.dta", replace

	* loop through `sel', collapse to `sel' level, save `sel'-level file for a given year
	foreach sel in state { // meso micro muni
		use E `sel' if `sel' < . using "${DIR_TEMP}/RAIS/temp_employment_by_state_meso_micro_muni.dta", clear
		${gtools}collapse ///
			(mean) emp=E ///
			, by(`sel') fast
		label var emp "Employment rate"
		foreach var of varlist emp {
			local l: variable label `var'
			local var_l_short = subinstr("`l'", "(mean) ", "", .)
			label var `var' "`var_l_short'"
		}
		gen int year = .
		if `y1' == $loop_year_min replace year = 1
		else if `y1' == $loop_year_max replace year = 2
		label var year "Year code (1 = ${loop_year_min}-${loop_year_min_plus_4}, 2 = ${loop_year_max}-${loop_year_max_plus_4})"
		order `sel' year emp
		compress
		save "${DIR_TEMP}/RAIS/employment_by_`sel'_`y1'_`y2'.dta", replace
	}

	* delete temporary file
	rm "${DIR_TEMP}/RAIS/temp_employment_by_state_meso_micro_muni.dta"
}

* append years
foreach sel in state { // meso micro muni
	clear
	foreach y1 in $loop_year_min $loop_year_max {
		local y2 = `y1' + 4
		append using "${DIR_TEMP}/RAIS/employment_by_`sel'_`y1'_`y2'.dta"
	}
	gen float emp_diff = .
// 	bys `sel' (year): replace emp_diff = emp[_n] - emp[_n - 1] if emp_diff == . // Note: leave the variable "emp_diff" as missing in the second of two years, since need only one nonmissing observation
	bys `sel' (year): replace emp_diff = emp[_n + 1] - emp[_n] if emp_diff == .
	label var emp_diff "Long difference in employment rate"
	drop year emp
	keep if emp_diff < .
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/employment_by_`sel'.dta"
}


*** construct worker flows by state / mesoregion / microregion / municipality
* load data
use persid date empstat ${empid_var} using "${DIR_TEMP}/RAIS/est_rais_monthly_${loop_year_min}_${loop_year_min_plus_4}.dta", clear

* set panel
xtset persid date 

* generate indicators for labor market transitions
gen byte EN = (empstat > 0 & F.empstat == 0) if empstat < . & F.empstat < .
label var EN "Ind: not employed next period | employed this period"
gen byte NE = (L.empstat == 0 & empstat > 0) if L.empstat < . & empstat < .
label var NE "Ind: employed next period | not employed this period"
gen byte EE = (empstat > 0 & F.empstat > 0 & ${empid_var} != F.${empid_var}) if empstat < . & F.empstat < . & ${empid_var} < . & F.${empid_var} < .
label var EE "Ind: employed at diff. estab. next period | employed this period"

* keep only employment spells (i.e., drop nonemployment spells)
keep if empstat > 0 & empstat < . //
drop persid date empstat

* merge in state / mesoregion / microregion / municipality variables
merge m:1 ${empid_var} using "${DIR_TEMP}/RAIS/${empid_var}_state_meso_micro_muni_${loop_year_min}_${loop_year_min_plus_4}.dta", keepusing(state) keep(master match) nogen // meso micro muni
drop ${empid_var}
foreach var of varlist state { // meso micro muni
	local l: variable label `var'
	local var_l_short = subinstr("`l'", "(firstnm) ", "", .)
	label var `var' "`var_l_short'"
}

* save temporary file
compress
save "${DIR_TEMP}/RAIS/temp_flows_by_state_meso_micro_muni.dta", replace

* loop through `sel', collapse to `sel' level, save `sel'-level file
foreach sel in state { // meso micro muni
	use EN NE EE `sel' if `sel' < . using "${DIR_TEMP}/RAIS/temp_flows_by_state_meso_micro_muni.dta", clear
	${gtools}collapse ///
		(mean) EN NE EE ///
		, by(`sel') fast
	foreach var of varlist EN NE EE {
		local l: variable label `var'
		local var_l_short = subinstr("`l'", "(mean) ", "", .)
		label var `var' "`var_l_short'"
	}
	order `sel' EN NE EE
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/flows_by_`sel'.dta"
}

* delete temporary file
rm "${DIR_TEMP}/RAIS/temp_flows_by_state_meso_micro_muni.dta"


*** append datasets
* start with clean slate
clear

* append dataset: inequality
foreach sel in state { // meso micro muni
	append using "${DIR_TEMP}/RAIS/inequality_`sel'.dta"
}
order state year inc_* N // meso micro muni

* append dataset: AKM moments
foreach sel in state { // meso micro muni
	merge m:1 `sel' using "${DIR_TEMP}/RAIS/akm_moments_by_`sel'.dta", update keepusing(pe_mean fe_mean pe_var fe_var pe_var_diff fe_var_diff pe_p50_p10 pe_p50_p10_diff fe_p50_p10 fe_p50_p10_diff pe_p90_p50 pe_p90_p50_diff fe_p90_p50 fe_p90_p50_diff) keep(master match match_update) nogen
}
order state year inc_* N // meso micro muni

* append dataset: employment
gen float emp_diff = .
label var emp_diff "Long difference in employment rate"
foreach sel in state { // meso micro muni
	merge m:1 `sel' using "${DIR_TEMP}/RAIS/employment_by_`sel'.dta", update keepusing(emp_diff) keep(master match match_update) nogen
}

* append dataset: labor market flows
foreach var in EN NE EE {
	gen byte `var' = .
}
foreach sel in state { // meso micro muni
	merge m:1 `sel' using "${DIR_TEMP}/RAIS/flows_by_`sel'.dta", update keepusing(EN NE EE) keep(master match match_update) nogen
}

* relabel variables
foreach var of varlist inc_*_diff pe_*_diff fe_*_diff emp_diff {
	local l: variable label `var'
	local l_short = subinstr("`l'", "Long difference in ", "", .)
	local l_short = subinstr("`l_short'", " log earnings percentile ratio", "", .)
	local l_short = subinstr("`l_short'", " of log earnings", "", .)
	local l_short = proper("`l_short'")
	label var `var' "`l_short'"
}

* keep only observations with nonmissing differences
keep if inc_var_diff < .

* append model-simulated data
foreach file in "EN" "NE" "EE" "fe_var" "inc_median" { // NOTE: as of 10am CT on 02/20/2021, NE is just a copy of EE... file to be updated by Nik!
	append using "${DIR_RESULTS}/${section}/`file'.dta"
}
replace model = 0 if model == .

* save
order state year inc* pe* fe* emp_diff EN NE EE N model // meso micro muni
sort model state year // meso micro muni
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/comparative_statics.dta"


// *** plot real-world inequality and employment effects in same graph
// * load data
// use if year == $plot_year_base using "${DIR_TEMP}/RAIS/comparative_statics.dta", clear

// * settings for all plots
// local level = "state" // "state", "meso", "micro", or "muni"
// local color_list = "blue red green orange purple"
// tokenize `color_list'
// local w_list = `" "[fw=N]" "" "'
// local x_var_list = `" "inc_median" "' // inc_mean inc_median inc_var pe_mean pe_var fe_var EN NE EE
// local ineq_var_diff = "inc_var_diff" // long difference in ... "inc_var_diff" = variance of log earnings, "fe_var_diff" = variance of AKM firm FEs, "fe_p50_p10" = P50-P10 of AKM firm FEs, "fe_p90_p50" = P90-P50 of AKM firm FEs
// local y_var_list = `" "`ineq_var_diff'" "emp_diff" "'

// * relabel variables
// foreach x_var of varlist EN NE EE inc_mean inc_median {
// 	local l: variable label `x_var'
// 	if substr("`l'", 1, 5) == "Ind: " {
// 		local l = subinstr("`l'", "Ind: ", "", .)
// 		label var `x_var' "Probability of being `l'"
// 	}
// }

// * plots with various weights and x-axis variables
// foreach w of local w_list {
// 	foreach x_var of local x_var_list {
// 		local scatter_str = ""
// 		local lfit_str = ""
// 		local count = 0
// 		foreach y_var of local y_var_list {
// 			local ++count
// 			local lcolor = "``count''"
// 			if `count' == 1 local lpattern_str = "l"
// 			else if `count' == 2 local lpattern_str = "dash"
// 			else local lpattern_str = "l"
// 			local scatter_str = "`scatter_str' (scatter `y_var' `x_var' if `level' < . `w' & model == 0, mcolor(`lcolor'%50) msymbol(Oh) yaxis(`count'))"
// 			local lfit_str = "`lfit_str' (lfit `y_var' `x_var' if `level' < . `w' & model == 0, lcolor(`lcolor') lwidth(thick) lpattern(`lpattern_str') yaxis(`count'))"
// 			// Note: could estimate linear regression here and save coefficients + standard errors!?
// 		}
// 		if "`w'" == "" local w_str = "unw"
// 		else if "`w'" == "[fw=N]" local w_str = "w"
// 		local l: variable label `x_var'
// 		local xtitle_str = "`l'"
// 		if "`ineq_var_diff'" == "inc_var_diff" local ytitle_str = "Long difference in variance of log earnings, ${year_min}-${year_max}"
// 		else if "`ineq_var_diff'" == "fe_var_diff" local ytitle_str = "Long difference in variance of AKM firm fixed effects, ${year_min}-${year_max}"
// 		if "`x_var'" == "inc_mean" {
// 			local xlabel_str = ".5(.2)1.9"
// 			local x_format_str = "2.1"
// 		}
// 		else if "`x_var'" == "inc_median" {
// 			local xlabel_str = ".5(.2)1.9"
// 			local x_format_str = "2.1"
// 		}
// 		else if "`x_var'" == "inc_var" {
// 			local xlabel_str = ".4(.1)1"
// 			local x_format_str = "2.1"
// 		}
// 		else if "`x_var'" == "pe_mean" {
// 			local xlabel_str = "-.2(.1).2"
// 			local x_format_str = "2.1"
// 		}
// 		else if "`x_var'" == "pe_var" {
// 			local xlabel_str = ".15(.05).35"
// 			local x_format_str = "3.2"
// 		}
// 		else if "`x_var'" == "fe_var" {
// 			local xlabel_str = ".1(.05).35"
// 			local x_format_str = "3.2"
// 		}
// 		else if "`x_var'" == "fe_p50_p10" {
// 			local xlabel_str = ".3(.1).8"
// 			local x_format_str = "3.2"
// 		}
// 		else if "`x_var'" == "fe_p90_p50" {
// 			local xlabel_str = ".2(.1).9"
// 			local x_format_str = "3.2"
// 		}
// 		else if "`x_var'" == "EN" {
// 			local xlabel_str = ".02(.005).05"
// 			local x_format_str = "4.3"
// 		}
// 		else if "`x_var'" == "NE" {
// 			local xlabel_str = ".02(.01).06"
// 			local x_format_str = "3.2"
// 		}
// 		else if "`x_var'" == "EE" {
// 			local xlabel_str = ".005(.005).03"
// 			local x_format_str = "4.3"
// 		}
// 		local legend_str = `" order(2 "Inequality" 4 "Employment") cols(2) region(lcolor(white)) "' // "Variance of log earnings" and "Employment rate"
// 		tw ///
// 			`scatter_str' ///
// 			`lfit_str' ///
// 			, xtitle("`xtitle_str'") ytitle("`ytitle_str'", axis(1)) ytitle("Long difference in employment rate, ${year_min}-${year_max}", axis(2)) ///
// 			xlabel(`xlabel_str', format(%`x_format_str'f) grid gstyle(dot) gmin gmax labsize(medium)) ylabel(-.5(.1).1, format(%2.1f) grid gstyle(dot) gmin gmax labsize(medium) axis(1)) ylabel(-.03(.03)0.15, format(%3.2f) nogrid axis(2)) ///
// 			legend(`legend_str') ///
// 			plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 			name(`x_var'_joint_`level'_`w_str', replace)
// 		graph export "${DIR_RESULTS}/${section}/`x_var'_joint_`level'_`w_str'.pdf", replace
// 	}
// }


*** plot inequality effects in model vs. data in same graph
* load data
use if inlist(year, $plot_year_base, .) using "${DIR_TEMP}/RAIS/comparative_statics.dta", clear

* settings for all plots
local level = "state" // "state", "meso", "micro", or "muni"
local color_list = "blue red green orange purple"
tokenize `color_list'
local w_list = `" "[fw=N]" "" "'
local x_var_list = `" "inc_median" "fe_var" "EN" "NE" "EE" "' // inc_mean inc_median inc_var pe_mean pe_var fe_var EN NE EE -- NOTE: as of 10am CT on 02/20/2021, NE is just a copy of EE... file to be updated by Nik!
local y_var_list = `" "inc_var_diff" "emp_diff" "' // long difference in ... "inc_var_diff" = variance of log earnings, "fe_var_diff" = variance of AKM firm FEs, "fe_p50_p10" = P50-P10 of AKM firm FEs, "fe_p90_p50" = P90-P50 of AKM firm FEs

* relabel variables
foreach x_var of local x_var_list {
	local l: variable label `x_var'
	if substr("`l'", 1, 5) == "Ind: " {
		local l = subinstr("`l'", "Ind: ", "", .)
		label var `x_var' "Probability of being `l'"
	}
}

* plots with various weights and x-axis variables
foreach w of local w_list {
	foreach x_var of local x_var_list {
		foreach y_var of local y_var_list {
			local scale_factor_1 = 0.5
			local scale_factor_2 = 1.5
			sum `x_var' if `level' < . & model == 0, meanonly
			if sign(r(min)) > 0 local x_min = `scale_factor_1'*r(min)
			else local x_min = `2'*r(min)
			if sign(r(max)) > 0 local x_max = `scale_factor_2'*r(max)
			else local x_max = `scale_factor_1'*r(max)
			cap confirm var `y_var'_`x_var'_pred
			if _rc { // if variable `y_var'_`x_var'_pred does not exist, then run regression on model-simulated data:
				reg `y_var' `x_var' if model == 1
				predict float `y_var'_`x_var'_pred if `level' < . & model == 0 & year == $plot_year_base, xb
// 				sum `y_var'_`x_var'_pred
			}
			local scatter_str = "(scatter `y_var' `x_var' if `level' < . & model == 0 `w', mcolor(blue%50) msymbol(Oh) yaxis(1))"
			local lfit_str = "(lfit `y_var' `x_var' if `level' < . & model == 0 `w', lcolor(blue) lwidth(thick) lpattern(l) yaxis(1))"
			local lfit_str = "`lfit_str' (line `y_var'_`x_var'_pred `x_var' if `level' < . & model == 0, sort lcolor(red) lwidth(thick) lpattern(dash) yaxis(2))"
			if "`w'" == "" local w_str = "unw"
			else if "`w'" == "[fw=N]" local w_str = "w"
			local l: variable label `x_var'
			local xtitle_str = "`l'"
			if "`y_var'" == "inc_var_diff" local ytitle_str = "Long diff. in var. of log earnings"
			else if "`y_var'" == "fe_var_diff" local ytitle_str = "Long diff. in var. of AKM firm FEs"
			else if "`y_var'" == "emp_diff" local ytitle_str = "Long diff. in employment"
			if "`y_var'" == "inc_var_diff" {
				if "`x_var'" == "inc_median" {
					local xlabel_str = ".3(.3)1.8"
					local x_format_str = "2.1"
					local y1label_str = "-.5(.1).1"
					local y1_format_str = "2.1"
					local y2label_str = "-.5(.1).1"
					local y2_format_str = "2.1"
				}
				else if "`x_var'" == "fe_var" {
					local xlabel_str = ".05(.05).35"
					local x_format_str = "3.2"
					local y1label_str = "-.5(.1).1"
					local y1_format_str = "2.1"
					local y2label_str = "-.12(.01)-.06"
					local y2_format_str = "3.2"
				}
				else if "`x_var'" == "EN" {
					local xlabel_str = ".01(.01).06"
					local x_format_str = "3.2"
					local y1label_str = "-.5(.1).1"
					local y1_format_str = "2.1"
					local y2label_str = "-.12(.01)-.06"
					local y2_format_str = "3.2"
				}
				else if "`x_var'" == "NE" {
					local xlabel_str = ".01(.01).06"
					local x_format_str = "3.2"
					local y1label_str = "-.5(.1).1"
					local y1_format_str = "2.1"
					local y2label_str = "-.12(.01)-.06"
					local y2_format_str = "3.2"
				}
				else if "`x_var'" == "EE" {
					local xlabel_str = ".005(.005).035"
					local x_format_str = "4.3"
					local y1label_str = "-.5(.1).1"
					local y1_format_str = "2.1"
					local y2label_str = "-.12(.01)-.06"
					local y2_format_str = "3.2"
				}
			}
			else {
				if "`x_var'" == "inc_median" {
					local xlabel_str = ".3(.3)1.8"
					local x_format_str = "2.1"
					local y1label_str = "-.05(.05).20"
					local y1_format_str = "3.2"
					local y2label_str = "-.025(.005)0"
					local y2_format_str = "4.3"
				}
				else if "`x_var'" == "fe_var" {
					local xlabel_str = ".05(.05).35"
					local x_format_str = "3.2"
					local y1label_str = "-.05(.05).20"
					local y1_format_str = "3.2"
					local y2label_str = "-.025(.005)0"
					local y2_format_str = "4.3"
				}
				else if "`x_var'" == "EN" {
					local xlabel_str = ".01(.01).06"
					local x_format_str = "3.2"
					local y1label_str = "-.05(.05).20"
					local y1_format_str = "3.2"
					local y2label_str = "-.025(.005)0"
					local y2_format_str = "4.3"
				}
				else if "`x_var'" == "NE" {
					local xlabel_str = ".01(.01).06"
					local x_format_str = "3.2"
					local y1label_str = "-.05(.05).20"
					local y1_format_str = "3.2"
					local y2label_str = "-.025(.005)0"
					local y2_format_str = "4.3"
				}
				else if "`x_var'" == "EE" {
					local xlabel_str = ".005(.005).035"
					local x_format_str = "4.3"
					local y1label_str = "-.05(.05).20"
					local y1_format_str = "3.2"
					local y2label_str = "-.025(.005)0"
					local y2_format_str = "4.3"
				}
			}
			local legend_str = `" order(2 "Data" 3 "Model") cols(2) region(lcolor(white)) "' // "Variance of log earnings" and "Employment rate"
			tw ///
				`scatter_str' ///
				`lfit_str' ///
				, xtitle("`xtitle_str'") ytitle("`ytitle_str', data", axis(1)) ytitle("`ytitle_str', model", axis(2)) ///
				xlabel(`xlabel_str', format(%`x_format_str'f) grid gstyle(dot) gmin gmax labsize(medium)) ylabel(`y1label_str', format(%`y1_format_str'f) grid gstyle(dot) gmin gmax labsize(medium) axis(1)) ylabel(`y2label_str', format(%`y2_format_str'f) nogrid axis(2)) ///
				legend(`legend_str' region(color(none)) ring(0) position(12)) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(`y_var'_`x_var'_`level'`w_str', replace)
			graph export "${DIR_RESULTS}/${section}/`y_var'_`x_var'_m_d_`level'_`w_str'.pdf", replace
		}
	}
}
