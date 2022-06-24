********************************************************************************
* DESCRIPTION: Find largest connected sets and estimates AKM wage equations.
********************************************************************************


*** macros
if "${year_est_min}" == "" | "${year_est_max}" == "" {
	global year_est_min = ${year_est_default_min}
	global year_est_max = ${year_est_default_max}
}


*** empirics: no selection, no controls
do "${DIR_DO}/FUN_CONNECTED.do" 0 0 0 0 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers.
do "${DIR_DO}/FUN_AKM.do" 0 0 0 0 0 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers; `5' = whether to include covariates (edu x time, edu x age, hours, occupation, tenure, actual experience) in AKM wage equation.

* variance decomposition for 1994-1998:
//   --> variance decomposition on largest connected set
// Var(income) = 0.71337 (100%)
// Var(worker FE) = 0.33117 (46.4237%)
// Var(employer FE) = 0.2235 (31.3308%)
// 2*sum(Cov(.)) = 0.12671 (17.7623%)
// Var(resid) = 0.031982 (4.4832%)
//   --> correlation coefficient between AKM worker and employer fixed effects on largest connected set = 0.2329
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// Info on the leave one out connected set:
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// mean wage: 1.4057
// variance of wage: 0.70874
// # of Movers: 9537493
// # of Firms: 1111276
// # of Person Year Observations: 67779530
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// Variance of Log Income (no controls): 0.70874
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// PLUG-IN ESTIMATES (BIASED)
// Variance of Firm Effects: 0.21194
// Covariance of Firm, Person Effects: 0.069923
// Variance of Person Effects: 0.32252
// Correlation of Firm, Person Effects: 0.26744
// Explained Variance Share (R2) - Plugin: 0.95142
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// BIAS CORRECTED ESTIMATES (JLA with 2000 simulations)
// Variance of Firm Effects: 0.19755
// Covariance of Firm, Person Effects: 0.081455
// Variance of Person Effects: 0.27864
// Correlation of Firm, Person Effects: 0.34718
// Explained Variance Share (R2) - Leave-Out: 0.90174

* variance decomposition for 2010-2014:
//   --> variance decomposition on largest connected set
// Var(income) = 0.44617 (100%)
// Var(worker FE) = 0.2512 (56.3024%)
// Var(employer FE) = 0.091422 (20.4904%)
// 2*sum(Cov(.)) = 0.08349 (18.7126%)
// Var(resid) = 0.020054 (4.4946%)
//   --> correlation coefficient between AKM worker and employer fixed effects on largest connected set = 0.2755
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// Info on the leave one out connected set:
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// mean wage: 0.8163
// variance of wage: 0.45323
// # of Movers: 18460201
// # of Firms: 2182319
// # of Person Year Observations: 125711204
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// Variance of Log Income (no controls): 0.45323
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// PLUG-IN ESTIMATES (BIASED)
// Variance of Firm Effects: 0.088349
// Covariance of Firm, Person Effects: 0.045227
// Variance of Person Effects: 0.25315
// Correlation of Firm, Person Effects: 0.30242
// Explained Variance Share (R2) - Plugin: 0.95304
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// BIAS CORRECTED ESTIMATES (JLA with 2000 simulations)
// Variance of Firm Effects: 0.082434
// Covariance of Firm, Person Effects: 0.04984
// Variance of Person Effects: 0.2279
// Correlation of Firm, Person Effects: 0.36362
// Explained Variance Share (R2) - Leave-Out: 0.90464


*** empirics: selection based on earnings >= MW and firm size >= 10, only year dummies as controls
// do "${DIR_DO}/FUN_CONNECTED.do" 0 1 10 0 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers.
// do "${DIR_DO}/FUN_AKM.do" 0 1 10 0 1 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers; `5' = whether to include covariates (edu x time, edu x age, hours, occupation, tenure, actual experience) in AKM wage equation.

* variance decomposition for 1994-1998:
// Var(ln_inc) = 0.691 (100.0%)
// Var(pe) = 0.346 (50.1%)
// Var(fe) = 0.180 (26.0%)
// Var(xb_year) = 0.000 ( 0.0%)
// 2*sum(Cov(.)) = 0.136 (19.7%)
// Var(resid) = 0.029 ( 4.2%)

* variance decomposition for 2010-2014:
// Var(ln_inc) = 0.460 (100.0%)
// Var(pe) = 0.276 (60.0%)
// Var(fe) = 0.075 (16.3%)
// Var(xb_year) = 0.000 ( 0.0%)
// 2*sum(Cov(.)) = 0.091 (19.8%)
// Var(resid) = 0.018 ( 3.9%)


*** empirics: selection based on earnings >= MW and number of switchers >= 10, only year dummies as controls
// do "${DIR_DO}/FUN_CONNECTED.do" 0 1 0 10 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers.
// do "${DIR_DO}/FUN_AKM.do" 0 1 0 10 1 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers; `5' = whether to include covariates (edu x time, edu x age, hours, occupation, tenure, actual experience) in AKM wage equation.

* variance decomposition for 1994-1998:
// Var(ln_inc) = 0.685 (100.0%)
// Var(pe) = 0.340 (49.6%)
// Var(fe) = 0.177 (25.8%)
// Var(xb_year) = 0.000 ( 0.0%)
// 2*sum(Cov(.)) = 0.138 (20.1%)
// Var(resid) = 0.030 ( 4.4%)

* variance decomposition for 2010-2014:
// Var(ln_inc) = 0.451 (100.0%)
// Var(pe) = 0.267 (59.2%)
// Var(fe) = 0.075 (16.6%)
// Var(xb_year) = 0.000 ( 0.0%)
// 2*sum(Cov(.)) = 0.091 (20.2%)
// Var(resid) = 0.018 ( 4.0%)


*** empirics: selection based on earnings >= MW and number of switchers >= 10, full set of controls
// do "${DIR_DO}/FUN_CONNECTED.do" 0 1 0 10 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers.
// do "${DIR_DO}/FUN_AKM.do" 0 1 0 10 1 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers; `5' = whether to include covariates (edu x time, edu x age, hours, occupation, tenure, actual experience) in AKM wage equation.

* variance decomposition for 1994-1998:
// Var(ln_inc) = 0.685 (100.0%)
// Var(pe) = 0.195 (28.5%)
// Var(fe) = 0.166 (24.2%)
// Var(xb_year) = 0.001 ( 0.1%)
// Var(xb_age) = 0.021 ( 3.1%)
// Var(xb_hours) = 0.000 ( 0.0%)
// Var(xb_occ) = 0.007 ( 1.0%)
// Var(xb_exp_act) = 0.014 ( 2.0%)
// 2*sum(Cov(.)) = 0.252 (36.8%)
// Var(resid) = 0.029 ( 4.2%)

* variance decomposition for 2010-2014:
// Var(ln_inc) = 0.451 (100.0%)
// Var(pe) = 0.146 (32.4%)
// Var(fe) = 0.070 (15.5%)
// Var(xb_year) = 0.000 ( 0.0%)
// Var(xb_age) = 0.021 ( 4.7%)
// Var(xb_hours) = 0.000 ( 0.0%)
// Var(xb_occ) = 0.007 ( 1.6%)
// Var(xb_exp_act) = 0.005 ( 1.1%)
// 2*sum(Cov(.)) = 0.185 (41.0%)
// Var(resid) = 0.017 ( 3.8%)


*** empirics: no selection, full set of controls
do "${DIR_DO}/FUN_CONNECTED.do" 0 0 0 0 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers.
do "${DIR_DO}/FUN_AKM.do" 0 0 0 0 1 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers; `5' = whether to include covariates (edu x time, edu x age, hours, occupation, tenure, actual experience) in AKM wage equation.

* variance decomposition for 1994-1998:
//   --> variance decomposition on largest connected set
// Var(income) = 0.71337 (100%)
// Var(worker FE) = 0.25403 (35.6095%)
// Var(employer FE) = 0.21794 (30.5513%)
// Var(edu-year FE) = 8.2423e-05 (0.011554%)
// Var(edu-age FE) = 0.021083 (2.9555%)
// Var(hours FE) = 0.00050808 (0.071223%)
// 2*sum(Cov(.)) = 0.188 (26.3546%)
// Var(resid) = 0.031719 (4.4464%)
//   --> correlation coefficient between AKM worker and employer fixed effects on largest connected set = 0.2007
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// Info on the leave one out connected set:
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// mean wage: 1.4057
// variance of wage: 0.70874
// # of Movers: 9537493
// # of Firms: 1111276
// # of Person Year Observations: 67779530
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// Variance of Residualized Log Income (cond. on controls): 0.54968
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// PLUG-IN ESTIMATES (BIASED)
// Variance of Firm Effects: 0.20095
// Covariance of Firm, Person Effects: 0.048993
// Variance of Person Effects: 0.21737
// Correlation of Firm, Person Effects: 0.23441
// Explained Variance Share (R2) - Plugin: 0.9393
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// BIAS CORRECTED ESTIMATES (JLA with 2000 simulations)
// Variance of Firm Effects: 0.18727
// Covariance of Firm, Person Effects: 0.059897
// Variance of Person Effects: 0.1763
// Correlation of Firm, Person Effects: 0.32965
// Explained Variance Share (R2) - Leave-Out: 0.87935

* variance decomposition for 2010-2014:
//   --> variance decomposition on largest connected set
// Var(income) = 0.44617 (100%)
// Var(worker FE) = 0.17951 (40.2339%)
// Var(employer FE) = 0.086199 (19.3198%)
// Var(edu-year FE) = 2.7486e-05 (0.0061604%)
// Var(edu-age FE) = 0.030585 (6.8551%)
// Var(hours FE) = 0.0013447 (0.3014%)
// 2*sum(Cov(.)) = 0.129 (28.9127%)
// Var(resid) = 0.019502 (4.371%)
//   --> correlation coefficient between AKM worker and employer fixed effects on largest connected set = 0.2464
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// Info on the leave one out connected set:
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// mean wage: 0.8163
// variance of wage: 0.45323
// # of Movers: 18460201
// # of Firms: 2182319
// # of Person Year Observations: 125711204
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// Variance of Residualized Log Income (cond. on controls): 0.31663
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// PLUG-IN ESTIMATES (BIASED)
// Variance of Firm Effects: 0.081966
// Covariance of Firm, Person Effects: 0.030546
// Variance of Person Effects: 0.15389
// Correlation of Firm, Person Effects: 0.27198
// Explained Variance Share (R2) - Plugin: 0.93784
// -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
// BIAS CORRECTED ESTIMATES (JLA with 2000 simulations)
// Variance of Firm Effects: 0.076976
// Covariance of Firm, Person Effects: 0.034381
// Variance of Person Effects: 0.13329
// Correlation of Firm, Person Effects: 0.33943
// Explained Variance Share (R2) - Leave-Out: 0.88126


*** model estimation: selection based on earnings != MW, no controls
do "${DIR_DO}/FUN_CONNECTED.do" 1 0 0 0 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers.
do "${DIR_DO}/FUN_AKM.do" 1 0 0 0 0 // `1' = whether to drop job spells with earnings = MW; `2' = whether to drop job spells with earnings < MW; `3' = whether to drop employers with fewer than ${connected_min_fsize} employees; `4' = whether to drop employers with fewer than ${connected_min_switchers} switchers; `5' = whether to include covariates (edu x time, edu x age, hours, occupation, tenure, actual experience) in AKM wage equation.

* variance decomposition for 1994-1998:
// Var(ln_inc) = 0.704 (100.0%)
// Var(pe) = 0.333 (47.3%)
// Var(fe) = 0.217 (30.8%)
// 2*sum(Cov(.)) = 0.122 (17.3%)
// Var(resid) = 0.032 ( 4.5%)

* variance decomposition for 2010-2014:
// Var(ln_inc) = 0.444 (100.0%)
// Var(pe) = 0.252 (56.8%)
// Var(fe) = 0.090 (20.3%)
// 2*sum(Cov(.)) = 0.082 (18.5%)
// Var(resid) = 0.020 ( 4.5%)
