********************************************************************************
* START EIMW_0_MASTER.DO
*
* DESCRIPTION: Master file.
*
* AUTHOR:      Niklas Engbom (New York University) and
*              Christian Moser (Columbia University and FRB Minneapolis).
*
* REFERENCES:  Please cite the following papers:
*              (1) Alvarez, Jorge & Felipe Benguria & Niklas Engbom & Christian
*                  Moser. 2018. "Firms and the Decline in Earnings Inequality in
*                  Brazil." American Economic Journal: Macroeconomics, 10 (1):
*                  149-89.
*              (2) Engbom, Niklas & Christian Moser. 2021. "Earnings Inequality
*                  and the Minimum Wage: Evidence from Brazil." NBER Working
*                  Paper No. 28831.
*              (3) Engbom, Niklas & Gustavo Gonzaga & Christian Moser & Roberta
*                  Olivieri. 2021. "Earnings Inequality and Dynamics in the
*                  Presence of Informality: The Case of Brazil." Working Paper.
*
* PACKAGES:    Required packages:
*              - datazoom_pnad (http://www.econ.puc-rio.br/datazoom/english/index.html)
*              - datazoom_pmenova (http://www.econ.puc-rio.br/datazoom/english/index.html)
*              [- datazoom_pmeantiga (http://www.econ.puc-rio.br/datazoom/english/index.html)] -- currently not required!
*
*              Recommended packages for increased speed:
*              - gtools (https://github.com/mcaceresb/stata-gtools)
*
* TIME STAMP:  December 13, 2021.
********************************************************************************


********************************************************************************
* INITIAL HOUSEKEEPING
********************************************************************************
set more off
clear all
if "`1'" == "" macro drop _all
timer clear 1
timer on 1
set seed 1
set type double
set excelxlsxlargefile on
set graphics off
set varabbrev off
set rmsg on
set matsize 11000
set linesize 100
set scrollbufsize 500000
cap log close _all


********************************************************************************
* SELECT PARTS TO RUN
********************************************************************************
if "`1'" == "" { // if setting arguments within master-file
	global n_cpus = 8 // number of cores to use (4 on Chris' MacBook or MacBook Pro with 2 dual cores; up to 8 on Princeton/Columbia servers)
	global sample = 0 // 0 = full raw data files; 1 = sample; 2 = mini-sample
	global year_min = 1996 // first year used for any analysis
	global year_max = 2018 // last year used for any analysis
	global year_est_min_list = "1994  2014" // list of first years for estimation (e.g., "1994  1998  2002  2006  2010  2014")
	global year_est_max_list = "1998  2018" // list of last years for estimation (e.g., "1998  2002  2006  2010  2014  2018")
	global age_group_list = "1  2  0" // list of age groups to loop through for estimation (0 = all ages, 1 = only young, 2 = only old)
	global EIMW_1_AUXILIARY_DATA = 0 // generates auxiliary datasets
	global EIMW_2_EST_BASELINE = 0 // construct baseline RAIS data
	global EIMW_3_EST_MONTHLY = 0 // construct full monthly panel from RAIS data
	global EIMW_4_EST_FSIZE = 0 // construct distribution of firm sizes in RAIS data
	global EIMW_5_EST_AKM = 0 // compute AKM wage components in RAIS data
	global EIMW_6_EST_PNAD = 0 // compute employment states in PNAD household survey data
	global EIMW_7_EST_COMB = 0 // combine estimation results
	global EIMW_8_SUMMARY_STATS = 0 // computes summary statistics
	global EIMW_9_PERCENTILES = 0 // compute percentiles by state
	global EIMW_10_MOTIVATING_FACTS = 0 // prepare motivating facts
	global EIMW_11_MW_SPIKE = 0 // analyze spike in wage distribution at minimum wage
	global EIMW_12_LEE = 1 // run Lee (1999) regressions on RAIS administrative data
	global EIMW_13_LEE_PNAD_PME = 0 // run Lee (1999) regressions on PNAD and PME household survey data
	global EIMW_14_COMPARATIVE_STATICS = 0 // compute moments corresponding to comparative statics in equilibrium model
	global EIMW_15_MODEL_RESULTS = 0 // processes model results
}
else { // if setting arguments from shell
	global n_cpus = `1'
	global sample = `2'
	global year_min = `3'
	global year_max = `4'
	global year_est_min_list = `5'
	global year_est_max_list = `6'
	global age_group_list = `7'
	global EIMW_1_AUXILIARY_DATA = `8'
	global EIMW_2_EST_BASELINE = `9'
	global EIMW_3_EST_MONTHLY = `10'
	global EIMW_4_EST_FSIZE = `11'
	global EIMW_5_EST_AKM = `12'
	global EIMW_6_EST_PNAD = `13'
	global EIMW_7_EST_COMB = `14'
	global EIMW_8_SUMMARY_STATS = `15'
	global EIMW_9_PERCENTILES = `16'
	global EIMW_10_MOTIVATING_FACTS = `17'
	global EIMW_11_MW_SPIKE = `18'
	global EIMW_12_LEE = `19'
	global EIMW_13_LEE_PNAD_PME = `20'
	global EIMW_14_COMPARATIVE_STATICS = `21'
	global EIMW_15_MODEL_RESULTS = `22'
}


********************************************************************************
* SET DIRECTORIES
********************************************************************************
* automatically detect user
local n = 0
local location = ""
foreach dir in ///
	"/Users/cm3594/" /// `location' == 1: Chris' work iMac Pro or work MacBook
	"/Users/economoser/" /// `location' == 2: Chris' personal iMac Pro
	"/Users/niklasengbom/" /// `location' == 3: Nik's computer
	"/shared/share_cmoser/" /// `location' == 4: Columbia Grid server
	{
	local ++n
	cap confirm file "`dir'"
	if !_rc & "`location'" == "" local location = `n'
	else if !_rc & "`location'" != "" {
		disp as error "USER ERROR: Cannot set user because more than one home directory was found."
		error 1
	}
}
if "`location'" == "" {
	disp as error "USER ERROR: Failed to automatically set user based on home directory."
	error 1
}

* user-specific directories
if inlist(`location', 1, 2) { // if run on Chris' work iMac Pro or work MacBook or personal iMac Pro
	if `location' == 1 global user = "cm3594"
	else if `location' == 2 global user = "economoser"
	global DIR_DO = "/Users/${user}/Dropbox (CBS)/Brazil/5 Code/12_EIMW_AER_RR"
	global DIR_PAPER = "/Users/${user}/Dropbox (CBS)/Brazil/7 Paper/5 EM (2016)/_9_AER_RR (May 2019)"
	global DIR_MODEL = "/Users/${user}/Dropbox (CBS)/Brazil/5 Code/1 Model"
	// global DIR_EST_INPUTS = "${DIR_MODEL}/3 Version 10302020/2 Data"
	global DIR_EST_INPUTS = "${DIR_MODEL}/4 Version 11122021/2 Data"
	global DIR_WRITE = "/Users/${user}/Data/RAIS/3_processed"
	global DIR_TEMP = "/Users/${user}/Data/temp"
	global DIR_PNAD_DATA = "/Users/${user}/Data/PNAD"
	global DIR_PME_DATA = "/Users/${user}/Data/PME"
	global DIR_RESULTS = "${DIR_DO}/_results"
	global DIR_ADO_PERSONAL = "/Users/${user}/Library/Application Support/Stata/ado/personal"
	global DIR_ADO_PLUS = "/Users/${user}/Library/Application Support/Stata/ado/plus"
	global DIR_CONVERSION = "/Users/${user}/Dropbox (CBS)/Brazil/4 Data/6_conversion"
	global APP_ZIPPER = "/usr/local/bin/7z"
	global APP_MATLAB = ""
	foreach version in "2019a" "2019b" "2020a" "2020b" "2021a" "2021b" {
		cap confirm file "/Applications/MATLAB_R`version'.app/bin/matlab"
		if !_rc global APP_MATLAB = "/Applications/MATLAB_R`version'.app/bin/matlab"
	}
	if "${APP_MATLAB}" == "" {
		disp as error "USER ERROR: Could not find MATLAB application."
		error 1
	}
}
else if `location' == 3 { // else, if run on Nik's computer
	global user = "niklasengbom"
	global DIR_DO = "XXX"
	global DIR_PAPER = "XXX"
	global DIR_MODEL = "XXX"
	global DIR_EST_INPUTS = "XXX"
	global DIR_WRITE = "XXX"
	global DIR_TEMP = "XXX"
	global DIR_PNAD_DATA = "XXX"
	global DIR_PME_DATA = "XXX"
	global DIR_RESULTS = "XXX"
	global DIR_ADO_PERSONAL = "XXX"
	global DIR_ADO_PLUS = "XXX"
	global DIR_CONVERSION = "XXX"
	global APP_ZIPPER = "XXX"
	global APP_MATLAB = "XXX"
}
else if `location' == 4 { // else, if run on Columbia Grid server
	global user = "cm3594"
	global DIR_DO = "/shared/share_cmoser/15_EIMW_AER_RR"
	global DIR_PAPER = "XXX"
	global DIR_MODEL = "/scratch/${user}/RAIS/3_model"
	// global DIR_EST_INPUTS = "${DIR_MODEL}/3 Version 10302020/2 Data"
	global DIR_EST_INPUTS = "${DIR_MODEL}/4 Version 11122021/2 Data"
	global DIR_WRITE = "/shared/share_cmoser/1_data/RAIS/3_processed"
	global DIR_TEMP = "/scratch/${user}/RAIS/1_scanned_data"
	global DIR_PNAD_DATA = "XXX"
	global DIR_PME_DATA = "XXX"
	global DIR_RESULTS = "/shared/share_cmoser/1_data/RAIS/4_extracts"
	global DIR_ADO_PERSONAL = "/shared/share_cmoser/4_Stata/personal"
	global DIR_ADO_PLUS = "/shared/share_cmoser/4_Stata/plus"
	global DIR_CONVERSION = "/shared/share_cmoser/1_data/RAIS/6_conversion"
	global APP_ZIPPER = "/shared/share_cmoser/10_RAIS_1985_2018/7z2102-linux-x64/7zz"
	global APP_MATLAB = "matlab"
}

* general directories
global DIR_LOG = "${DIR_DO}/_logs"
global DIR_MW_RAW = "${DIR_CONVERSION}/min_wage/minwage_nominal_IPEA_13February2019.xls"
global DIR_MW = "${DIR_CONVERSION}/min_wage/minwage_conv.dta"
global DIR_MW_YEARLY = "${DIR_CONVERSION}/min_wage/minwage_conv_yearly.dta"
global DIR_MW_MONTHLY = "${DIR_CONVERSION}/min_wage/minwage_conv.dta"
global DIR_CPI_RAW = "${DIR_CONVERSION}/cpi/IPCA_IPEA_13February2019.xls"
global DIR_CPI = "${DIR_CONVERSION}/cpi/cpi_conv.dta"
global DIR_CPI_YEARLY = "${DIR_CONVERSION}/cpi/cpi_conv_yearly.dta"


********************************************************************************
* AUTOMATICALLY CREATE LIST OF SECTIONS TO RUN
********************************************************************************
global all_globals: all globals
global sections = ""
foreach section of global all_globals {
	if substr("`section'", 1, 5) == "EIMW_" global sections = "`section' ${sections}"
}


********************************************************************************
* AUTOMATICALLY CREATE DIRECTORIES
********************************************************************************
foreach dir in ///
	"${DIR_TEMP}" ///
	"${DIR_TEMP}/PNAD" ///
	"${DIR_TEMP}/PME" ///
	"${DIR_TEMP}/RAIS" ///
	"${DIR_TEMP}/IPEA" ///
	"${DIR_RESULTS}" ///
	{
	cap confirm file "`dir'"
	if _rc {
		!mkdir "`dir'"
	}
}
foreach section of global sections {
	cap confirm file "${DIR_RESULTS}/`section'"
	if _rc {
		!mkdir "${DIR_RESULTS}/`section'"
	}
}


********************************************************************************
* SET USER-SPECIFIC PARAMETERS
********************************************************************************
if `location' == 1 { // if run on Chris' work iMac Pro or work MacBook
	cap confirm file "/Users/${user}/Data/RAIS/3_processed/${year_max}/clean${year_max}.dta"
	if !_rc { // if run on Chris' Chris' work iMac Pro
		set segmentsize 256m
		set niceness 1
	}
	else { // if run on Chris' work MacBook
		set segmentsize 32m
		set niceness 5
	}
}
else if `location' == 2 { // else, if run on Chris' personal iMac Pro
	set segmentsize 64m
	set niceness 1
}
else if `location' == 3 { // else, if run on Nik's computer
	set segmentsize 32m
	set niceness 5
}
else if `location' == 4 { // else, if run on Columbia Grid server
	set segmentsize 2g
	set niceness 1
}


********************************************************************************
* SET SYSTEM DIRECTORIES
********************************************************************************
sysdir set PERSONAL "${DIR_ADO_PERSONAL}"
sysdir set PLUS "${DIR_ADO_PLUS}"


********************************************************************************
* INSTALL PACKAGES
********************************************************************************
foreach package in ///
	"datazoom_pnad" ///
	"datazoom_pmenova" ///
	"datazoom_pmeantiga" ///
	{
	cap confirm file "${DIR_ADO_PLUS}/d/`package'.ado"
	if _rc net install `package'.pkg
}

********************************************************************************
* AUTOMATED STEPS
********************************************************************************
* call user-defined function to define time stamp file name extension
do "${DIR_DO}/FUN_EXTENSION.do"

* set processors
set processors `=min(${n_cpus}, `c(processors_max)')'

* define sample prefix
if $sample == 0 {
	global sample_prefix = ""
	global sample_ext = ""
}
else if $sample == 1 {
	global sample_prefix = "sample_"
	global sample_ext = "_sample"
}
else if $sample == 2 {
	global sample_prefix = "sample_mini_"
	global sample_ext = "_sample_mini"
}

* start log file
global log_name = "log_EIMW_${year_min}_${year_max}_${ext}"
log using "${DIR_LOG}/${log_name}.log", text name(EIMW_master) replace


********************************************************************************
* SET PARAMETERS
********************************************************************************
* data parameters
global year_data_min = 1985 // first year of available data
global year_data_max = 2018 // last year of available data

* estimation parameters
global year_est_default_min = 1994 // default start year for estimation
global year_est_default_max = 1998 // default end year for estimation
global year_est_default_mid = 1996 // default middle year for estimation

* simulation parameters
global year_sim_default_min = 2014 // default start year for simulation
global year_sim_default_max = 2018 // default end year for simulation

* list of variables to load
global empid_var = "empid_est" // "empid_est" = establishment level; "empid_firm" = firm level
// global vars_list = "year persid ${empid_var} gender edu age yob occ02_6 hours tenure exp_act earn_mean_mw hire_month sep_month id_unique" // ind07_5 muni hours_year

* selection parameters
global persid_min = 1
global persid_max = 10^16
global ${empid_var}_min = 1
global ${empid_var}_max = 10^16
global gender_min = 1 // 1 = male; 2 = female; . = missing
global gender_max = 1
global race_min = . // 1 = Indigenous; 2 = White; 3 = Black; 4 = Asian; 5 = Brown; . = missing
global race_max = .
global edu_min = . // 1 = illiterate; 2 = some primary; 3 = primary; 4 = some middle; 5 = middle; 6 = some high; 7 = high; 8 = some college; 9 = Bachelor's or higher; . = missing
global edu_max = .
global age_min = 18 // 18 // 1-99 = age in years; . = missing
global age_max = 54 // 54
global yob_min = . // 1944
global yob_max = . // 1976
global ind07_5_min = . // 0
global ind07_5_max = . // 999999
global muni_min = . // 1
global muni_max = . // 999999
global occ02_6_min = . // 0
global occ02_6_max = . // 999999
global hours_min = . // 1
global hours_max = . // 7*24
global hours_year_min = . // 1
global hours_year_max = . // 365*24
global tenure_min = . // 1
global tenure_max = . // 999
global exp_act_min = . // 1
global exp_act_max = . // 999
global earn_mean_mw_min = 10^-6 // make this 1 + epsilon in order to exclude those earning <=MW from estimation of connected set and AKM wage equation
global earn_mean_mw_max = 150
global hire_month_min = . // 0 = not hired; 1; ... ; 12; . = missing
global hire_month_max = . // 
global sep_month_min = . // 0 = not separated; 1; ... ; 12; . = missing
global sep_month_max = .
global id_unique_min = .
global id_unique_max = .

* parameters for drawing random sample
global sample_share_flows = 0.05 // share of data used as sample in computation of labor market parameters using monthly flows (0.00 - 1.00)

* parameters for defining connected set
global connect_by_gender = 0 // 0 = create connected set for populuation; 1 = create connected set separately by gender.
global connect_strong = 0 // 0 = create weakly connected set; 1 = create strongly connected set.
global drop_singletons = 0 // 0 = keep all observations; 1 = recursively drop singletons by employer ID and worker ID.
global size_emp_min = 1 // minimum employment threshold (>=1).
global size_emp_min_years = 0 // 0 = impose minimum employer threshold (${size_emp_min}) across pooled years; 1 = impose minimum employer threshold (${size_emp_min}) on average in each year across total timespan; 2 = impose minimum employer threshold (${size_emp_min}) on average in each year across years that firm exists; 3 = impose minimum employer threshold (${size_emp_min}) in each year.
global size_emp_min_nonsingletons = 0 // 0 = apply minimum employer threshold w.r.t. all workers; 1 = apply minimum employer threshold w.r.t. nonsingleton workers (i.e., workers that are observed at least one more time at a future date -- see Sorkin ('18 QJE).
global min_emp_years = 1 // minimum number of employer-years per employer in the sample (>=1).
global min_hire_UE = 0 // minimum number of hires from nonemployment, i.e., from outside of RAIS (>=0) -- Bagger & Lentz (REStud '19) and Sorkin (QJE '18) set = 1.
global min_hire_tot = 0 // minimum number of hires (>=0) -- Bagger & Lentz (REStud '19) set = 15, Sorkin (QJE '18) sets = 0.
global connected_default = 1 // 0 = save connected set with random file name extension; 1 = save connected set without extension, i.e., make it the default file to use.
global unrestricted_connected = 1 // 0 = restrict connected set to earnings from ${earn_mean_mw_min} to ${earn_mean_mw_max}; 1 = in addition, restrict another connected set to earnings from ${unrestricted_connected_earn_min} to ${earn_mean_mw_max}
global unrestricted_connected_earn_min = 1.0 // unrestricted lower-earnings threshold

* parameters for estimating MW spike
// global earn_mean_mw_min_alt_mw_spike = 1.0

* parameters for estimating MW spike
// TBC!

* parameters for estimating transitions into and out of MW jobs
global n_q = 10 // number of AKM person FE quantiles used in computing statistics

* parameters for estimating monthly transition rates
global n_pe_q = 10 // number of AKM person FE quantiles
global unrestricted_transition_earn_min = 0.0 // unrestricted lower-earnings threshold

* AKM estimation parameters
global akm_age_poly_order = 1 // 0 = do not include age terms in AKM regression; 1 = age dummies with income-age profile restricted to be flat from age ${age_flat_min}-${age_flat_max}; 2 / 3 / etc. = include 2nd order term / 2nd and 3rd order terms / etc.
global age_flat_min = 45 // minimum age for which income-age profile is restricted to be flat (only relevant if akm_age_poly_order == 1)
global age_flat_max = 49 // maximum age for which income-age profile is restricted to be flat (only relevant if akm_age_poly_order == 1)
global age_norm = 49 // age around which to normalize higher-order age polynomial terms in AKM estimation (relevant only if ${akm_age_poly_order} >= 2; coincides with where the age profile is assumed to be flat for interpretation of worker FEs and year FEs)
global edu_inter = 1 // 0 = no education interactions; 1 = interact education with time trends and age profiles
global akm_year_dummies = 1 // 0 = do not include year FEs; 1 = include year FEs
global akm_hours = 1 // 0 = do not include hours controls in AKM estimation; 1 = include hours controls in AKM estimation
global akm_occ = 1 // 0 = do not include occupation controls in AKM estimation; 1 = include occupation controls in AKM estimation
global akm_tenure = 0 // 0 = do not include tenure controls in AKM estimation; 1 = include tenure controls in AKM estimation
global akm_exp_act = 0 // 0 = do not include actual experience controls in AKM estimation; 1 = include actual experience controls in AKM estimation
global akm_coarsen = 1 // 0 = leave all variables as originally coded; 1 = coarsen variables before AKM estimation
global N_coarsen = 15 // minimum number of observations used for coarsening categories of each AKM independent variable
global akm_default = 1 // 0 = save AKM estimates with random file name extension; 1 = save AKM estimates without extension, i.e., make it the default file to use.

* labor market parameters estimation
global U_dur_max = 48

* other parameters
global n_bins = 100
global norm_lb = 0.9
global norm_ub = 1.1
global n_batches = 5 // number of batches to split panel data into (higher numbers take more CPU time but less RAM) for connected set, employer ranks, and labor market parameters
global binpoints = 200 // number of grid points for density estimation of fixed effects
global p_list = "5 10 25 50 75 90 95" // percentiles of the female employment share distribution to compute ("1 5 10 25 50 75 90 95 99")

* system options
global saveold_v = 13 // version of Stata to save data files in

* package options
global gtools = "g" // "" = to use Stata-native functions; "g" = use (faster) gtools package


********************************************************************************
* PROGRAMS
********************************************************************************
*** call user-defined function to load programs
do "${DIR_DO}/FUN_PROGRAMS.do"


********************************************************************************
* ORDER OF CODE EXECUTION AND DATASET CREATION
********************************************************************************
// (1) PNAD household survey
//  - load person-level survey data for 1996
//  - create variable empstat with values 0 = "Nonemployed (informal, unemployed, searching)" 1 =  "Formally empl., != MW" 2 = "Formally empl., == MW"
// 	- variables: year empstat weight

// (2) baseline RAIS dataset with various variables subject to minimal selection criteria
// 	- append 5 years of data
// 	- keep spells if year < . & persid < . & empid < . & inc > 0 & inc < .
// 	- keep workers if all other variables (empid, age, edu, hours, occ02_6, tenure, exp_act, hire_month, sep_month, earn_mean_mw) are always nonmissing
// 	- keep relevant cohorts and men
// 	- recast income variable type as float instead of double
// 	- impose uniform upper winsorizing
// 	- compute number of months worked in a particular spell during the current year
// 	- save month a particular spell started during the current year
// 	- for each worker-firm combination, compute average monthly income across the 5-years
// 	- variables: persid year empid_est inc edu age occ02_6 hours tenure exp_act hire_month months_worked id_unique

// Then branch that dataset into 4 additional datasets:

// (2.A) monthly dataset with information on worker transitions
//  - create variable date with values 1994m1 to 1998m12
// 	- expand data to monthly frequency
// 	- select a main employment status and employer in every month based on lexicographic preferences over (i) most months worked, (ii) earliest start month, (iii) random seed
// 	- fill panel, making sure that the key variables (year, age through yob, edu, empstat) exist and those that are supposed to be missing (hours, occ02_6, tenure, exp_act, hire_month, sep_month, earn_mean_mw) are indeed missing
//  - variables: persid date year empstat empid_est inc

// (2.B) annual dataset with information on employer sizes
// 	- selecting a main employer in every year based on lexicographic preferences over (i) most months worked, (ii) earliest start month, (iii) random seed
// 	- create variable fsize that contains annual employer size measured as number of employees in a given year
//  - variables: persid year empid_est inc fsize

// (2.C) annual dataset with information on estimated AKM wage components with various covariates for empirical section
// 	- selecting a main employer in every year based on lexicographic preferences over (i) most months worked, (ii) earliest start month, (iii) random seed
// 	- restrict to largest connected set (various restrictions based on firm size or number of switchers per employer, but keeping singletons, etc.)
// 	- estimate AKM wage components with full set of covariates (age, tenure, occupation, etc.)
//  - variables: persid inc pe fe resid

// (2.D) annual dataset with information on estimated AKM wage components without covariates for estimation
// 	- selecting a main employer in every year based on lexicographic preferences over (i) most months worked, (ii) earliest start month, (iii) random seed
// 	- drop earnings exactly equal to MW
// 	- restrict to largest connected set (no restrictions based on firm size, singletons, etc.)
// 	- estimate AKM wage components without any controls
//  - variables: persid inc pe fe resid


********************************************************************************
* EXECUTE CODE
********************************************************************************
disp "STARTING ON $S_DATE AT $S_TIME."
display _newline(5)
global sections_est = ""
global sections_no_est = ""
foreach section of global sections {
	if strpos("`section'", "_EST_") global sections_est = "${sections_est} `section'"
	else global sections_no_est = "${sections_no_est} `section'"
}
local N_est: word count ${year_est_min_list}
forval n = 1/`N_est' { // loop through sets of start/end years
	global year_est_min: word `n' of ${year_est_min_list} // first year of estimation
	global year_est_max: word `n' of ${year_est_max_list} // last year of estimation
	foreach section of global sections_est { // loop through sections to run
		if $`section' { // i.e., if section switch is turned on
			if ///
				(strpos("`section'", "_EST_PNAD") & `n' > 1) /// i.e., do not execute PNAD estimation file more than once, since it automatically runs for a fixed year.
				| (strpos("`section'", "_EST_COMB") & `n' < `N_est') /// i.e., do not execute file that combines estimation results more than once, since it automatically runs for a fixed set of years
				{
				continue // skip current loop iteration
			}
			else if strpos("`section'", "_EST_COMB") & `n' == `N_est' { // i.e., if combining estimation results, then loop through age groups
				foreach a of global age_group_list { // loop through age groups (0 = all, 1 = young, 2 = old)
					global age_group = `a'
					if inlist(`a', 1, 2) {
						global age_min_save = ${age_min}
						global age_max_save = ${age_max}
						if `a' == 1 {
							global age_min = ${age_min_save}
							global age_max = floor((${age_min_save} + ${age_max_save})/2)
						}
						else if `a' == 2 {
							global age_min = floor((${age_min_save} + ${age_max_save})/2) + 1
							global age_max = ${age_max_save}
						}
					}
					global section = "`section'"
					log using "${DIR_LOG}/log_`section'_${year_est_min}_${year_est_max}_a`a'.log", text name(`section'_a`a') replace
					disp "START ${section}.do"
					do "${DIR_DO}/`section'.do"
					disp "END ${section}.do"
					log close `section'_a`a'
					if inlist(`a', 1, 2) {
						global age_min = ${age_min_save}
						global age_max = ${age_max_save}
					}
				}
			}
			else {
				global section = "`section'"
				log using "${DIR_LOG}/log_`section'_${year_est_min}_${year_est_max}.log", text name(`section') replace
				disp "START ${section}.do"
				do "${DIR_DO}/`section'.do"
				disp "END ${section}.do"
				log close `section'
			}
		}
	}
}

* loop through other do-files
foreach section of global sections_no_est {
	if $`section' { // i.e., if section switch is turned on
		if !strpos("`section'", "_EST_") { // i.e., execute files other than estimation files
			global section = "`section'"
			log using "${DIR_LOG}/log_`section'.log", text name(`section') replace
			disp "START ${section}.do"
			do "${DIR_DO}/`section'.do"
			disp "END ${section}.do"
			log close `section'
		}
	}
}


********************************************************************************
* FINAL HOUSEKEEPING
********************************************************************************
timer off 1
timer list 1
disp "FINISHED ON ${S_DATE} AT ${S_TIME} IN A TOTAL OF `=r(t1)' SECONDS."
log close _all
clear all


********************************************************************************
* END EIMW_0_MASTER.do
********************************************************************************
