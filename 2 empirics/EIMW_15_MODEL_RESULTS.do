********************************************************************************
* DESCRIPTION: Process model results.
********************************************************************************


*** compute productivity-adjusted minimum wage series
import excel using "${DIR_CONVERSION}/min_wage/prod_adjusted_real_minwage.xlsx", sheet("Brazil prod-adj minimum wage") cellrange(A12:b47) clear
rename A year
label var year "Year"
rename B mw_adj
label var mw_adj "Productivity-adjusted minimum wage"
prog_comp_desc_sum_save "${DIR_RESULTS}/${section}/mw_adj_estimation.dta"
export delim "${DIR_RESULTS}/${section}/mw_adj_estimation.out", nolabel replace


*** comparison of model CDFs in 1996 vs. 2012
* loop through years
foreach y in 1996 2012 {
	disp "year = `y'"
	
	* load
	XXX MUST CREATE THIS AUTOMATICALLY!!!
	import delim using "${DIR_TEMP}/RAIS/cdf_comparison.csv", delim(",") rowrange(2:) varnames(2) clear
	
	* rename variables
	rename x_`y' cdf
	label var cdf "CDF of log wages"
	rename y_`y' w_`y'
	label var w_`y' "Log wage in `y'"
	
	* winsorize wage distribution from below to adhere to minimum wage
	if `y' == 2012 {
// 		gen byte below_mw = -(w_2012 < .04)
// 		label var below_mw "Ind: falls below minimum wage"
		replace w_2012 = max(w_2012, .04)
	}
// 	if `y' == 2012 xxx
	
	* keep only relevant variables
	keep w_`y' cdf
	
	* set number of observations
	count if cdf < .
	local N = r(N)
	local N_new = `N' + 200
	set obs `N_new'
	
	* number new CDF grid points
	gen int cdf_num = _n - `N' if cdf == .
	label var cdf_num "Number of new CDF grid points"
	
	* generate common x-axis grid
	replace cdf = (_n - `N' - 1)/(_N - `N' - 1) if cdf == .
	
	* interpolate CDF values w.r.t. common x-axis grid
	ipolate w_`y' cdf, generate(w_`y'_interp)
	drop w_`y'
	rename w_`y'_interp w_`y'
	label var w_`y' "Log wage in `y' (interpolated)"
	
	* keep only relevant variables and observations
	keep w_`y' cdf cdf_num
	keep if cdf_num < .
	
	* save
	order w_`y' cdf cdf_num
	sort w_`y'
	tempfile y_`y'
	save "`y_`y''"
}

* merge log wages from both years
use `y_1996', clear
merge 1:1 cdf_num using "`y_2012'", keepusing(w_2012) keep(master match) nogen
drop cdf_num

* generate difference in log wage conditional on CDF
gen w_diff = w_2012 - w_1996
label var w_diff "Difference in log wage conditional on CDF of log wages"

* smooth out difference in log wages conditional on CDF
replace w_diff = max(w_diff, 0)
sort cdf
replace w_diff = min(w_diff[_n], w_diff[_n - 1])

* order and sort
order cdf w_1996 w_2012
sort cdf

* plot
tw ///
	(line cdf w_1996, sort lcolor(blue) lpattern(l) lwidth(thick)) ///
	(line cdf w_2012, sort lcolor(red) lpattern(_) lwidth(thick)) ///
	, xlabel(-.4(.4)3.6, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.1)1, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Log wage") ytitle("CDF") ///
	legend(order(1 "1996" 2 "2012") region(lcolor(white)) cols(2) ring(0) position(11)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(cdf, replace)
graph export "${DIR_RESULTS}/${section}/cdf.pdf", replace
tw ///
	(line w_1996 cdf, sort lcolor(blue) lpattern(l) lwidth(thick)) ///
	(line w_2012 cdf, sort lcolor(red) lpattern(_) lwidth(thick)) ///
	, xlabel(0(.1)1, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(-.4(.4)3.6, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("CDF") ytitle("Log wage") ///
	legend(order(1 "1996" 2 "2012") region(lcolor(white)) cols(2) ring(0) position(11)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(cdf_inv, replace)
graph export "${DIR_RESULTS}/${section}/inv_cdf.pdf", replace
tw ///
	(line w_diff cdf, sort lcolor(purple) lpattern(dash) lwidth(thick)) ///
	, xlabel(0(.1)1, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.05).45, grid gstyle(dot) gmin gmax format(%3.2f)) ///
	xtitle("CDF of log wages") ytitle("Difference in log wages due to the minimum wage") ///
	legend(order(1 "1996" 2 "2012") region(lcolor(white)) cols(2)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(w_diff, replace)
graph export "${DIR_RESULTS}/${section}/w_diff.pdf", replace


*** survival rates in RAIS vs. model-simulated data
* loop through years
foreach y1 in 1994 2010 0 {
	local y2 = `y1' + 4
	disp _newline(3)
	if `y1' != 0 {
		disp "* RAIS, `y1'-`y2':"
		local data_source = "RAIS"
	}
	else {
		disp "* model:"
		local data_source = "model-simulated data"
	}

	* load data
	if `y1' != 0 use persid empid_est year using "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta", clear
	else {
		import delim "${DIR_MODEL}/3 Version 10302020/2 Data/Model_microdata_connected.csv", delim(tab) clear // contains as variables: id empid year wage pe fe
		keep id empid year
		rename id persid
		rename empid empid_est
		destring empid_est, force replace
		keep if empid_est < .
	}
	
	* compute number of years that individuals are in `data_source'
	bys persid: gen byte N_persid_years = _N // Note: there is already only one individual-year per year by construction.
	bys persid: replace N_persid_years = . if _n > 1
	label var N_persid_years "Number of years that worker is in `data_source'"
	disp as result "   cumulative observation shares for persid:"
	disp as text "   --> share of years that workers are in `data_source':"
	tab N_persid_years
	drop N_persid_years
	
	* compute number of years that firms are in `data_source'
	bys empid_est year: gen byte ind_empid_est_year_unique = 1 if _n == 1
	if "${gtools}" == "" bys empid_est: egen byte N_empid_est_years = total(ind_empid_est_year_unique)
	else gegen byte N_empid_est_years = total(ind_empid_est_year_unique), by(empid_est)
	drop ind_empid_est_year_unique
	bys empid_est: replace N_empid_est_years = . if _n > 1
	label var N_empid_est_years "Number of years that firm is in `data_source'"
	disp as result "   cumulative observation shares for empid_est:"
	disp as text "   --> share of years that firms are in `data_source':"
	tab N_empid_est_years
	drop N_empid_est_years
	
	* keep only initial cohort
	if `y1' != 0 {
		local cohort_min = `y1'
		local cohort_max = `y2'
	}
	else {
		local cohort_min = 1
		local cohort_max = 5
	}
	foreach var of varlist persid empid_est {
		disp as result "   cohort survival rates for `var':"
		preserve
		if "`var'" == "empid_est" bys `var' year: keep if _n == 1 // Note: there is already only one individual-year per year by construction.
		bys `var' (year): keep if year[1] == `cohort_min'
		bys `var' (year): gen int `var'_year_last = year[_N]
		label var `var'_year_last "Last year that `var' appears in the data"
		count
		local N_cohort = r(N)
		forval y = 1/5 {
			count if `var'_year_last == `cohort_min' + `y' - 1
			local N_cohort_`y' = r(N)
			local share_cohort_`y': di %3.1f 100*`N_cohort_`y''/`N_cohort'
			disp as text "   --> share surviving for `y' year(s) = `share_cohort_`y''%"
		}
		restore
	}
}
