********************************************************************************
* DESCRIPTION: Function to load user-written programs.
********************************************************************************


*** prepare
* clear all programs from memory
program drop _all


*** define programs
* describe, summarize, and compress data
program prog_desc_sum_comp // input: none; output = none
	desc
	sum, sep(0)
	compress
end

* describe, summarize, compress, and save data
program prog_desc_sum_comp_save // input: `1' = file name; output = summary display output and saved file
	desc
	sum, sep(0)
	compress
	save "`1'", replace
end

* describe, summarize, compress, and save data
program prog_comp_desc_sum_save // input: `1' = file name; output = summary display output and saved file
	compress
	desc
	sum, sep(0)
	save "`1'", replace
end

* insert comma separator for thousands in strings
program prog_comma_thousands // input: `1' = name of string variable, `2' = observation number; output = comma separated thousands in string values
	destring `1', force generate(`1'_num)
	sum `1'_num if _n == `2', meanonly
	local N = r(mean)
	if `N' < . {
		if `N' >= 10^12 replace `1' = substr("`N'", 1, mod(strlen("`N'"), 3)) + "," + substr("`N'", -12, 3) + "," + substr("`N'", -9, 3) + "," + substr("`N'", -6, 3) + "," + substr("`N'", -3, 3) if _n == `2'
		else if `N' >= 10^11 replace `1' = substr("`N'", -12, 3) + "," + substr("`N'", -9, 3) + "," + substr("`N'", -6, 3) + "," + substr("`N'", -3, 3) if _n == `2'
		else if `N' >= 10^9 replace `1' = substr("`N'", 1, mod(strlen("`N'"), 3)) + "," + substr("`N'", -9, 3) + "," + substr("`N'", -6, 3) + "," + substr("`N'", -3, 3) if _n == `2'
		else if `N' >= 10^8 replace `1' = substr("`N'", -9, 3) + "," + substr("`N'", -6, 3) + "," + substr("`N'", -3, 3) if _n == `2'
		else if `N' >= 10^6 replace `1' = substr("`N'", 1, mod(strlen("`N'"), 3)) + "," + substr("`N'", -6, 3) + "," + substr("`N'", -3, 3) if _n == `2'
		else if `N' >= 10^5 replace `1' = substr("`N'", -6, 3) + "," + substr("`N'", -3, 3) if _n == `2'
		else if `N' >= 10^3 replace `1' = substr("`N'", 1, mod(strlen("`N'"), 3)) + "," + substr("`N'", -3, 3) if _n == `2'
		else if `N' >= 10^2 replace `1' = substr("`N'", -3, 3) if _n == `2'
	}
	drop `1'_num
end

* compute and display number of unique observations
program prog_unique_vals // input: `1' = name of variable for which to compute unique values
	${gtools}egen double `1'_group = group(`1')
	qui sum `1'_group, meanonly
	global `1'_N = r(max)
	drop `1'_group
	disp "--> number of unique values of variable `1' = ${`1'_N}"
end

* store Mincer estimation coefficients from GENDER_3_MINCER.do
program prog_mincer_reg // input: none; output = regression outut to screen and postfile line to file
	disp _newline(1)
	global spec_str = "${spec}"
	forval p = 1/99 {
		global spec_str = subinstr("${spec_str}", " pool(`p')", "", .)
	}
	while strpos("${spec_str}", "  ") {
		global spec_str = subinstr("${spec_str}", "  ", " ", .)
	}
	global spec_str = subinstr("${spec_str}", "( ", "(", .)
	global spec_str = subinstr("${spec_str}", " )", ")", .)
	foreach dep in earn wage { // generate indicators for type of dependent variable: dep_earn and dep_wage
		global dep_`dep' = (strpos("${spec}", "`dep'") != 0)
	}
	foreach indep in c.edu_y i.edu_y i.age i.exp_act c.exp_pot##c.exp_pot c.exp_act##c.exp_act i.${empid_var} i.hours i.race i.nation i.muni i.ind_5 i.occ_6 i.tenure {
		local indep_str = subinstr("`indep'", ".", "_", .)
		local indep_str = subinstr("`indep_str'", "##", "_", .)
		local indep_str = subinstr("`indep_str'", "#", "_", .)
		if "`indep'" == "i.${empid_var}" global indep_`indep_str' = (strpos("${spec}", "i.${empid_var}") != 0)
		else global indep_`indep_str' = (strpos("${spec}", "`indep'") != 0)
	}
	global indep_i_empid_gender = (strpos("${spec}", "i.empid_gender") != 0)
	disp "${spec_str}"
	cap n ${spec} // run regression
	if e(N) < . {
		if (strpos("${spec}", "i.empid_gender") != 0) { // if specification includes gender-specific employer FEs
			* Oaxaca-Blinder decomposition -- alternatively, move to main text!!!
			
			// prepare:
			bys ${empid_var} (gender): gen byte dual_gender = (gender[1] == 1 & gender[_N] == 2) if gender[_N] < .
			gen double fge_men = fge if gender == 1
			bys ${empid_var} (fge_men): replace fge_men = fge_men[1]
			gen double fge_women = fge if gender == 2
			bys ${empid_var} (fge_women): replace fge_women = fge_women[1]
			gen double fge_men_minus_women = fge_men - fge_women
			
			// all firms:
			qui sum fge_men if gender == 1
			local pay_men_mean = r(mean)
			local pay_men_sd = r(sd)
			local pay_men_N = r(N)
			qui sum fge_women if gender == 2
			local pay_women_mean = r(mean)
			local pay_women_sd = r(sd)
			local pay_women_N = r(N)
			sum fge_men_minus_women if gender == 1, meanonly
			local oaxaca_blinder_bargaining_1: di %5.4f `=r(mean)'
			sum fge_men_minus_women if gender == 2, meanonly
			local oaxaca_blinder_bargaining_2: di %5.4f `=r(mean)'
			sum fge_men if gender == 2, meanonly
			local pay_men_w_by_women_mean = r(mean)
			sum fge_women if gender == 1, meanonly
			local pay_women_w_by_men_mean = r(mean)
			local oaxaca_blinder_sorting_1: di %5.4f `=`pay_women_w_by_men_mean' - `pay_women_mean''
			local oaxaca_blinder_sorting_2: di %5.4f `=`pay_men_mean' - `pay_men_w_by_women_mean''
			local mean_gap: di %5.4f `=`pay_men_mean' - `pay_women_mean''
			global b = `pay_men_mean' - `pay_women_mean' // implied coefficient
			global se = (`pay_men_sd'^2/`pay_men_N' + `pay_women_sd'^2/`pay_women_N')^0.5 // implied standard error
			disp _newline(5)
			disp "*** ALL FIRMS:"
			disp "Oaxaca-Blinder decomposition 1:   `mean_gap' (mean gap) = `oaxaca_blinder_bargaining_1' (bargaining) + `oaxaca_blinder_sorting_1' (sorting)"
			disp "Oaxaca-Blinder decomposition 2:   `mean_gap' (mean gap) = `oaxaca_blinder_bargaining_2' (bargaining) + `oaxaca_blinder_sorting_2' (sorting)"
			
			// only dual-gender firms:
			qui sum fge_men if gender == 1 & dual_gender == 1, meanonly
			local pay_men_mean = r(mean)
			qui sum fge_women if gender == 2 & dual_gender == 1, meanonly
			local pay_women_mean = r(mean)
			sum fge_men_minus_women if gender == 1 & dual_gender == 1, meanonly
			local oaxaca_blinder_bargaining_1: di %5.4f `=r(mean)'
			sum fge_men_minus_women if gender == 2 & dual_gender == 1, meanonly
			local oaxaca_blinder_bargaining_2: di %5.4f `=r(mean)'
			sum fge_men if gender == 2 & dual_gender == 1, meanonly
			local pay_men_w_by_women_mean = r(mean)
			sum fge_women if gender == 1 & dual_gender == 1, meanonly
			local pay_women_w_by_men_mean = r(mean)
			local oaxaca_blinder_sorting_1: di %5.4f `=`pay_women_w_by_men_mean' - `pay_women_mean''
			local oaxaca_blinder_sorting_2: di %5.4f `=`pay_men_mean' - `pay_men_w_by_women_mean''
			local mean_gap: di %5.4f `=`pay_men_mean' - `pay_women_mean''
			disp _newline(5)
			disp "*** ONLY DUAL-GENDER FIRMS:"
			disp "Oaxaca-Blinder decomposition 1:   `mean_gap' (mean gap) = `oaxaca_blinder_bargaining_1' (bargaining) + `oaxaca_blinder_sorting_1' (sorting)"
			disp "Oaxaca-Blinder decomposition 2:   `mean_gap' (mean gap) = `oaxaca_blinder_bargaining_2' (bargaining) + `oaxaca_blinder_sorting_2' (sorting)"
			
			// clean up:
			drop fge dual_gender fge_men fge_women fge_men_minus_women
		}
		else { // else, if specification does not include gender-specific employer FEs
			cap global b = _b[1.gender] // coefficient
			if _rc global b = -9
			cap global se = _se[1.gender] // standard error
			if _rc global se = -9
		}
		cap global N_nosingletons = e(N) // number of observations after dropping singletons
		if _rc global N_nosingletons = -9
		cap global r2 = e(r2) // R-squared
		if _rc global r2 = -9
		cap global r2_a = e(r2_a) // adjusted R-squared
		if _rc global r2_a = -9
		cap global r2_within = e(r2_within) // within R-squared
		if _rc global r2_within = -9
		cap global r2_a_within = e(r2_a_within) // within adjusted R-squared
		if _rc global r2_a_within = -9
		global var_list = "`=e(depvar)' `=e(indepvars)' `=e(absvars)'"
		global var_list = subinstr("`var_list'", "c.", "", .)
		global var_list = subinstr("`var_list'", "i.", "", .)
		forval i = 1/9 {
			global var_list = subinstr("`var_list'", "ib`i'.", "", .)
		}
		global var_list = subinstr("`var_list'", "#", " ", .)
		global count_cond = ""
		foreach var in `var_list' {
			if "`count_cond'" == "" global count_cond = "if `var' < ."
			else global count_cond = "`count_cond' & `var' < ."
		}
		qui count `count_cond'
		global N = r(N) // number of observations
		 post gender_mincer (${year}) ("${spec_str}") (${dep_earn}) (${dep_wage}) (${indep_c_edu_y}) (${indep_i_edu_y}) (${indep_i_age}) (${indep_i_exp_act}) (${indep_c_exp_pot_c_exp_pot}) (${indep_c_exp_act_c_exp_act}) (${indep_i_${empid_var}}) (${indep_i_empid_gender}) (${indep_i_hours}) (${indep_i_race}) (${indep_i_nation}) (${indep_i_tenure}) (${indep_i_muni}) (${indep_i_ind_5}) (${indep_i_occ_6}) (${b}) (${se}) (${N}) (${N_nosingletons}) (${r2}) (${r2_a}) (${r2_within}) (${r2_a_within})
	}
	else post gender_mincer (${year}) ("${spec_str}") (${dep_earn}) (${dep_wage}) (${indep_c_edu_y}) (${indep_i_edu_y}) (${indep_i_age}) (${indep_i_exp_act}) (${indep_c_exp_pot_c_exp_pot}) (${indep_c_exp_act_c_exp_act}) (${indep_i_${empid_var}}) (${indep_i_empid_gender}) (${indep_i_hours}) (${indep_i_race}) (${indep_i_nation}) (${indep_i_tenure}) (${indep_i_muni}) (${indep_i_ind_5}) (${indep_i_occ_6}) (.)    (.)     (${N}) (.)                 (.)     (.)       (.)            (.)
end

* store life-cycle estimation coefficients from GENDER_4_LIFE_CYCLE.do
program prog_life_cycle_reg // input: none; output = regression outut to screen and postfile line to file
	disp _newline(1)
	global spec_name = "`1'"
	global exp_var_name = "`2'"
	global inc_var_name = "`3'"
	global hours_contr_name = "`4'"
	global race_contr_name = "`5'"
	global spec_str = subinstr("${spec}", " pool(1)", "", .)
	global spec_str = subinstr("${spec_str}", " allbaselevel", "", .)
	while strpos("${spec_str}", "  ") {
		global spec_str = subinstr("${spec_str}", "  ", " ", .)
	}
	global spec_str = subinstr("${spec_str}", "( ", "(", .)
	global spec_str = subinstr("${spec_str}", " )", ")", .)
	disp "${spec_str}"
	cap n ${spec} // run regression
	if e(N) < . {
		global N = e(N)
		if strpos("${spec}", "gender#") | strpos("${spec}", "#ib2.gender") { // if experience profile is interacted with gender
			forval g = 1/2 {
				forval e = 0/$exp_max {
					if `g' == 1 { // if gender = male
						if `e' == 0 cap lincom 1.gender
						else cap lincom `e'.${exp_var_name} + 1.gender#`e'.${exp_var_name}
						if !_rc {
							global b = r(estimate)
							global se = r(se)
						}
						else {
							global b = -9
							global se = -9
						}
					}
					else { // if gender = female
						if `e' == 0 {
							global b = 0
							global se = 0
						}
						else {
							cap global b = _b[`e'.${exp_var_name}]
							if _rc global b = -9
							cap global se = _se[`e'.${exp_var_name}]
							if _rc global se = -9
						}
					}
					cap global gap = _b[1.gender]
					if _rc global gap = -9
					cap global gap_se = _se[1.gender]
					if _rc global gap_se = -9
					qui count if gender == `g' & ${exp_var_name} == `e'
					global n = r(N)
					post gender_life_cycle (${year}) ("${spec_name}") ("${spec_str}") ("${exp_var_name}") ("${inc_var_name}") ("${hours_contr_name}") ("${hours_contr_name}") (`g') (`e') (${b}) (${se}) (${gap}) (${gap_se}) (${n}) (${N})
				}
			}
		}
		else { // else if experience profile is not interacted with gender
			forval e = 0/$exp_max {
				cap global b = _b[`e'.${exp_var_name}]
				if _rc global b = -9
				cap global se = _se[`e'.${exp_var_name}]
				if _rc global se = -9
				cap global gap = _b[1.gender]
				if _rc global gap = -9
				cap global gap_se = _se[1.gender]
				if _rc global gap_se = -9
				qui count if ${exp_var_name} == `e'
				global n = r(N)
				post gender_life_cycle (${year}) ("${spec_name}") ("${spec_str}") ("${exp_var_name}") ("${inc_var_name}") ("${hours_contr_name}") ("${hours_contr_name}") (0) (`e') (${b}) (${se}) (${gap}) (${gap_se}) (${n}) (${N})
			}
		}
	}
end

* coarsen variables to be included as indicators in AKM regression
program prog_coarsen // input: `1' = name of variable to be coarsened; `2' = minimum number of observations in each (coarsened) category
	disp "--> coarsening variable `1' up to minimum category size `2':"
	sum `1', meanonly
	global coarsen_val = 10^ceil(log10(r(max))) - 1 // use as missing code the largest number within the same order of magnitude as the variable's maximum
	if r(min) <= 0 replace `1' = `1' - r(min) + 1 // ensure categorical variable starts from 1, 2, ...
	local g = 0
	local needs_coarsening = 1
	while `needs_coarsening' {
		bys `1': gen N = _N
		sum N, meanonly
		local N_min = r(min)
		local needs_coarsening = (`N_min' < `2')
		if `needs_coarsening' { // if there exists some category that needs coarsening
			sum N if `1' == ${coarsen_val}, meanonly
			local N_coarsened = r(mean)
			if `N_coarsened' < `2' { // if the coarsened category itself has too few observations, then merge with the (next) smallest noncoarsened category.
				sum N if `1' != ${coarsen_val}, meanonly
				local N_min = r(min)
				replace `1' = ${coarsen_val} if N == `N_min'
			}
			else replace `1' = ${coarsen_val} if N == `N_min' // coarsened category = 999999 // else, if the coarsened category has enough observations, then recode the category with insufficient observations to coarsened value.
		}
		drop N
	}
end

* check if -gtools- package can handle number of observations (i.e., if _N <= 2^31 - 1)
program prog_gtools_check // input: `1' = factor by which current number of observations will increase during next operation (e.g., -reshape-)
	if "`1'" != "" local factor = `1'
	else local factor = 1
	qui count
	local N_count = r(N)
	if `factor'*`N_count' <= 2^31 - 1 global gtools_check = "g"
	else global gtools_check = ""
end

* compute share of MW jobs
program define prog_share_mw, rclass
	cap confirm var `1'
	if _rc {
		disp as error "USER ERROR: Could not find earnings variable `1'!"
		error 1
	}
	qui count
	local N_pop = r(N) // = number of observations
// 	qui count if `1' > 0.99 & `1' < 1.01
	qui count if `1' == 1
	local N_mw = r(N) // = number of minimum wage jobs
	local share_mw = `N_mw'/`N_pop' // = share of minimum wage jobs
	return local share `share_mw'
end

* define macros for Lee (1999) analysis
// program program_sel_def // input = "`1'"; output = global sel_var, global sel_use, global sel_crit, global sel_name
// 	if "`1'" == "overall" global sel_var = ""
// 	else if inlist("`1'","micro","meso","state") global sel_var = "municipio"
// 	else if inlist("`1'","ind94_3","ind85_2","occ94_5","occ02_6") global sel_var = substr("`1'",1,5)
// 	else if inlist("`1'","ind92_90 micro","ind92_90 meso","ind92_90 state") global sel_var = "ind92_90 municipio"
// 	else global sel_var = "`1'"
// 	if "`1'" == "overall" global sel_use = ""
// 	else global sel_use = "`1'"
// 	if inlist("`1'","overall","age","edu") global sel_crit = ""
// 	else if inlist("`1'","municipio","micro","meso","state") global sel_crit = "& municipio < ."
// 	else if inlist("`1'","ind92_90 micro","ind92_90 meso","ind92_90 state") global sel_crit = "& ind92_90 < . & municipio < ."
// 	else if "`1'" =="ind92_90" global sel_crit = "& ind92_90 < ."
// 	else if inlist("`1'","ind94","ind94_3","ind85_2","ocu94","occ94_5","occ02_6") global sel_crit = "& ${sel_var} > 1 & ${sel_var} < ."
// 	else global sel_crit = "& ${sel_var} < ."
// 	if inlist("`1'","ind92_90 micro","ind92_90 meso","ind92_90 state") global sel_name = subinstr("`1'"," ","_",.) // replace spaces in "`1'" with "_"
// 	else global sel_name = "`1'"
// end

* compute highest significant earnings percentile in Lee (1999) regression analysis
program prog_lee_signif // input: `1' = specificatio name; `2' = earnings base percentile (50 or 90); output = display percentiles
	sum inc_p if signif == 1 & spec == "`1'" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", meanonly
	local base_signif_max = r(max)
	sum inc_p if signif == 1 & spec == "`1'" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", meanonly
	local haanw_signif_max = r(max)
	sum inc_p if signif == 1 & spec == "`1'" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", meanonly
	local full_signif_max = r(max)
	disp as result "--> Spec. `1': highest sign. perc. (P`2') = `base_signif_max' (baseline), `haanw_signif_max' (Haanwinckel), `full_signif_max' (full)"
end

********************************************************************************
* END OF FUNCTION FUN_PROGRAMS.do
********************************************************************************
