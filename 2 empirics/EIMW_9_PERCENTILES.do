********************************************************************************
* DESCRIPTION: Compute log earnings percentiles.
********************************************************************************


*** macros
* other parameters
global sel_groups = `" "overall" "state" "meso" "' // groups by which to compute earnings quantiles // "micro" "muni" "ind_5" "ind_2"
global percentiles_by_edu = 0 // 0 = create percentiles for overall population, 1 = create percentiles separately by education subgroup (group 0 = overall, group 1 = <primary, group 2 = primary, group 3 = high school, group 4 = college)


// *** generate bridge between establishment ID and state / mesoregion / microregion / municipality
// * load data
// do "${DIR_DO}/FUN_LOAD.do" ${year_data_min} ${year_data_max} "persid ${empid_var} gender age earn_mean_mw state meso micro muni ind07_5 ind85_2"
// drop persid gender age earn_mean_mw

// * rename variables
// rename ind07_5 ind_5
// rename ind85_2 ind_2

// * collapse to establishment level
// ${gtools}collapse ///
// 	(firstnm) state meso micro muni ind_5 ind_2 ///
// 	, by(${empid_var}) fast
// foreach var of varlist state meso micro muni ind_5 ind_2 {
// 	local l: variable label `var'
// 	local l = subinstr("`l'", "(firstnm) ", "", .)
// 	label var `var' "`l'"
// }

// * save bridge
// sort ${empid_var}
// order ${empid_var} state meso micro muni ind_5 ind_2
// prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/${empid_var}_state_meso_micro_muni_ind_5_ind_2.dta"


*** prepare RAIS income data
forval y = $year_data_min/$year_data_max {

	* call user-defined function to load all data (including MW spells)
	if `y' >= 1994 local hours = "hours"
	else local hours = ""
	do "${DIR_DO}/FUN_LOAD.do" `y' `y' "persid ${empid_var} gender age earn_mean_mw edu meso state `hours' size_est active_eoy earn_dec_mw" // muni micro ind07_5 ind85_2
	
	* rename variables
	rename earn_mean_mw inc
// 	rename ind07_5 ind_5
// 	rename ind85_2 ind_2
	
	* keep only nonmissing and nonzero incomes
	keep if inc > 0 & inc < .
	
	* keep only nomissing region variables
	keep if state < . & meso < . // & micro < . & muni < .
	
	* keep only nomissing industries
// 	keep if ind_5 < . & ind_2 < .
	
	* keep only men
	keep if inrange(gender, ${gender_min}, ${gender_max})
	drop gender
	
	* keep only prime-age workers
	keep if inrange(age, ${age_min}, ${age_max})

	* apply time-invariant upper-income winsorizing
	replace inc = min(inc, 120) if inc < .
	
	* generate December-to-mean wage ratio
	replace earn_dec_mw = min(earn_dec_mw, 120) if earn_dec_mw < .
	gen float inc_bonus = earn_dec_mw/inc - 1
	label var inc_bonus "Bonus = December-to-mean wage ratio"
	drop earn_dec_mw
	
	* recast variables to lower precision
	foreach var of varlist inc size_est {
		recast float `var', force
	}

	* save income data
	order persid ${empid_var} meso state edu age inc `hours' size_est active_eoy inc_bonus // micro muni ind_5 ind_2
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/rais_inc_`y'_`y'.dta"
}

* append years
clear
gen int year = .
label var year "Year"
forval y = $year_data_min/$year_data_max {
	append using "${DIR_TEMP}/RAIS/rais_inc_`y'_`y'.dta"
	replace year = `y' if year == .
	rm "${DIR_TEMP}/RAIS/rais_inc_`y'_`y'.dta"
}

* generate entry and exit indicators
bys ${empid_var} (year): gen int year_entry = year[1]
bys ${empid_var} (year): gen int year_before_exit = year[_N]
drop ${empid_var}
gen byte entry = (year == year_entry) if year > $year_data_min
label var entry "Ind: did establishment enter this year?"
drop year_entry
gen byte exit = (year == year_before_exit) if year < $year_data_max
label var exit "Ind: will establishment exit next year?"
drop year_before_exit

* save appended income data with entry and exit indicators
order persid year state meso edu age inc hours size_est active_eoy inc_bonus entry exit // micro muni ind_5 ind_2
sort persid year
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/rais_inc_${year_data_min}_${year_data_max}.dta"

* save sample thereof
if !$sample keep if mod(_n, 10^4) == 0
prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/rais_inc_${year_data_min}_${year_data_max}_sample.dta"


*** create log earnings percentiles
* loop over education groups
if $percentiles_by_edu local e_max = 4 // run overall and by population subgroups (group 0 = overall, group 1 = <primary, group 2 = primary, group 3 = high school, group 4 = college)
else local e_max = 0 // run only for overall population
forval e = 0/`e_max' {
	if `e' == 0 local edu_list = "1, 2, 3, 4, 5, 6, 7, 8, 9"
	else if `e' == 1 local edu_list = "1, 2"
	else if `e' == 2 local edu_list = "3, 4, 5, 6"
	else if `e' == 3 local edu_list = "7, 8"
	else if `e' == 4 local edu_list = "9"
	if `e' == 0 local edu_str = ""
	else local edu_str = "_e`e'"

	* loop over subgroups
	foreach sel of global sel_groups {
		disp "* selection = `sel'"
		if "`sel'" == "overall" local sel_var = ""
		else local sel_var = "`sel'"
		forval y = $year_data_min/$year_data_max {
			
			* load
			use `sel_var' year edu inc hours size_est active_eoy inc_bonus entry exit if year == `y' & inlist(edu, `edu_list') using "${DIR_TEMP}/RAIS/rais_inc_${year_data_min}_${year_data_max}${sample_ext}.dta", clear
			
			* drop redundant variables
			drop year edu
			
			* convert variables into logs
			foreach var of varlist inc hours size_est inc_bonus {
				replace `var' = ln(`var')
			}
			
			* collapse
			local collapse_str = ""
			foreach p of numlist 5(5)95 {
				local collapse_str = "`collapse_str' (p`p') inc_p`p'=inc"
			}
			if "`sel_var'" == "" {
				${gtools}collapse ///
					`collapse_str' ///
					(mean) inc_mean=inc hours_mean=hours size_est_mean=size_est active_eoy_mean=active_eoy inc_bonus_mean=inc_bonus entry_mean=entry exit_mean=exit ///
					(sd) inc_var=inc ///
					(count) N=inc ///
					, fast
			}
			else {
				${gtools}collapse ///
					`collapse_str' ///
					(mean) inc_mean=inc hours_mean=hours size_est_mean=size_est active_eoy_mean=active_eoy inc_bonus_mean=inc_bonus entry_mean=entry exit_mean=exit ///
					(sd) inc_var=inc ///
					(count) N=inc ///
					, by(`sel_var') fast
			}
			
			* generate year
			gen int year = `y'
			label var year "Year"
			
			* format variables
			foreach p of numlist 5(5)95 {
				recast float inc_p`p', force
				label var inc_p`p' "Percentile `p' of log earnings"
			}
			recast float inc_mean, force
			label var inc_mean "Mean of log earnings"
			recast float inc_var, force
			replace inc_var = inc_var^2
			label var inc_var "Variance of log earnings"
			label var N "Number of jobs"
			
			* save
			sort `sel_var' year
			order `sel_var' year inc_p* inc_mean inc_var hours_mean size_est_mean inc_bonus_mean active_eoy_mean entry_mean exit_mean N
			prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/percentiles_`sel'`edu_str'_`y'.dta"
		}
	}

	* append years
	foreach sel of global sel_groups {
		disp "* selection = `sel'"
		if "`sel'" == "overall" local sel_var = ""
		else local sel_var = "`sel'"
		clear
		forval y = $year_data_min/$year_data_max {
			append using "${DIR_TEMP}/RAIS/percentiles_`sel'`edu_str'_`y'.dta"
			rm "${DIR_TEMP}/RAIS/percentiles_`sel'`edu_str'_`y'.dta"
		}
		sort `sel_var' year
		order `sel_var' year inc_p* inc_mean inc_var hours_mean size_est_mean inc_bonus_mean active_eoy_mean entry_mean exit_mean N
		prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_`sel'`edu_str'.dta"
	}
}


*** save separate file containing Kaitz indices for each subgroup-year combination for model estimation
foreach sel of global sel_groups {
	if "`sel'" == "overall" local sel_var = ""
	else local sel_var = "`sel'"
	use year `sel_var' inc_p50 N if inrange(year, ${year_data_min}, ${year_data_max}) using "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_`sel'.dta", clear
	gen float kaitz_`sel' = -inc_p50
	label var kaitz_`sel' "Kaitz index, log(MW/P50)"
	drop inc_p50
	prog_comp_desc_sum_save "${DIR_RESULTS}/${section}/percentiles_${year_data_min}_${year_data_max}_`sel'_estimation.dta"
	export delim "${DIR_RESULTS}/${section}/percentiles_${year_data_min}_${year_data_max}_`sel'_estimation.out", nolabel replace
}


// *** create AKM firm FE percentiles and percentile ratios
// * append AKM estimates
// foreach y1 of numlist 1994(2)2010 {
// 	local y2 = `y1' + 4
// 	use ${empid_var} pe fe if pe < . | fe < . using "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta", clear
// 	recast float pe fe, force
// 	gen int year = `y1' + 2
// 	label var year "Year (center of 5-year AKM estimation window)"
// 	local file_exists = 0
// 	while !`file_exists' {
// 		cap confirm file "${DIR_TEMP}/RAIS/${empid_var}_state_meso_micro_muni_ind_5_ind_2.dta"
// 		local file_exists = !_rc
// 		if !`file_exists' sleep 10000
// 	}
// 	merge m:1 ${empid_var} using "${DIR_TEMP}/RAIS/${empid_var}_state_meso_micro_muni_ind_5_ind_2.dta", keepusing(state meso micro muni) keep(master match) nogen // ind_5 ind_2
// 	drop ${empid_var}
// 	order state meso micro muni year pe fe // ind_5 ind_2
// 	save "${DIR_TEMP}/RAIS/temp_pe_fe_`y1'_`y2'.dta", replace
// }

// * loop through subgroups
// foreach sel of global sel_groups {
// 	disp "* selection = `sel'"
// 	foreach y1 of numlist 1994(2)2010 {
// 		disp "   --> year = `y1'"
// 		local y2 = `y1' + 4
// 		if "`sel'" == "overall" local sel_var = ""
// 		else local sel_var = "`sel'"
// 		use `sel_var' year pe fe using "${DIR_TEMP}/RAIS/temp_pe_fe_`y1'_`y2'.dta", clear
// 		if "`sel_var'" != "" keep if `sel_var' < .
// 		local collapse_str = ""
// 		foreach p of numlist 5(5)95 {
// 			local collapse_str = "`collapse_str' (p`p') pe_p`p'=pe fe_p`p'=fe"
// 		}
// 		${gtools}collapse ///
// 			`collapse_str' ///
// 			(mean) pe_mean=pe fe_mean=fe ///
// 			(sd) pe_var=pe fe_var=pe ///
// 			(count) N=pe ///
// 			, by(`sel_var' year) fast
// 		foreach p of numlist 5(5)95 {
// 			recast float pe_p`p', force
// 			label var pe_p`p' "Percentile `p' of AKM person FE"
// 			recast float fe_p`p', force
// 			label var fe_p`p' "Percentile `p' of AKM firm FE"
// 		}
// 		recast float pe_mean, force
// 		label var pe_mean "Mean of AKM person FE"
// 		recast float fe_mean, force
// 		label var fe_mean "Mean of AKM firm FE"
// 		recast float pe_var, force
// 		replace pe_var = pe_var^2
// 		label var pe_var "Variance of AKM person FE"
// 		recast float fe_var, force
// 		replace fe_var = fe_var^2
// 		label var fe_var "Variance of AKM firm FE"
// 		label var N "Number of jobs"
// 		sort `sel_var' year
// 		order `sel_var' year pe_p* fe_p* pe_mean fe_mean pe_var fe_var N
// 		prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/percentiles_akm_${year_data_min}_${year_data_max}_`sel'_`y1'_`y2'.dta"
// 	}
// }

// * append years
// foreach sel of global sel_groups {
// 	disp "* selection = `sel'"
// 	clear
// 	foreach y1 of numlist 1994(2)2010 {
// 		disp "   --> year = `y1'"
// 		local y2 = `y1' + 4
// 		if "`sel'" == "overall" local sel_var = ""
// 		else local sel_var = "`sel'"
// 		append using "${DIR_TEMP}/RAIS/percentiles_akm_${year_data_min}_${year_data_max}_`sel'_`y1'_`y2'.dta"
// // 		rm "${DIR_TEMP}/RAIS/percentiles_akm_${year_data_min}_${year_data_max}_`sel'_`y1'_`y2'.dta"
// 	}
// 	if "`sel_var'" != "" keep if `sel_var' < .
// 	sort `sel_var' year
// 	order `sel_var' year pe_p* fe_p* pe_mean fe_mean pe_var fe_var N
// 	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/percentiles_akm_${year_data_min}_${year_data_max}_`sel'.dta"
// }
