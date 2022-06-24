********************************************************************************
* DESCRIPTION: Construct moments for model estimation.
********************************************************************************


*** section switches
* compute change in productivity-adjusted real MW
global section_mw_change = 1

* share in formal sector employment
global section_empstat = 1

* shares in minimum wage jobs and shares with both types of jobs in 5 year window
global section_shares = 1

* wage percentiles
global section_percentiles = 1

* firm size stats
global section_firmsize = 1

* akm stats
global section_akm = 1

* worker flows
global section_flows = 1

* combine and outsheet to matlab
global section_tomatlab = 1


*** directories and data files
* output directory specific to age group
if $age_group == 0 global DIR_EST_INPUTS_AGE = "${DIR_EST_INPUTS}/all"
else if $age_group == 1 global DIR_EST_INPUTS_AGE = "${DIR_EST_INPUTS}/young"
else if $age_group == 2 global DIR_EST_INPUTS_AGE = "${DIR_EST_INPUTS}/old"
cap n {
	!rm -r "${DIR_EST_INPUTS_AGE}"
}
!mkdir "${DIR_EST_INPUTS_AGE}"

* PNAD data of men aged 18-54 including non-employed (incl. informal sector)
* 	- this data set is cross-sectional 1996-2000
*	- data have to contain the following variables:
*			empstat: coded empstat = 0*(not employed & informal employed) + 1*(formal employed & wage ~= MW) + 2*(formal employed & wage == MW)
*					 note that empstat = 1 includes also those earning LESS than MW (just not exactly MW)!
*			weight: relevant individual survey weight (ensure weight is consistent across years of PNAD)
*			year
global FILE_EST_PNAD = "${DIR_TEMP}/PNAD/est_pnad_${year_est_default_mid}_${year_est_default_mid}.dta"

* RAIS data of men aged 18-54 for full sample
*	- expanded to have one observation per month for each individual who is in the data at any point from ${year_est_default_min}-${year_est_default_max}
* 	- data have to contain the following variables:
* 			empstat: coded as in PNAD above
*			id
*			date: concatenation of year and month
*			year
*			empid 
* 	- please ensure that the data is consistent with my comments COMMENT1 and COMMENT2 below
global FILE_EST_MONTHLY = "${DIR_TEMP}/RAIS/est_rais_monthly"

* RAIS data of men aged 18-54 for full sample
* 	- conditions on:
*		(1) drop missing wages but no size, largest set or minimum wage thresholds
* 	- this data set is at worker-year level ${year_est_default_min}-${year_est_default_max}
* 	- data have to contain the following variables:
* 			fsize: count of workers with particular firm as main employer in year
*			empid
*			year
*			inc
global FILE_EST_FSIZE = "${DIR_TEMP}/RAIS/est_rais_fsize"

* RAIS data of men aged 18-54 for largest connected set with AKM effects
* 	- conditions on (in exactly this order):
*		(1) drop missing (log) wages
*		(2) keep only firm-years where firm has 10 or more employees
*		(3) keep only worker-years earning strictly above the minimum wage
*		(4) keep only worker-years part of the largest connected set
* 	- this data set is at worker-year level 1996-2000
* 	- data have to contain the following variables:
*			id
*			inc
*			pe
*			fe
*			resid
global FILE_EST_AKM_ESTIMATES = "${DIR_TEMP}/RAIS/est_rais_akm_estimates"

* AKM decomposition of log wages based on RAIS data of men aged 18-54 for largest connected set
global FILE_EST_AKM_DECOMPOSITION = "${DIR_TEMP}/RAIS/est_rais_akm_decomposition"


*** automatically set macros
* check that estimation and simulation do not coincide
assert (${year_est_default_min} != ${year_sim_default_min}) | (${year_est_default_max} != ${year_sim_default_max})

* create list of first and last years
global y1_list = "${year_est_default_min} ${year_sim_default_min}" // "${year_est_min} ${year_sim_min}"
global y2_list = "${year_est_default_max} ${year_sim_default_max}" // "${year_est_max} ${year_sim_max}"

* compute number of start/end years to loop through 
local N_list: word count ${y1_list}


*** compute "productivity-adjusted" real MW change
if $section_mw_change {

	* set base year and last year
	local year_base_min = ${year_est_default_min} // e.g., 1994
	local year_base_max = ${year_est_default_max} // e.g., 1998
	local year_last = ${year_sim_default_max} // e.g., 2018

	* define GDP concept
	local var_gdp = "gdp_pc_const_lcu" // "gdp_pc_const_lcu" = GDP per capita in constant LCU; "gdp_pc_const_ppp" = GDP per capita in constant PPP international dollars; "gdp_pc_real_lcu" = GDP per capita in real LCU; "gdp_pc_real_ppp" = GDP per capita in PPP international dollars

	* load MW data
	use "${DIR_TEMP}/IPEA/mw_real_yearly.dta", clear

	* keep relevant years
	keep if inrange(year, ${year_data_min}, ${year_data_max})

	* generate log MW
	gen float mw_real_ln = ln(mw_real)
	label var mw_real_ln "Log real minimum wage (constant September 2021 BRL)"
	drop mw_real

	* compute change in log real MW since base year
	sum mw_real_ln if inrange(year, `year_base_min', `year_base_max'), meanonly
	gen float mw_real_ln_change = mw_real_ln - r(mean)
	label var mw_real_ln_change "Change in log real MW since `year_base_min'-`year_base_max' (constant September 2021 BRL)"

	* merge in GDP per capita data
	merge 1:1 year using "${DIR_CONVERSION}/gdp/gdp.dta", keep(master match) keepusing(`var_gdp') nogen
	rename `var_gdp' gdp_pc_real
	label var gdp_pc_real "Real GDP per capita"

	* compute log real GDP per capita
	gen float gdp_pc_real_ln = ln(gdp_pc_real)
	label var gdp_pc_real_ln "Log real GDP per capita"
	drop gdp_pc_real

	* compute change in log real GDP per capita since base year
	sum gdp_pc_real_ln if inrange(year, `year_base_min', `year_base_max'), meanonly
	gen float gdp_pc_real_ln_change = gdp_pc_real_ln - r(mean)
	label var gdp_pc_real_ln_change "Change in log real GDP per capita since `year_base_min'-`year_base_max'"

	* compute change in productivity-adjusted real MW since base year
	gen float mw_real_ln_prod_change = mw_real_ln_change - gdp_pc_real_ln_change
	label var mw_real_ln_prod_change "Change in log real productivity-adjusted MW since `year_base_min'-`year_base_max'"

	* store change in productivity-adjusted real MW since base year
	keep if year == `year_last'
	keep mw_real_ln_prod_change
	sum mw_real_ln_prod_change, meanonly
	global mw_change = r(mean)
	disp "--> Change in real productivity-adjusted MW = ${mw_change}"
	rename mw_real_ln_prod_change mw_change
	export delim using "${DIR_RESULTS}/${section}/mw_change.csv", replace
}
else global mw_change = ""


*** define initial and final MW levels, and create list of MWs
global mw_initial = exp(0) // Note: The log MW is normalized to 0 in the initial period.
if "$mw_change" == "" global mw_final = exp(.5861435) // Note: By default, relative to the initial period, MW increases by 58.6 log points.
else global mw_final = exp(${mw_change}) // Note: If otherwise specified, relative to the initial period, MW increases by some specified amount.
global mw_list = "${mw_initial}  ${mw_final}"


*** execute code
if $section_empstat {

// 	****************************************************************************
// 	* (1A) Share of employed from PNAD
// 	use empstat year weight if year >= 1996 & year <= 2000 & empstat < . & weight < . & weight > 0 using "${FILE_EST_PNAD}", clear
// 	drop year
// 	compress

// 	* compute employment share (at any wage including at or below MW)
// 	gen byte e = inlist(empstat,1,2)

// 	${gtools}collapse ///
// 		(mean) e ///
// 		[aw=weight] ///
// 		, fast

// 	compress
// 	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/empstat_pnad.dta"
// 	****************************************************************************


	****************************************************************************
	* (1B) Share of employed from RAIS
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
	
		* load data
		if $age_group == 0 use empstat using "${FILE_EST_MONTHLY}_`y1'_`y2'.dta", clear
		else if inlist(${age_group}, 1, 2) {
			use persid year empstat using "${FILE_EST_MONTHLY}_`y1'_`y2'.dta", clear
			merge m:1 persid year using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
			drop persid year
			keep if inrange(age, ${age_min}, ${age_max})
			drop age
		}
				
		* compute employment share (at any wage including at or below MW)
		gen byte e = inlist(empstat,1,2)

		${gtools}collapse ///
			(mean) e ///
			, fast
		
		if `y1' == $year_est_default_min gen byte period = 1
		else if `y1' == $year_sim_default_min gen byte period = 2
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
		
		compress
		save "${DIR_TEMP}/empstat_`y1'_`y2'.dta", replace
	}

	clear
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		append using "${DIR_TEMP}/empstat_`y1'_`y2'.dta"
		rm "${DIR_TEMP}/empstat_`y1'_`y2'.dta"
	}
	
	order period e
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/empstat_rais.dta"
	****************************************************************************
	
}


if $section_shares {

	****************************************************************************
	* (2) Share of minimum wage employed and aggregate flows
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
	
		* load data
		if $age_group == 0 use persid date empstat using "${FILE_EST_MONTHLY}_`y1'_`y2'.dta", clear
		if inlist(${age_group}, 1, 2) {
			use persid year date empstat using "${FILE_EST_MONTHLY}_`y1'_`y2'.dta", clear
			merge m:1 persid year using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
			drop year
			keep if inrange(age, ${age_min}, ${age_max})
			drop age
		}
		
		* rename variables
		rename persid id

		* code for empstat
		* 0 = not employed
		* 1 = employed at wage != MW (note that this includes workers earning < MW)
		* 2 = employed at wage == MW
		gen byte e = (empstat == 1)
		gen byte m = (empstat == 2)
		drop empstat
		
		* workers who have been both regularly employed and MW employed during 5-year period but at different employers
		gegen byte me1 = max(e), by(id)
		gegen byte me2 = max(m), by(id)
		gen byte me = me1 == 1 & me2 == 1
		drop me1 me2

		* keep one observation per individual
		bys id (date): keep if _n == _N

		${gtools}collapse ///
			(mean) me ///
			(sum) e m ///
			, fast

		replace m = m/(m + e)
		drop e

		if `y1' == $year_est_default_min gen byte period = 1
		else if `y1' == $year_sim_default_min gen byte period = 2
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
		
		compress
		save "${DIR_TEMP}/mw_`y1'_`y2'.dta", replace
	}
	
	clear
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		append using "${DIR_TEMP}/mw_`y1'_`y2'.dta"
		rm "${DIR_TEMP}/mw_`y1'_`y2'.dta"
	}
	
	order period me m
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/mw.dta"
	****************************************************************************

}


if $section_percentiles {

	****************************************************************************
	* (3) Wage percentiles and distribution
	
	
	*** compute wage percentiles
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		
		* load data
		if $age_group == 0 use persid empid_est inc using "${FILE_EST_FSIZE}_`y1'_`y2'.dta", clear
		if inlist(${age_group}, 1, 2) {
			use persid year empid_est inc using "${FILE_EST_FSIZE}_`y1'_`y2'.dta", clear
			merge m:1 persid year using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
			drop year
			keep if inrange(age, ${age_min}, ${age_max})
			drop age
		}
		
		* rename variables
		rename persid id
		rename empid_est empid
		rename inc wage
		replace wage = ln(wage)
		
		* take out year effects
	// 	qui reghdfe wage, a(year) resid
	// 	qui predict rwage, r
	// 	drop wage

		* wage percentiles
		qui sum wage, d
		local p50=r(p50)
		gquantiles ///
			wage ///
			, _pctile percentiles(5(5)95)
		local i = 5
		forvalues pp = 1/19 {
			gen float wage_p`i'_50 = r(r`pp')-`p50'
			local i=`i' + 5
		}
		drop wage_p50_50
		
		* minimum wage is normalized s.t. ln(MW) = 0
		gen float wage_p50_min = `p50'

		${gtools}collapse  ///
			(mean) wage_* ///
			, fast

		if `y1' == $year_est_default_min gen byte period = 1
		else if `y1' == $year_sim_default_min gen byte period = 2
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
		
		compress
		save "${DIR_TEMP}/wage_percentiles_`y1'_`y2'.dta", replace
	}
	
	clear
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		append using "${DIR_TEMP}/wage_percentiles_`y1'_`y2'.dta"
		rm "${DIR_TEMP}/wage_percentiles_`y1'_`y2'.dta"
	}
	
	order period
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/wage_percentiles.dta"
	
	
	*** compute distribution over wage bins
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		
		* load data
		if $age_group == 0 use inc using "${FILE_EST_FSIZE}_`y1'_`y2'.dta", clear
		if inlist(${age_group}, 1, 2) {
			use persid year inc using "${FILE_EST_FSIZE}_`y1'_`y2'.dta", clear
			merge m:1 persid year using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
			drop persid year
			keep if inrange(age, ${age_min}, ${age_max})
			drop age
		}
		
		* keep only observations with nonmissing earnings
		keep if inc < .
		
		* count the number of people in 100 bins between -.5 and 4.5
		gen float wage = ln(inc)
		drop inc
		
		* convert to real productivity adjusted wages
		if `y1' == $year_sim_default_min replace wage = wage + ln(${mw_final})
		
		* keep only certain range
		keep if wage >= -.5 & wage < 4.5
		
		* export to MATLAB
		compress
		outsheet using "${DIR_EST_INPUTS_AGE}/wages_data_`y1'_`y2'.out", comma nolabel replace
		
		* generate wage bins
		gen float wage_bin = floor(10*wage)/10
		
		* collapse into wage bins
		${gtools}collapse  ///
			(count) y=wage ///
			, by(wage_bin) fast
		
		label var y "Bin count of log earnings"
		
		* rename variables
		rename wage_bin x
		label var x "Log-earnings bins"
		
		* create period indicator
		if `y1' == $year_est_default_min gen byte period = 1
		else if `y1' == $year_sim_default_min gen byte period = 2
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
		
		* save
		prog_comp_desc_sum_save "${DIR_TEMP}/wage_bins_`y1'_`y2'.dta"
	}
	
	clear
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		append using "${DIR_TEMP}/wage_bins_`y1'_`y2'.dta"
		rm "${DIR_TEMP}/wage_bins_`y1'_`y2'.dta"
	}
	
	order period x y
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/wage_bins.dta"
	****************************************************************************
	
}


if $section_firmsize {

	****************************************************************************
	* (4) Firm size distribution
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		
		* load data
		if $age_group == 0 use empid_est year using "${FILE_EST_FSIZE}_`y1'_`y2'.dta", clear
		if inlist(${age_group}, 1, 2) {
			use persid empid_est year using "${FILE_EST_FSIZE}_`y1'_`y2'.dta", clear
			merge m:1 persid year using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
			drop persid
			keep if inrange(age, ${age_min}, ${age_max})
			drop age
		}
		
		* compute firm size
		bys empid_est year: gen long fsize = _N
		
		* unweighted firm size (i.e., one observation per firm)
		bys empid_est year: gen long fsize_firm = fsize if _n == 1
		foreach ff in 1 50 100 500 {
			gen byte fsize_`ff' = (fsize >= `ff' & fsize < .)
		}
		replace fsize = ln(fsize)

		${gtools}collapse  ///
			(mean) fsize_mean=fsize_firm  ///
			(sum) fsize_*  ///
			(sd) fsize_std=fsize ///
			, fast
		drop fsize_firm
		
		* convert to shares
		foreach ff in 50 100 500 {
			replace fsize_`ff' = fsize_`ff'/fsize_1
		}
		drop fsize_1

		if `y1' == $year_est_default_min gen byte period = 1
		else if `y1' == $year_sim_default_min gen byte period = 2
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
		
		compress
		save "${DIR_TEMP}/fsize_`y1'_`y2'.dta", replace
	}
	
	clear
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		append using "${DIR_TEMP}/fsize_`y1'_`y2'.dta"
		rm "${DIR_TEMP}/fsize_`y1'_`y2'.dta"
	}
	
	order period fsize_mean fsize_std fsize_50 fsize_100 fsize_500
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/fsize.dta"
	****************************************************************************

}


if $section_akm {

	****************************************************************************
	* (5) AKM estimates
	
	* compute variances and covariances of fixed effects
	if $age_group == 0 {
		clear
		gen byte period = .
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
		forval n = 1/`N_list' {
			local y1: word `n' of ${y1_list} // first year
			local y2: word `n' of ${y2_list} // last year
			append using "${FILE_EST_AKM_DECOMPOSITION}_`y1'_`y2'.dta"
			if `y1' == $year_est_default_min replace period = 1 if period == .
			else if `y1' == $year_sim_default_min replace period = 2 if period == .
		}
		order period wage_var pe_var fe_var pe_fe_cov resid_var pe_fe_corr
		prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/akm.dta"
	}
	else if inlist(${age_group}, 1, 2) {
		forval n = 1/`N_list' {
			local y1: word `n' of ${y1_list} // first year
			local y2: word `n' of ${y2_list} // last year
			use persid year inc_ln pe fe resid using "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta", clear
			merge m:1 persid year using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
			drop persid year
			keep if inrange(age, ${age_min}, ${age_max})
			drop age
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
			if `y1' == $year_est_default_min gen byte period = 1
			else if `y1' == $year_sim_default_min gen byte period = 2
			gen float pe_fe_corr = `pe_fe_corr'
			gen float pe_fe_cov = `pe_fe_cov'
			label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
			label var wage_var "Variance of log earnings (${year_est_min}-${year_est_max})"
			label var pe_var "Variance of AKM person FEs (${year_est_min}-${year_est_max})"
			label var fe_var "Variance of AKM employer FEs (${year_est_min}-${year_est_max})"
			label var pe_fe_cov "2*Cov b/w AKM person & employer FEs (${year_est_min}-${year_est_max})"
			label var resid_var "Variance of AKM residual (${year_est_min}-${year_est_max})"
			label var pe_fe_corr "Correlation b/w AKM person & employer FEs (${year_est_min}-${year_est_max})"
			order period wage_var pe_var fe_var pe_fe_cov resid_var pe_fe_corr
			save "${DIR_TEMP}/RAIS/akm_temp_`n'.dta", replace
		}
		clear
		forval n = 1/`N_list' {
			append using "${DIR_TEMP}/RAIS/akm_temp_`n'.dta"
			rm "${DIR_TEMP}/RAIS/akm_temp_`n'.dta"
		}
		prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/akm.dta"
	}
	
	* compute moments by person FE quantiles
	if $age_group == 0 {
		clear
		gen byte period = .
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
		forval n = 1/`N_list' {
			local y1: word `n' of ${y1_list} // first year
			local y2: word `n' of ${y2_list} // last year
			append using "${FILE_EST_AKM_ESTIMATES}_`y1'_`y2'.dta"
			if `y1' == $year_est_default_min replace period = 1 if period == .
			else if `y1' == $year_sim_default_min replace period = 2 if period == .
		}
	}
	else if inlist(${age_group}, 1, 2) {
		forval n = 1/`N_list' {
			local y1: word `n' of ${y1_list} // first year
			local y2: word `n' of ${y2_list} // last year
			use persid year inc_ln pe fe using "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta", clear
			merge m:1 persid year using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
			drop persid year
			keep if inrange(age, ${age_min}, ${age_max})
			drop age
			if `y1' == $year_est_default_min gen byte period = 1
			else if `y1' == $year_sim_default_min gen byte period = 2
			label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
			order period inc_ln pe fe
			save "${DIR_TEMP}/RAIS/akm_by_pe_decile_temp_`n'.dta", replace
		}
		clear
		forval n = 1/`N_list' {
			append using "${DIR_TEMP}/RAIS/akm_by_pe_decile_temp_`n'.dta"
			rm "${DIR_TEMP}/RAIS/akm_by_pe_decile_temp_`n'.dta"
		}
	}
	drop if inc_ln == 0
	gquantiles ///
		pe_b=pe ///
		, xtile n(10) by(period)
	${gtools}collapse  ///
		(mean) wage_mean=inc_ln fe_mean=fe ///
		(var) wage_var=inc_ln fe_var=fe ///
		, by(period pe_b) fast
	rename pe_b pe
// 	bys period (pe): gen float s = wage_mean[_N]
// 	replace wage_mean = wage_mean-s
// 	drop s
	order period pe wage_mean wage_var
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/akm_by_pe_decile.dta"
	
	* compute employment unweighted ranking, in line with model
	if $age_group == 0 {
		clear
		gen byte period = .
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
		forval n = 1/`N_list' {
			local y1: word `n' of ${y1_list} // first year
			local y2: word `n' of ${y2_list} // last year
			append using "${FILE_EST_AKM_ESTIMATES}_`y1'_`y2'.dta", keep(fe inc_ln empid_est)
			if `y1' == $year_est_default_min replace period = 1 if period == .
			else if `y1' == $year_sim_default_min replace period = 2 if period == .
		}
	}
	else if inlist(${age_group}, 1, 2) {
		forval n = 1/`N_list' {
			local y1: word `n' of ${y1_list} // first year
			local y2: word `n' of ${y2_list} // last year
			use persid empid_est year inc_ln fe using "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta", clear
			merge m:1 persid year using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
			drop persid year
			keep if inrange(age, ${age_min}, ${age_max})
			drop age
			if `y1' == $year_est_default_min gen byte period = 1
			else if `y1' == $year_sim_default_min gen byte period = 2
			label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
			order empid_est period inc_ln fe
			save "${DIR_TEMP}/RAIS/akm_by_pe_decile_temp_`n'.dta", replace
		}
		clear
		forval n = 1/`N_list' {
			append using "${DIR_TEMP}/RAIS/akm_by_pe_decile_temp_`n'.dta"
			rm "${DIR_TEMP}/RAIS/akm_by_pe_decile_temp_`n'.dta"
		}
	}
	drop if inc_ln == 0 | inc_ln == . // drop jobs with earnings equal to MW or with zero or missing earnings
	bys empid_est period: gen float weight = 1/_N
	gquantiles ///
		fe_b=fe ///
		[aw=weight] ///
		, xtile n(10) by(period)
	${gtools}collapse  ///
		(mean) wage_mean=inc_ln ///
		(var) wage_var=inc_ln ///
		(count) weight=inc_ln ///
		, by(period fe_b) fast
	rename fe_b fe
	gegen long tot = total(weight), by(period)
	replace weight = weight/tot
	drop tot
	compress
	order period fe wage_mean wage_var
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/akm_by_fe_decile.dta"
	****************************************************************************	
	
}


if $section_flows {

	****************************************************************************
	* (6) Worker flows by AKM person effects
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		
		* load AKM person FE and employer FE data
		if $age_group == 0 use persid empid_est pe fe if pe < . & fe < . using "${FILE_EST_AKM_ESTIMATES}_`y1'_`y2'.dta", clear
		else if inlist(${age_group}, 1, 2) {
			use persid empid_est year pe fe if pe < . & fe < . using "${DIR_TEMP}/RAIS/lset_`y1'_`y2'.dta", clear
			merge m:1 persid year using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
			drop year
			keep if inrange(age, ${age_min}, ${age_max})
			drop age
		}
		save "${DIR_TEMP}/temp.dta", replace
		
		* create worker-level file containing AKM person FEs
// 		use persid pe using "${DIR_TEMP}/temp.dta", clear
		keep persid pe
		rename persid id
		bys id: keep if _n == 1
		compress
		save "${DIR_TEMP}/temp_worker.dta", replace
		
		* create employer-level file containing AKM employer FEs and AKM employer FE quantiles
		use empid_est fe using "${DIR_TEMP}/temp.dta", clear
		rm "${DIR_TEMP}/temp.dta"
		rename empid_est empid
		bys empid: keep if _n == 1	
		gquantiles ///
			fe_b = fe ///
			, xtile n(10) // note: bin at this point to get weights right!
		compress
		save "${DIR_TEMP}/temp_firm.dta", replace	

		* compute worker flows
		if $age_group == 0 use "${FILE_EST_MONTHLY}_`y1'_`y2'.dta", clear
		else if inlist(${age_group}, 1, 2) {
			use "${FILE_EST_MONTHLY}_`y1'_`y2'.dta", clear
			
			// SELECTION BY AGE (drop workers who are ever observed either below minimum age threshold or above maximum age threshold are dropped):
// 			merge m:1 persid using "${DIR_TEMP}/RAIS/age_`y1'_`y2'.dta", keepusing(age) keep(match) nogen
// 			bys persid (age): keep if age[1] >= ${age_min} & age[_N] <= ${age_max}
// 			drop age
			
			// SELECTION BY YEAR OF BIRTH (drop workers who are not potentially observed in all years):
			merge m:1 persid using "${DIR_TEMP}/RAIS/yob_`y1'_`y2'.dta", keepusing(yob) keep(match) nogen
// 			Note: keep observations that meet two conditions:
//           - condition 1: year - yob = age >= ${age_min} in y1  iff.  y1 - ${age_min} >= yob
// 			 - condition 2: year - yob = age <= ${age_max} in y2  iff.  y2 - ${age_max} <= yob
			keep if `y1' - ${age_min} >= yob & `y2' - ${age_max} <= yob
			drop yob
			
		}
		rename persid id
		rename empid_est empid
		rename inc wage
	// 	gen byte empstat = (empid < .) + (wage == ${mw_initial})
		compress
		
		* COMMENT1: check that panel is full (i.e., for each worker ID, there are all (`y2' - `y1' + 1)*12 months of data)!
		*	-->	if we want to condition on age, it has to be done such that it maintains the full panel structure, i.e.:
		*			(1) load the underlying monthly data
		*			(2A) bys id (age): keep if age[1] >= ${age_min} & age[_N] <= ${age_max} // OR:
		*			(2B) keep if `y1' - ${age_min} >= yob & `y2' - ${age_max} <= yob
		*			(3) xtset id date
		*			(4) tsfill, full
		*** CONFIRM THIS IS THE CASE:
	// 	gegen byte tot = count(empstat), by(id)
	// 	sum tot // check that this = (`y2' - `y1' + 1)*12
	// 	drop tot
		bys id: assert _N == (`y2' - `y1' + 1)*12

		* COMMENT2: check that all employed workers have valid employer ID.
		*** CONFIRM THIS IS THE CASE:
	// 	count if empstat > 0 & empstat < . & empid == . // check that this = 0
		assert !(empstat > 0 & empstat < . & empid == .)
		
		* share of currently employed who are employed at different employer in next month at a higher wage
		xtset id date
		gen byte ee = f.empstat > 0 & f.empstat < . & ///
				 f.empid ~= empid ///
				 if empid > 0 & empid < .
		gen byte ee_down = f.empstat > 0 & f.empstat < . & ///
				 f.empid ~= empid & ///
				 f.wage <= wage & f.wage < . ///
				 if empid > 0 & empid < .			 

		* share of employed who are not employed in next month
		gen byte en = f.empstat == 0 if empstat > 0 & empstat < .

		* share of employed who are minimum wage employed in next month
		gen byte em = f.empstat == 2 if empstat == 1
		
		* share of nonemployed who are employed in next month
		gen byte ne = f.empstat > 0 & f.empstat < . if empstat == 0

		* share of minimum wage employed who are employed in next month
		gen byte me = f.empstat == 1 if empstat == 2
		
		* share of minimum wage employed who are nonemployed in next month
		gen byte mn = f.empstat == 0 if empstat == 2

		* share employer earning != MW
		gen byte e = empstat == 1
		
		* share nonemployed
		gen byte u = empstat == 0
		
		* share employed earning = MW
		gen byte m = empstat == 2
		
		* compute recall within next 12 months
		gen byte recall_en = (f2.empid == empid) if en == 1
		gen byte recall_ee = (f2.empid == empid) if ee == 1	
	// 	gen byte recall_ee_down = (f2.empid == empid) if ee_down == 1	
		forval i = 3/13 {
			replace recall_en = 1 if (f`i'.empid == empid) & en == 1
			replace recall_ee = 1 if (f`i'.empid == empid) & ee == 1
	// 		replace recall_ee_down = 1 if (f`i'.empid == empid) & ee_down == 1
		}
		
		* drop last date since all are missing
		sum date, meanonly
		local r = r(max)
		keep if date < `r'
		sum date, meanonly
		local r = r(max) - 13
		foreach var in en ee {
			replace recall_`var' = . if date >= `r'
		}
		keep id empid ee ee_down en em ne me mn m e u wage recall*

		* store aggregates
		preserve
		${gtools}collapse ///
			(mean) ee ee_down en em ne me mn recall*
				
		if `y1' == $year_est_default_min gen byte period = 1
		else if `y1' == $year_sim_default_min gen byte period = 2
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"
		
		compress
		save "${DIR_TEMP}/flows_`y1'_`y2'.dta", replace
		
		restore
		
		* removing those earning exactly the minimum wage
		replace wage = . if wage == 1 // == ${mw_initial} XXX WHICH MW??? -- the CURRENT MW!!!
		
		* merge in AKM person FEs
		merge m:1 id using "${DIR_TEMP}/temp_worker.dta", nogen keep(match)
		rm "${DIR_TEMP}/temp_worker.dta"
		drop id
		compress
		
		* merge in AKM employer FEs
		merge m:1 empid using "${DIR_TEMP}/temp_firm.dta", nogen keep(match master) keepusing(fe_b)
		rm "${DIR_TEMP}/temp_firm.dta"
		drop empid
		compress	

		* compute AKM person FE quantiles
		gquantiles ///
			pe_b=pe ///
			, xtile n(10) // note: bin at this point to get weights right!
		drop pe

		preserve
		${gtools}collapse ///
			(mean) ee ee_down en em ne me mn e m u recall* ///
			(p1) wage_p1=wage ///
			(p5) wage_p5=wage ///
			(p10) wage_p10=wage ///
			(min) minwage=wage ///
			, by(pe_b) fast

		* share of employed
		replace m = m/(m + e)
		drop e
		
		* minimum wage in logs
		replace minwage = ln(minwage)
		foreach i in 1 5 10 {
			replace wage_p`i' = ln(wage_p`i')
		}
		
		rename pe_b pe
		sort pe
		
		if `y1' == $year_est_default_min gen byte period = 1
		else if `y1' == $year_sim_default_min gen byte period = 2
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"

		compress
		save "${DIR_TEMP}/akm_flows_worker_`y1'_`y2'.dta", replace
		
		restore
		preserve
		${gtools}collapse ///
			(mean) ee en em ne me mn e m u ///
			(p1) wage_p1=wage ///
			(p5) wage_p5=wage ///
			(p10) wage_p10=wage ///
			(min) minwage=wage ///
			, by(fe_b) fast

		* share of employed
		replace m = m/(m + e)
		drop e
		
		* minimum wage in logs
		replace minwage = ln(minwage)
		foreach i in 1 5 10 {
			replace wage_p`i' = ln(wage_p`i')
		}
		
		rename fe_b fe
		drop if fe == .
		sort fe
		
		if `y1' == $year_est_default_min gen byte period = 1
		else if `y1' == $year_sim_default_min gen byte period = 2
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"

		compress
		save "${DIR_TEMP}/akm_flows_firm_`y1'_`y2'.dta", replace	

		restore
		drop if fe_b == .
		${gtools}collapse ///
			(mean) ee en em ne me mn e m u ///
			(p1) wage_p1=wage ///
			(p5) wage_p5=wage ///
			(p10) wage_p10=wage ///
			(min) minwage=wage ///
			, by(fe_b pe_b) fast

		* share of employed
		replace m = m/(m + e)
		drop e

		* minimum wage in logs
		replace minwage = ln(minwage)
		foreach i in 1 5 10 {
			replace wage_p`i' = ln(wage_p`i')
		}
		
		rename fe_b fe
		sort fe
		
		if `y1' == $year_est_default_min gen byte period = 1
		else if `y1' == $year_sim_default_min gen byte period = 2
		label var period "Period (1 = ${year_est_default_min}-${year_est_default_max}, 2 = ${year_sim_default_min}-${year_sim_default_max})"

		compress
		save "${DIR_TEMP}/akm_flows_firm_worker_`y1'_`y2'.dta", replace
	}
	
	
	clear
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		append using "${DIR_TEMP}/flows_`y1'_`y2'.dta"
		rm "${DIR_TEMP}/flows_`y1'_`y2'.dta"
	}
	
	order period ee ee_down en em ne me mn recall_en recall_ee
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/flows.dta"
	
	
	clear
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		append using "${DIR_TEMP}/akm_flows_worker_`y1'_`y2'.dta"
		rm "${DIR_TEMP}/akm_flows_worker_`y1'_`y2'.dta"
	}
	
	order period pe ee ee_down en em ne me mn m u recall_en recall_ee wage_p1 wage_p5 wage_p10 minwage
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/akm_flows_worker.dta"
	
	
	clear
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		append using "${DIR_TEMP}/akm_flows_firm_`y1'_`y2'.dta"
		rm "${DIR_TEMP}/akm_flows_firm_`y1'_`y2'.dta"
	}
	
	order period fe ee en em ne me mn m u wage_p1 wage_p5 wage_p10 minwage
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/akm_flows_firm.dta"
	
	
	clear
	forval n = 1/`N_list' {
		local y1: word `n' of ${y1_list} // first year
		local y2: word `n' of ${y2_list} // last year
		append using "${DIR_TEMP}/akm_flows_firm_worker_`y1'_`y2'.dta"
		rm "${DIR_TEMP}/akm_flows_firm_worker_`y1'_`y2'.dta"
	}
	
	order period fe pe_b ee en em ne me mn m u wage_p1 wage_p5 wage_p10 minwage
	prog_comp_desc_sum_save "${DIR_EST_INPUTS_AGE}/akm_flows_firm_worker.dta"
	****************************************************************************

}


if $section_tomatlab {

	****************************************************************************
	* (7) Combine and outsheet the data to matlab
	
	
	*** outsheet target moments
	* load data on employment status
	use "${DIR_EST_INPUTS_AGE}/empstat_rais.dta", clear
	
	* merge in other data files
	merge 1:1 period using "${DIR_EST_INPUTS_AGE}/mw.dta", nogen
	merge 1:1 period using "${DIR_EST_INPUTS_AGE}/wage_percentiles.dta", nogen
	merge 1:1 period using "${DIR_EST_INPUTS_AGE}/fsize.dta", nogen
	merge 1:1 period using "${DIR_EST_INPUTS_AGE}/akm.dta", nogen
	merge 1:1 period using "${DIR_EST_INPUTS_AGE}/flows.dta", nogen
	
	* outsheet
	outsheet using "${DIR_EST_INPUTS_AGE}/Moments.out", comma nolabel replace
	
	
	*** outsheet worker flows
	* load data
	use "${DIR_EST_INPUTS_AGE}/akm_flows_worker.dta", clear
	merge 1:1 period pe using "${DIR_EST_INPUTS_AGE}/akm_by_pe_decile.dta", nogen keepusing(wage_mean wage_var fe_mean fe_var)
	
	* outsheet
	outsheet using "${DIR_EST_INPUTS_AGE}/MomentsByDecile.out", comma nolabel replace
	
	
	*** outsheet firm wage outcomes
	* load data
	use "${DIR_EST_INPUTS_AGE}/akm_by_fe_decile.dta", clear
	
	* outsheet
	outsheet using "${DIR_EST_INPUTS_AGE}/MomentsByDecileFE.out", comma nolabel replace
	
	
	*** outsheet wage bins
	* load data
	use "${DIR_EST_INPUTS_AGE}/wage_bins.dta", clear
	
	* outsheet
	outsheet using "${DIR_EST_INPUTS_AGE}/wage_bins.out", comma nolabel replace
	****************************************************************************

}
