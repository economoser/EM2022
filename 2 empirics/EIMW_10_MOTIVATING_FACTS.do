********************************************************************************
* DESCRIPTION: Generate a set of motivating facts.
*
* NOTE:        Potentially need to edit years that are hard-coded in!
********************************************************************************


*** macros
* manually set macros
global p_base = 50 // base quantile for computing earnings quantile ratios
global ranking_method = 3 // 1 = Wikipedia GDP per capita in 2018, 2 = RAIS median log earnings in 1996, 3 = RAIS mean log earnings in 1996
global norm_operator = "/" // "-" = log-difference normalization for time series of richest vs. poorest states; "/" = log-ratio normalization for time series of richest vs. poorest states
global plot_step_size = 5

* automatically set macros
if ${year_est_default_mid} == 1996 & ${year_max} == 2012 {
	global y1 = 1996
	global y2 = 2000
	global y3 = 2004
	global y4 = 2008
	global y5 = 2012
}
else if ${year_est_default_mid} == 1985 & ${year_max} == 2018 {
	global y1 = 1985
	global y2 = 1994
	global y3 = 2002
	global y4 = 2010
	global y5 = 2018
}
else if ${year_est_default_mid} == 1996 & ${year_max} == 2018 {
	global y1 = 1996
	global y2 = 2001
	global y3 = 2007
	global y4 = 2013
	global y5 = 2018
}
else {
	disp as error "USER ERROR: Invalid global macros year_est_default_mid and year_max specified!"
	error 1
}

*** table: time series of lower-tail wage inequality in Brazil (to compare to U.S. estimates by Autor et al., 2016)
* load data
use "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_state.dta", clear

* generate lower-tail inequality
gen float inc_p10_p50 = inc_p10 - inc_p50
label var inc_p10_p50 "Log P10/P50 wage percentile ratio"

* compute mean lower-tail inequality by year
sum year, meanonly
local year_loop_min = min(r(min), 1979) // 1979 = first year of data reported in AMS (2016)
local year_loop_max = max(r(max), 2012) // 2012 = last year of data reported in AMS (2016)
local year_loop_N = `year_loop_max' - `year_loop_min' + 1
foreach y of numlist `year_loop_min'/`year_loop_max' {
	sum inc_p10_p50 if year == `y', meanonly
	local inc_p10_p50_mean_BRA_`y' = r(mean)
}

* create empty dataset with `year_loop_N' observations
clear
set obs `year_loop_N'

* generate year variable
gen int year = .
local count = 0
foreach y of numlist `year_loop_min'/`year_loop_max' {
	local ++count
	replace year = `y' in `count'
}
label var year "Year"

* input log earnings percentile ratios from Autor et al. (2016)
gen float inc_p10_p50_mean_USA = .
replace inc_p10_p50_mean_USA = -.64 if year == 1979
replace inc_p10_p50_mean_USA = -.65 if year == 1980
replace inc_p10_p50_mean_USA = -.68 if year == 1981
replace inc_p10_p50_mean_USA = -.71 if year == 1982
replace inc_p10_p50_mean_USA = -.73 if year == 1983
replace inc_p10_p50_mean_USA = -.73 if year == 1984
replace inc_p10_p50_mean_USA = -.74 if year == 1985
replace inc_p10_p50_mean_USA = -.74 if year == 1986
replace inc_p10_p50_mean_USA = -.73 if year == 1987
replace inc_p10_p50_mean_USA = -.72 if year == 1988
replace inc_p10_p50_mean_USA = -.72 if year == 1989
replace inc_p10_p50_mean_USA = -.72 if year == 1990
replace inc_p10_p50_mean_USA = -.71 if year == 1991
replace inc_p10_p50_mean_USA = -.72 if year == 1992
replace inc_p10_p50_mean_USA = -.73 if year == 1993
replace inc_p10_p50_mean_USA = -.71 if year == 1994
replace inc_p10_p50_mean_USA = -.71 if year == 1995
replace inc_p10_p50_mean_USA = -.71 if year == 1996
replace inc_p10_p50_mean_USA = -.69 if year == 1997
replace inc_p10_p50_mean_USA = -.69 if year == 1998
replace inc_p10_p50_mean_USA = -.69 if year == 1999
replace inc_p10_p50_mean_USA = -.68 if year == 2000
replace inc_p10_p50_mean_USA = -.68 if year == 2001
replace inc_p10_p50_mean_USA = -.69 if year == 2002
replace inc_p10_p50_mean_USA = -.69 if year == 2003
replace inc_p10_p50_mean_USA = -.70 if year == 2004
replace inc_p10_p50_mean_USA = -.71 if year == 2005
replace inc_p10_p50_mean_USA = -.70 if year == 2006
replace inc_p10_p50_mean_USA = -.70 if year == 2007
replace inc_p10_p50_mean_USA = -.71 if year == 2008
replace inc_p10_p50_mean_USA = -.74 if year == 2009
replace inc_p10_p50_mean_USA = -.73 if year == 2010
replace inc_p10_p50_mean_USA = -.72 if year == 2011
replace inc_p10_p50_mean_USA = -.74 if year == 2012
label var inc_p10_p50_mean_USA "Mean log P10/P50 wage pctl ratio in USA"

* export mini-dataset with mean lower-tail inequality by year
gen float inc_p10_p50_mean_BRA = .
label var inc_p10_p50_mean_BRA "Mean log P10/P50 wage pctl ratio in BRA"
local count = 0
foreach y of numlist `year_loop_min'/`year_loop_max' {
	local ++count
	replace inc_p10_p50_mean_BRA = `inc_p10_p50_mean_BRA_`y'' in `count'
}
format year %4.0f
format inc_p10_p50_mean_BRA inc_p10_p50_mean_USA %3.2f
order year inc_p10_p50_mean_BRA inc_p10_p50_mean_USA
export delim using "${DIR_RESULTS}/${section}/lower_tail_inequality.csv", replace

* plot of lower-tail inequality in BRA vs. USA
sum year, meanonly
local year_plot_min = floor(r(min)/${plot_step_size})*${plot_step_size}
local year_plot_max = ceil(r(max)/${plot_step_size})*${plot_step_size}
tw ///
	(connected inc_p10_p50_mean_BRA inc_p10_p50_mean_USA year, lcolor(blue red) mcolor(blue red) msymbol(O D) msize(medium medium) lwidth(medthick medthick) lpattern(solid longdash)) ///
	, title("") xtitle("") ytitle("Mean log P10/P50 wage percentile ratio") ///
	xlabel(`year_plot_min'(${plot_step_size})`year_plot_max', grid gstyle(dot) gmin gmax) ylabel(-1(.1)-.5, format(%2.1f) grid gstyle(dot) gmin gmax) ///
	legend(order(1 "Brazil" 2 "United States") region(color(none)) cols(2) ring(0) position(6)) ///
	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
	name(lower_tail_ineq_BRA_USA, replace)
graph export "${DIR_RESULTS}/${section}/lower_tail_ineq_BRA_USA.pdf", replace


*** figures: time series of nominal and real MW
* monthly plots of nominal MW
use if inrange(year, ${year_data_min}, ${year_data_max}) using "${DIR_TEMP}/IPEA/mw_monthly.dta", clear
sum year, meanonly
local year_plot_min = floor(r(min)/${plot_step_size})*${plot_step_size}
local year_plot_max = ceil(r(max)/${plot_step_size})*${plot_step_size}
tw ///
	(connected mw_nominal date_plot, lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Nominal minimum wage (current BRL)") ///
	xlabel(`year_plot_min'(${plot_step_size})`year_plot_max', grid gstyle(dot) gmin gmax) ylabel(0(200)1000, format(%4.0f) grid gstyle(dot) gmin gmax) ///
	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
	name(mw_nominal_monthly, replace)
graph export "${DIR_RESULTS}/${section}/mw_nominal_monthly.pdf", replace
tw ///
	(connected mw_real date_plot, lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Real minimum wage (constant September 2021 BRL)") ///
	xlabel(`year_plot_min'(${plot_step_size})`year_plot_max', grid gstyle(dot) gmin gmax) ylabel(0(200)1200, format(%4.0f) grid gstyle(dot) gmin gmax) ///
	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
	name(mw_real_monthly, replace)
graph export "${DIR_RESULTS}/${section}/mw_real_monthly.pdf", replace

* yearly plots of nominal MW
use if inrange(year, ${year_data_min}, ${year_data_max}) using "${DIR_TEMP}/IPEA/mw_yearly.dta", clear
tw ///
	(connected mw_nominal year, lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Nominal minimum wage (current BRL)") ///
	xlabel(`year_plot_min'(${plot_step_size})`year_plot_max', grid gstyle(dot) gmin gmax) ylabel(0(200)1000, format(%4.0f) grid gstyle(dot) gmin gmax) ///
	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
	name(mw_nominal_yearly, replace)
graph export "${DIR_RESULTS}/${section}/mw_nominal_yearly.pdf", replace
tw ///
	(connected mw_real year, lcolor(blue) mcolor(blue) msymbol(O) msize(vsmall) lwidth(medthick) lpattern(solid)) ///
	, title("") xtitle("") ytitle("Real minimum wage (constant September 2021 BRL)") ///
	xlabel(`year_plot_min'(${plot_step_size})`year_plot_max', grid gstyle(dot) gmin gmax) ylabel(0(200)1200, format(%4.0f) grid gstyle(dot) gmin gmax) ///
	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
	name(mw_real_yearly, replace)
graph export "${DIR_RESULTS}/${section}/mw_real_yearly.pdf", replace


*** figures: time series of std. dev., variance, and percentile ratios of log earnings vs. real minimum wage
* load data
use year inc_var inc_p10 inc_p50 inc_p90 using "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_overall.dta", clear

* compute variance of log earnings by year
gen float inc_sd = inc_var^.5
label var inc_sd "Std. dev. of log earnings (log multiples of MW)"

* compute log earnings percentile ratios
gen inc_p50_p10 = inc_p50 - inc_p10
label var inc_p50_p10 "Log P50/P10 earnings percentile ratio"
gen inc_p90_p50 = inc_p90 - inc_p50
label var inc_p90_p50 "Log P90/P50 earnings percentile ratio"

* compute normalized log earnings percentile ratios
foreach var of varlist inc_p50_p10 inc_p90_p50 {
	sum `var' if year == ${year_est_default_mid}, meanonly
	gen `var'_norm = `var' / r(mean)
}

* merge in data on real minimum wage
merge 1:1 year using "${DIR_TEMP}/IPEA/mw_real_yearly.dta", nogen keepusing(mw_real) keep(match)

* summarize rise
sum mw_real if year == $year_data_min, meanonly
local mw_data_min = r(mean)
sum mw_real if year == $year_min, meanonly
local mw_min = r(mean)
sum mw_real if year == $year_data_max, meanonly
local mw_data_max = r(mean)
local mw_year_data_min_year_data_max = `mw_data_max'/`mw_data_min' - 1
local mw_year_min_year_data_max = `mw_data_max'/`mw_min' - 1
disp "MW increase from $year_data_min-$year_data_max: `mw_year_data_min_year_data_max'"
disp "MW increase from $year_min-$year_data_max: `mw_year_min_year_data_max'"

* correlation
corr inc_sd mw_real
corr inc_sd mw_real if inrange(year, ${year_min}, ${year_max})
corr inc_var mw_real
corr inc_var mw_real if inrange(year, ${year_min}, ${year_max})

* plots
local y_min_plot = ${year_data_min} - mod(${year_data_min}, 5)
local y_max_plot = ${year_data_max} + 5 - mod(${year_data_max}, 5)
tw ///
	(connected inc_sd year, yaxis(1) lcolor(blue) mcolor(blue) msymbol(O) lpattern(l)) ///
	(connected mw_real year, yaxis(2) lcolor(red) mcolor(red) msymbol(D) lpattern(_)) ///
	, xlabel(`y_min_plot'(${plot_step_size})`y_max_plot', grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.65(.05).95, grid gstyle(dot) gmin gmax format(%3.2f) axis(1)) ylabel(350(150)1250, nogrid gmin gmax format(%4.0f) axis(2)) ///
	xtitle("") ytitle("Std. dev. of log earnings", axis(1)) ///
	legend(order(1 "Std. dev. of log earnings" 2 "Real minimum wage") region(color(none)) cols(2) ring(0) position(12)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(sd_mw_real, replace)
graph export "${DIR_RESULTS}/${section}/sd_mw_real.pdf", replace

tw ///
	(connected inc_sd year if inrange(year, ${year_min}, ${year_max}), yaxis(1) lcolor(blue) mcolor(blue) msymbol(O) lpattern(l)) ///
	(connected mw_real year if inrange(year, ${year_min}, ${year_max}), yaxis(2) lcolor(red) mcolor(red) msymbol(D) lpattern(_)) ///
	, xlabel(${year_min}(2)${year_max}, grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.65(.05).95, grid gstyle(dot) gmin gmax format(%3.2f) axis(1)) ylabel(350(150)1250, nogrid gmin gmax format(%4.0f) axis(2)) ///
	xtitle("") ytitle("Std. dev. of log earnings", axis(1)) ///
	legend(order(1 "Std. dev. of log earnings" 2 "Real minimum wage") region(color(none)) cols(2) ring(0) position(12)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(sd_mw_real_short, replace)
graph export "${DIR_RESULTS}/${section}/sd_mw_real_short.pdf", replace

// tw ///
// 	(connected inc_var year, yaxis(1) lcolor(blue) mcolor(blue) msymbol(O) lpattern(l)) ///
// 	(connected mw_real year, yaxis(2) lcolor(red) mcolor(red) msymbol(D) lpattern(_)) ///
// 	, xlabel(`y_min_plot'(${plot_step_size})`y_max_plot', grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.35(.1).85, grid gstyle(dot) gmin gmax format(%3.2f) axis(1)) ylabel(350(150)1100, nogrid gmin gmax format(%4.0f) axis(2)) ///
// 	xtitle("") ytitle("Variance of log earnings", axis(1)) ///
// 	legend(order(1 "Variance of log earnings" 2 "Real minimum wage") region(color(none)) cols(2)) ///
// 	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 	name(var, replace)
// graph export "${DIR_RESULTS}/${section}/var_mw_real.pdf", replace

tw ///
	(connected inc_p50_p10_norm inc_p90_p50_norm year if inrange(year, ${year_est_default_mid}, ${year_max}), lcolor(blue red) mcolor(blue red) msymbol(O T) lpattern(l _)) ///
	, xlabel(${year_est_default_mid}(2)${year_max}, grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.5(.1)1.1, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle(" ") ytitle("Log earnings percentile ratios (${year_est_default_mid} = 1.0)") ///
	legend(order(1 "P50/P10" 2 "P90/P50") region(color(none)) cols(2) ring(0) position(12)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(inc_p50_p10_inc_p90_p50_short, replace)
graph export "${DIR_RESULTS}/${section}/inc_p50_p10_inc_p90_p50_short.pdf", replace

tw ///
	(connected inc_p50_p10_norm inc_p90_p50_norm year, lcolor(blue red) mcolor(blue red) msymbol(O T) lpattern(l _)) ///
	, xlabel(`y_min_plot'(${plot_step_size})`y_max_plot', grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.5(.1)1.1, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("") ytitle("Log earnings percentile ratios (${year_est_default_mid} = 1.0)") ///
	legend(order(1 "P50/P10" 2 "P90/P50") region(color(none)) cols(2)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(inc_p50_p10_inc_p90_p50_nomw, replace)
graph export "${DIR_RESULTS}/${section}/inc_p50_p10_inc_p90_p50_nomw.pdf", replace

tw ///
	(connected inc_p50_p10_norm inc_p90_p50_norm year, yaxis(1) lcolor(blue%100 blue%35) mcolor(blue%100 blue%35) msymbol(O T) lpattern(l l)) ///
	(connected mw_real year, yaxis(2) lcolor(red) mcolor(red) msymbol(D) lpattern(_)) ///
	, xlabel(`y_min_plot'(${plot_step_size})`y_max_plot', grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.4(.15)1.15, grid gstyle(dot) gmin gmax format(%3.2f) axis(1)) ylabel(350(150)1100, nogrid gmin gmax format(%4.0f) axis(2)) ///
	xtitle("") ytitle("Log earnings percentile ratios (${year_est_default_mid} = 1.0)", axis(1)) ///
	legend(order(1 "P50/P10" 2 "P90/P50" 3 "Real minimum wage") region(color(none)) cols(3)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(inc_p50_p10_inc_p90_p50, replace)
graph export "${DIR_RESULTS}/${section}/inc_p50_p10_inc_p90_p50.pdf", replace


*** figures: share of workers with earning equal to, less than, or around the MW -- overall and by region/industry
foreach group in "" "state" "meso" { // "micro" "muni" "ind_5" "ind_2"
foreach group in "" "state" "meso" { // "micro" "muni" "ind_5" "ind_2"
	
	* load data
	use ///
		year `group' inc ///
		if inrange(year, ${year_est_default_mid}, ${year_max}) ///
		using "${DIR_TEMP}/RAIS/rais_inc_${year_data_min}_${year_data_max}${sample_ext}.dta", clear
	
	* generate indicator for earnings = MW
// 	gen byte mw_equal = inrange(inc, 0.9950, 1.0049)
	gen byte mw_equal = (inc == 1)
	
	* generate indicator for earnings <= MW
// 	gen byte mw_less = inc < 1.005
	gen byte mw_less = inc <= 1
	
	* generate indicator for earnings approx.= MW
// 	gen byte mw_approx = inrange(inc, 0.9450, 1.0549)
	gen byte mw_approx = inrange(inc, 0.95, 1.05)
	
	* compute share of MW jobs
	replace inc = ln(inc)
	${gtools}collapse ///
		(mean) share_mw_equal=mw_equal share_mw_less=mw_less share_mw_approx=mw_approx ///
		(p50) kaitz_p50=inc ///
		(count) N=inc ///
		, by(year `group') fast
	label var share_mw_equal "Share of jobs with earnings = MW"
	label var share_mw_less "Share of jobs with earnings <= MW"
	label var share_mw_approx "Share of jobs with earnings within 5% of MW"
	replace kaitz_p50 = -kaitz_p50
	label var kaitz_p50 "P50-Kaitz index, log(MW/P50)"
	label var N "Number of jobs"

	* prepare plots
	if "`group'" == "" local group_name = "all"
	else local group_name = "`group'"
	
	* plot share of jobs at, below, and around MW
	if "`group'" == "" {
		sum year, meanonly
		local year_plot_min = floor(r(min)/${plot_step_size})*${plot_step_size}
		local year_plot_max = ceil(r(max)/${plot_step_size})*${plot_step_size}
		tw /// time series evolution of share of jobs at / below / around MW
			(connected share_mw_equal share_mw_less share_mw_approx year if inrange(year, `year_plot_min', `year_plot_max'), lcolor(blue red green) mcolor(blue red green) msymbol(O D T) lpattern(l _ -)) ///
			, xlabel(${year_min}(2)${year_max}, grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(0(.02).10, grid gstyle(dot) gmin gmax format(%3.2f)) ///
			xtitle("") ytitle("Share of jobs", axis(1)) ///
			legend(order(1 "exactly at MW" 2 "at or below MW" 3 "within 5% of MW") region(color(none)) cols(3) ring(0) pos(12)) ///
			plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
			name(share_mw_all, replace)
		graph export "${DIR_RESULTS}/${section}/share_mw_all.pdf", replace
	}
	else {
		tw /// circle plot of share earning MW vs. P50-Kaitz index
			(scatter share_mw_equal kaitz_p50 [aw=N] if year == ${year_est_default_mid}, msymbol(Oh) mcolor(blue)) ///
			(scatter share_mw_equal kaitz_p50 [aw=N] if year == ${year_max}, msymbol(Oh) mcolor(red)) ///
			, xlabel(-1.8(.3)0, grid gstyle(dot) gmin gmax format(%3.1f) labsize(medium)) ylabel(, grid gstyle(dot) gmin gmax format(%3.2f) labsize(medium)) ///
			xtitle("P50-Kaitz index, log(MW/P50)") ytitle("Worker share with earnings exactly at MW", size(medium)) ///
			legend(order(1 "${year_est_default_mid}" 2 "${year_max}") region(color(none)) size(medium) cols(2) ring(0) pos(11)) ///
			plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
			name(share_mw_kaitz_p50_`group_name', replace)
		graph export "${DIR_RESULTS}/${section}/share_mw_kaitz_p50_`group_name'.pdf", replace
		tw /// histogram of municipality-/state-/industry-level share of MW jobs
			(hist share_mw_equal [fw=N] if inrange(share_mw_equal, 0, .12) & year == ${year_est_default_mid}, start(0) width(.0024) fcolor(blue%50) lcolor(blue%0)) ///
			(hist share_mw_equal [fw=N] if inrange(share_mw_equal, 0, .12) & year == ${year_max}, start(0) width(.0024) fcolor(red%50) lcolor(red%0)) ///
			, xlabel(0(.02).12, format(%3.2f) gmin gmax grid gstyle(dot)) ylabel(0(40)200, format(%3.0f) gmin gmax grid gstyle(dot)) ///
			xtitle("Share earning exactly MW") ytitle("Density") ///
			legend(order(1 "${year_est_default_mid}" 2 "${year_max}") region(color(none)) size(medium) cols(2) ring(0) pos(12)) ///
			plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
			name(hist_share_mw_`group_name', replace)
		graph export "${DIR_RESULTS}/${section}/hist_share_mw_`group_name'.pdf", replace
	}
}


*** figures: earnings histograms
forval y = $year_data_min/$year_data_max {
	disp "* year = `y'"
	
	* load
	use ///
		year inc state ///
		if year == `y' ///
		using "${DIR_TEMP}/RAIS/rais_inc_${year_data_min}_${year_data_max}${sample_ext}.dta", clear
	drop year
	
	* rename variables
	rename inc inc_lvl
	
	* generate log income
	gen float inc_ln = ln(inc_lvl)
	
	* produce counts
	qui count
	local N = r(N)
	qui count if inc_lvl == 1
	local N_mw = r(N)
	local share_mw = `N_mw'/`N'
	local share_mw_perc : di %3.1f 100*`share_mw'
	disp "--> share of workers earning MW = `share_mw_perc'%"
	
	* plot histogram of earnings
	tw ///
		(hist inc_lvl if inrange(inc_lvl, 0, 20), start(0) width(.2) fcolor(blue%50) lcolor(blue%0)) ///
		, xline(1, lwidth(thick) lpattern(_) lcolor(gs8)) ///
		xlabel(0(2)20, format(%3.0f) gmin gmax grid gstyle(dot)) ylabel(0(.1).8, format(%2.1f) gmin gmax grid gstyle(dot)) ///
		xtitle("Earnings (multiples of MW)") ytitle("Density") ///
		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
		name(hist_spike_`y', replace)
	graph export "${DIR_RESULTS}/${section}/hist_spike_`y'.pdf", replace
	
	* plot histogram of log earnings
	tw ///
		(hist inc_ln if inrange(inc_ln, -.5, 5), start(-.5) width(.1) fcolor(blue%50) lcolor(blue%0)) ///
		, xline(0, lwidth(thick) lpattern(_) lcolor(gs8)) ///
		xlabel(-.5(.5)5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.1)1, format(%3.1f) gmin gmax grid gstyle(dot)) ///
		xtitle("Earnings (log multiples of MW)") ytitle("Density") ///
		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
		name(hist_spike_ln_`y', replace)
	graph export "${DIR_RESULTS}/${section}/hist_spike_ln_`y'.pdf", replace
	
	* plot histogram of log earnings of poor state (Maranhao)
	tw ///
		(hist inc_ln if inrange(inc_ln, -.5, 5) & state == 8, start(-.5) width(.1) fcolor(blue%50) lcolor(blue%0)) ///
		, xline(0, lwidth(thick) lpattern(_) lcolor(gs8)) ///
		xlabel(-.5(.5)5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.3)2.1, format(%3.1f) gmin gmax grid gstyle(dot)) ///
		xtitle("Earnings (log multiples of MW)") ytitle("Density") ///
		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
		name(hist_spike_ln_`y'_state_poor, replace)
	graph export "${DIR_RESULTS}/${section}/hist_spike_ln_`y'_state_poor.pdf", replace
	
	* plot histogram of log earnings of rich state (Distrito Federal)
	tw ///
		(hist inc_ln if inrange(inc_ln, -.5, 5) & state == 27, start(-.5) width(.1) fcolor(blue%50) lcolor(blue%0)) ///
		, xline(0, lwidth(thick) lpattern(_) lcolor(gs8)) ///
		xlabel(-.5(.5)5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.3)2.1, format(%3.1f) gmin gmax grid gstyle(dot)) ///
		xtitle("Earnings (log multiples of MW)") ytitle("Density") ///
		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
		name(hist_spike_ln_`y'_state_rich, replace)
	graph export "${DIR_RESULTS}/${section}/hist_spike_ln_`y'_state_rich.pdf", replace
	
	* plot histogram of earnings, zoomed in around MW
	tw ///
		(hist inc_lvl if inrange(inc_lvl, .95, 1.20), start(.95) width(.01) fcolor(blue%50) lcolor(blue%0)) ///
		, xline(1, lwidth(thick) lpattern(_) lcolor(gs8)) ///
		xlabel(0.95(.01)1.20, format(%3.2f) angle(90) gmin gmax grid gstyle(dot)) ylabel(0(5)35, format(%2.0f) gmin gmax grid gstyle(dot)) ///
		xtitle("Earnings (multiples of MW)") ytitle("Density") ///
		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
		name(hist_spike_zoom_`y', replace)
	graph export "${DIR_RESULTS}/${section}/hist_spike_zoom_`y'.pdf", replace
	
	* plot histogram of log earnings, zoomed in around MW
	tw ///
		(hist inc_ln if inrange(inc_ln, -.05, 0.20), start(-.05) width(.01) fcolor(blue%50) lcolor(blue%0)) ///
		, xline(0, lwidth(thick) lpattern(_) lcolor(gs8)) ///
		xlabel(-.05(.01).20, format(%3.2f) angle(90) gmin gmax grid gstyle(dot)) ylabel(0(5)35, format(%2.0f) gmin gmax grid gstyle(dot)) ///
		xtitle("Earnings (log multiples of MW)") ytitle("Density") ///
		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
		name(hist_spike_ln_zoom_`y', replace)
	graph export "${DIR_RESULTS}/${section}/hist_spike_ln_zoom_`y'.pdf", replace
}


*** figures: earnings histograms for Rio Grande do Sul and by education group, replicating Haanwinckel (2020)

//////////////////////////////////////////////
// REMOVE IN REVISION (NOVEMBER 15, 2021)??? //
//////////////////////////////////////////////

// * load
// use ///
// 	year inc edu state ///
// 	if inlist(year, ${year_est_default_mid}, ${year_max}) ///
// 	using "${DIR_TEMP}/RAIS/rais_inc_${year_data_min}_${year_data_max}${sample_ext}.dta", clear

// * rename variables
// rename inc inc_lvl

// * generate log income
// gen float inc_ln = ln(inc_lvl)

// * produce counts
// count
// local N = r(N)
// count if inc_lvl == 1
// local N_mw = r(N)
// local share_mw = `N_mw'/`N'
// local share_mw_perc : di %3.1f 100*`share_mw'
// disp "--> share of workers earning MW = `share_mw_perc'%"

// tw ///
// 	(hist inc_ln if inrange(inc_ln, -.5, 5) & state == 23 & year == ${year_est_default_mid}, start(-.5) width(.05) fcolor(blue%50) lcolor(blue%0)) ///
// 	(hist inc_ln if inrange(inc_ln, -.5, 5) & state == 23 & year == ${year_max}, start(-.5) width(.05) fcolor(red%50) lcolor(red%0)) ///
// 	, xline(0, lwidth(thick) lpattern(_) lcolor(gs8)) ///
// 	xlabel(-.5(.5)5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.2)1.4, format(%2.1f) gmin gmax grid gstyle(dot)) ///
// 	xtitle("Earnings (log multiples of MW)") ytitle("Density") ///
// 	legend(order(1 "${year_est_default_mid}" 2 "${year_max}") region(color(none)) cols(2)) ///
// 	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
// 	name(hist_spike_ln_RS_edu_all, replace)
// graph export "${DIR_RESULTS}/${section}/hist_spike_ln_RS_edu_all_${year_est_default_mid}_${year_max}.pdf", replace

// replace edu = 1 if edu == 2
// replace edu = 3 if inlist(edu, 3, 4, 5, 6)
// replace edu = 7 if edu == 8
// foreach edu in 1 3 7 9 {
// 	tw ///
// 		(hist inc_ln if inrange(inc_ln, -.5, 5) & state == 23 & edu == `edu' & year == ${year_est_default_mid}, start(-.5) width(.05) fcolor(blue%50) lcolor(blue%0)) ///
// 		(hist inc_ln if inrange(inc_ln, -.5, 5) & state == 23 & edu == `edu' & year == ${year_max}, start(-.5) width(.05) fcolor(red%50) lcolor(red%0)) ///
// 		, xline(0, lwidth(thick) lpattern(_) lcolor(gs8)) ///
// 		xlabel(-.5(.5)5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.2)1.4, format(%2.1f) gmin gmax grid gstyle(dot)) ///
// 		xtitle("Earnings (log multiples of MW)") ytitle("Density") ///
// 		legend(order(1 "${year_est_default_mid}" 2 "${year_max}") region(color(none)) cols(2)) ///
// 		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
// 		name(hist_spike_ln_RS_edu_`edu', replace)
// 	graph export "${DIR_RESULTS}/${section}/hist_spike_ln_RS_edu_`edu'_${year_est_default_mid}_${year_max}.pdf", replace
// }


*** figures: time series evolution of inequality measures in high- vs. low-income states
* load data
use if inrange(year, ${year_est_default_mid}, ${year_max}) using "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_state.dta", clear

* create state-level P50-Kaitz index and state-level P90-Kaitz index
foreach p in 50 90 {
	gen float kaitz_p`p'_state = -inc_p`p'
	label var kaitz_p`p'_state "P`p'-Kaitz index, log(MW/P`p')"
}

* create standard deviation of log earnings
gen float inc_sd = inc_var^.5
label var inc_sd "Std. dev. of log earnings"

* create log percentile ratios
foreach p of numlist 5(5)95 {
	if `p' < $p_base {
		gen float inc_p${p_base}_p`p' = inc_p${p_base} - inc_p`p'
		label var inc_p${p_base}_p`p' "Log P${p_base}-P`p' percentile ratio, log(P${p_base}/P`p')"
	}
	else if `p' > $p_base {
		gen float inc_p`p'_p${p_base} = inc_p`p' - inc_p${p_base}
		label var inc_p`p'_p${p_base} "Log P`p'-P${p_base} percentile ratio, log(P`p'/P${p_base})"
	}
}

* list of state codes:
// 1 "Rondonia (RO)"
// 2 "Acre (AC)"
// 3 "Amazonas (AM)"
// 4 "Roraima (RR)"
// 5 "Para (PA)"
// 6 "Amapa (AP)"
// 7 "Tocantins (TO)"
// 8 "Maranhao (MA)"
// 9 "Piaui (PI)"
// 10 "Ceara (CE)"
// 11 "Rio Grande do Norte (RN)"
// 12 "Paraiba (PB)"
// 13 "Pernambuco (PE)"
// 14 "Alagoas (AL)"
// 15 "Sergipe (SE)"
// 16 "Bahia (BA)"
// 17 "Minas Gerais (MG)"
// 18 "Espirito Santo (ES)"
// 19 "Rio de Janeiro (RJ)"
// 20 "Sao Paulo (SP)"
// 21 "Parana (PR)"
// 22 "Santa Catarina (SC)"
// 23 "Rio Grande do Sul (RS)"
// 24 "Mato Grosso do Sul (MS)"
// 25 "Mato Grosso (MT)"
// 26 "Goias (GO)"
// 27 "Distrito Federal (DF)"

* list of poorest, middle, and richest state codes according to GDP per capita in 2018 (Source: Wikipedia, https://pt.wikipedia.org/wiki/Lista_de_unidades_federativas_do_Brasil_por_PIB_per_capita, retrieved on November 15, 2021)
// poorest state codes: 9 = PI, 8 = MA, 14 = AL, 12 = PB, 10 = CE
// middle state codes: 26 = GO, 17 = MG, 2 = AC, 25 = MT, 7 = TO
// richest state codes: 27 = DF, 20 = SP, 19 = RJ, 18 = ES, 22 = SC

* identify poorest and richest states by income
if $ranking_method == 1 { // ranking method 1: Wikipedia GDP per capita in 2018
	gen byte poorest = inlist(state, 9, 8, 12) // formerly (before Nov 15, 2021): inlist(state, 9, 8, 14)
	label var poorest "Ind: Among poorest 3 states?"
	gen byte richest = inlist(state, 27, 20, 19)
	label var richest "Ind: Among richest 3 states?"
}
else if $ranking_method == 2 { // ranking method 2: RAIS median log earnings in ${year_est_default_mid}
	bys state: gen float inc_p50_ref = inc_p50 if year == ${year_est_default_mid}
	sort inc_p50_ref
	gen byte inc_p50_ref_rank = _n if inc_p50_ref < .
	drop inc_p50_ref
	bys state (inc_p50_ref_rank): replace inc_p50_ref_rank = inc_p50_ref_rank[1]
	sum inc_p50_ref_rank, meanonly
	local N_states = r(max)
	gen byte poorest = (inc_p50_ref_rank <= 3)
	label var poorest "Ind: Among poorest 3 states?"
	gen byte richest = (inc_p50_ref_rank >= r(max) - 2)
	label var richest "Ind: Among richest 3 states?"
	drop inc_p50_ref_rank
}
else if $ranking_method == 3 { // ranking method 3: RAIS mean log earnings in ${year_est_default_mid}
	bys state: gen float inc_mean_ref = inc_mean if year == ${year_est_default_mid}
	sort inc_mean_ref
	gen byte inc_mean_ref_rank = _n if inc_mean_ref < .
	drop inc_mean_ref
	bys state (inc_mean_ref_rank): replace inc_mean_ref_rank = inc_mean_ref_rank[1]
	sum inc_mean_ref_rank, meanonly
	local N_states = r(max)
	gen byte poorest = (inc_mean_ref_rank <= 3)
	label var poorest "Ind: Among poorest 3 states?"
	gen byte richest = (inc_mean_ref_rank >= r(max) - 2)
	label var richest "Ind: Among richest 3 states?"
	drop inc_mean_ref_rank
}

* confirm classification of poorest and richest states
tab state if poorest == 1
tab state if richest == 1

* compute mean percentile ratios across income groups
foreach l in "poorest" "richest" {
	foreach p of numlist 5 10 25 75 90 95 {
		if `p' < 50 local p_post = "_p`p'"
		else local p_post = ""
		if `p' > 50 local p_pre = "p`p'_"
		else local p_pre = ""
		if "${gtools}" != "" ${gtools}egen float inc_`p_pre'p50`p_post'_`l' = mean(inc_`p_pre'p50`p_post') if `l' == 1, by(year)
		else bys year: egen float inc_`p_pre'p50`p_post'_`l' = mean(inc_`p_pre'p50`p_post') if `l' == 1
		bys year `l': replace inc_`p_pre'p50`p_post'_`l' = . if _n > 1
		sum inc_`p_pre'p50`p_post'_`l' if year == ${year_est_default_mid}, meanonly
		gen float inc_`p_pre'p50`p_post'_`l'_norm = inc_`p_pre'p50`p_post'_`l' ${norm_operator} r(mean)
	}
	
	if "${gtools}" != "" ${gtools}egen float inc_var_`l' = mean(inc_var) if `l' == 1, by(year)
	else bys year: egen float inc_var_`l' = mean(inc_var) if `l' == 1
	if "${gtools}" != "" ${gtools}egen float inc_sd_`l' = mean(inc_sd) if `l' == 1, by(year)
	else bys year: egen float inc_sd_`l' = mean(inc_sd) if `l' == 1
	sum inc_var_`l' if year == ${year_est_default_mid}, meanonly
	gen float inc_var_`l'_norm = inc_var_`l' ${norm_operator} r(mean)
	sum inc_sd_`l' if year == ${year_est_default_mid}, meanonly
	gen float inc_sd_`l'_norm = inc_sd_`l' ${norm_operator} r(mean)
}
drop poorest richest

* merge in overall P50-Kaitz index and overall P90-Kaitz index
merge m:1 year using "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_overall.dta", nogen keep(master match) keepusing(inc_p50 inc_p90)
foreach p in 50 90 {
	replace inc_p`p' = -inc_p`p'
	rename inc_p`p' kaitz_p`p'_overall
}

* rank states by P50-Kaitz index
foreach y in $year_est_default_mid $year_max {
	${gtools}egen byte rank_`y'_temp = rank(kaitz_p50_state) if year == `y'
	bys state (rank_`y'_temp): gen byte rank_`y' = rank_`y'_temp[1] if year == ${year_est_default_mid}
	drop rank_`y'_temp
}

* plots
${gtools}levelsof state, local(states_list)
local s_number = 0
foreach s of local states_list { // define color palette
	local ++s_number
	local rgb_blue1_`s_number' = floor(255/27*(`s_number' - 1)*.8)
	local rgb_blue2_`s_number' = ceil(255 - `rgb_blue1_`s_number''/5)
}
foreach p in 50 90 {
	global plot_str_p`p' = ""
	foreach s of local states_list { // create string with plot and formatting info
		sum rank_${year_est_default_mid} if state == `s', meanonly
		local s_rank = 27 - r(mean) + 1
		global plot_str_p`p' = `"${plot_str_p`p'} (line kaitz_p`p'_state year if state == `s', sort(year) lcolor("`rgb_blue1_`s_rank'' `rgb_blue1_`s_rank'' `rgb_blue2_`s_rank''"))"'
	}
}
// sort state year
foreach p in 50 90 {
	if `p' == 50 local y_label_grid = "-1.6(.2)0.0"
	else if `p' == 90 local y_label_grid = "-3.0(.4)-1.0"
	tw ///
		${plot_str_p`p'} ///
		(line kaitz_p`p'_overall year if state == 1, sort(year) lcolor(red) lwidth(thick)) if inrange(year, ${year_est_default_mid}, ${year_max}) ///
		, xtitle("") ytitle("P`p'-Kaitz index, log(MW/P`p')") ///
		xlabel(${year_est_default_mid}(2)${year_max}, grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(`y_label_grid', grid gstyle(dot) gmin gmax format(%3.1f)) ///
		legend(off) ///
		plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
		name(kaitz_p`p'_evolution, replace)
	graph export "${DIR_RESULTS}/${section}/kaitz_p`p'_evolution.pdf", replace
}
tw ///
	(connected inc_sd_poorest_norm inc_sd_richest_norm year, sort(year) lcolor(blue red) mcolor(blue red) msymbol(O S) lpattern(l _)) if inrange(year, ${year_est_default_mid}, ${year_max}) ///
	, xlabel(${year_est_default_mid}(2)${year_max}, grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.4(.1)1.2, grid gstyle(dot) gmin gmax format(%3.1f)) ///
	xtitle("") ytitle("Normalized std. dev. of log earnings (${year_est_default_mid} = 1.0)") ///
	legend(order(1 "Low income states" 2 "High income states") cols(2) region(color(none)) symxsize(*1) ring(0) position(12)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(sd_${year_est_default_mid}_${year_max}, replace)
graph export "${DIR_RESULTS}/${section}/comp_sd_${year_est_default_mid}_${year_max}.pdf", replace
// tw ///
// 	(connected inc_var_poorest_norm inc_var_richest_norm year, lcolor(blue red) mcolor(blue red) msymbol(O S) lpattern(l _)) if inrange(year, ${year_est_default_mid}, ${year_max}) ///
// 	, xlabel(${year_est_default_mid}(${plot_step_size})${year_max}, grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.4(.1)1.1, grid gstyle(dot) gmin gmax format(%3.1f)) ///
// 	xtitle("") ytitle("Normalized variance of log earnings (${year_est_default_mid} = 1.0)") ///
// 	legend(order(1 "Low income states" 2 "High income states") cols(2) region(color(none)) symxsize(*1)) ///
// 	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 	name(var_${year_est_default_mid}_${year_max}, replace)
// graph export "${DIR_RESULTS}/${section}/comp_var_${year_est_default_mid}_${year_max}.pdf", replace
tw ///
	(connected inc_p50_p10_poorest_norm inc_p50_p25_poorest_norm inc_p50_p10_richest_norm inc_p50_p25_richest_norm year, sort(year) lcolor(blue blue red red) mcolor(blue blue red red) msymbol(O S D T) lpattern(l _ - longdash_dot)) if inrange(year, ${year_est_default_mid}, ${year_max}) ///
	, xlabel(${year_est_default_mid}(2)${year_max}, grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.4(.1)1.2, grid gstyle(dot) gmin gmax format(%3.1f)) ///
	xtitle("") ytitle("Normalized log percentile ratio (${year_est_default_mid} = 1.0)") ///
	legend(order(1 "Low income states: P50/P10" 2 "Low income states: P50/P25" 3 "High income states: P50/P10" 4 "High income states: P50/P25") cols(2) region(color(none)) symxsize(*1) ring(0) position(12)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(percentiles_bottom_${year_est_default_mid}_${year_max}, replace)
graph export "${DIR_RESULTS}/${section}/comp_percentiles_bottom_${year_est_default_mid}_${year_max}.pdf", replace
tw ///
	(connected inc_p75_p50_poorest_norm inc_p90_p50_poorest_norm inc_p75_p50_richest_norm inc_p90_p50_richest_norm year, sort(year) lcolor(blue blue red red) mcolor(blue blue red red) msymbol(O S D T) lpattern(l _ - longdash_dot)) if inrange(year, ${year_est_default_mid}, ${year_max}) ///
	, xlabel(${year_est_default_mid}(2)${year_max}, grid gstyle(dot) gmin gmax format(%4.0f)) ylabel(.4(.1)1.2, grid gstyle(dot) gmin gmax format(%3.1f)) ///
	xtitle("") ytitle("Normalized log percentile ratio (${year_est_default_mid} = 1.0)") ///
	legend(order(1 "Low income states: P75/P50" 2 "Low income states: P90/P50" 3 "High income states: P75/P50" 4 "High income states: P90/P50") cols(2) region(color(none)) symxsize(*1) ring(0) position(6)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(percentiles_top_${year_est_default_mid}_${year_max}, replace)
graph export "${DIR_RESULTS}/${section}/comp_percentiles_top_${year_est_default_mid}_${year_max}.pdf", replace


*** percentile scatter plots a la Lee (1999)
foreach unit in state meso { // micro muni
	
	* load state-level data
	use if inlist(year, ${y1}, ${y2}, ${y3}, ${y4}, ${y5}) using "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_`unit'.dta", clear
	
	* create P50-Kaitz index
	gen float kaitz_p50 = -inc_p50
	label var kaitz_p50 "P50-Kaitz index, log(MW/P50)"

	* create standard deviation of log earnings
	gen float inc_sd = inc_var^.5
	label var inc_sd "Std. dev. of log earnings"

	* create log percentile ratios
	foreach p of numlist 5(5)95 {
		if `p' < $p_base {
			gen float inc_p${p_base}_p`p' = inc_p${p_base} - inc_p`p'
			label var inc_p${p_base}_p`p' "Log P${p_base}-P`p' percentile ratio, log(P${p_base}/P`p')"
		}
		else if `p' > $p_base {
			gen float inc_p`p'_p${p_base} = inc_p`p' - inc_p${p_base}
			label var inc_p`p'_p${p_base} "Log P`p'-P${p_base} percentile ratio, log(P`p'/P${p_base})"
		}
	}

	* plots
	tw ///
		(scatter inc_sd kaitz_p50 if year == ${y1}, msymbol(O) mcolor(blue) msize(large)) ///
		(scatter inc_sd kaitz_p50 if year == ${y2}, msymbol(D) mcolor(red) msize(large)) ///
		(scatter inc_sd kaitz_p50 if year == ${y3}, msymbol(T) mcolor(green) msize(large)) ///
		(scatter inc_sd kaitz_p50 if year == ${y4}, msymbol(S) mcolor(orange) msize(large)) ///
		(scatter inc_sd kaitz_p50 if year == ${y5}, msymbol(X) mcolor(purple) msize(large)) ///
		, xlabel(-2(.2)0, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.2)2, grid gstyle(dot) gmin gmax format(%2.1f)) ///
		xtitle("P50-Kaitz index, log(MW/P50)") ytitle("Std. dev. of log earnings") ///
		legend(order(1 "${y1}" 2 "${y2}" 3 "${y3}" 4 "${y4}" 5 "${y5}") cols(5) region(color(none)) symxsize(*1)) ///
		plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///	
		name(perc_scatter_sd_`unit', replace)
	graph export "${DIR_RESULTS}/${section}/perc_scatter_sd_`unit'.pdf", replace
	// tw ///
	// 	(scatter inc_var kaitz_p50 if year == ${y1}, msymbol(O) mcolor(blue) msize(large)) ///
	// 	(scatter inc_var kaitz_p50 if year == ${y2}, msymbol(D) mcolor(red) msize(large)) ///
	// 	(scatter inc_var kaitz_p50 if year == ${y3}, msymbol(T) mcolor(green) msize(large)) ///
	// 	(scatter inc_var kaitz_p50 if year == ${y4}, msymbol(S) mcolor(orange) msize(large)) ///
	// 	(scatter inc_var kaitz_p50 if year == ${y5}, msymbol(X) mcolor(purple) msize(large)) ///
	// 	, xlabel(-1.8(.2)0, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.2)1.8, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	// 	xtitle("P50-Kaitz index, log(MW/P50)") ytitle("Variance of log earnings") ///
	// 	legend(order(1 "${y1}" 2 "${y2}" 3 "${y3}" 4 "${y4}" 5 "${y5}") cols(5) region(color(none)) symxsize(*1)) ///
	// 	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///	
	// 	name(perc_scatter_var_`unit', replace)
	// graph export "${DIR_RESULTS}/${section}/perc_scatter_var_`unit'.pdf", replace
	foreach p of numlist 5(5)95 {
		if `p' < $p_base {
			tw ///
				(scatter inc_p50_p`p' kaitz_p50 if year == ${y1}, msymbol(O) mcolor(blue) msize(large)) ///
				(scatter inc_p50_p`p' kaitz_p50 if year == ${y2}, msymbol(D) mcolor(red) msize(large)) ///
				(scatter inc_p50_p`p' kaitz_p50 if year == ${y3}, msymbol(T) mcolor(green) msize(large)) ///
				(scatter inc_p50_p`p' kaitz_p50 if year == ${y4}, msymbol(S) mcolor(orange) msize(large)) ///
				(scatter inc_p50_p`p' kaitz_p50 if year == ${y5}, msymbol(X) mcolor(purple) msize(large)) ///
				(function y = -x, range(-2 0) lcolor(gs8)) ///
				, xlabel(-2(.2)0, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.2)2, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("P50-Kaitz index, log(MW/P50)") ytitle("Log P50-P`p' percentile ratio") ///
				legend(order(1 "${y1}" 2 "${y2}" 3 "${y3}" 4 "${y4}" 5 "${y5}") cols(5) region(color(none))) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///	
				name(perc_scatter_p50_p`p'_`unit', replace)
			graph export "${DIR_RESULTS}/${section}/perc_scatter_p50_p`p'_`unit'.pdf", replace
		}
		else if `p' > $p_base {
			tw ///
				(scatter inc_p`p'_p50 kaitz_p50 if year == ${y1}, msymbol(O) mcolor(blue) msize(large)) ///
				(scatter inc_p`p'_p50 kaitz_p50 if year == ${y2}, msymbol(D) mcolor(red) msize(large)) ///
				(scatter inc_p`p'_p50 kaitz_p50 if year == ${y3}, msymbol(T) mcolor(green) msize(large)) ///
				(scatter inc_p`p'_p50 kaitz_p50 if year == ${y4}, msymbol(S) mcolor(orange) msize(large)) ///
				(scatter inc_p`p'_p50 kaitz_p50 if year == ${y5}, msymbol(X) mcolor(purple) msize(large)) ///
				, xlabel(-2(.2)0, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.2)2, grid gstyle(dot) gmin gmax format(%2.1f)) ///
				xtitle("P50-Kaitz index, log(MW/P50)") ytitle("Log P`p'-P50 percentile ratio") ///
				legend(order(1 "${y1}" 2 "${y2}" 3 "${y3}" 4 "${y4}" 5 "${y5}") cols(5) region(color(none))) ///
				plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///	
				name(perc_scatter_p`p'_p50_`unit', replace)
			graph export "${DIR_RESULTS}/${section}/perc_scatter_p`p'_p50_`unit'.pdf", replace
		}
	}
}


*** upper-tail inequality versus median earnings across states
* load data
use if year == ${year_est_default_mid} using "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_state.dta", clear

* create log earnings percentile ratios
foreach p_base of numlist 50(10)80 {
	foreach p of numlist 55(5)95 {
		gen float inc_p`p'_p`p_base' = inc_p`p' - inc_p`p_base'
		label var inc_p`p'_p`p_base' "Log P`p'-P`p_base' percentile ratio, log(P`p'/P`p_base')"
	}
}

* plots
tw ///
	(scatter inc_p60_p50 inc_p50, msymbol(Oh) mcolor(blue) msize(large)) ///
	(scatter inc_p70_p50 inc_p50, msymbol(Dh) mcolor(red) msize(large)) ///
	(scatter inc_p80_p50 inc_p50, msymbol(Sh) mcolor(green) msize(large)) ///
	(scatter inc_p90_p50 inc_p50, msymbol(Th) mcolor(orange) msize(large)) /// (scatter inc_p95_p50 inc_p50, msymbol(X) mcolor(purple) msize(large)) ///
	(lfit inc_p60_p50 inc_p50, lcolor(blue) lwidth(thick)) ///
	(lfit inc_p70_p50 inc_p50, lcolor(red) lwidth(thick)) ///
	(lfit inc_p80_p50 inc_p50, lcolor(green) lwidth(thick)) ///
	(lfit inc_p90_p50 inc_p50, lcolor(orange) lwidth(thick)) /// (lfit inc_p95_p50 inc_p50, lcolor(purple) lwidth(thick)) ///
	, xlabel(.4(.2)1.6, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.2)1.6, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Median earnings (log multiples of MW)") ytitle("Log earnings percentile ratio") ///
	legend(order(1 "P60-P50" 2 "P70-P50" 3 "P80-P50" 4 "P90-P50") cols(4) region(color(none))) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///	
	name(upper_tails_1, replace)
graph export "${DIR_RESULTS}/${section}/upper_tails_1.pdf", replace
tw ///
	(scatter inc_p70_p60 inc_p50, msymbol(Dh) mcolor(red) msize(large)) ///
	(scatter inc_p80_p60 inc_p50, msymbol(Sh) mcolor(green) msize(large)) ///
	(scatter inc_p90_p60 inc_p50, msymbol(Th) mcolor(orange) msize(large)) /// (scatter inc_p95_p50 inc_p50, msymbol(X) mcolor(purple) msize(large)) ///
	(lfit inc_p70_p60 inc_p50, lcolor(red) lwidth(thick)) ///
	(lfit inc_p80_p60 inc_p50, lcolor(green) lwidth(thick)) ///
	(lfit inc_p90_p60 inc_p50, lcolor(orange) lwidth(thick)) /// (lfit inc_p95_p50 inc_p50, lcolor(purple) lwidth(thick)) ///
	, xlabel(.4(.2)1.6, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.2)1.6, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Median earnings (log multiples of MW)") ytitle("Log earnings percentile ratio") ///
	legend(order(1 "P70-P60" 2 "P80-P60" 3 "P90-P60") cols(3) region(color(none))) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///	
	name(upper_tails_2, replace)
graph export "${DIR_RESULTS}/${section}/upper_tails_2.pdf", replace
tw ///
	(scatter inc_p80_p70 inc_p50, msymbol(Sh) mcolor(green) msize(large)) ///
	(scatter inc_p90_p70 inc_p50, msymbol(Th) mcolor(orange) msize(large)) /// (scatter inc_p95_p50 inc_p50, msymbol(X) mcolor(purple) msize(large)) ///
	(lfit inc_p80_p70 inc_p50, lcolor(green) lwidth(thick)) ///
	(lfit inc_p90_p70 inc_p50, lcolor(orange) lwidth(thick)) /// (lfit inc_p95_p50 inc_p50, lcolor(purple) lwidth(thick)) ///
	, xlabel(.4(.2)1.6, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.2)1.6, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Median earnings (log multiples of MW)") ytitle("Log earnings percentile ratio") ///
	legend(order(1 "P80-P70" 2 "P90-P70") cols(2) region(color(none))) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///	
	name(upper_tails_3, replace)
graph export "${DIR_RESULTS}/${section}/upper_tails_3.pdf", replace
tw ///
	(scatter inc_p90_p80 inc_p50, msymbol(Th) mcolor(orange) msize(large)) /// (scatter inc_p95_p50 inc_p50, msymbol(X) mcolor(purple) msize(large)) ///
	(lfit inc_p90_p80 inc_p50, lcolor(orange) lwidth(thick)) /// (lfit inc_p95_p50 inc_p50, lcolor(purple) lwidth(thick)) ///
	, xlabel(.4(.2)1.6, grid gstyle(dot) gmin gmax format(%2.1f)) ylabel(0(.2)1.6, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Median earnings (log multiples of MW)") ytitle("Log earnings percentile ratio") ///
	legend(order(1 "P90-P80") cols(1) region(color(none))) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///	
	name(upper_tails_4, replace)
graph export "${DIR_RESULTS}/${section}/upper_tails_4.pdf", replace


*** MW shares throughout income distribution (data)
* load data
use ///
	persid year inc age edu ///
	if inrange(year, ${year_est_default_mid}, ${year_max}) ///
	using "${DIR_TEMP}/RAIS/rais_inc_${year_data_min}_${year_data_max}${sample_ext}.dta", clear

* mark minimum wage job spells
gen byte mw_current = (inc == 1)
label var mw_current "Ind: Currently employed at minimum wage?"

* mark first and last minimum wage years
gen int mw_year = year if mw_current == 1
if "${gtools}" != "" {
	gegen int mw_min_year = min(mw_year), by(persid)
	gegen int mw_max_year = max(mw_year), by(persid)
}
else {
	bys persid: egen int mw_min_year = min(mw_year)
	bys persid: egen int mw_max_year = max(mw_year)
}
label var mw_min_year "First year employed at minimum wage"
label var mw_max_year "Last year employed at minimum wage"
drop persid mw_year

* decomposition of share of ever-minimum wage earners
// 7 ways of having ever earned the minimum wage:
// (1) not in past, not currently, in future
// (2) not in past, currently, not in future
// (3) not in past, currently, in future
// (4) in past, not currently, not in future
// (5) in past, not currently, in future
// (6) in past, currently, not in future
// (7) in past, currently, in future
// --> ever minimum wage = union((1), (2), (3), (4), (5), (6), (7)) = union(union((2), (3), (6), (7)), union((4), (5)), (1))

* mark ever-minimum-wage earners
gen byte mw_ever = (mw_min_year < .)
label var mw_ever "Ind: Ever employed at minimum wage?"

* mark past minimum-wage earners
gen byte mw_past = (year > mw_min_year)
label var mw_past "Ind: Employed at minimum wage in past?"
drop mw_min_year

* mark future minimum-wage earners
gen byte mw_future = (year < mw_max_year & mw_max_year < .)
label var mw_future "Ind: Employed at minimum wage in future?"
drop mw_max_year

* mark past minimum-wage earners currently not employed at minimum wage
gen byte mw_past_not_current = (mw_past == 1 & mw_current == 0)
label var mw_past_not_current "Ind: Employed at minimum wage in past but not currently?"

* mark future minimum-wage earners not currently or in the past employed at minimum wage
gen byte mw_future_not_current_not_past = (mw_future == 1 & mw_current == 0 & mw_past == 0)
label var mw_future_not_current_not_past "Ind: Employed at minimum wage in future but not currently or in past?"
drop mw_past mw_future

* define income quantiles
if "${gtools}" != "" gquantiles inc_q = inc, xtile n(100) by(year)
else {
	disp as error "USER ERROR: Must use -gtools-!"
	error 1
}
label var inc_q "Earnings quantile, by year"
drop inc

* recode age
recode age (18/24=1) (25/34=2) (35/44=3) (45/54=4), generate(age_group)
label var age_group "Age group"
drop age
label define age_l 1 "Age 18-24" 2 "Age 25-34" 3 "Age 35-44" 4 "Age 45-54", replace
label val age_group age_l

* recode education
gen byte edu_group = 1
replace edu_group = 2 if inlist(edu, 5, 6)
replace edu_group = 3 if inlist(edu, 7, 8)
replace edu_group = 4 if edu == 9
label var edu_group "Education group"
drop edu
label define edu_l 1 "Primary school" 2 "Middle school" 3 "High school" 4 "College", replace
label val edu_group edu_l

* plot ever-MW share and its decomposition across income quantiles, overall
preserve
${gtools}collapse (mean) mw_ever_share=mw_ever mw_current_share=mw_current mw_past_not_current_share=mw_past_not_current mw_future_not_current_not_past_s=mw_future_not_current_not_past, by(inc_q) fast
label var mw_ever_share "Share ever employed at minimum wage"
label var mw_current_share "Share currently employed at minimum wage"
label var mw_past_not_current_share "Share in past but not currently employed at minimum wage"
label var mw_future_not_current_not_past_s "Share in future but not currently or in past employed at minimum wage"
local inc_q_list = ""
foreach q of numlist 5(5)95 {
	local inc_q_list = "`inc_q_list',`q'"
}
tw ///
	(connected mw_ever_share inc_q if inlist(inc_q`inc_q_list'), mcolor(blue) lcolor(blue) msymbol(O) lpattern(l _ - longdash_dot)) ///
	, xlabel(0(10)100, grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(0(.1).6, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Income percentile") ytitle("Share ever employed at minimum wage, ${year_est_default_mid}-${year_max}") ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(mw_ever_share_all, replace)
graph export "${DIR_RESULTS}/${section}/mw_ever_share_all.pdf", replace
tw ///
	(connected mw_ever_share mw_current_share mw_past_not_current_share mw_future_not_current_not_past_s inc_q if inlist(inc_q`inc_q_list'), mcolor(blue blue%70 blue%50 blue%30) lcolor(blue blue%70 blue%50 blue%30) msymbol(O D T S) lpattern(l _ - longdash_dot)) ///
	, xlabel(0(10)100, grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(0(.1).6, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Income percentile") ytitle("Minimum wage share of all jobs, ${year_est_default_mid}-${year_max}") ///
	legend(order(1 "Ever (present, past, or future)" 2 "Present" 3 "Past, not present" 4 "Future, not present or past") region(color(none)) symxsize(*.66) cols(2)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(mw_ever_share_all_decomp, replace)
graph export "${DIR_RESULTS}/${section}/mw_ever_share_all_decomp.pdf", replace
restore

* plot ever-MW share across income quantiles, by age group
preserve
${gtools}collapse (mean) mw_ever_share=mw_ever, by(inc_q age_group) fast
label var mw_ever_share "Share ever employed at minimum wage"
local inc_q_list = ""
foreach q of numlist 5(5)95 {
	local inc_q_list = "`inc_q_list',`q'"
}
tw ///
	(connected mw_ever_share inc_q if age_group == 1 & inlist(inc_q`inc_q_list'), mcolor(blue) lcolor(blue) msymbol(O) lpattern(l)) ///
	(connected mw_ever_share inc_q if age_group == 2 & inlist(inc_q`inc_q_list'), mcolor(red) lcolor(red) msymbol(D) lpattern(_)) ///
	(connected mw_ever_share inc_q if age_group == 3 & inlist(inc_q`inc_q_list'), mcolor(green) lcolor(green) msymbol(T) lpattern(-)) ///
	(connected mw_ever_share inc_q if age_group == 4 & inlist(inc_q`inc_q_list'), mcolor(orange) lcolor(orange) msymbol(S) lpattern(longdash_dot)) ///
	, xlabel(0(10)100, grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(0(.1)1, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Income percentile") ytitle("Share ever employed at minimum wage, ${year_est_default_mid}-${year_max}") ///
	legend(order(1 "Age 18-24" 2 "Age 25-34" 3 "Age 35-44" 4 "Age 45-54") region(color(none)) symxsize(*.66) cols(4)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(mw_ever_share_by_age, replace)
graph export "${DIR_RESULTS}/${section}/mw_ever_share_by_age.pdf", replace
restore

* plot ever-MW share across income quantiles, by education group
preserve
${gtools}collapse (mean) mw_ever_share=mw_ever, by(inc_q edu_group) fast
label var mw_ever_share "Share ever employed at minimum wage"
local inc_q_list = ""
foreach q of numlist 5(5)95 {
	local inc_q_list = "`inc_q_list',`q'"
}
tw ///
	(connected mw_ever_share inc_q if edu_group == 1 & inlist(inc_q`inc_q_list'), mcolor(blue) lcolor(blue) msymbol(O) lpattern(l)) ///
	(connected mw_ever_share inc_q if edu_group == 2 & inlist(inc_q`inc_q_list'), mcolor(red) lcolor(red) msymbol(D) lpattern(_)) ///
	(connected mw_ever_share inc_q if edu_group == 3 & inlist(inc_q`inc_q_list'), mcolor(green) lcolor(green) msymbol(T) lpattern(-)) ///
	(connected mw_ever_share inc_q if edu_group == 4 & inlist(inc_q`inc_q_list'), mcolor(orange) lcolor(orange) msymbol(S) lpattern(longdash_dot)) ///
	, xlabel(0(10)100, grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(0(.1)1, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Income percentile") ytitle("Share ever employed at minimum wage, ${year_est_default_mid}-${year_max}") ///
	legend(order(1 "Primary school" 2 "Middle school" 3 "High school" 4 "College") region(color(none)) symxsize(*.6) cols(4)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(mw_ever_share_by_edu, replace)
graph export "${DIR_RESULTS}/${section}/mw_ever_share_by_edu.pdf", replace
restore

* plot ever-MW share across income quantiles, by year
preserve
${gtools}collapse (mean) mw_ever_share=mw_ever, by(inc_q year) fast
label var mw_ever_share "Share ever employed at minimum wage"
local inc_q_list = ""
foreach q of numlist 5(5)95 {
	local inc_q_list = "`inc_q_list',`q'"
}
tw ///
	(connected mw_ever_share inc_q if year == ${y1} & inlist(inc_q`inc_q_list'), mcolor(blue) lcolor(blue) msymbol(O) lpattern(l)) ///
	(connected mw_ever_share inc_q if year == ${y2} & inlist(inc_q`inc_q_list'), mcolor(red) lcolor(red) msymbol(D) lpattern(_)) ///
	(connected mw_ever_share inc_q if year == ${y3} & inlist(inc_q`inc_q_list'), mcolor(green) lcolor(green) msymbol(T) lpattern(-)) ///
	(connected mw_ever_share inc_q if year == ${y4} & inlist(inc_q`inc_q_list'), mcolor(orange) lcolor(orange) msymbol(S) lpattern(longdash_dot)) ///
	(connected mw_ever_share inc_q if year == ${y5} & inlist(inc_q`inc_q_list'), mcolor(purple) lcolor(purple) msymbol(X) lpattern(dash_dot)) ///
	, xlabel(0(10)100, grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(0(.1)1, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("Income percentile") ytitle("Share ever employed at minimum wage, ${year_est_default_mid}-${year_max}") ///
	legend(order(1 "${y1}" 2 "${y2}" 3 "${y3}" 4 "${y4}" 5 "${y5}") region(color(none)) symxsize(*.66) cols(5)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(mw_ever_share_by_year, replace)
graph export "${DIR_RESULTS}/${section}/mw_ever_share_by_year.pdf", replace
restore

* plot (ever-)MW share across age groups, by education group
foreach current_ever in "_current" "_ever" {
	if "`current_ever'" == "_current" {
		local y_step = ".01"
		local y_max = ".04"
		local y_format = "%3.2f"
		local y_label = "currently"
	}
	else if "`current_ever'" == "_ever" {
		local y_step = ".05"
		local y_max = ".2"
		local y_format = "%3.2f"
		local y_label = "ever"
	}
	preserve
	${gtools}collapse (mean) mw`current_ever'_share=mw`current_ever', by(age_group edu_group) fast
	if "`current_ever'" == "_current" label var mw_current_share "Share currently employed at minimum wage"
	else if "`current_ever'" == "_ever" label var mw_ever_share "Share ever employed at minimum wage"
	tw ///
		(connected mw`current_ever'_share age_group if edu_group == 1, mcolor(blue) lcolor(blue) msymbol(O) lpattern(l)) ///
		(connected mw`current_ever'_share age_group if edu_group == 2, mcolor(red) lcolor(red) msymbol(D) lpattern(_)) ///
		(connected mw`current_ever'_share age_group if edu_group == 3, mcolor(green) lcolor(green) msymbol(T) lpattern(-)) ///
		(connected mw`current_ever'_share age_group if edu_group == 4, mcolor(orange) lcolor(orange) msymbol(S) lpattern(longdash_dot)) ///
		, xlabel(1 `" "Age" "18-24" "' 2 `" "Age" "25-34" "' 3 `" "Age" "35-44" "' 4 `" "Age" "45-54 " "', grid gstyle(dot) gmin gmax) ylabel(0(`y_step')`y_max', grid gstyle(dot) gmin gmax format(`y_format')) ///
		xtitle("") ytitle("Share `y_label' employed at MW, ${year_est_default_mid}-${year_max}") ///
		legend(order(1 "Primary school" 2 "Middle school" 3 "High school" 4 "College") region(color(none)) symxsize(*.6) cols(4)) ///
		plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
		name(mw`current_ever'_share_by_edu, replace)
	graph export "${DIR_RESULTS}/${section}/mw`current_ever'_share_by_edu.pdf", replace
	restore
}


// *** MW shares throughout income distribution (model -- severely underpredicts ever-MW share)
// * load data (Note: the two datasets use different person IDs, hence cannot be merged.)
// // import delim "${DIR_MODEL}/3 Version 10302020/2 Data/Model_microdata_connected.csv", delim(tab) clear // contains as variables: id empid year wage pe fe
// import delim "${DIR_MODEL}/3 Version 10302020/2 Data/Model_microdata.csv", delim(tab) clear // contains as variables: id empid year wage

// * drop variables not needed in analysis
// drop empid

// * rename variables
// rename id persid
// rename wage inc

// * destring, i.e., convert MATLAB missing ("NaN") to Stata missing (.)
// foreach var of varlist * {
// 	destring `var', float force replace
// }

// * set panel
// xtset persid year

// * mark minimum wage job spells
// gen byte mw_current = (inc == 1)
// label var mw_current "Ind: Currently employed at minimum wage?"

// * mark first and last minimum wage years
// gen int mw_year = year if mw_current == 1
// if "${gtools}" != "" {
// 	gegen int mw_min_year = min(mw_year), by(persid)
// 	gegen int mw_max_year = max(mw_year), by(persid)
// }
// else {
// 	bys persid: egen int mw_min_year = min(mw_year)
// 	bys persid: egen int mw_max_year = max(mw_year)
// }
// label var mw_min_year "First year employed at minimum wage"
// label var mw_max_year "Last year employed at minimum wage"
// drop persid mw_year

// * decomposition of share of ever-minimum wage earners
// // 7 ways of having ever earned the minimum wage:
// // (1) not in past, not currently, in future
// // (2) not in past, currently, not in future
// // (3) not in past, currently, in future
// // (4) in past, not currently, not in future
// // (5) in past, not currently, in future
// // (6) in past, currently, not in future
// // (7) in past, currently, in future
// // --> ever minimum wage = union((1), (2), (3), (4), (5), (6), (7)) = union(union((2), (3), (6), (7)), union((4), (5)), (1))

// * mark ever-minimum-wage earners
// gen byte mw_ever = (mw_min_year < .)
// label var mw_ever "Ind: Ever employed at minimum wage?"

// * mark past minimum-wage earners
// gen byte mw_past = (year > mw_min_year)
// label var mw_past "Ind: Employed at minimum wage in past?"
// drop mw_min_year

// * mark future minimum-wage earners
// gen byte mw_future = (year < mw_max_year & mw_max_year < .)
// label var mw_future "Ind: Employed at minimum wage in future?"
// drop mw_max_year

// * mark past minimum-wage earners currently not employed at minimum wage
// gen byte mw_past_not_current = (mw_past == 1 & mw_current == 0)
// label var mw_past_not_current "Ind: Employed at minimum wage in past but not currently?"

// * mark future minimum-wage earners not currently or in the past employed at minimum wage
// gen byte mw_future_not_current_not_past = (mw_future == 1 & mw_current == 0 & mw_past == 0)
// label var mw_future_not_current_not_past "Ind: Employed at minimum wage in future but not currently or in past?"
// drop mw_past mw_future

// * define income quantiles
// if "${gtools}" != "" gquantiles inc_q = inc, xtile n(100) by(year)
// else {
// 	disp as error "USER ERROR: Must use -gtools-!"
// 	error 1
// }
// label var inc_q "Earnings quantile, by year"
// drop inc

// * plot ever-MW share and its decomposition across income quantiles, overall
// ${gtools}collapse (mean) mw_ever_share=mw_ever mw_current_share=mw_current mw_past_not_current_share=mw_past_not_current mw_future_not_current_not_past_s=mw_future_not_current_not_past, by(inc_q) fast
// label var mw_ever_share "Share ever employed at minimum wage"
// label var mw_current_share "Share currently employed at minimum wage"
// label var mw_past_not_current_share "Share in past but not currently employed at minimum wage"
// label var mw_future_not_current_not_past_s "Share in future but not currently or in past employed at minimum wage"
// local inc_q_list = ""
// foreach q of numlist 5(5)95 {
// 	local inc_q_list = "`inc_q_list',`q'"
// }
// tw ///
// 	(connected mw_ever_share inc_q if inlist(inc_q`inc_q_list'), mcolor(blue) lcolor(blue) msymbol(O) lpattern(l _ - longdash_dot)) ///
// 	, xlabel(0(10)100, grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(0(.1).6, grid gstyle(dot) gmin gmax format(%2.1f)) ///
// 	xtitle("Income percentile") ytitle("Share ever employed at minimum wage, ${year_est_default_mid}-${year_max}") ///
// 	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 	name(mw_ever_share_all_model, replace)
// graph export "${DIR_RESULTS}/${section}/mw_ever_share_all_model.pdf", replace
// tw ///
// 	(connected mw_ever_share mw_current_share mw_past_not_current_share mw_future_not_current_not_past_s inc_q if inlist(inc_q`inc_q_list'), mcolor(blue blue%70 blue%50 blue%30) lcolor(blue blue%70 blue%50 blue%30) msymbol(O D T S) lpattern(l _ - longdash_dot)) ///
// 	, xlabel(0(10)100, grid gstyle(dot) gmin gmax format(%3.0f)) ylabel(0(.1).6, grid gstyle(dot) gmin gmax format(%2.1f)) ///
// 	xtitle("Income percentile") ytitle("Minimum wage share of all jobs, ${year_est_default_mid}-${year_max}") ///
// 	legend(order(1 "Ever (present, past, or future)" 2 "Present" 3 "Past, not present" 4 "Future, not present or past") region(color(none)) symxsize(*.66) cols(2)) ///
// 	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
// 	name(mw_ever_share_all_model_decomp, replace)
// graph export "${DIR_RESULTS}/${section}/mw_ever_share_all_model_decomp.pdf", replace





*** hours distribution
foreach y in $year_est_default_mid $year_max {

	* call user-defined function to load all data (including MW spells)
	do "${DIR_DO}/FUN_LOAD.do" `y' `y' "persid ${empid_var} gender age earn_mean_mw hours state"
	drop persid ${empid_var}
	
	* rename variables
	rename earn_mean_mw inc
	
	* keep only nonmissing and nonzero incomes
	keep if inc > 0 & inc < .
	
	* keep only men
	keep if inrange(gender, ${gender_min}, ${gender_max})
	drop gender
	
	* keep only prime-age workers
	keep if inrange(age, ${age_min}, ${age_max})
	drop age
	
	* apply time-invariant upper-income winsorizing
	replace inc = min(inc, 120) if inc < .

	* recast income variable to lower precision
	recast float inc, force
	
	* generate full-time indicator
	gen byte full_time = (hours >= 40) if hours < .
	
	* save hours data
	order hours inc
	prog_comp_desc_sum_save "${DIR_TEMP}/RAIS/temp_rais_hours_`y'_`y'.dta"
}

* append years
clear
gen int year = .
label var year "Year"
foreach y in $year_est_default_mid $year_max {
	append using "${DIR_TEMP}/RAIS/temp_rais_hours_`y'_`y'.dta"
	replace year = `y' if year == .
	rm "${DIR_TEMP}/RAIS/temp_rais_hours_`y'_`y'.dta"
}

* plot histograms of contractual work hours
foreach y in $year_est_default_mid $year_max {
	tw ///
		(hist hours if year == `y' & inrange(hours, 1, 59), discrete color(blue%50) lcolor(blue%0)), ///
		xlabel(0(5)60, grid gstyle(dot) format(%2.0f)) ylabel(0(.1).9, grid gstyle(dot) format(%2.1f)) ///
		xtitle("Contractual hours") ytitle("Density") ///
		plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
		name(hours_hist_`y', replace)
	graph export "${DIR_RESULTS}/${section}/hours_hist_`y'.pdf", replace
}

* collapse
replace inc = ln(inc)
${gtools}collapse ///
	(mean) full_time_share=full_time hours_mean=hours ///
	(p50) kaitz_p50=inc ///
	(count) N=inc ///
	, by(state year) fast
label var full_time_share "Share in full-time employment"
replace kaitz_p50 = -kaitz_p50
label var kaitz_p50 "P50-Kaitz index, log(MW/P50)"
label var N "Number of jobs"

* plot full-time share and mean contractual work hours against P50-Kaitz index
tw ///
	(scatter hours_mean kaitz_p50 [aw=N] if year == ${year_est_default_mid}, msymbol(Oh) mcolor(blue)) ///
	(scatter hours_mean kaitz_p50 [aw=N] if year == ${year_max}, msymbol(Oh) mcolor(red)) ///
	, xlabel(-2(.4)0, grid gstyle(dot) gmin gmax format(%3.1f)) ylabel(0(10)50, grid gstyle(dot) gmin gmax format(%3.0f)) ///
	xtitle("P50-Kaitz index, log(MW/P50)") ytitle("Mean contractual hours") ///
	legend(order(1 "${year_est_default_mid}" 2 "${year_max}") cols(2) region(color(none))) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(hours_kaitz_p50_mean, replace)
qui graph export "${DIR_RESULTS}/${section}/hours_kaitz_p50_mean.pdf", replace
tw ///
	(scatter full_time_share kaitz_p50 [aw=N] if year == ${year_est_default_mid}, msymbol(Oh) mcolor(blue)) ///
	(scatter full_time_share kaitz_p50 [aw=N] if year == ${year_max}, msymbol(Oh) mcolor(red)) ///
	, xlabel(-2(.4)0, grid gstyle(dot) gmin gmax format(%3.1f)) ylabel(0(.2)1, grid gstyle(dot) gmin gmax format(%3.1f)) ///
	xtitle("P50-Kaitz index, log(MW/P50)") ytitle("Share in full-time employment") ///
	legend(order(1 "${year_est_default_mid}" 2 "${year_max}") cols(2) region(color(none))) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(hours_kaitz_p50_full_time_share, replace)
qui graph export "${DIR_RESULTS}/${section}/hours_kaitz_p50_full_time_share.pdf", replace


*** log earnings across percentiles -- overall
* load data
use year inc_p* using "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_overall.dta", clear

* keep relevant years
keep if inlist(year, ${year_est_default_mid}, ${year_max})

* reshape data
reshape long inc_p, i(year) j(perc)
rename inc_p inc

* plot
tw ///
	(connected inc perc if year == ${year_est_default_mid} & mod(perc, 10) == 0, lcolor(blue) mcolor(blue) msymbol(O) lpattern(l)) ///
	(connected inc perc if year == ${year_max} & mod(perc, 10) == 0, lcolor(red) mcolor(red) msymbol(D) lpattern(_)) ///
	, xlabel(, grid gstyle(dot) gmin gmax format(%2.0f)) ylabel(0(.5)3.0, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("") ytitle("Log earnings relative to current MW (0.0 = MW)") ///
	legend(order(1 "${year_est_default_mid}" 2 "${year_max}") region(color(none)) cols(2)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(inc_perc, replace)
graph export "${DIR_RESULTS}/${section}/inc_perc.pdf", replace


*** log earnings across percentiles -- state level
* load data
use state year inc_p* if inlist(year, ${year_est_default_mid}, ${year_max}) using "${DIR_TEMP}/RAIS/percentiles_${year_data_min}_${year_data_max}_state.dta", clear

* reshape data
reshape long inc_p, i(state year) j(perc)
rename inc_p inc

* plot
local plot_1 = ""
local plot_2 = ""
${gtools}levelsof state, local(states_list)
foreach s of local states_list {
	local color_transparency = round(100 - (100/27)*(`s' - 1))
	local plot_1 = "`plot_1' (connected inc perc if year == ${year_est_default_mid} & mod(perc, 10) == 0 & state == `s', lcolor(blue%`color_transparency') mcolor(blue%`color_transparency') msymbol(Oh) lpattern(l))"
	local plot_2 = "`plot_2' (connected inc perc if year == ${year_max} & mod(perc, 10) == 0 & state == `s', lcolor(red%`color_transparency') mcolor(red%`color_transparency') msymbol(Dh) lpattern(_))"
}
disp "plot 1 = `plot_1'"
disp "plot 2 = `plot_2'"
tw ///
	`plot_1' ///
	`plot_2' ///
	, xlabel(, grid gstyle(dot) gmin gmax format(%2.0f)) ylabel(0(.5)3.0, grid gstyle(dot) gmin gmax format(%2.1f)) ///
	xtitle("") ytitle("Log earnings relative to current MW (0.0 = MW)") ///
	legend(order(1 "States in ${year_est_default_mid}" 28 "States in ${year_max}") region(color(none)) cols(2)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(inc_perc_state, replace)
graph export "${DIR_RESULTS}/${section}/inc_perc_state.pdf", replace


*** how much do wages in multiples of the minimum wage change: histograms and variance decomposition
* load data
do "${DIR_DO}/FUN_LOAD.do" 1994 1998 "persid ${empid_var} gender age earn_mean_mw year hours_year hire_month sep_month occ02_6"

* rename and recast variables
rename earn_mean_mw inc_mw
recast float inc_mw, force
rename occ02_6 occ
rename ${empid_var} empid

* keep only men
keep if inrange(gender, ${gender_min}, ${gender_max})
drop gender

* keep only prime-age workers
keep if inrange(age, ${age_min}, ${age_max})
drop age

* keep only nonmissing monthly earning
keep if inc_mw < .

* keep only highest-paid among all longest employment spells
bys persid year (hours_year inc_mw): keep if _n == _N
drop hours_year

* merge in minimum wage time series
merge m:1 year hire_month sep_month using "${DIR_MW_MONTHLY}", nogen keepusing(mw) keep(master match)
drop hire_month sep_month

* generate monthly earnings in BRL
gen float inc = inc_mw*mw
label var inc "Mean monthly earnings (current BRL)"
drop mw

* compute log earnings in current BRL
gen float inc_ln = ln(inc)
label var inc_ln "Log mean monthly earnings (log current BRL)"

* compute log earnings in multiples of MW
gen float inc_mw_ln = ln(inc_mw)
label var inc_mw_ln "Log mean monthly earnings (log multiples of the MW)"

* set panel
xtset persid year

* compute differences in log earnings (current BRL)
gen double D_inc = D.inc // = inc - L.inc
label var D_inc "1-year difference in monthly earnings (current BRL)"

* compute differences in log earnings (multiples of MW)
gen double D_inc_mw = D.inc_mw // = inc_mw - L.inc_mw
label var D_inc_mw "1-year difference in monthly earnings (multiples of MW)"

* compute differences in log earnings (current BRL, logs)
gen double D_inc_ln = D.inc_ln // = inc_ln - L.inc_ln
label var D_inc_ln "1-year difference in log earnings (current BRL, logs)"

* compute differences in log earnings (multiples of MW, logs)
gen double D_inc_mw_ln = D.inc_mw_ln // = inc_mw_ln - L.inc_mw_ln
label var D_inc_mw_ln "1-year difference in log earnings (multiples of MW, logs)"

* generate indicator for stayer in same occupation
gen byte stayer_occ = (occ == L.occ)
label var stayer_occ "Ind: same occupation as last year?"

* generate indicator for stayer in same occupation
gen byte stayer_empid = (empid == L.empid)
label var stayer_empid "Ind: same employer as last year?"

* summarize differences in earnings (current BRL and multiples of MW, levels and logs)
sum D_inc D_inc_mw, d
sum D_inc_ln D_inc_mw_ln, d

* compute share with constant wage between two consecutive years
foreach var of varlist D_inc D_inc_mw D_inc_ln D_inc_mw_ln {
	disp _newline(1)
	qui count if `var' < .
	local N = r(N)
	qui count if `var' == 0
	local N_no_change = r(N)
	local share_no_change: di %3.1f 100*`N_no_change'/`N'
	disp as result "share with `var' = 0: `share_no_change'%"
	qui count if `var' > -.01 & `var' < .01
	local N_approx_no_change = r(N)
	local share_approx_no_change: di %3.1f 100*`N_approx_no_change'/`N'
	disp as result "share with `var' approx. = 0: `share_approx_no_change'%"
}

* generate normalized wage variables
foreach var of varlist inc_ln inc_mw_ln {
	sum `var', meanonly
	gen float `var'_norm = `var' - r(mean)
	local l: variable label `var'
	label var `var'_norm "Normalized `l'"
}

* histograms of differences in earnings (multiples of MW), ${year_est_default_mid} and ${year_max}
// tw ///
// 	(hist D_inc if inrange(D_inc, -750, 750) & inrange(year, 1994, 1998), start(-760) width(20) fcolor(blue%50) lcolor(blue%0)) /// (hist D_inc if inrange(D_inc, -750, 750) & inrange(year, 2010, 2014), start(-510) width(20) fcolor(red%50) lcolor(red%0)) ///
// 	, xlabel(-750(250)750, format(%4.0f) gmin gmax grid gstyle(dot)) ylabel(0(.001).007, format(%4.3f) gmin gmax grid gstyle(dot)) ///
// 	xtitle("One-year change in wage (current BRL)") ytitle("Density") ///
// 	legend(off) /// order(1 "1994-1998" 2 "2010-2014") region(color(none)) cols(2)
// 	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
// 	name(hist_D_inc_1994_1998, replace)
// graph export "${DIR_RESULTS}/${section}/hist_D_inc_1994_1998.pdf", replace
// tw ///
// 	(hist D_inc_mw if inrange(D_inc_mw, -5, 5) & inrange(year, 1994, 1998), start(-5.1) width(.2) fcolor(blue%50) lcolor(blue%0)) /// (hist D_inc_mw if inrange(D_inc_mw, -5, 5) & inrange(year, 2010, 2014), start(-5.1) width(.2) fcolor(red%50) lcolor(red%0)) ///
// 	, xlabel(-5(1)5, format(%1.0f) gmin gmax grid gstyle(dot)) ylabel(0(.2)1, format(%2.1f) gmin gmax grid gstyle(dot)) ///
// 	xtitle("One-year change in wage (multiples of MW)") ytitle("Density") ///
// 	legend(off) /// order(1 "1994-1998" 2 "2010-2014") region(color(none)) cols(2)
// 	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
// 	name(hist_D_inc_mw_1994_1998, replace)
// graph export "${DIR_RESULTS}/${section}/hist_D_inc_mw_1994_1998.pdf", replace
// tw ///
// 	(hist D_inc_ln if inrange(D_inc_ln, -1.5, 1.5) & inrange(year, 1994, 1998), start(-1.53) width(.06) fcolor(blue%50) lcolor(blue%0)) /// (hist D_inc_ln if inrange(D_inc_ln, -1.5, 1.5) & inrange(year, 2010, 2014), start(-1.53) width(.06) fcolor(red%50) lcolor(red%0)) ///
// 	, xlabel(-1.5(.5)1.5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.5)2.5, format(%2.1f) gmin gmax grid gstyle(dot)) ///
// 	xtitle("One-year change in log wage (log current BRL)") ytitle("Density") ///
// 	legend(off) /// order(1 "1994-1998" 2 "2010-2014") region(color(none)) cols(2)
// 	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
// 	name(hist_D_inc_ln_1994_1998, replace)
// graph export "${DIR_RESULTS}/${section}/hist_D_inc_ln_1994_1998.pdf", replace
// tw ///
// 	(hist D_inc_mw_ln if inrange(D_inc_mw_ln, -1.5, 1.5) & inrange(year, 1994, 1998), start(-1.53) width(.06) fcolor(blue%50) lcolor(blue%0)) /// (hist D_inc_mw_ln if inrange(D_inc_mw_ln, -1.5, 1.5) & inrange(year, 2010, 2014), start(-1.53) width(.06) fcolor(red%50) lcolor(red%0)) ///
// 	, xlabel(-1.5(.5)1.5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.5)3.5, format(%2.1f) gmin gmax grid gstyle(dot)) ///
// 	xtitle("One-year change in log wage (log multiples of MW)") ytitle("Density") ///
// 	legend(off) /// order(1 "1994-1998" 2 "2010-2014") region(color(none)) cols(2)
// 	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
// 	name(hist_D_inc_mw_ln_1994_1998, replace)
// graph export "${DIR_RESULTS}/${section}/hist_D_inc_mw_ln_1994_1998.pdf", replace
tw ///
	(hist inc_ln_norm if inrange(inc_ln_norm, -2.5, 2.5) & inrange(year, 1994, 1998), start(-2.53) width(.1) fcolor(blue%50) lcolor(blue%0)) /// (hist inc_ln if inrange(inc_ln, -1.5, 1.5) & inrange(year, 2010, 2014), start(-1.53) width(.06) fcolor(red%50) lcolor(red%0)) ///
	(hist inc_mw_ln_norm if inrange(inc_mw_ln_norm, -2.5, 2.5) & inrange(year, 1994, 1998), start(-2.53) width(.1) fcolor(red%50) lcolor(red%0)) /// (hist inc_mw_ln if inrange(inc_mw_ln, -1.5, 1.5) & inrange(year, 2010, 2014), start(-1.53) width(.06) fcolor(red%50) lcolor(red%0)) ///
	, xlabel(-2.5(.5)2.5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.1).6, format(%2.1f) gmin gmax grid gstyle(dot)) ///
	xtitle("Log wage") ytitle("Density") ///
	legend(order(1 "Log current BRL" 2 "Log multiples of current minimum wage") region(color(none)) cols(2)) ///
	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
	name(hist_inc_ln_norm_comp_1994_1998, replace)
graph export "${DIR_RESULTS}/${section}/hist_inc_ln_norm_comp_1994_1998.pdf", replace
tw ///
	(hist D_inc_ln if inrange(D_inc_ln, -1.5, 1.5) & inrange(year, 1994, 1998), start(-1.53) width(.06) fcolor(blue%50) lcolor(blue%0)) /// (hist D_inc_ln if inrange(D_inc_ln, -1.5, 1.5) & inrange(year, 2010, 2014), start(-1.53) width(.06) fcolor(red%50) lcolor(red%0)) ///
	(hist D_inc_mw_ln if inrange(D_inc_mw_ln, -1.5, 1.5) & inrange(year, 1994, 1998), start(-1.53) width(.06) fcolor(red%50) lcolor(red%0)) /// (hist D_inc_mw_ln if inrange(D_inc_mw_ln, -1.5, 1.5) & inrange(year, 2010, 2014), start(-1.53) width(.06) fcolor(red%50) lcolor(red%0)) ///
	, xlabel(-1.5(.5)1.5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.5)3.5, format(%2.1f) gmin gmax grid gstyle(dot)) ///
	xtitle("One-year change in log wage") ytitle("Density") ///
	legend(order(1 "Log current BRL" 2 "Log multiples of current minimum wage") region(color(none)) cols(2)) ///
	graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
	name(hist_D_inc_ln_comp_1994_1998, replace)
graph export "${DIR_RESULTS}/${section}/hist_D_inc_ln_comp_1994_1998.pdf", replace

* drop variables no longer needed
drop inc_ln_norm inc_mw_ln_norm

* generate within-individual mean of wages
foreach var of varlist inc_ln inc_mw_ln D_inc_ln D_inc_mw_ln { // inc inc_mw D_inc D_inc_mw
	disp _newline(3)
	disp as result "--> variable = `var'"
	local l: variable label `var'
	foreach sel in "all" "stayer_occ" "stayer_empid" {
		disp _newline(1)
		disp as input "-----> selection: `sel'"
		if "`sel'" == "all" local and_if_cond = ""
		else if "`sel'" == "stayer_occ" local and_if_cond = "& stayer_occ == 1"
		else if "`sel'" == "stayer_empid" local and_if_cond = "& stayer_empid == 1"
		if "${gtools}" == "" qui bys persid: egen float `var'_mean = mean(`var') if `var' < . `and_if_cond'
		else qui gegen float `var'_mean = mean(`var') if `var' < . `and_if_cond', by(persid)
		label var `var'_mean "Within-person mean of `l'"
		qui gen float `var'_deviation = `var' - `var'_mean
		label var `var'_deviation "Within-person dispersion of `l'"
		if "`sel'" == "all" local if_cond = ""
		else if "`sel'" == "stayer_occ" local if_cond = "if stayer_occ == 1"
		else if "`sel'" == "stayer_empid" local if_cond = "if stayer_empid == 1"
		foreach var2 of varlist `var' `var'_mean `var'_deviation {
			qui sum `var2' `if_cond'
	// 		local vari_`var2' = r(Var)
			local vari_`var2': di %4.3f r(Var)
		}
		drop *_mean *_deviation
	// 	local vari_`var'_mean_s = 100*`vari_`var'_mean'/`vari_`var''
		local vari_`var'_mean_s: di %3.0f 100*`vari_`var'_mean'/`vari_`var''
	// 	local vari_`var'_deviation_s = 100*`vari_`var'_deviation'/`vari_`var''
		local vari_`var'_deviation_s: di %3.0f 100*`vari_`var'_deviation'/`vari_`var''
		disp as text "--------> variance = `vari_`var''"
		disp as text "-----------> variance of means = `vari_`var'_mean' (`vari_`var'_mean_s'%)"
		disp as text "-----------> variance of dispersion around mean = `vari_`var'_deviation' (`vari_`var'_deviation_s'%)"
	}
}


*** how important is between- vs. within-education-group wage heterogeneity
* load data
do "${DIR_DO}/FUN_LOAD.do" 1994 1998 "persid ${empid_var} gender age earn_mean_mw year edu hours hours_year occ02_6"

* rename and recast variables
rename earn_mean_mw inc_mw
recast float inc_mw, force
rename occ02_6 occ
rename ${empid_var} empid

* keep only men
keep if inrange(gender, ${gender_min}, ${gender_max})
drop gender

* keep only prime-age workers
keep if inrange(age, ${age_min}, ${age_max})

* keep only nonmissing monthly earning
keep if inc_mw > 0 & inc_mw < .

* keep only highest-paid among all longest employment spells
bys persid year (hours_year inc_mw): keep if _n == _N
drop hours_year

* generate log income
gen float inc_mw_ln = ln(inc_mw)
label var inc_mw_ln "Log wage (log multiples of MW)"
drop inc_mw

* compute education-level mean log wages
if "${gtools}" == "" bys edu: egen float inc_mw_ln_mean_by_edu = mean(inc_mw_ln)
else gegen float inc_mw_ln_mean_by_edu = mean(inc_mw_ln), by(edu)
label var inc_mw_ln_mean_by_edu "Education mean log wage"

* compute deviation from education-level mean log wages
gen float inc_mw_ln_within_edu = inc_mw_ln - inc_mw_ln_mean_by_edu
label var inc_mw_ln_within_edu "Log wage - education mean log wage"

* compute variance of log wages within vs. between education groups
foreach var of varlist inc_mw_ln inc_mw_ln_mean_by_edu inc_mw_ln_within_edu {
	qui sum `var'
	local vari_`var': di %4.3f r(Var)
}
local vari_between_edu_s: di %3.0f 100*`vari_inc_mw_ln_mean_by_edu'/`vari_inc_mw_ln'
local vari_within_edu_s: di %3.0f 100*`vari_inc_mw_ln_within_edu'/`vari_inc_mw_ln'
disp as text "--------> variance = `vari_inc_mw_ln'"
disp as text "-----------> variance between education groups = `vari_inc_mw_ln_mean_by_edu' (`vari_between_edu_s'%)"
disp as text "-----------> variance within education groups = `vari_inc_mw_ln_within_edu' (`vari_within_edu_s'%)"

* various regressions
reghdfe inc_mw_ln, a(i.edu##i.age i.edu##i.year i.hours i.occ)
reghdfe inc_mw_ln, a(i.edu##i.age i.edu##i.year i.hours i.occ i.empid)
reghdfe inc_mw_ln, a(i.edu##i.age i.edu##i.year i.hours i.occ i.persid)
reghdfe inc_mw_ln, a(i.edu##i.age i.edu##i.year i.hours i.occ i.empid i.persid)
