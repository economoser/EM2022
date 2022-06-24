********************************************************************************
* DESCRIPTION: Estimate Lee (1999) and AMS (2016) regressions.
********************************************************************************


*** macros
* switches
global lee_regressions = 1 // 0 = do not run Lee (1999) regressions; 1 = run Lee (1999) regressions
global lee_plots = 1 // 0 = do not plot graphs; 1 = plot graphs

* lists to loop over
// global years_list = "0 1 2 3" // 0 = use all years from ${year_min}-${year_max}; 1 = use years used in Haanwinckel (i.e., 1996-2013 except 2002, 2003, 2004, and 2010); 2 = use even years from ${year_min}-${year_max}; 3 = use odd years from ${year_min}-${year_max}
global years_list = "0 1" // 0 = use all years from ${year_min}-${year_max}; 1 = use years used in Haanwinckel (i.e., 1996-2013 except 2002, 2003, 2004, and 2010); 2 = use even years from ${year_min}-${year_max}; 3 = use odd years from ${year_min}-${year_max}
global sel_list = "state meso" // units of analysis at which to run Lee (1999) / AMS (2016) regressions -- "state meso micro muni" -- Note: App. 5,595 municipios, 558 microregions, 137 mesoregions, 27 states.
global p_base_list = "50 90" // base percentiles used for Lee (1999) / AMS (2016) regressions -- "50 90"
global p_min = 10 // minimum earnings percentile to plot in graphs
global p_max = 90 // maximum earnings percentile to plot in graphs

* data parameters
global weighted = 1 // 0 = state-weighted regressions; 1 = job-weighted regressions
global noisily_str = "" // "" to suppress regression output; "n" or "noisily" to show regression output
global crit_val = 2.576 // 1.645 = 90% level; 1.960 = 95% level; 2.576 = 99% level
global min_drop_n = 100 // minimum number of workers in each state / region / etc. (e.g., if "`sel'" == "state" and `min_drop_n' == 100, then there is >=1 worker per percentile bin)
global akm = 0 // 0 = run on income data; 1 = run on AKM person FE estimates; 2 = run on AKM firm FE estimates
global years_consecutive = 0 // 0 = count years since ${year_lee_min}, thereby preserving gaps in years (e.g., 2003-2005 are not in Hannwinckel's sample); 1 = count years as 1, 2, ..., T, even if there are missing years (e.g., 2003-2005 are not in Hannwinckel's sample)

* automatically set macros
if $year_min > 1996 | $year_max < 2013 global years_list = subinstr("${years_list}", "1", "", .)
if $year_min > 1985 | $year_max < 2018 {
	global years_list = subinstr("${years_list}", "2", "", .)
	global years_list = subinstr("${years_list}", "3", "", .)
}
if inlist(${akm}, 1, 2) global akm_ext = "_akm" // file extension for regressions run on earnings vs. AKM components
else global akm_ext = ""
if $akm == 0 global inc = "inc" // income concept
else if $akm == 1 global inc = "pe"
else if $akm == 2 global inc = "fe"
global years_haanwinckel = "1996 1997 1998 1999 2000 2001 2005 2006 2007 2008 2009 2011 2012 2013" // list of years used in Haanwinckel (2020)
global years_haanwinckel_comma = subinstr("${years_haanwinckel}", " ", ", ", .) // comma-separated list of years used in Haanwinckel (2020)


** loop through units of analysis and base percentiles
foreach years of global years_list {
	foreach sel of global sel_list {
		foreach p_base of global p_base_list {
			
			*** skip loop?
			if $lee_regressions == 0 continue
			
			*** loop-specific macros
			if `years' == 0 local years_ext = "" // years ${year_min}-${year_max}
			else if `years' == 1 local years_ext = "_h" // years used in Haanwinckel (i.e., 1996-2013 except 2002, 2003, 2004, and 2010)
			else if `years' == 2 local years_ext = "_even" // even years in ${year_min}-${year_max}
			else if `years' == 3 local years_ext = "_odd" // odd years in ${year_min}-${year_max}
			local p_kaitz = `p_base' // percentile used for Kaitz index normalization (denominator)
			local p_mean = `p_base' // percentile used for computing `sel'-level mean log percentile earnings
// 			global spec_list = "`sel' year `sel'_year `sel'_trend_1 `sel'_trend_2 `sel'_trend_3 `sel'_trend_1_iv `sel'_trend_2_iv `sel'_trend_3_iv `sel'_year_trend_1 `sel'_year_trend_2 `sel'_year_trend_3 `sel'_diff year_diff `sel'_year_diff `sel'_trend_1_diff `sel'_trend_2_diff `sel'_trend_3_diff `sel'_trend_1_iv_diff `sel'_trend_2_iv_diff `sel'_trend_3_iv_diff `sel'_year_trend_1_diff `sel'_year_trend_2_diff `sel'_year_trend_3_diff `sel'_trend_1_ntrend_2 `sel'_trend_1_ntrend_2_iv `sel'_trend_0_ntrend_1_diff `sel'_trend_0_ntrend_1_iv_diff" // complete list of specifications
			if "`sel'" == "state" global spec_list = "`sel' year `sel'_year `sel'_trend_1 `sel'_trend_2 `sel'_trend_3 `sel'_trend_1_iv `sel'_year_trend_1 `sel'_trend_1_diff `sel'_trend_1_iv_diff `sel'_trend_1_ntrend_2 `sel'_trend_1_ntrend_2_iv `sel'_trend_0_ntrend_1_diff `sel'_trend_0_ntrend_1_iv_diff" // shorter list of specifications
			else if "`sel'" == "meso" global spec_list = "`sel'_trend_1" // shorter list of specifications
			else global spec_list = "" // no specifications
			
			*** prepare percentiles ratios
			foreach source in "data" "model" {
				if "`sel'" != "state" & "`source'" == "model" continue
				if "`source'" == "data" {
				
					* load data
					if `years' == 0 use if inrange(year, ${year_min}, ${year_max}) using "${DIR_TEMP}/RAIS/percentiles${akm_ext}_${year_data_min}_${year_data_max}_`sel'.dta", clear
					else if `years' == 1 use if inlist(year, ${years_haanwinckel_comma}) using "${DIR_TEMP}/RAIS/percentiles${akm_ext}_${year_data_min}_${year_data_max}_`sel'.dta", clear
					else if `years' == 2 use if mod(year, 2) == 0 using "${DIR_TEMP}/RAIS/percentiles${akm_ext}_${year_data_min}_${year_data_max}_`sel'.dta", clear
					else if `years' == 3 use if mod(year, 2) == 1 using "${DIR_TEMP}/RAIS/percentiles${akm_ext}_${year_data_min}_${year_data_max}_`sel'.dta", clear
					
					* generate log number of observations
					gen float N_ln = ln(N)
					label var N_ln "Log number of observations"
					
					* generate Kaitz index
					if inlist($akm, 1, 2) merge 1:1 `sel' year using "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_`sel'.dta", keep(master match) keepusing(inc_p`p_kaitz') nogen
					qui gen float kaitz = -inc_p`p_kaitz'
					label var kaitz "Kaitz-`p_kaitz' index, log(MW/P`p_kaitz')"
					if inlist($akm, 1, 2) drop inc_p`p_kaitz'
					
					* rename variables
					if inlist($akm, 1, 2) {
						local inc_str = "${inc}"
						foreach var of varlist `inc_str'_* {
							local inc_str_sub = subinstr("`var'", "${inc}", "inc", .)
							qui rename `var' `inc_str_sub'
						}
					}
					if $akm == 1 drop fe*
					else if $akm == 2 drop pe*
					drop inc_mean
					
					* merge in real minimum wage
					qui merge m:1 year using "${DIR_TEMP}/IPEA/mw_real_yearly.dta", keep(master match) keepusing(mw_real) nogen
					qui replace mw_real = ln(mw_real)
					qui recast float mw_real, force
					label var mw_real "Real minimum wage (log constant BRL)"
				}
				else if "`source'" == "model" {
				
					* load
					cap n { // XXX REMOVE LATER -- PRODUCE MODEL RESULTS BEFORE RUNNING THIS!!!
// 						!cp "${DIR_MODEL}/3 Version 10302020/2 Data/Lee.csv" "${DIR_RESULTS}/${section}/Lee.csv"
						!cp "${DIR_MODEL}/4 Version 11122021/2 Data/Lee.csv" "${DIR_RESULTS}/${section}/Lee.csv"
					}
					qui import delim using "${DIR_RESULTS}/${section}/Lee.csv", delim(tab) clear
					
					* keep only relevant years
					if `years' == 0 qui keep if inrange(year, ${year_min}, ${year_max})
					else if `years' == 1 qui keep if inlist(year, ${years_haanwinckel_comma})
					else if `years' == 2 qui keep if mod(year, 2) == 0
					else if `years' == 3 qui keep if mod(year, 2) == 1
					
					* format variables
					rename n N
					foreach var of varlist inc* mw {
						qui recast float `var', force
					}
					rename mw mw_real
					label var mw_real "Productivity-adjusted log minimum wage (1996 = 0.0)"

					* generate Kaitz index
					qui gen float kaitz = mw_real - inc_p`p_kaitz'
					label var kaitz "Kaitz index, log(MW/P`p_kaitz')"
				}
				
				* generate log earnings percentile ratios
				foreach p of numlist $p_min(5)$p_max {
					label var inc_p`p' "Percentile `p' of log earnings"
					if `p' != `p_base' {
						qui gen float inc_p`p'_p`p_base' = inc_p`p' - inc_p`p_base'
						label var inc_p`p'_p`p_base' "Log P`p'-P`p_base' percentile ratio, log(P`p'/P`p_base')"
					}
				}
				
				* normalize year
				if $years_consecutive {
					rename year year_old
					${gtools}egen int year = group(year_old)
					drop year_old
					label var year "Normalized year"
					qui compress year
				}
				else {
					sum year, meanonly
					qui replace year = year - r(min)
				}
				
				* generate square of year
				qui gen long year_2 = year^2
				label var year_2 "Normalized year squared"
				
				* generate cube of year
				qui gen long year_3 = year^3
				label var year_3 "Normalized year cubed"
				
				* generate square of Kaitz index
				qui gen float kaitz_2 = kaitz^2
				label var kaitz_2 "Squared Kaitz index, [log(MW/P`p_kaitz')]^2"
				
				* generate square of real minimum wage
				qui gen float mw_real_2 = mw_real^2
				label var mw_real_2 "Squared mean real minimum wage (log constant BRL)"
				
				* generate differenced variables
				qui xtset `sel' year
				qui gen float D_kaitz = D.kaitz
				label var D_kaitz "Differenced Kaitz index, D.[log(MW/P`p_kaitz')]"
				qui gen float D_kaitz_2 = D.kaitz_2
				label var D_kaitz_2 "Differenced squared Kaitz index, D.[[log(MW/P`p_kaitz')]^2]"
				foreach p of numlist $p_min(5)$p_max {
					if `p' != `p_base' {
						qui gen float D_inc_p`p'_p`p_base' = D.inc_p`p'_p`p_base'
						label var D_inc_p`p'_p`p_base' "Differenced log P`p'-P`p_base' percentile ratio, D.[log(P`p'/P`p_base')]"
					}
				}
				gen float inc_std = inc_var^.5
				drop inc_var
				qui gen float D_inc_std = D.inc_std
				label var D_inc_std "Differenced std. dev. of log earnings"
				qui gen float D_mw_real = D.mw_real
				label var D_mw_real "Differenced real minimum wage (log constant BRL)"
				qui gen float D_mw_real_2 = D.mw_real_2
				label var D_mw_real_2 "Differenced squared real minimum wage (log constant BRL)"
				if "`source'" == "data" {
					local vars_additional = "hours_mean size_est_mean inc_bonus_mean active_eoy_mean entry_mean exit_mean N_ln"
					local vars_D_additional = ""
					foreach var of local vars_additional {
						qui gen float D_`var' = D.`var'
						local l: variable label `var'
						local l = subinstr("`l'", "(", "", .)
						local l = subinstr("`l'", ")", "", .)
						label var `var' "`l'"
						local l_D = "Differenced `l'"
						label var D_`var' "`l_D'"
						local vars_D_additional = "`vars_D_additional' D_`var'"
					}
				}
				else if "`source'" == "model" {
					local vars_additional = ""
					local vars_D_additional = ""
				}
				
				* generate `sel'-level mean log P`p_mean' earnings
				if "${gtools}" == "" qui bys `sel': egen inc_p`p_mean'_mean = mean(inc_p`p_mean'*mw_real) // Note: Could try with and without multiplying by real MW ("mw_real") here!
				else qui gegen float inc_p`p_mean'_mean = mean(inc_p`p_mean'*mw_real), by(`sel')
				local sel_proper = proper("`sel'")
				label var inc_p`p_mean'_mean "`sel_proper'-level mean log median earnings (constant BRL)"
				drop inc_p? inc_p??
				
				* generate interaction between real minimum wage and `sel'-level mean log median earnings
				qui gen float inter_mw_real_inc_p`p_mean'_mean = mw_real*inc_p`p_mean'_mean
				label var inter_mw_real_inc_p`p_mean'_mean "Interaction b/w log real MW and `sel'-level mean log median earnings"
				qui gen float inter_D_mw_real_inc_p`p_mean'_mean = D_mw_real*inc_p`p_mean'_mean
				label var inter_D_mw_real_inc_p`p_mean'_mean "Interaction b/w differenced log real MW and `sel'-level mean log median earnings"
				
				* normalize weights
				if "${gtools}" == "" qui bys year: egen float N_yearly_total = total(N)  // Note: Could try with and without multiplying by real MW ("mw_real") here!
				else qui gegen float N_yearly_total = total(N), by(year)
				qui replace N = N/N_yearly_total
				drop N_yearly_total
				label var N "Normalized weights"
				
				* generate weights for difference specifications
				qui xtset `sel' year
				qui gen float N_diff=(N*L.N)/(N + L.N) // construct weights following AMS (2016)
				if "${gtools}" == "" qui bys year: egen float N_diff_yearly_total = total(N_diff) // Note: Could try with and without multiplying by real MW ("mw_real") here!
				else qui gegen float N_diff_yearly_total = total(N_diff), by(year)
				qui replace N_diff = N_diff/N_diff_yearly_total
				drop N_diff_yearly_total
				label var N_diff "Normalized weights for difference specification"
				
				* save
				order `sel' year year_2 year_3 inc_p*_p`p_base' D_inc_p*_p`p_base' inc_std D_inc_std `vars_additional' `vars_D_additional' kaitz D_kaitz kaitz_2 D_kaitz_2 mw_real D_mw_real mw_real_2 D_mw_real_2 inc_p`p_mean'_mean inter_mw_real_inc_p`p_mean'_mean inter_D_mw_real_inc_p`p_mean'_mean N N_diff
				sort `sel' year
				qui compress
				qui save "${DIR_TEMP}/RAIS/percentiles${akm_ext}_lee_`sel'_`source'_${year_min}_${year_max}`years_ext'.dta", replace
			}


			*** Lee (1999) / AMS (2016) regression analysis, data and model
			foreach source in "data" "model" {
				if "`sel'" != "state" & "`source'" == "model" continue
				disp _newline(1)
				disp as input "   --> regressions for years = `years', sel = `sel', p_base = `p_base', source = `source'"
				postutil clear
				postfile lee_reg_`sel' ///
					abovemw belowcap min_drop p_base str32 spec inc_p ///
					b se_1 se_2 r2 n ///
					using "${DIR_TEMP}/RAIS/lee_reg_`sel'_`source'_p`p_base'_${year_min}_${year_max}`years_ext'.dta", replace
				foreach bound in ""  { // "" "_abovemw" "_belowcap" "_abovemw_belowcap"
					local abovemw_ind = inlist("`bound'","_abovemw","_abovemw_belowcap")
					local belowcap_ind = inlist("`bound'","_belowcap","_abovemw_belowcap")
					serset clear // important; clears Stata's serset (graphics data memory)
					foreach min_drop in 0 { // 0 1
						use "${DIR_TEMP}/RAIS/percentiles${akm_ext}_lee_`sel'_`source'_${year_min}_${year_max}`years_ext'.dta", clear // `sel' year year_2 year_3 inc_p*_p`p_base' D_inc_p*_p`p_base' inc_std D_inc_std kaitz kaitz_2 D_kaitz D_kaitz_2 mw_real mw_real_2 D_mw_real D_mw_real_2 inc_p`p_mean'_mean inter_mw_real_inc_p`p_mean'_mean inter_D_mw_real_inc_p`p_mean'_mean N N_diff ///
						if $weighted == 0 {
							qui replace N = 1
							qui replace N_diff = 1
						}
						if `min_drop' {
							if "${gtools}" == "" qui bys `sel': egen long N_min = min(N) // drop all `sel' groups associated with number of observations below a threshold in any year
							else qui gegen long N_min = min(N), by(`sel')
							drop if N_min < ${min_drop_n}
							drop N_min
						}
						foreach spec of global spec_list {
							if "`spec'" == "year" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.year)"
								local dof_option = ""
								disp as text "   -----> year FEs, estimated in levels"
							}
							else if "`spec'" == "`sel'" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel')"
								local dof_option = ""
								disp as text "   -----> `sel' FEs, estimated in levels"
							}
							else if "`spec'" == "`sel'_year" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel' i.year)"
								local dof_option = ""
								disp as text "   -----> `sel' FEs and year FEs, estimated in levels"
							}
							else if "`spec'" == "`sel'_trend_1" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and linear `sel' time trends, estimated in levels"
							}
							else if "`spec'" == "`sel'_trend_2" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and quadratic `sel' time trends, estimated in levels"
							}
							else if "`spec'" == "`sel'_trend_3" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2 c.year_3))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and cubic `sel' time trends, estimated in levels"
							}
							else if "`spec'" == "`sel'_trend_1_iv" {
								local reg_command = "ivreghdfe"
								local diff = ""
								local vars_indep = "(`diff'kaitz `diff'kaitz_2=c.`diff'mw_real c.`diff'mw_real_2 c.inter_`diff'mw_real_inc_p`p_mean'_mean)"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and linear `sel' time trends, IV, estimated in levels"
							}
							else if "`spec'" == "`sel'_trend_2_iv" {
								local reg_command = "ivreghdfe"
								local diff = ""
								local vars_indep = "(`diff'kaitz `diff'kaitz_2=c.`diff'mw_real c.`diff'mw_real_2 c.inter_`diff'mw_real_inc_p`p_mean'_mean)"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and quadratic `sel' time trends, IV, estimated in levels"
							}
							else if "`spec'" == "`sel'_trend_3_iv" {
								local reg_command = "ivreghdfe"
								local diff = ""
								local vars_indep = "(`diff'kaitz `diff'kaitz_2=c.`diff'mw_real c.`diff'mw_real_2 c.inter_`diff'mw_real_inc_p`p_mean'_mean)"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2 c.year_3))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and cubic `sel' time trends, IV, estimated in levels"
							}
							else if "`spec'" == "`sel'_year_trend_1" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year) i.year)"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and year FEs and linear `sel' time trends, estimated in levels"
							}
							else if "`spec'" == "`sel'_year_trend_2" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2) i.year)"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and year FEs and quadratic `sel' time trends, estimated in levels"
							}
							else if "`spec'" == "`sel'_year_trend_3" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2 c.year_3) i.year)"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and year FEs and cubic `sel' time trends, estimated in levels"
							}
							else if "`spec'" == "`sel'_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel')"
								local dof_option = ""
								disp as text "   -----> `sel' FEs, estimated in differences"
							}
							else if "`spec'" == "year_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.year)"
								local dof_option = ""
								disp as text "   -----> year FEs, estimated in differences"
							}
							else if "`spec'" == "`sel'_year_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel' i.year)"
								local dof_option = ""
								disp as text "   -----> `sel' FEs and year FEs, estimated in differences"
							}
							else if "`spec'" == "`sel'_trend_1_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel'##(c.year))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and linear `sel' time trends, estimated in differences"
							}
							else if "`spec'" == "`sel'_trend_2_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and quadratic `sel' time trends, estimated in differences"
							}
							else if "`spec'" == "`sel'_trend_3_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2 c.year_3))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and cubic `sel' time trends, estimated in differences"
							}
							else if "`spec'" == "`sel'_trend_1_iv_diff" {
								local reg_command = "ivreghdfe"
								local diff = "D_"
								local vars_indep = "(`diff'kaitz `diff'kaitz_2=c.`diff'mw_real c.`diff'mw_real_2 c.inter_`diff'mw_real_inc_p`p_mean'_mean)"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel'##(c.year))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and linear `sel' time trends, IV, estimated in differences"
							}
							else if "`spec'" == "`sel'_trend_2_iv_diff" {
								local reg_command = "ivreghdfe"
								local diff = "D_"
								local vars_indep = "(`diff'kaitz `diff'kaitz_2=c.`diff'mw_real c.`diff'mw_real_2 c.inter_`diff'mw_real_inc_p`p_mean'_mean)"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and quadratic `sel' time trends, IV, estimated in differences"
							}
							else if "`spec'" == "`sel'_trend_3_iv_diff" {
								local reg_command = "ivreghdfe"
								local diff = "D_"
								local vars_indep = "(`diff'kaitz `diff'kaitz_2=c.`diff'mw_real c.`diff'mw_real_2 c.inter_`diff'mw_real_inc_p`p_mean'_mean)"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2 c.year_3))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and cubic `sel' time trends, IV, estimated in differences"
							}
							else if "`spec'" == "`sel'_year_trend_1_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel'##(c.year) i.year)"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and year FEs and linear `sel' time trends, estimated in differences"
							}
							else if "`spec'" == "`sel'_year_trend_2_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2) i.year)"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and year FEs and quadratic `sel' time trends, estimated in differences"
							}
							else if "`spec'" == "`sel'_year_trend_3_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel'##(c.year c.year_2 c.year_3) i.year)"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and year FEs and cubic `sel' time trends, estimated in differences"
							}
							else if "`spec'" == "`sel'_trend_1_ntrend_2" {
								local reg_command = "reghdfe"
								local diff = ""
								local vars_indep = "`diff'kaitz `diff'kaitz_2 c.year_2"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs, linear `sel' time trends, and quadratic national trend, estimated in levels"
							}
							else if "`spec'" == "`sel'_trend_1_ntrend_2_iv" {
								local reg_command = "ivreghdfe"
								local diff = ""
								local vars_indep = "c.year_2 (`diff'kaitz `diff'kaitz_2=c.`diff'mw_real c.`diff'mw_real_2 c.inter_`diff'mw_real_inc_p`p_mean'_mean)"
								local w = "[aw=N]"
								local absorb_option = "a(i.`sel'##(c.year))"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs, linear `sel' time trends, and quadratic national trend, IV, estimated in levels"
							}
							else if "`spec'" == "`sel'_trend_0_ntrend_1_diff" {
								local reg_command = "reghdfe"
								local diff = "D_"
								local vars_indep = "`diff'kaitz `diff'kaitz_2 c.year"
								local w = "[aw=N_diff]"
								local absorb_option = "a(i.`sel')"
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and linear national time trend, estimated in differences"
							}
							else if "`spec'" == "`sel'_trend_0_ntrend_1_iv_diff" {
								local reg_command = "ivreghdfe"
								local diff = "D_"
								local vars_indep = "i.`sel' c.year (`diff'kaitz `diff'kaitz_2=c.`diff'mw_real c.`diff'mw_real_2 c.inter_`diff'mw_real_inc_p`p_mean'_mean)"
								local w = "[aw=N_diff]"
								local absorb_option = ""
								local dof_option = "dof(cont)"
								disp as text "   -----> `sel' FEs and linear national time trend, IV, estimated in differences"
							}
							
							sum `diff'kaitz [aw=N], meanonly
							local mean_mw = r(mean)
							if "`source'" == "data" local p_additional = "-1 -2 -3 -4 -5 -6 -7"
							else if "`source'" == "model" local p_additional = ""
							foreach p of numlist 0 $p_min(5)$p_max `p_additional' { // Note: 0 corresponds to std. dev. of log earnings (inc_std) as dependent variable
								cap confirm var test // Note: Need this here to reset "_rc"
								if `p' == 0 cap ${noisily_str} `reg_command' `diff'inc_std `vars_indep' `w', `absorb_option' // Note: Dependent variable = variance of log earnings
								else if `p' == -1 cap ${noisily_str} `reg_command' `diff'hours_mean `vars_indep' `w', `absorb_option' // Note: Dependent variable = mean log contractual work hours
								else if `p' == -2 cap ${noisily_str} `reg_command' `diff'size_est_mean `vars_indep' `w', `absorb_option' // Note: Dependent variable = mean log establishment size
								else if `p' == -3 cap ${noisily_str} `reg_command' `diff'inc_bonus_mean `vars_indep' `w', `absorb_option' // Note: Dependent variable = mean log bonus ratio (i.e., December-to-mean wage)
								else if `p' == -4 cap ${noisily_str} `reg_command' `diff'active_eoy_mean `vars_indep' `w', `absorb_option' // Note: Dependent variable = probability of workers remaining employed until next year
								else if `p' == -5 cap ${noisily_str} `reg_command' `diff'entry_mean `vars_indep' `w', `absorb_option' // Note: Dependent variable = probability of establishment having just entered this year
								else if `p' == -6 cap ${noisily_str} `reg_command' `diff'exit_mean `vars_indep' `w', `absorb_option' // Note: Dependent variable = probability of establishment exiting next year
								else if `p' == -7 cap ${noisily_str} `reg_command' `diff'N_ln `vars_indep' `w', `absorb_option' // Note: Dependent variable = log number of observations in RAIS (i.e., log number of formal jobs)
								else if `p' != `p_base' cap ${noisily_str} `reg_command' `diff'inc_p`p'_p`p_base' `vars_indep' `w', `absorb_option' // Note: Dependent variable = log earnings percentile ratio
								if !_rc & `p' != `p_base' {
									local n = e(N)
									local r2 = e(r2)
									qui lincom `diff'kaitz + 2*`mean_mw'*`diff'kaitz_2
									local b = r(estimate) // automatically compute marginal effect, as in AMS (2016)
									local se_1 = r(se) // automatically compute standard error of marginal effect, as in AMS (2016)
								}
								else if `p' == `p_base' {
									local b = 0
									local se_1 = 0
									qui count
									local n = r(N)
									local r2 = 1
								}
								else { // if _rc, i.e., if regression failed
									disp as error "USER WARNING: No observations for `source' specification = `spec', p = `p'."
									local b = 0
									local se_1 = 0
									local n = 0
									local r2 = -1 // mark errors as "R^2 = -1"
								}
								cap confirm var test // Note: need this here to reset "_rc"
								if `p' == 0 cap ${noisily_str} `reg_command' `diff'inc_std `vars_indep' `w', `absorb_option' cluster(`sel') // Note: Dependent variable = variance of log earnings
								else if `p' == -1 cap ${noisily_str} `reg_command' `diff'hours_mean `vars_indep' `w', `absorb_option' cluster(`sel') // Note: Dependent variable = mean log contractual work hours
								else if `p' == -2 cap ${noisily_str} `reg_command' `diff'size_est_mean `vars_indep' `w', `absorb_option' cluster(`sel') // Note: Dependent variable = mean log establishment size
								else if `p' == -3 cap ${noisily_str} `reg_command' `diff'inc_bonus_mean `vars_indep' `w', `absorb_option' cluster(`sel') // Note: Dependent variable = mean log bonus ratio (i.e., December-to-mean wage)
								else if `p' == -4 cap ${noisily_str} `reg_command' `diff'active_eoy_mean `vars_indep' `w', `absorb_option' cluster(`sel') // Note: Dependent variable = probability of workers remaining employed until next year
								else if `p' == -5 cap ${noisily_str} `reg_command' `diff'entry_mean `vars_indep' `w', `absorb_option' cluster(`sel') // Note: Dependent variable = probability of establishment having just entered this year
								else if `p' == -6 cap ${noisily_str} `reg_command' `diff'exit_mean `vars_indep' `w', `absorb_option' cluster(`sel') // Note: Dependent variable = probability of establishment exiting next year
								else if `p' == -7 cap ${noisily_str} `reg_command' `diff'N_ln `vars_indep' `w', `absorb_option' cluster(`sel') // Note: Dependent variable = log number of observations in RAIS (i.e., log number of formal jobs)
								else if `p' != `p_base' cap ${noisily_str} `reg_command' `diff'inc_p`p'_p`p_base' `vars_indep' `w', `absorb_option' cluster(`sel') // Note: Dependent variable = log earnings percentile ratio
								if !_rc {
									qui lincom `diff'kaitz + 2*`mean_mw'*`diff'kaitz_2
									local se_2 = r(se)
								}
								else local se_2 = 0
	// 							disp as text "         ...predicted effect on P`p' is `b' (regular std. err. `se_1', clustered std. err. `se_2')"
								post lee_reg_`sel' ///
									(`abovemw_ind') (`belowcap_ind') (`min_drop') (`p_base') ("`spec'") ///
									(`p') (`b') (`se_1') (`se_2') (`r2') (`n')
							}
						}
					}
				}
				postclose lee_reg_`sel'
				
				* format postfile
				use ///
					p_base spec inc_p b se_1 se_2 r2 n ///
					using "${DIR_TEMP}/RAIS/lee_reg_`sel'_`source'_p`p_base'_${year_min}_${year_max}`years_ext'.dta", clear
				qui label define inc_p_l -7 "Log number of obs." -6 "Prob(estab. exit)" -5 "Prob(estab. entry)" -4 "Prob(emp. until next year)" -3 "Mean log bonus ratio" -2 "Mean log estab. size" -1 "Mean log hours" 0 "Var(log wages)", replace
				label val inc_p inc_p_l
				label var se_1 "Regular standard errors"
				label var se_2 "Standard errors clustered within `sel'"
				qui compress
				
				* save postfile
				qui save "${DIR_TEMP}/RAIS/lee_reg_`sel'_`source'_p`p_base'_${year_min}_${year_max}`years_ext'.dta", replace
			}
		}
	}
}


*** plot results
foreach years of global years_list {
	foreach p_base of global p_base_list {
	
		*** skip loop?
		if $lee_plots == 0 continue
		
		* loop-specific macros
		if `years' == 0 local years_ext = "" // years ${year_min}-${year_max}
		else if `years' == 1 local years_ext = "_h" // years used in Haanwinckel (i.e., 1996-2013 except 2002, 2003, 2004, and 2010)
		else if `years' == 2 local years_ext = "_even" // even years in ${year_min}-${year_max}
		else if `years' == 3 local years_ext = "_odd" // odd years in ${year_min}-${year_max}
		
		* combine data and model datasets
		foreach sel of global sel_list {
			use "${DIR_TEMP}/RAIS/lee_reg_`sel'_data_p`p_base'_${year_min}_${year_max}.dta", clear
			if "`sel'" != "state" keep if inlist(spec, "`sel'_trend_1", "`sel'_trend_2", "`sel'_trend_3")
			save "${DIR_TEMP}/RAIS/temp_`sel'.dta", replace
		}
		clear
		foreach sel of global sel_list {
			qui append using "${DIR_TEMP}/RAIS/temp_`sel'.dta"
			rm "${DIR_TEMP}/RAIS/temp_`sel'.dta"
		}
		gen str5 source = "data"
		append using "${DIR_TEMP}/RAIS/lee_reg_state_model_p`p_base'_${year_min}_${year_max}.dta"
		qui replace source = "model" if source == ""
		qui compress
		order source p_base spec inc_p b se_1 se_2 r2 n
		sort source spec inc_p
		
		* save combined data
		qui save "${DIR_TEMP}/RAIS/lee_reg_merged_p`p_base'_${year_min}_${year_max}.dta", replace
		
		* define placement of legend in figures
		if `p_base' == 50 local legend_pos = 2
		else if `p_base' == 90 local legend_pos = 6
		
		* baseline specification and robustness in new paper (December 2021)
		if `years' == 0 & $akm == 0 {
			
			* create merged data
			clear
			gen str9 source = ""
			local empty = 1
			foreach f in ///
				"${DIR_TEMP}/RAIS/lee_reg_state_data_p`p_base'_1985_2018.dta" ///
				"${DIR_TEMP}/RAIS/lee_reg_state_data_p`p_base'_1985_1995.dta" ///
				"${DIR_TEMP}/RAIS/lee_reg_state_data_p`p_base'_1985_2007.dta" ///
				"${DIR_TEMP}/RAIS/lee_reg_state_data_p`p_base'_1996_2018.dta" ///
				{
				cap confirm file "`f'"
				if !_rc {
					append using "`f'"
					replace source = substr("`f'", -13, 9) if source == ""
					local empty = 0
				}
			}
			gen float se_low_1 = b - ${crit_val}*se_1
			label var se_low_1 "Lower bound of regular standard error band"
			gen float se_high_1 = b + ${crit_val}*se_1
			label var se_high_1 "Upper bound of regular standard error band"
			gen float se_low_2 = b - ${crit_val}*se_2
			label var se_low_2 "Lower bound of clustered standard error band"
			gen float se_high_2 = b + ${crit_val}*se_2
			label var se_high_2 "Upper bound of clustered standard error band"
			if `empty' == 0 save "${DIR_TEMP}/RAIS/temp_merged.dta", replace
			
			* load data
			use "${DIR_TEMP}/RAIS/lee_reg_merged_p`p_base'_${year_min}_${year_max}.dta", clear
			
			* generate appropriate standard error bands
			gen float se_low_1 = b - ${crit_val}*se_1
			label var se_low_1 "Lower bound of regular standard error band"
			gen float se_high_1 = b + ${crit_val}*se_1
			label var se_high_1 "Upper bound of regular standard error band"
			gen float se_low_2 = b - ${crit_val}*se_2
			label var se_low_2 "Lower bound of clustered standard error band"
			gen float se_high_2 = b + ${crit_val}*se_2
			label var se_high_2 "Upper bound of clustered standard error band"
			
			* prepare graphs
			sort inc_p
			
			* plot graphs
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.4(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(off) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(baseline_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/baseline_p`p_base'_${year_min}_${year_max}.pdf", replace
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_1_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1_iv" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1_iv" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1_diff" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1_diff" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(green%30) lcolor(green%0)) ///
				(connected b inc_p if spec == "state_trend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(green) mcolor(green) msymbol(S) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1_iv_diff" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) msymbol(S) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1_iv_diff" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-2.0(.5)3.0, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline (OLS in levels)" 7 "IV in levels" 11 "OLS in differences" 15 "IV in differences") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(robustness_specifications_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/robustness_specifications_p`p_base'_${year_min}_${year_max}.pdf", replace
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "year" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "year" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(green%30) lcolor(green%0)) ///
				(connected b inc_p if spec == "state_year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(green) mcolor(green) msymbol(S) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_year" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) msymbol(S) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_year" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_year_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(orange%30) lcolor(orange%0)) ///
				(connected b inc_p if spec == "state_year_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(orange) mcolor(orange) msymbol(+) msize(large) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_year_trend_1" & inc_p == 0 & source == "data", lcolor(orange) mcolor(orange) lpattern(l) msymbol(+) msize(large) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_year_trend_1" & inc_p == 0 & source == "data", lcolor(orange) mcolor(orange) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.6(.2)1, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline (state FEs and linear state trends)" 7 "State FEs" 11 "Year FEs" 15 "State FEs and year FEs" 19 "State FEs, year FEs, and linear state trends") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(robustness_controls_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/robustness_controls_p`p_base'_${year_min}_${year_max}.pdf", replace
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_2" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_2" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_3" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_3" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.6(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline (linear state trends)" 7 "Quadratic state trends" 11 "Cubic state trends") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(robustness_trends_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/robustness_trends_p`p_base'_${year_min}_${year_max}.pdf", replace
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "meso_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "meso_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "meso_trend_1" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "meso_trend_1" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.6(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline (regular SEs)" 7 "SEs clustered within states" 11 "SEs clustered within mesoregions") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(robustness_ses_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/robustness_ses_p`p_base'_${year_min}_${year_max}.pdf", replace
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(gs10%30) lcolor(gs10%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(gs10) mcolor(gs10) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(gs10) mcolor(gs10) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "data", lcolor(gs10) mcolor(gs10) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.6(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "${year_min}-${year_max}") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(robustness_years_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/robustness_years_p`p_base'_${year_min}_${year_max}.pdf", replace
			preserve
			use "${DIR_TEMP}/RAIS/temp_merged.dta", clear
			rm "${DIR_TEMP}/RAIS/temp_merged.dta"
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "1996_2018", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "1996_2018", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "1996_2018", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "1996_2018", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "1985_1995", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "1985_1995", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "1985_1995", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "1985_1995", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "1985_2007", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "1985_2007", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "1985_2007", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "1985_2007", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "1985_2018", fcolor(green%30) lcolor(green%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "1985_2018", lcolor(green) mcolor(green) msymbol(S) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "1985_2018", lcolor(green) mcolor(green) lpattern(l) msymbol(S) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "1985_2018", lcolor(green) mcolor(green) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.6(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline (1996-2018)" 7 "1985-1995" 11 "1985-2007" 15 "1985-2018") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(robustness_years_p`p_base'_m, replace)
			graph export "${DIR_RESULTS}/${section}/robustness_years_p`p_base'_merged.pdf", replace
			restore
			
// 			global spec_list = "state year state_year state_trend_1 state_trend_2 state_trend_3 state_trend_1_iv state_trend_2_iv state_trend_3_iv state_year_trend_1 state_year_trend_2 state_year_trend_3 state_diff year_diff state_year_diff state_trend_1_diff state_trend_2_diff state_trend_3_diff state_trend_1_iv_diff state_trend_2_iv_diff state_trend_3_iv_diff state_year_trend_1_diff state_year_trend_2_diff state_year_trend_3_diff" // list of specifications to run
// 			global spec_list = "state year state_year state_trend_1 state_trend_2 state_trend_3 state_trend_1_iv state_year_trend_1 state_trend_1_diff state_trend_1_iv_diff" // shorter list of specifications to run
			global spec_list = "state_trend_1 state_trend_1_iv" // even shorter list of specifications to run
			foreach spec of global spec_list { // focus on: XXX TBC!
				if inlist("`spec'", "year", "state", "state_trend_1", "state_trend_2", "state_trend_3", "state_trend_1_iv", "state_trend_2_iv", "state_trend_3_iv") local y_scale = "-.4(.2).8"
				else if inlist("`spec'", "state_trend_1_diff", "state_trend_2_diff", "state_trend_3_diff") local y_scale = "-1.5(.5)3"
				else if inlist("`spec'", "state_trend_1_iv_diff", "state_trend_2_iv_diff", "state_trend_3_iv_diff") local y_scale = "-1.5(.5)3"
				tw ///
					(function y = 0, range(0 100) lcolor(gs8)) ///
					///
					(rarea se_high_1 se_low_1 inc_p if inlist(spec, "`spec'", "") & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(black%30) lcolor(black%0)) ///
					(connected b inc_p if inlist(spec, "`spec'", "") & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
					(connected b inc_p if inlist(spec, "`spec'", "") & inc_p == 0 & source == "data", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
					(rcap se_high_1 se_low_1 inc_p if inlist(spec, "`spec'", "") & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
					///
					(rarea se_high_1 se_low_1 inc_p if inlist(spec, "`spec'", "") & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "model", fcolor(magenta%30) lcolor(magenta%0)) ///
					(connected b inc_p if inlist(spec, "`spec'", "") & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "model", lcolor(magenta) mcolor(magenta) msymbol(X) msize(large) lpattern(_) lwidth(thick)) ///
					(connected b inc_p if inlist(spec, "`spec'", "") & inc_p == 0 & source == "model", lcolor(magenta) mcolor(magenta) msymbol(X) msize(large) lpattern(_) lwidth(thick)) ///
					(rcap se_high_1 se_low_1 inc_p if inlist(spec, "`spec'", "") & inc_p == 0 & source == "model", lcolor(magenta) mcolor(magenta) lpattern(_) lwidth(thick)) ///
					///
					, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(`y_scale', grid gstyle(dot) gmin gmax format(%2.1f)) ///
					xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
					legend(order(3 "Data" 7 "Model") region(color(none)) cols(2) ring(0) position(`legend_pos')) ///
					plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
					name(`spec'_p`p_base'_se1, replace)
				graph export "${DIR_RESULTS}/${section}/comp_`spec'_p`p_base'_se1_${year_min}_${year_max}.pdf", replace
			}
		}
		
		* comparison to Haanwinckel in new paper (December 2021)
		if `years' == 1 & $akm == 0 {
			
			* load data
			foreach sel of global sel_list {
				use "${DIR_TEMP}/RAIS/lee_reg_`sel'_data_p`p_base'_${year_min}_${year_max}.dta", clear
				if "`sel'" != "state" keep if inlist(spec, "`sel'_trend_1", "`sel'_trend_2", "`sel'_trend_3")
				save "${DIR_TEMP}/RAIS/temp_`sel'.dta", replace
			}
			clear
			foreach sel of global sel_list {
				qui append using "${DIR_TEMP}/RAIS/temp_`sel'.dta"
				rm "${DIR_TEMP}/RAIS/temp_`sel'.dta"
			}
			gen str5 source = "base"
			
			if $year_min <= 1996 & $year_max >= 2013 {
				qui append using "${DIR_TEMP}/RAIS/lee_reg_state_data_p`p_base'_${year_min}_${year_max}_h.dta"
				replace source = "haanw" if source == ""
				qui append using "${DIR_TEMP}/RAIS/lee_reg_meso_data_p`p_base'_${year_min}_${year_max}_h.dta"
				keep if source != "" | inlist(spec, "meso_trend_1", "meso_trend_2", "meso_trend_3")
				replace source = "haanw" if source == ""
			}
			
			cap confirm file "${DIR_TEMP}/RAIS/lee_reg_state_data_p`p_base'_1985_2018.dta"
			if !_rc & ($year_min != 1985 | $year_max != 2018) {
				qui append using "${DIR_TEMP}/RAIS/lee_reg_state_data_p`p_base'_1985_2018.dta"
				replace source = "full" if source == ""
				cap confirm file "${DIR_TEMP}/RAIS/lee_reg_state_data_p`p_base'_1985_2018.dta"
				if !_rc {
					qui append using "${DIR_TEMP}/RAIS/lee_reg_meso_data_p`p_base'_1985_2018.dta"
					keep if source != "" | inlist(spec, "meso_trend_1", "meso_trend_2", "meso_trend_3")
					replace source = "full" if source == ""
				}
			}
			
			* generate appropriate standard error bands
			gen float se_low_1 = b - ${crit_val}*se_1
			label var se_low_1 "Lower bound of regular standard error band"
			gen float se_high_1 = b + ${crit_val}*se_1
			label var se_high_1 "Upper bound of regular standard error band"
			gen float se_low_2 = b - ${crit_val}*se_2
			label var se_low_2 "Lower bound of clustered standard error band"
			gen float se_high_2 = b + ${crit_val}*se_2
			label var se_high_2 "Upper bound of clustered standard error band"
			
			* mark significance
			gen byte signif = 0
			replace signif = 1 if (sign(se_low_2) == sign(se_high_2)) & se_low_2 < . & se_high_2 < . & se_low_2 != 0 & se_high_2 != 0
			
			* prepare graphs
			sort inc_p
			
			* plot graphs
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_1 se_low_1 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.4(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline years (${year_min}-${year_max})" 7 "Haanwinckel years (1996-2001, 2005-2009, 2011-2013)" 11 "All years (1985-2018)") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(h_baseline_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/haanwinckel_baseline_p`p_base'_${year_min}_${year_max}.pdf", replace
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.4(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline years (${year_min}-${year_max})" 7 "Haanwinckel years (1996-2001, 2005-2009, 2011-2013)" 11 "All years (1985-2018)") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(h_s_trend_1_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/haanwinckel_state_trend_1_p`p_base'_${year_min}_${year_max}.pdf", replace
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_2" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_2" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_2" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_2" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_2" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_2" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-0.4(.2)0.8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline years (${year_min}-${year_max})" 7 "Haanwinckel years (1996-2001, 2005-2009, 2011-2013)" 11 "All years (1985-2018)") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(h_s_trend_2_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/haanwinckel_state_trend_2_p`p_base'_${year_min}_${year_max}.pdf", replace
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_3" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_3" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_3" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_3" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_3" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_3" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-0.4(.2)1.0, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline years (${year_min}-${year_max})" 7 "Haanwinckel years (1996-2001, 2005-2009, 2011-2013)" 11 "All years (1985-2018)") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(h_s_trend_3_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/haanwinckel_state_trend_3_p`p_base'_${year_min}_${year_max}.pdf", replace

			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-0.4(.2)1.0, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline years (${year_min}-${year_max})" 7 "Haanwinckel years (1996-2001, 2005-2009, 2011-2013)" 11 "All years (1985-2018)") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(h_s_trend_1_ntrend_2_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/haanwinckel_state_trend_1_ntrend_2_p`p_base'_${year_min}_${year_max}.pdf", replace
			prog_lee_signif "state_trend_1_ntrend_2"  `p_base'
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2_iv" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2_iv" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2_iv" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2_iv" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_1_ntrend_2_iv" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_1_ntrend_2_iv" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-0.4(.2)0.8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline years (${year_min}-${year_max})" 7 "Haanwinckel years (1996-2001, 2005-2009, 2011-2013)" 11 "All years (1985-2018)") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(h_s_trend_1_ntrend_2_iv_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/haanwinckel_state_trend_1_ntrend_2_iv_p`p_base'_${year_min}_${year_max}.pdf", replace
			prog_lee_signif "state_trend_1_ntrend_2_iv" `p_base'
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_diff" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_diff" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_diff" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_diff" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_diff" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_diff" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-2.0(1)4.0, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline years (${year_min}-${year_max})" 7 "Haanwinckel years (1996-2001, 2005-2009, 2011-2013)" 11 "All years (1985-2018)") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(h_s_t_0_nt_1_diff_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/haanwinckel_state_trend_0_ntrend_1_diff_p`p_base'_${year_min}_${year_max}.pdf", replace
			prog_lee_signif "state_trend_0_ntrend_1_diff" `p_base'
			
			tw ///
				(function y = 0, range(0 100) lcolor(gs8)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", fcolor(black%30) lcolor(black%0)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "base", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) msymbol(O) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inc_p == 0 & source == "base", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", fcolor(blue%30) lcolor(blue%0)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "haanw", lcolor(blue) mcolor(blue) msymbol(D) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) msymbol(D) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inc_p == 0 & source == "haanw", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
				///
				(rarea se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", fcolor(red%30) lcolor(red%0)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "full", lcolor(red) mcolor(red) msymbol(T) lpattern(l) lwidth(thick)) ///
				(connected b inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) msymbol(T) lwidth(thick)) ///
				(rcap se_high_2 se_low_2 inc_p if spec == "state_trend_0_ntrend_1_iv_diff" & inc_p == 0 & source == "full", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
				///
				, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-2.0(1)4.0, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("Earnings percentile") ytitle("Marginal effect of minimum wage") ///
				legend(order(3 "Baseline years (${year_min}-${year_max})" 7 "Haanwinckel years (1996-2001, 2005-2009, 2011-2013)" 11 "All years (1985-2018)") region(color(none)) cols(1) symxsize(*.66) ring(0) position(`legend_pos')) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
				name(h_s_t_0_nt_1_iv_diff_p`p_base', replace)
			graph export "${DIR_RESULTS}/${section}/haanwinckel_state_trend_0_ntrend_1_iv_diff_p`p_base'_${year_min}_${year_max}.pdf", replace
			prog_lee_signif "state_trend_0_ntrend_1_iv_diff" `p_base'
		}
		
// 		* loop over units of analysis (state, mesoregion, etc.)
// 		foreach sel of global sel_list {
		
// 			* loop over various standard error types
// 			if "`sel'" == "state" local se_n_list = "1 2"
// 			else local se_n_list = "2"
// 			foreach se_n of local se_n_list {
				
// 				* load joint data-model dataset
// 				use "${DIR_TEMP}/RAIS/lee_reg_merged_p`p_base'_${year_min}_${year_max}`years_ext'.dta", clear
				
// 				* generate appropriate standard error bands
// 				gen float se_low = b - ${crit_val}*se_`se_n'
// 				label var se_low "Lower bound of standard error band"
// 				gen float se_high = b + ${crit_val}*se_`se_n'
// 				label var se_high "Upper bound of standard error band"
				
// 				* prepare plots of different data specifications
// 				if $akm == 0 {
// 					local xtitle_str = "Earnings"
// 					local name_str = ""
// 				}
// 				else if $akm == 1 {
// 					local xtitle_str = "AKM person FE"
// 					local name_str = "_pe"
// 				}
// 				else if $akm == 2 {
// 					local xtitle_str = "AKM firm FE"
// 					local name_str = "_fe"
// 				}
// 				sort inc_p
// 				local sel_proper = proper("`sel'")
				
// 				* replicate specifications from old paper (March 2021)
// 				tw ///
// 					(function y = 0, range(0 100) lcolor(gs8)) ///
// 					///
// 					(rarea se_high se_low inc_p if spec == "year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(blue%30) lcolor(blue%0)) ///
// 					(connected b inc_p if spec == "year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(blue) mcolor(blue) msymbol(O) lpattern(l) lwidth(thick)) ///
// 					(connected b inc_p if spec == "year" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) msymbol(O) lwidth(thick)) ///
// 					(rcap se_high se_low inc_p if spec == "year" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
// 					///
// 					(rarea se_high se_low inc_p if spec == "`sel'" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(red%30) lcolor(red%0)) ///
// 					(connected b inc_p if spec == "`sel'" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(red) mcolor(red) msymbol(D) lpattern(l) lwidth(thick)) ///
// 					(connected b inc_p if spec == "`sel'" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) msymbol(D) lwidth(thick)) ///
// 					(rcap se_high se_low inc_p if spec == "`sel'" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
// 					///
// 					(rarea se_high se_low inc_p if spec == "`sel'_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(green%30) lcolor(green%0)) ///
// 					(connected b inc_p if spec == "`sel'_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(green) mcolor(green) msymbol(T) lpattern(l) lwidth(thick)) ///
// 					(connected b inc_p if spec == "`sel'_trend_2" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) msymbol(T) lwidth(thick)) ///
// 					(rcap se_high se_low inc_p if spec == "`sel'_trend_2" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) lwidth(thick)) ///
// 					///
// 					(rarea se_high se_low inc_p if spec == "`sel'_trend_2_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(orange%30) lcolor(orange%0)) ///
// 					(connected b inc_p if spec == "`sel'_trend_2_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(orange) mcolor(orange) msymbol(S) lpattern(l) lwidth(thick)) ///
// 					(connected b inc_p if spec == "`sel'_trend_2_iv" & inc_p == 0 & source == "data", lcolor(orange) mcolor(orange) lpattern(l) msymbol(S) lwidth(thick)) ///
// 					(rcap se_high se_low inc_p if spec == "`sel'_trend_2_iv" & inc_p == 0 & source == "data", lcolor(orange) mcolor(orange) lpattern(l) lwidth(thick)) ///
// 					///
// 					, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.6(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
// 					xtitle("`xtitle_str' percentile") ytitle("Marginal effect of minimum wage") ///
// 					legend(order(3 "Year FEs (OLS)" 7 "`sel_proper' FEs (OLS)" 11 "`sel_proper' FEs + trends (OLS)" 15 "`sel_proper' FEs + trends (IV)") region(color(none)) cols(2) symxsize(*.66) ring(0) position(`legend_pos')) ///
// 					plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 					name(replic_`sel'`p_base'`name_str'`se_n'`years_ext', replace)
// 				graph export "${DIR_RESULTS}/${section}/replic_`sel'`name_str'_p`p_base'_se`se_n'_${year_min}_${year_max}`years_ext'.pdf", replace
				
// 				* main specifications: `sel' FEs vs. year FEs vs. `sel' FEs + year FEs vs. `sel' FEs + `sel'-specific trends
// 				tw ///
// 					(function y = 0, range(0 100) lcolor(gs8)) ///
// 					///
// 					(rarea se_high se_low inc_p if spec == "`sel'" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(blue%30) lcolor(blue%0)) ///
// 					(connected b inc_p if spec == "`sel'" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(blue) mcolor(blue) msymbol(O) lpattern(l) lwidth(thick)) ///
// 					(connected b inc_p if spec == "`sel'" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) msymbol(O) lwidth(thick)) ///
// 					(rcap se_high se_low inc_p if spec == "`sel'" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
// 					///
// 					(rarea se_high se_low inc_p if spec == "year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(red%30) lcolor(red%0)) ///
// 					(connected b inc_p if spec == "year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(red) mcolor(red) msymbol(D) lpattern(l) lwidth(thick)) ///
// 					(connected b inc_p if spec == "year" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) msymbol(D) lwidth(thick)) ///
// 					(rcap se_high se_low inc_p if spec == "year" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
// 					///
// 					(rarea se_high se_low inc_p if spec == "`sel'_year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(green%30) lcolor(green%0)) ///
// 					(connected b inc_p if spec == "`sel'_year" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(green) mcolor(green) msymbol(T) lpattern(l) lwidth(thick)) ///
// 					(connected b inc_p if spec == "`sel'_year" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) msymbol(T) lwidth(thick)) ///
// 					(rcap se_high se_low inc_p if spec == "`sel'_year" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) lwidth(thick)) ///
// 					///
// 					(rarea se_high se_low inc_p if spec == "`sel'_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(orange%30) lcolor(orange%0)) ///
// 					(connected b inc_p if spec == "`sel'_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(orange) mcolor(orange) msymbol(S) lpattern(l) lwidth(thick)) ///
// 					(connected b inc_p if spec == "`sel'_trend_1" & inc_p == 0 & source == "data", lcolor(orange) mcolor(orange) lpattern(l) msymbol(S) lwidth(thick)) ///
// 					(rcap se_high se_low inc_p if spec == "`sel'_trend_1" & inc_p == 0 & source == "data", lcolor(orange) mcolor(orange) lpattern(l) lwidth(thick)) ///
// 					///
// 					, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.6(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
// 					xtitle("`xtitle_str' percentile") ytitle("Marginal effect of minimum wage") ///
// 					legend(order(3 "`sel_proper' FEs (OLS)" 7 "Year FEs (OLS)" 11 "`sel_proper' FEs + year FEs (OLS)" 15 "`sel_proper' FEs + trends (OLS)") region(color(none)) cols(2) symxsize(*.66) ring(0) position(`legend_pos')) ///
// 					plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 					name(main_`sel'`p_base'`name_str'`se_n'`years_ext', replace)
// 				graph export "${DIR_RESULTS}/${section}/main_`sel'`name_str'_p`p_base'_se`se_n'_${year_min}_${year_max}`years_ext'.pdf", replace
				
// 				if "`sel'" == "state" & $akm == 0 & inlist(`years', 0, 1) {
					
// 					* differences specifications
// 					tw ///
// 						(function y = 0, range(0 100) lcolor(gs8)) ///
// 						///
// 						(rarea se_high se_low inc_p if spec == "`sel'_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(blue%30) lcolor(blue%0)) ///
// 						(connected b inc_p if spec == "`sel'_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(blue) mcolor(blue) msymbol(O) lpattern(l) lwidth(thick)) ///
// 						(connected b inc_p if spec == "`sel'_diff" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) msymbol(O) lwidth(thick)) ///
// 						(rcap se_high se_low inc_p if spec == "`sel'_diff" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
// 						///
// 						(rarea se_high se_low inc_p if spec == "year_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(red%30) lcolor(red%0)) ///
// 						(connected b inc_p if spec == "year_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(red) mcolor(red) msymbol(D) lpattern(l) lwidth(thick)) ///
// 						(connected b inc_p if spec == "year_diff" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) msymbol(D) lwidth(thick)) ///
// 						(rcap se_high se_low inc_p if spec == "year_diff" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
// 						///
// 						(rarea se_high se_low inc_p if spec == "`sel'_year_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(green%30) lcolor(green%0)) ///
// 						(connected b inc_p if spec == "`sel'_year_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(green) mcolor(green) msymbol(T) lpattern(l) lwidth(thick)) ///
// 						(connected b inc_p if spec == "`sel'_year_diff" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) msymbol(T) lwidth(thick)) ///
// 						(rcap se_high se_low inc_p if spec == "`sel'_year_diff" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) lwidth(thick)) ///
// 						///
// 						(rarea se_high se_low inc_p if spec == "`sel'_trend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(orange%30) lcolor(orange%0)) ///
// 						(connected b inc_p if spec == "`sel'_trend_1_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(orange) mcolor(orange) msymbol(S) lpattern(l) lwidth(thick)) ///
// 						(connected b inc_p if spec == "`sel'_trend_1_diff" & inc_p == 0 & source == "data", lcolor(orange) mcolor(orange) lpattern(l) msymbol(S) lwidth(thick)) ///
// 						(rcap se_high se_low inc_p if spec == "`sel'_trend_1_diff" & inc_p == 0 & source == "data", lcolor(orange) mcolor(orange) lpattern(l) lwidth(thick)) ///
// 						///
// 						, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.6(.2).8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
// 						xtitle("`xtitle_str' percentile") ytitle("Marginal effect of minimum wage") ///
// 						legend(order(3 "`sel_proper' FEs (OLS, differences)" 7 "Year FEs (OLS, differences)" 11 "`sel_proper' FEs + year FEs (OLS, differences)" 15 "`sel_proper' FEs + trends (OLS, differences)") region(color(none)) cols(2) symxsize(*.66) ring(0) position(`legend_pos')) ///
// 						plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 						name(diff_`sel'`p_base'`name_str'`se_n'`years_ext', replace)
// 					graph export "${DIR_RESULTS}/${section}/diff_`sel'`name_str'_p`p_base'_se`se_n'_${year_min}_${year_max}`years_ext'.pdf", replace
					
// 					* IV specifications
// 					tw ///
// 						(function y = 0, range(0 100) lcolor(gs8)) ///
// 						///
// 						(rarea se_high se_low inc_p if spec == "`sel'_trend_1_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(blue%30) lcolor(blue%0)) ///
// 						(connected b inc_p if spec == "`sel'_trend_1_iv" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(blue) mcolor(blue) msymbol(O) lpattern(l) lwidth(thick)) ///
// 						(connected b inc_p if spec == "`sel'_trend_1_iv" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) msymbol(O) lwidth(thick)) ///
// 						(rcap se_high se_low inc_p if spec == "`sel'_trend_1_iv" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
// 						///
// 						(rarea se_high se_low inc_p if spec == "`sel'_trend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(red%30) lcolor(red%0)) ///
// 						(connected b inc_p if spec == "`sel'_trend_1_iv_diff" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(red) mcolor(red) msymbol(D) lpattern(l) lwidth(thick)) ///
// 						(connected b inc_p if spec == "`sel'_trend_1_iv_diff" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) msymbol(D) lpattern(l) lwidth(thick)) ///
// 						(rcap se_high se_low inc_p if spec == "`sel'_trend_1_iv_diff" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
// 						///
// 						, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-1.5(.5)3, grid gstyle(dot) gmin gmax format(%3.1f)) ///
// 						xtitle("`xtitle_str' percentile") ytitle("Marginal effect of minimum wage") ///
// 						legend(order(3 "State FEs + trends (IV, levels)" 7 "State FEs + trends (IV, differences)") region(color(none)) cols(2) symxsize(*.5) ring(0) position(`legend_pos')) ///
// 						plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 						name(iv_`sel'`p_base'`name_str'`se_n'`years_ext', replace)
// 					graph export "${DIR_RESULTS}/${section}/iv_`sel'`name_str'_p`p_base'_se`se_n'_${year_min}_${year_max}`years_ext'.pdf", replace
					
// 					* specifications with different trends
// 					tw ///
// 						(function y = 0, range(0 100) lcolor(gs8)) ///
// 						///
// 						(rarea se_high se_low inc_p if spec == "`sel'_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(blue%30) lcolor(blue%0)) ///
// 						(connected b inc_p if spec == "`sel'_trend_1" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(blue) mcolor(blue) msymbol(O) lpattern(l) lwidth(thick)) ///
// 						(connected b inc_p if spec == "`sel'_trend_1" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) msymbol(O) lpattern(l) lwidth(thick)) ///
// 						(rcap se_high se_low inc_p if spec == "`sel'_trend_1" & inc_p == 0 & source == "data", lcolor(blue) mcolor(blue) lpattern(l) lwidth(thick)) ///
// 						///
// 						(rarea se_high se_low inc_p if spec == "`sel'_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(red%30) lcolor(red%0)) ///
// 						(connected b inc_p if spec == "`sel'_trend_2" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(red) mcolor(red) msymbol(D) lpattern(l) lwidth(thick)) ///
// 						(connected b inc_p if spec == "`sel'_trend_2" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) msymbol(D) lpattern(l) lwidth(thick)) ///
// 						(rcap se_high se_low inc_p if spec == "`sel'_trend_2" & inc_p == 0 & source == "data", lcolor(red) mcolor(red) lpattern(l) lwidth(thick)) ///
// 						///
// 						(rarea se_high se_low inc_p if spec == "`sel'_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(green%30) lcolor(green%0)) ///
// 						(connected b inc_p if spec == "`sel'_trend_3" & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(green) mcolor(green) msymbol(T) lpattern(l) lwidth(thick)) ///
// 						(connected b inc_p if spec == "`sel'_trend_3" & inc_p == 0 & source == "data", lcolor(green) mcolor(green)  msymbol(T) lpattern(l) lwidth(thick)) ///
// 						(rcap se_high se_low inc_p if spec == "`sel'_trend_3" & inc_p == 0 & source == "data", lcolor(green) mcolor(green) lpattern(l) lwidth(thick)) ///
// 						///
// 						, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(-.6(.2).8, grid gstyle(dot) gmin gmax format(%3.1f)) ///
// 						xtitle("`xtitle_str' percentile") ytitle("Marginal effect of minimum wage") ///
// 						legend(order(3 "`sel_proper' FEs + linear trends (OLS, levels)" 7 "`sel_proper' FEs + quadratic trends (OLS, levels)" 11 "`sel_proper' FEs + cubic trends (OLS, levels)") region(color(none)) cols(1) symxsize(*.5) ring(0) position(`legend_pos')) ///
// 						plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 						name(trend_`sel'`p_base'`name_str'`se_n'`years_ext', replace)
// 					graph export "${DIR_RESULTS}/${section}/trend_`sel'`name_str'_p`p_base'_se`se_n'_${year_min}_${year_max}`years_ext'.pdf", replace
// 				}
				
// 				* comparisons of data vs. model
// 				if "`sel'" == "state" & $akm == 0 & inlist(`years', 0, 1) {
// 					sort inc_p
// 					foreach spec of global spec_list { // focus on: year state state_trend_2 state_trend_2_iv state_trend_2_diff state_trend_2_iv_diff ?
// 						if inlist("`spec'", "year", "state", "state_trend_1", "state_trend_2", "state_trend_3", "state_trend_1_iv", "state_trend_2_iv", "state_trend_3_iv") local y_scale = "-.4(.2).8"
// 						else if inlist("`spec'", "state_trend_1_diff", "state_trend_2_diff", "state_trend_3_diff") local y_scale = "-1.5(.5)3"
// 						else if inlist("`spec'", "state_trend_1_iv_diff", "state_trend_2_iv_diff", "state_trend_3_iv_diff") local y_scale = "-1.5(.5)3"
// 						tw ///
// 							(function y = 0, range(0 100) lcolor(gs8)) ///
// 							///
// 							(rarea se_high se_low inc_p if inlist(spec, "`spec'", "") & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", fcolor(black%30) lcolor(black%0)) ///
// 							(connected b inc_p if inlist(spec, "`spec'", "") & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "data", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
// 							(connected b inc_p if inlist(spec, "`spec'", "") & inc_p == 0 & source == "data", lcolor(black) mcolor(black) msymbol(O) lpattern(l) lwidth(thick)) ///
// 							(rcap se_high se_low inc_p if inlist(spec, "`spec'", "") & inc_p == 0 & source == "data", lcolor(black) mcolor(black) lpattern(l) lwidth(thick)) ///
// 							///
// 							(rarea se_high se_low inc_p if inlist(spec, "`spec'", "") & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "model", fcolor(magenta%30) lcolor(magenta%0)) ///
// 							(connected b inc_p if inlist(spec, "`spec'", "") & inrange(inc_p, ${p_min}, ${p_max}) & inlist(mod(inc_p, 10), 0, 5) & source == "model", lcolor(magenta) mcolor(magenta) msymbol(D) lpattern(_) lwidth(thick)) ///
// 							(connected b inc_p if inlist(spec, "`spec'", "") & inc_p == 0 & source == "model", lcolor(magenta) mcolor(magenta) msymbol(D) lpattern(_) lwidth(thick)) ///
// 							(rcap se_high se_low inc_p if inlist(spec, "`spec'", "") & inc_p == 0 & source == "model", lcolor(magenta) mcolor(magenta) lpattern(_) lwidth(thick)) ///
// 							///
// 							, xlabel(0 "St.d." 10 "10" 20 "20" 30 "30" 40 "40" 50 "50" 60 "60" 70 "70" 80 "80" 90 "90" 100 "100", grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(`y_scale', grid gstyle(dot) gmin gmax format(%2.1f)) ///
// 							xtitle("`xtitle_str' percentile") ytitle("Marginal effect of minimum wage") ///
// 							legend(order(3 "Data" 7 "Model") region(color(none)) cols(2) ring(0) position(`legend_pos')) ///
// 							plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 							name(`spec'`p_base'`name_str'`se_n'`years_ext', replace)
// 						graph export "${DIR_RESULTS}/${section}/comp_`spec'`name_str'_p`p_base'_se`se_n'_${year_min}_${year_max}`years_ext'.pdf", replace
// 					}
// 				}
// 			}
// 		}
	}
}
