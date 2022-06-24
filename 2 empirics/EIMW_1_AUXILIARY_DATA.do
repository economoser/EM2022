********************************************************************************
* DESCRIPTION: Generate auxiliary datasets.
********************************************************************************


*** nominal and real minimum wage from IPEA
* load data on nominal minimum wage (http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=1739471028)
import excel using ///
	"${DIR_CONVERSION}/min_wage/ipeadata[05-11-2021-02-29] NOMINAL.xls" ///
	, firstrow case(lower) clear

* rename and label
rename data date_str
label var date_str "Date (string)"
rename saláriomínimovigentermi mw_nominal
label var mw_nominal "Nominal minimum wage (current BRL)"

* generate year
gen int year = real(substr(date_str, 1, 4))
label var year "Year"

* generate month
gen int month = real(substr(date_str, -2, 2))
label var month "Month"

* create date variable in Stata date format
gen int date_num = ym(year,month)
format date_num %tm
label var date_num "Date (numeric)"

* create numeric date variable
gen float date_plot = year + (month - 1)/12
label var date_plot "Date (numeric)"

* keep only years that overlap with RAIS data
keep if inrange(year, ${year_data_min}, ${year_data_max})

* save monthly data
order year month date_str date_num date_plot mw_nominal
prog_comp_desc_sum_save "${DIR_TEMP}/IPEA/mw_nominal_monthly.dta"

* collapse to yearly data
${gtools}collapse (mean) mw_nominal, by(year)
label var mw_nominal "Nominal minimum wage (current BRL)"

* save yearly data
order year mw_nominal
prog_comp_desc_sum_save "${DIR_TEMP}/IPEA/mw_nominal_yearly.dta"

* load data on real minimum wage (http://www.ipeadata.gov.br/ExibeSerie.aspx?serid=37667)
import excel using ///
	"${DIR_CONVERSION}/min_wage/ipeadata[05-11-2021-02-29] REAL.xls" ///
	, firstrow case(lower) clear

* rename and label
rename data date_str
label var date_str "Date (string)"
rename saláriomínimorealrdoúlt mw_real
label var mw_real "Real minimum wage (constant September 2021 BRL)"

* generate year
gen int year = real(substr(date_str, 1, 4))
label var year "Year"

* generate month
gen int month = real(substr(date_str, -2, 2))
label var month "Month"

* create date variable in Stata date format
gen int date_num = ym(year,month)
format date_num %tm
label var date_num "Date (numeric)"

* create numeric date variable
gen float date_plot = year + (month - 1)/12
label var date_plot "Date (numeric)"

* keep only years that overlap with RAIS data
keep if inrange(year, ${year_data_min}, ${year_data_max})

* save monthly data
order year month date_str date_num date_plot mw_real
prog_comp_desc_sum_save "${DIR_TEMP}/IPEA/mw_real_monthly.dta"

* collapse to yearly data
${gtools}collapse (mean) mw_real, by(year)
label var mw_real "Real minimum wage (constant September 2021 BRL)"

* save yearly data
order year mw_real
prog_comp_desc_sum_save "${DIR_TEMP}/IPEA/mw_real_yearly.dta"

* combine monthly datasets
use "${DIR_TEMP}/IPEA/mw_nominal_monthly.dta", clear
merge 1:1 year month using "${DIR_TEMP}/IPEA/mw_real_monthly.dta", keep(match) nogen
order year month date_str date_num date_plot mw_nominal mw_real
prog_comp_desc_sum_save "${DIR_TEMP}/IPEA/mw_monthly.dta"

* combine yearly datasets
use "${DIR_TEMP}/IPEA/mw_nominal_yearly.dta", clear
merge 1:1 year using "${DIR_TEMP}/IPEA/mw_real_yearly.dta", keep(match) nogen
order year mw_nominal mw_real
prog_comp_desc_sum_save "${DIR_TEMP}/IPEA/mw_yearly.dta"
