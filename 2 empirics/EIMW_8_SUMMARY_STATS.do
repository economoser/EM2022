********************************************************************************
* DESCRIPTION: Computes summary statistics.
*
* NOTE:        Potentially need to edit years that are hard-coded in!
********************************************************************************


*** sample sizes and basic summary statistics
* open postfile
postfile summary_stats ///
	year inc_mean_m inc_mean_f mw_share_m mw_share_f inc_mean_primeage inc_mean_notprimeage mw_share_primeage mw_share_notprimeage N N_unique N_unique_male N_unique_male_prime N_final ///
	using "${DIR_RESULTS}/${section}/summary_stats.dta", replace

* loop over years
foreach y in $year_est_default_mid $year_sim_default_max {
	disp _newline(3)
	disp as text "* year `y'"
	
	* load data
	qui use year persid gender age edu empid_est earn_mean_mw hours_year hire_month sep_month using "${DIR_WRITE}/`y'/${sample_prefix}clean`y'.dta", clear
	
	* count total number of jobs
	qui count
	local N = r(N)
	local N_disp: di %12.0fc r(N)
	
	* count number of unique workers
	qui replace earn_mean_mw = . if earn_mean_mw <= 0 // Note: keep unique observation with nonzero and nonmissing earnings, if one exists (part 1)
	qui bys persid (earn_mean_mw): keep if _n == 1 // Note: keep unique observation with nonzero and nonmissing earnings, if one exists (part 2)
	drop persid
	qui count
	local N_unique = r(N)
	local N_unique_disp: di %12.0fc r(N)
	
	* summarize log earnings and share earning MW by gender
	qui gen float earn_mean_mw_ln = ln(earn_mean_mw)
	label var earn_mean_mw_ln "Log mean monthly earnings (log multiples of MW)"
	disp "   subgroup comparisons:"
	forval g = 1/2 {
		sum earn_mean_mw_ln if gender == `g', meanonly
		local inc_mean_g`g': di %4.3f r(mean)
		local N_subgroup = r(N)
		qui count if earn_mean_mw == 1
		local N_subgroup_mw = r(N)
		local mw_share_g`g': di %3.1f 100*`N_subgroup_mw'/`N_subgroup'
		disp "   --> gender `g' (1 = men, 2 = women): mean log earnings = `inc_mean_g`g'', MW share = `mw_share_g`g''%"
	}
	
	* count number of unique male workers
	qui keep if gender == 1
	drop gender
	qui count
	local N_unique_male = r(N)
	local N_unique_male_disp: di %12.0fc r(N)
	
	* summarize log earnings and share earning MW by age group
	forval a = 1/2 {
		if `a' == 1 sum earn_mean_mw_ln if inrange(age, ${age_min}, ${age_max}), meanonly
		else if `a' == 2 sum earn_mean_mw_ln if !inrange(age, ${age_min}, ${age_max}), meanonly
		local inc_mean_a`a': di %4.3f r(mean)
		local N_subgroup = r(N)
		qui count if earn_mean_mw == 1
		local N_subgroup_mw = r(N)
		local mw_share_a`a': di %3.1f 100*`N_subgroup_mw'/`N_subgroup'
		disp "   --> age group `a' (1 = 18-54, 2 = <18 or >54): mean log earnings = `inc_mean_a`a'', MW share = `mw_share_a`a''%"
	}
	drop earn_mean_mw_ln
	
	* count number of unique male prime-age workers
	qui keep if inrange(age, ${age_min}, ${age_max})
	qui count
	local N_unique_male_prime = r(N)
	local N_unique_male_prime_disp: di %12.0fc r(N)
	
	* count number of workers satisfying selection criteria (i.e., final sample)
	qui keep if !inlist(., empid_est, earn_mean_mw, hours_year, hire_month, sep_month) & earn_mean_mw > 0
	drop empid_est hours_year
	qui count
	local N_final = r(N)
	local N_final_disp: di %12.0fc r(N)
	
	* compute basic summary statistics on age, education, and log earnings in final sample
	qui recode edu (1 = 0) (2 = 3) (3 = 5) (4 = 7.5) (5 = 9) (6 = 11) (7 = 12) (8 = 14) (9 = 16)
	qui merge m:1 year hire_month sep_month using "${DIR_MW_MONTHLY}", nogen keepusing(mw) keep(master match)
	qui merge m:1 year hire_month sep_month using "${DIR_CPI}", nogen keepusing(cpi) keep(master match using)
	sum cpi if year == ${year_sim_default_max} & hire_month == 12 & sep_month == 12, meanonly
	qui replace cpi = cpi/r(mean)
	drop hire_month sep_month
	qui keep if year < .
	qui gen float earn_mean_ln = ln(earn_mean_mw*mw/cpi)
	drop mw
	label var earn_mean_ln "Log mean monthly earnings (log real BRL, December ${year_sim_default_max})"
	
	foreach var of varlist age edu earn_mean_ln {
		qui sum `var'
		local `var'_mean: di %5.3f r(mean)
		local `var'_sd: di %5.3f r(sd)
	}
	drop age edu earn_mean_ln
	disp _newline(1)
	disp "   summary statistics:"
	foreach var in age edu earn_mean_ln {
		disp "   --> `var': mean = ``var'_mean', sd = ``var'_sd'"
	}
	
	* count number of workers also earning weakly above the MW
// 	qui keep if earn_mean_mw >= 1
// 	drop earn_mean_mw
// 	qui count
// 	local N_above_mw: di %12.0fc r(N)
	
	* print resulting sample sizes
	disp _newline(1)
	disp "   sample sizes:"
	disp "   --> total                     = `N_disp'"
	disp "   --> unique                    = `N_unique_disp'"
	disp "   --> unique + male             = `N_unique_male_disp'"
	disp "   --> unique + male + prime age = `N_unique_male_prime_disp'"
	disp "   --> final                     = `N_final_disp'"

	* post to postfile
	post summary_stats ///
		(`y') (`inc_mean_g1') (`inc_mean_g2') (`mw_share_g1') (`mw_share_g2') (`inc_mean_a1') (`inc_mean_a2') (`mw_share_a1') (`mw_share_a2') (`N') (`N_unique') (`N_unique_male') (`N_unique_male_prime') (`N_final')
}

* close postfile
postclose summary_stats

* format postfile
use "${DIR_RESULTS}/${section}/summary_stats.dta", clear
label var year "Year"
label var inc_mean_m "Mean log earnings among men"
label var inc_mean_f "Mean log earnings among women"
label var mw_share_m "Share of men earning MW"
label var mw_share_f "Share of women earning MW"
label var inc_mean_primeage "Mean log earnings among workers in prime age"
label var inc_mean_notprimeage "Mean log earnings among workers not in prime age"
label var mw_share_primeage "Share of workers in prime age earning MW"
label var mw_share_notprimeage "Share of workers not in prime age earning MW"
label var N "Total number of observations"
label var N_unique "Number of unique observations"
label var N_unique_male "Number of unique male observations"
label var N_unique_male_prime "Number of unique male prime-aged observations"
label var N_final "Final number of observations (unique male prime-aged and nonmissing key variables)"
foreach var of varlist N* {
	format %12.0fc `var'
}

* export
export delim using "${DIR_RESULTS}/${section}/summary_stats.csv", replace


*** graphs
* loop through years
foreach y in $year_min $year_max {

	* load data
	do "${DIR_DO}/FUN_LOAD.do" `y' `y' "persid gender age edu earn_mean_mw tenure"
	drop gender
	rename earn_mean_mw earn
	
	* basic sample selection
	foreach var of varlist * {
		keep if `var' < .
	}
	
	* recode education variable
	recode edu (1/3=1) (4/5=2) (6/7=3) (8/9=4), generate(edu_group) // 1 = "<= primary school", 2 = "middle school", 3 = "high school", 4 = ">= college"
	tab edu_group, generate(edu_group_)
	qui recode edu (1 = 0) (2 = 3) (3 = 5) (4 = 7.5) (5 = 9) (6 = 11) (7 = 12) (8 = 14) (9 = 16)
	
	* recode tenure variable
	replace tenure = tenure/12
	
	* generate income groups
	if "${gtools}" == "" xtile earn_q = earn, n(100)
	else gquantiles earn_q = earn, n(100) xtile
	
	* collapse to income groups
	${gtools}collapse (mean) earn edu edu_group_* age tenure, by(earn_q) fast
	
	* plot
	tw ///
		(connected earn edu age tenure earn_q, lcolor(blue red green orange) mcolor(blue red green orange) msymbol(O D T S) msize(medium medium medium medium) lwidth(medthick medthick medthick medthick) lpattern(solid longdash dash shortdash)) ///
		, title("") xtitle("Earnings percentiles, `y'") ytitle("Mean conditional on earnings percentile") ///
		xlabel(0(10)100, format(%3.0f) grid gstyle(dot) gmin gmax) ylabel(0(10)60, format(%2.0f) grid gstyle(dot) gmin gmax) ///
		legend(order(1 "Earnings (multiples of MW)" 2 "Education (years)" 3 "Age (years)" 4 "Tenure (years)") symxsize(*.66) region(color(none)) cols(2) ring(0) position(12)) ///
		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
		name(sumstats_demographics_`y', replace)
	graph export "${DIR_RESULTS}/${section}/sumstats_demographics_`y'.pdf", replace
	
	tw ///
		(connected edu_group_1 edu_group_2 edu_group_3 edu_group_4 earn_q, lcolor(blue red green orange) mcolor(blue red green orange) msymbol(Oh Dh Th Sh) msize(medium medium medium medium) lwidth(medthick medthick medthick medthick) lpattern(solid longdash dash shortdash)) ///
		, title("") xtitle("Earnings percentiles, `y'") ytitle("Mean conditional on earnings percentile") ///
		xlabel(0(10)100, format(%3.0f) grid gstyle(dot) gmin gmax) ylabel(0(.1).9, format(%2.1f) grid gstyle(dot) gmin gmax) ///
		legend(order(1 "<= Primary" 2 "Middle school" 3 "High school" 4 ">= College") symxsize(*.66) region(color(none)) cols(4) ring(0) position(12)) ///
		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
		name(sumstats_edu_`y', replace)
	graph export "${DIR_RESULTS}/${section}/sumstats_edu_`y'.pdf", replace
}
