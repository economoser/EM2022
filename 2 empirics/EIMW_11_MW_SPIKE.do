********************************************************************************
* DESCRIPTION: Estimate minimum-wage spike in raw earnings distribution.
*
* NOTE:        Potentially need to edit years that are hard-coded in!
********************************************************************************


*** macros
global plot_step_size = 5


*** how does size of minimum wage spike change with various sample selections?
* open postfile
cap postclose mw_spike_sel
postfile mw_spike_sel ///
	year share_mw_raw share_mw_sel share_mw_con ///
	using "${DIR_RESULTS}/${section}/mw_spike_sel.dta", replace

* loops through years
forval y = $year_min/$year_max {

	* raw data
	use earn_mean_mw using "${DIR_WRITE}/`y'/${sample_prefix}clean`y'.dta", clear
	prog_share_mw "earn_mean_mw"
	local share_mw_raw = r(share)
	
	* load data
	do "${DIR_DO}/FUN_LOAD.do" `y' `y' "persid $empid_var gender age earn_mean_mw"
	keep earn_mean_mw
	prog_share_mw "earn_mean_mw"
	local share_mw_sel = r(share)
	
	* after additional selection criteria and restriction to connected set (unrestricted, incl. MW jobs)
	if inrange(`y', 1985,1989) local y1 = 1985
	else if inrange(`y', 1990,1993) local y1 = 1990
	else if inrange(`y', 1994,1997) local y1 = 1994
	else if inrange(`y', 1998,2001) local y1 = 1998
	else if inrange(`y', 2002,2005) local y1 = 2002
	else if inrange(`y', 2006,2009) local y1 = 2006
	else if inrange(`y', 2010,2013) local y1 = 2010
	else if inrange(`y', 2014,2018) local y1 = 2014
	else {
		disp as error "USER ERROR: Year `y' falls outside valid range 1985-2018."
		error 1
	}
	local y2 = `y1'+ 4
	cap confirm file "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta"
	if !_rc {
		use inc_lvl year if year == `y' using "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta", clear
		keep inc_lvl
		prog_share_mw "inc_lvl"
		local share_mw_con = r(share)
	}
	else {
		disp as error "USER WARNING: Could not find AKM estimates for year `y' (period `y1'-`y2')!"
		local share_mw_con = .
	}
	
	* post to postfile
	post mw_spike_sel ///
		(`y') (`share_mw_raw') (`share_mw_sel') (`share_mw_con')
}

* close postfile
postclose mw_spike_sel

* format postfile
use "${DIR_RESULTS}/${section}/mw_spike_sel.dta", clear
label var year "Year"
label var share_mw_raw "Share of MW jobs in raw data"
label var share_mw_sel "Share of MW jobs after imposing selection criteria"
label var share_mw_con "Share of MW jobs in connected set"
save "${DIR_RESULTS}/${section}/mw_spike_sel.dta", replace

* format variables
foreach var of varlist share* {
	replace `var' = `var'*100
	local lab: variable label `var'
	label var `var' "`lab' (%)"
}

* plot MW share over time subject to different selection criteria
sum year, meanonly
local year_plot_min = floor(r(min)/${plot_step_size})*${plot_step_size}
local year_plot_max = ceil(r(max)/${plot_step_size})*${plot_step_size}
tw ///
	(connected share_mw_raw share_mw_sel share_mw_con year, mcolor(blue red green) lcolor(blue red green) lpattern(l _ -) msymbol(O D S)) ///
	, xlabel(`year_plot_min'(${plot_step_size})`year_plot_max', grid gstyle(dot) gmin gmax) ylabel(0(1)4, format(%1.0f) grid gstyle(dot) gmin gmax) ///
	xtitle("") ytitle("Share of observations earning minimum wage (%)") ///
	legend(order(1 "Raw" 2 "Selection" 3 "Connected set") region(lcolor(white)) cols(3)) ///
	plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) graphregion(color(white)) ///
	name(share_mw_year, replace)
graph export "${DIR_RESULTS}/${section}/share_mw_year.eps", replace


*** create earnings histograms for largest connected set
* loop through periods
foreach y of numlist $year_min $year_max {
	
	* confirm that AKM estimates exist
	if inrange(`y', 1985,1989) local y1 = 1985
	else if inrange(`y', 1990,1993) local y1 = 1990
	else if inrange(`y', 1994,1997) local y1 = 1994
	else if inrange(`y', 1998,2001) local y1 = 1998
	else if inrange(`y', 2002,2005) local y1 = 2002
	else if inrange(`y', 2006,2009) local y1 = 2006
	else if inrange(`y', 2010,2013) local y1 = 2010
	else if inrange(`y', 2014,2018) local y1 = 2014
	else {
		disp as error "USER ERROR: Year `y' falls outside valid range 1985-2018."
		error 1
	}
	local y2 = `y1'+ 4
	cap confirm file "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta"
	if !_rc {
		
		* load data
		use inc_ln inc_lvl year if year == `y' using "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta", clear
		keep inc_ln inc_lvl

		* produce counts
		assert inc_lvl < . & inc_ln < .
		qui count
		local N = r(N)
		qui count if inc_lvl == 1
		local N_MW = r(N)
		local MW_share = `N_MW'/`N'
		local MW_share_perc : di %3.1f `=100*`MW_share''
		disp "--> share of workers earning MW = `MW_share_perc'%"

		* plot histogram of earnings
		tw (hist inc_lvl if inrange(inc_lvl, 0, 20), start(`=float(0)') width(`=float(.5)') fcolor(blue) lcolor(white)), ///
			xline(1, lwidth(thick) lpattern(_) lcolor(red)) ///
			xlabel(0(2)20, format(%3.0f) gmin gmax grid gstyle(dot)) ylabel(0(.05).51, format(%3.2f) gmin gmax grid gstyle(dot)) ///
			xtitle("Earnings (multiples of MW)") ytitle("Density") ///
			graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
			name(hist_spike_`y1'_`y2', replace)
		graph export "${DIR_RESULTS}/${section}/hist_spike_`y1'_`y2'.eps", replace

		* plot histogram of earnings zoomed in around MW
		tw (hist inc_lvl if inrange(inc_lvl, .99, 1.25), start(`=float(.99)') width(`=float(.01)') fcolor(blue) lcolor(white)), ///
			xline(1, lwidth(thick) lpattern(_) lcolor(red)) ///
			xlabel(0.99(.01)1.25, format(%3.2f) angle(90) gmin gmax grid gstyle(dot)) ylabel(0(3)24, format(%2.0f) gmin gmax grid gstyle(dot)) ///
			xtitle("Earnings (multiples of MW)") ytitle("Density") ///
			graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
			name(hist_spike_zoom_`y1'_`y2', replace)
		graph export "${DIR_RESULTS}/${section}/hist_spike_zoom_`y1'_`y2'.eps", replace

		* plot histogram of log earnings
		tw (hist inc_ln if inrange(inc_ln, 0, 5), start(`=float(0)') width(`=float(.1)') fcolor(blue) lcolor(white)), ///
			xline(0, lwidth(thick) lpattern(_) lcolor(red)) ///
			xlabel(0(.5)5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.08).8, format(%3.2f) gmin gmax grid gstyle(dot)) ///
			xtitle("Earnings (log multiples of MW)") ytitle("Density") ///
			graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
			name(hist_spike_ln_`y1'_`y2', replace)
		graph export "${DIR_RESULTS}/${section}/hist_spike_ln_`y1'_`y2'.eps", replace

		* plot kernel density of earnings
		tw (kdensity inc_lvl if inrange(inc_lvl, 0, 20), n(200) lwidth(thick) lpattern(l) lcolor(blue)), ///
			xline(1, lwidth(thick) lpattern(_) lcolor(red)) ///
			xlabel(0(2)20, format(%3.0f) gmin gmax grid gstyle(dot)) ylabel(0(.05).5, format(%3.2f) gmin gmax grid gstyle(dot)) ///
			xtitle("Earnings (multiples of MW)") ytitle("Density") ///
			graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
			name(kdens_spike_`y1'_`y2', replace)
		graph export "${DIR_RESULTS}/${section}/kdens_spike_`y1'_`y2'.eps", replace

		* plot kernel density of earnings zoomed in around MW
		tw (kdensity inc_lvl if inrange(inc_lvl, .99, 1.2), n(100) lwidth(thick) lpattern(l) lcolor(blue)), ///
			xline(1, lwidth(thick) lpattern(_) lcolor(red)) ///
			xlabel(0.99(.01)1.2, format(%3.2f) angle(90) gmin gmax grid gstyle(dot)) ylabel(0(3)24, format(%2.0f) gmin gmax grid gstyle(dot)) ///
			xtitle("Earnings (multiples of MW)") ytitle("Density") ///
			graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
			name(kdens_spike_zoom_`y1'_`y2', replace)
		graph export "${DIR_RESULTS}/${section}/kdens_spike_zoom_`y1'_`y2'.eps", replace
			
		* plot kernel density of log earnings
		tw (kdensity inc_ln if inrange(inc_ln, 0, 5), n(200) lwidth(thick) lpattern(l) lcolor(blue)), ///
			xline(0, lwidth(thick) lpattern(_) lcolor(red)) ///
			xlabel(0(.5)5, format(%2.1f) gmin gmax grid gstyle(dot)) ylabel(0(.08).8, format(%3.2f) gmin gmax grid gstyle(dot)) ///
			xtitle("Earnings (log multiples of MW)") ytitle("Density") ///
			graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
			name(kdens_spike_ln_`y1'_`y2', replace)
		graph export "${DIR_RESULTS}/${section}/kdens_spike_ln_`y1'_`y2'.eps", replace
	}
	else disp as error "USER WARNING: Could not find AKM estimates for year `y' (period `y1'-`y2')!"
}


*** create histograms separately by year
* loop through years
// foreach y of varlist $year_data_min/$year_data_max {
// foreach y in $year_data_min $year_data_max {
// foreach y in $year_data_min {
foreach y in $year_data_min $year_min $year_data_max {
	
	* load data
	do "${DIR_DO}/FUN_LOAD.do" `y' `y' "gender age earn_mean_mw"
	keep earn_mean_mw
	rename earn_mean_mw earn
	replace earn = ln(earn)
	keep if inrange(earn, -1, 5)
	
	* plot histogram of earnings
	tw (hist earn, start(`=float(-1)') width(`=float(.1)') fcolor(blue) lcolor(white) lwidth(thin)), ///
		xline(0, lwidth(thick) lpattern(_) lcolor(red)) ///
		xlabel(-1(1)5, format(%1.0f) gmin gmax grid gstyle(dot)) ylabel(0(.2)1, format(%2.1f) gmin gmax grid gstyle(dot)) ///
		xtitle("Earnings (log multiples of MW)") ytitle("Density") ///
		graphregion(color(white)) plotregion(lcolor(black) margin(l=0 r=0 b=0 t=0)) ///
		name(hist_spike_`y', replace)
	graph export "${DIR_RESULTS}/${section}/hist_spike_`y'.eps", replace	
}
