********************************************************************************
* DESCRIPTION: Compute moments for estimation based on the PNAD survey data.
********************************************************************************


*** macros
// if "${year_est_min}" == "" | "${year_est_max}" == "" {
// 	global year_est_min = ${year_est_default_mid}
// 	global year_est_max = ${year_est_default_mid}
// }
global year_est_min_local = ${year_est_default_mid} // Note: for PNAD estimation file only, use a single year of data for ${year_est_default_mid}!
global year_est_max_local = ${year_est_default_mid} // Note: for PNAD estimation file only, use a single year of data for ${year_est_default_mid}!


*** load and clean data
* PNAD person-level file names
global file_pnad_pes_1976 = "PNAD76BR.txt"
global file_pnad_pes_1977 = "PNAD77BR.DAT"
global file_pnad_pes_1978 = "PNAD78BR.DAT"
global file_pnad_pes_1979 = "PNAD79BR.DAT"
// 1980: missing!
global file_pnad_pes_1981 = "PNAD81BR.TXT"
global file_pnad_pes_1982 = "PNAD82BR.TXT"
global file_pnad_pes_1983 = "PND83RM1.DAT PND83RM2.DAT PND83RM3.DAT PND83RM4.DAT PND83RM5.DAT PND83RM6.DAT PND83RM7.DAT PND83RM8.DAT"
global file_pnad_pes_1984 = "PNAD84BR.DAT"
global file_pnad_pes_1985 = "PNAD1985.DAT"
global file_pnad_pes_1986 = "PNAD1986.dat"
global file_pnad_pes_1987 = "PND1987N.DAT"
global file_pnad_pes_1988 = "PND88RM1.DAT PND88RM2.DAT PND88RM3.DAT PND88RM4.DAT PND88RM5.DAT PND88RM6.DAT PND88RM7.DAT PND88RM8.DAT"
global file_pnad_pes_1989 = "PND1989N.DAT"
global file_pnad_pes_1990 = "PND1990N.DAT"
// 1991: missing!
global file_pnad_pes_1992 = "PES92.DAT"
global file_pnad_pes_1993 = "PES93.DAT"
// 1994: missing!
global file_pnad_pes_1995 = "PES95.DAT"
global file_pnad_pes_1996 = "P96BR.TXT"
global file_pnad_pes_1997 = "Pessoas97"
global file_pnad_pes_1998 = "Pessoa98.txt"
global file_pnad_pes_1999 = "Pessoa99.txt"
// 2000: missing!
global file_pnad_pes_2001 = "PES2001.TXT"
global file_pnad_pes_2002 = "PES2002.txt"
global file_pnad_pes_2003 = "PES2003.txt"
global file_pnad_pes_2004 = "PES2004.TXT"
global file_pnad_pes_2005 = "PES2005.txt"
global file_pnad_pes_2006 = "PES2006.txt"
global file_pnad_pes_2007 = "PES2007.txt"
global file_pnad_pes_2008 = "PES2008.TXT"
global file_pnad_pes_2009 = "PES2009.TXT"
// 2010: missing!
global file_pnad_pes_2011 = "PES2011.txt"
global file_pnad_pes_2012 = "PES2012.txt"
global file_pnad_pes_2013 = "PES2013.txt"
global file_pnad_pes_2014 = "PES2014.txt"
global file_pnad_pes_2015 = "PES2015.txt"

* PNAD household-level file names
global file_pnad_pes_1976 = "PNAD76BR.txt"
global file_pnad_pes_1977 = "PNAD77BR.DAT"
global file_pnad_pes_1978 = "PNAD78BR.DAT"
global file_pnad_pes_1979 = "PNAD79BR.DAT"
// 1980: missing!
global file_pnad_pes_1981 = "PNAD81BR.TXT"
global file_pnad_pes_1982 = "PNAD82BR.TXT"
global file_pnad_pes_1983 = "PND83RM1.DAT PND83RM2.DAT PND83RM3.DAT PND83RM4.DAT PND83RM5.DAT PND83RM6.DAT PND83RM7.DAT PND83RM8.DAT"
global file_pnad_pes_1984 = "PNAD84BR.DAT"
global file_pnad_pes_1985 = "PNAD1985.DAT"
global file_pnad_pes_1986 = "PNAD1986.dat"
global file_pnad_pes_1987 = "PND1987N.DAT"
global file_pnad_pes_1988 = "PND88RM1.DAT PND88RM2.DAT PND88RM3.DAT PND88RM4.DAT PND88RM5.DAT PND88RM6.DAT PND88RM7.DAT PND88RM8.DAT"
global file_pnad_pes_1989 = "PND1989N.DAT"
global file_pnad_pes_1990 = "PND1990N.DAT"
// 1991: missing!
global file_pnad_dom_1992 = "DOM92.DAT"
global file_pnad_dom_1993 = "DOM93.DAT"
// 1994: missing!
global file_pnad_dom_1995 = "DOM95.DAT"
global file_pnad_dom_1996 = "D96BR.TXT"
global file_pnad_dom_1997 = "Domicilios97"
global file_pnad_dom_1998 = "Domicilio98.txt"
global file_pnad_dom_1999 = "Domicilio99.txt"
// 2000: missing!
global file_pnad_dom_2001 = "DOM2001.TXT"
global file_pnad_dom_2002 = "DOM2002.txt"
global file_pnad_dom_2003 = "DOM2003.txt"
global file_pnad_dom_2004 = "DOM2004.TXT"
global file_pnad_dom_2005 = "DOM2005.txt"
global file_pnad_dom_2006 = "DOM2006.txt"
global file_pnad_dom_2007 = "DOM2007.txt"
global file_pnad_dom_2008 = "DOM2008.TXT"
global file_pnad_dom_2009 = "DOM2009.TXT"
// 2010: missing!
global file_pnad_dom_2011 = "DOM2011.TXT"
global file_pnad_dom_2012 = "DOM2012.txt"
global file_pnad_dom_2013 = "DOM2013.txt"
global file_pnad_dom_2014 = "DOM2014.txt"
global file_pnad_dom_2015 = "DOM2015.txt"

* extract
forval y = $year_est_min_local/$year_est_max_local {
	cap confirm file "${DIR_TEMP}/PNAD/`y'"
	if _rc {
		!mkdir "${DIR_TEMP}/PNAD/`y'"
	}
	if inlist(`y', 1976, 1977, 1978, 1979, 1981, 1982, 1983, 1984, 1985, 1986, 1988, 1992, 1993, 1995, 1996, 1997, 1998, 1999, 2011, 2012) {
		!${APP_ZIPPER} e "${DIR_PNAD_DATA}/data/`y'/Dados.zip" -o"${DIR_TEMP}/PNAD/`y'" -y
	}
	else if inlist(`y', 1987, 1989, 1990) {
// 		!${APP_ZIPPER} e "${DIR_PNAD_DATA}/data/`y'/PND`y'N.DAT" -o"${DIR_TEMP}/PNAD/`y'" -y
		!cp "${DIR_PNAD_DATA}/data/`y'/PND`y'N.DAT" "${DIR_TEMP}/PNAD/`y'/PND`y'N.DAT" // Note: This does not seem to be compressed file, but rather a data (text) file.
	}
	else if inlist(`y', 2001, 2002, 2004, 2005, 2006, 2008) {
		!${APP_ZIPPER} e "${DIR_PNAD_DATA}/data/`y'/PNAD_reponderado_`y'.zip" -o"${DIR_TEMP}/PNAD/`y'" -y
	}
	else if inlist(`y', 2003, 2007) {
		!${APP_ZIPPER} e "${DIR_PNAD_DATA}/data/`y'/PNAD_reponderado_`y'_20150814.zip" -o"${DIR_TEMP}/PNAD/`y'" -y
	}
	else if `y' == 2009 {
		!${APP_ZIPPER} e "${DIR_PNAD_DATA}/data/2009/PNAD_reponderado_2009_20171228.zip" -o"${DIR_TEMP}/PNAD/2009" -y
	}
	else if `y' == 2013 {
		!${APP_ZIPPER} e "${DIR_PNAD_DATA}/data/2013/Dados_20170807.zip" -o"${DIR_TEMP}/PNAD/2013" -y
	}
	else if `y' == 2014 {
		!${APP_ZIPPER} e "${DIR_PNAD_DATA}/data/2014/Dados_20170323.zip" -o"${DIR_TEMP}/PNAD/2014" -y
	}
	else if `y' == 2015 {
		!${APP_ZIPPER} e "${DIR_PNAD_DATA}/data/2015/Dados_20170517.zip" -o"${DIR_TEMP}/PNAD/2015" -y
	}
	else if `y' < 1976 | inlist(`y', 1980, 1991, 1994, 2000, 2010) | `y' > 2015 {
		disp as error "USER ERROR: Cannot read PNAD data for year `y' because those data do not exist!"
		error 1
	}
}

* run Datazoom cleaning procedures
forval y = $year_est_min_local/$year_est_max_local {
	foreach unit in "pes" "dom" {
		disp _newline(1)
		disp "* Year = `y', unit = `unit'"
		local file_list = `""'
		foreach file of global file_pnad_`unit'_`y' {
			local file_list = `" `file_list' "${DIR_TEMP}/PNAD/`y'/`file'" "'
		}
		qui datazoom_pnad, years(`y') original(`file_list') saving("${DIR_TEMP}/PNAD/`y'") `unit' comp92
	}
}


*** process data
* load individual-level data
clear
forval y = $year_est_min_local/$year_est_max_local {
	append using "${DIR_TEMP}/PNAD/`y'/PNAD`y'pes_comp92.dta"
}

* merge in reference month from household-level data
forval y = $year_est_min_local/$year_est_max_local {
	merge m:1 id_dom using "${DIR_TEMP}/PNAD/`y'/PNAD`y'dom_comp92.dta", keepusing(v4601) keep(master match) nogen
// 	!rm -r "${DIR_TEMP}/PNAD/`y'"
}

* rename variables
rename v0302 female
rename v8005 age
rename v0602 school
rename v9001 work
rename v9008 status_agri
rename v9029 status_other
rename v9042 formal
rename v9065 formal_prev
rename v9115 u_search_current
rename v9116 u_search_before
rename v9122 retired
rename v9532 inc_1
rename v9982 inc_2
rename v1022 inc_3
rename v4601 month
rename v0101 year
rename v4729 weight

* recode variables
recode female (2=0) (4=1) (9 99=.)
recode school (2=1) (4=0) (9 99=.)
recode work (1=1) (3=0) (0 9 99=.)
recode status_agri (1 2 3 4=1) (5 6 7=2) (8 9 10=3) (11 12 13=4) (88 99=.)
recode status_other (1 2=1) (3=2) (4=3) (5 6 7=4) (8 9=.)
recode formal (2=1) (4=0) (9 99=.)
recode formal_prev (1=1) (3=0) (9 99=.)
recode u_search_current (1=1) (3=0) (9 99=.)
recode u_search_before (2=1) (4=0) (9 99=.)
recode retired (2=1) (4=0) (9 99=.)

* relabel variables
label var female "Ind: Female?"
label var age "Age (years)"
label var school "Ind: In school?"
label var work "Ind: Worked during reference week?"
label var status_agri "Work status in agriculture"
label var status_other "Work status outside of agriculture"
label var formal "Ind: Legally employed?"
label var formal_prev "Ind: Legally employed in previous job?"
label var retired "Ind: Retired?"
label var weight "Sampling weight"

* merge in nominal minimum wage
merge m:1 year month using "${DIR_TEMP}/IPEA/mw_nominal_monthly.dta", keep(match) keepusing(mw_nominal) nogen

* manually generate nominal minimum wage -- XXX EXTEND TO OTHER YEARS / MONTHS?!?
// gen int mw_nominal = .
// label var mw_nominal "Nominal minimum wage (current BRL)"
// replace mw_nominal = 11.957091 if year == 1994 & month == 1
// replace mw_nominal = 15.574182 if year == 1994 & month == 2
// replace mw_nominal = 18.290305 if year == 1994 & month == 3
// replace mw_nominal = 26.011716 if year == 1994 & month == 4
// replace mw_nominal = 37.413735 if year == 1994 & month == 5
// replace mw_nominal = 53.682575 if year == 1994 & month == 6
// replace mw_nominal = 64.79 if year == 1994 & inrange(month, 7, 8)
// replace mw_nominal = 70 if (year == 1994 & inrange(month, 9, 12)) | (year == 1995 & inrange(month, 1, 4))
// replace mw_nominal = 100 if (year == 1995 & inrange(month, 5, 12)) | (year == 1996 & inrange(month, 1, 4))
// replace mw_nominal = 112 if (year == 1996 & inrange(month, 5, 12)) | (year == 1997 & inrange(month, 1, 4))
// replace mw_nominal = 120 if (year == 1997 & inrange(month, 5, 12)) | (year == 1998 & inrange(month, 1, 4))
// replace mw_nominal = 130 if year == 1998 & inrange(month, 5, 12)

* generate other variables
${gtools}egen byte status = rowmin(status_agri status_other)
label var status "Work status"
gen byte u_search = max(u_search_current, u_search_before)
label var u_search "Ind: Searched for job during last month?"
// ${gtools}egen long inc = rowtotal(inc_1 inc_2 inc_3)
// label var inc "Income from any job (BRL)"
gen long inc = inc_1
label var inc "Earnings from main job (BRL)"
gen byte inc_pos = (inc_1 > 0) if inc < .
label var inc_pos "Ind: Positive income?"
gen byte inc_mw = (inc_1 == mw_nominal) if inc < .
label var inc_mw "Ind: Income equals minimum wage?"

* label variables
label define fem_l 0 "Male" 1 "Female", replace
label val female fem_l
label define sch_l 0 "Not in school" 1 "In school", replace
label val school sch_l
label define wor_l 0 "Not working" 1 "Working", replace
label val work wor_l
label define sta_l 1 "Employed" 2 "Self-employed" 3 "Employer" 4 "Unpaid", replace
label val status_agri sta_l
label val status_other sta_l
label val status sta_l
label define for_l 0 "Informal" 1 "Formal", replace
label val formal for_l
label val formal_prev for_l
label define u_s_l 0 "Did not search for job" 1 "Searched for job", replace
label val u_search_current u_s_l
label val u_search_before u_s_l
label val u_search u_s_l
label define ret_l 0 "Not retired" 1 "Retired", replace
label val retired ret_l
label define inc_l 0 "No income" 1 "Positive income", replace
label val inc_pos inc_l

* adjust variables
replace inc = 0 if inc < . & status == 4
replace inc_pos = 0 if inc_pos < . & status == 4
// replace formal = . if inc_pos == 0

* keep only observations with nonmissing key variables
keep if !inlist(., weight)

* keep only relevant variables
keep year female age inc work school retired status formal u_search inc_pos inc_mw mw_nominal weight

* order variables
order year female age inc work school retired status formal u_search inc_pos inc_mw mw_nominal weight

* save cleaned data
prog_comp_desc_sum_save "${DIR_TEMP}/PNAD/pnad_clean_${year_est_min_local}_${year_est_max_local}.dta"


*** compute statistics
* load data
use "${DIR_TEMP}/PNAD/pnad_clean_${year_est_min_local}_${year_est_max_local}.dta", clear

* classify individuals in labor force
gen byte lab_force = ((status == 1 & inc_pos == 1) | (u_search == 1)) if (status < . & inc_pos < .) | u_search < . // define labor force as the pool of workers who are employed and earning positive income (status == 1 & inc_pos == 1) or searching for employment (u_search == 1) = E + N in structural model
label var lab_force "Ind: In labor force = earning income or searching?"
label define lab_l 0 "Not in labor force" 1 "In labor force", replace
label val lab_force lab_l

* classify individuals in formal sector and earning positive income
gen byte formal_pos = (formal == 1 & inc_pos == 1) if formal < . & inc_pos < .
label var formal_pos "Ind: In formal sector and earning positive income?"
label define f_p_l 0 "Informal or earning no income" 1 "Formal and earning positive income", replace
label val formal_pos f_p_l

* classify individuals in formal sector and earning the minimum wage
gen byte formal_mw = (formal == 1 & inc_mw == 1) if formal < . & inc_mw < .
label var formal_mw "Ind: In formal sector and earning minimum wage?"
label define f_m_l 0 "Informal or not earning minimum wage" 1 "Formal and earning minimum wage", replace
label val formal_pos f_p_l

* classify individuals in informal sector and earning positive income = part of nonemployed in structural model
gen byte informal_pos = (formal == 0 & inc_pos == 1) if formal < . & inc_pos < .
label var informal_pos "Ind: In informal sector and earning positive income = part of N in structural model?"
label define i_p_l 0 "Formal or earning no income" 1 "Informal and earning income", replace
label val informal_pos i_p_l

* classify nonemployed = part of N in structural model
gen byte nonemp = (inc_pos == 0 & u_search == 1) | (inc_pos == 1 & status == 2 & u_search == 1) if (inc_pos < . & u_search < .) // | (inc_pos < . & status < . & u_search < .)
label var nonemp "Ind: nonemployed = part of N in structural model?"

* classify employment state
gen byte empstat = .
// replace empstat = 0 if formal_pos == 0 // i.e., if informally employed, working as self-employed or employer, or unemployed
replace empstat = 0 if formal_pos == 0 | u_search == 1 | formal == . // i.e., if informally employed, working as self-employed or employer, or unemployed
replace empstat = 1 if formal_pos == 1 & formal_mw == 0
replace empstat = 2 if formal_pos == 1 & formal_mw == 1
label var empstat "Employment status"
label define emp_l 0 "Nonemployed (informal, unemployed, searching)" 1 "Formally empl., != MW" 2 "Formally empl., == MW", replace
label val empstat emp_l

* make selections
keep if ///
	inrange(female, ${gender_min} - 1, ${gender_max} - 1) /// selection based on gender
	& inrange(age, ${age_min}, ${age_max}) /// selection based on age
	& lab_force == 1 /// selection based on being in labor force
	& inlist(status, 1, 2, 3, 4) // selection based on being employed, self-employed, employer, or unpaid -- XXX TEST

* save processed data
prog_comp_desc_sum_save "${DIR_TEMP}/PNAD/pnad_processed_${year_est_min_local}_${year_est_max_local}.dta"


*** save PNAD household survey data for estimation
* load processed data
use "${DIR_TEMP}/PNAD/pnad_processed_${year_est_min_local}_${year_est_max_local}.dta", clear

* keep only relevant variables
keep year empstat weight

* order and sort
order year empstat weight
sort year empstat weight

* save
prog_comp_desc_sum_save "${DIR_TEMP}/PNAD/est_pnad_${year_est_min_local}_${year_est_max_local}.dta"
// save "${DIR_RESULTS}/${section}/est_pnad_${year_est_min_local}_${year_est_max_local}.dta", replace


*** summarize employment states, incl. formal vs. informal sectors
// * load processed data
// use ///
// 	work status formal u_search inc inc_pos inc_mw lab_force formal_pos formal_mw informal_pos nonemp mw_nominal weight ///
// 	using "${DIR_TEMP}/PNAD/pnad_processed_${year_est_min_local}_${year_est_max_local}.dta", clear

// * compute formal employment share
// sum lab_force [fw=weight] //, meanonly
// local N_lab_force = r(mean)
// sum formal_pos [fw=weight] //, meanonly
// local N_formal_pos = r(mean)
// tab formal_pos [fw=weight]
// tab formal_pos [fw=weight], m
// local share_formal_pos = `N_formal_pos'/`N_lab_force'
// disp "Formal employment share = share of employed in structural model = `share_formal_pos'"

// * tabulate employment states
// tab empstat [fw=weight]
// tab empstat [fw=weight], m

// * histogram of earnings
// hist inc if inrange(inc, 0, 5000), name(inc, replace)

// gen float inc_mw_mult = inc/mw_nominal
// label var inc_mw_mult "Earnings from main job (multiples of MW)"
// hist inc_mw_mult if inrange(inc_mw_mult, 0, 50), name(inc_mw_mult, replace)

// gen float ln_inc = ln(inc)
// label var ln_inc "Earnings from main job (log BRL)"
// hist ln_inc if inrange(ln_inc, 2, 10), name(ln_inc, replace)

// gen float ln_inc_mw_mult = ln(inc_mw_mult)
// label var ln_inc_mw_mult "Earnings from main job (log multiples of MW)"
// hist ln_inc_mw_mult if inrange(ln_inc_mw_mult, -2, 6), name(ln_inc_mw_mult, replace)

// * plots
// tw ///
// 	(hist ln_inc_mw_mult if ln_inc_mw_mult == 0, color(red) start(-0.01) width(.2)) ///
// 	(hist ln_inc_mw_mult if inrange(ln_inc_mw_mult, -2.01, 4) & ln_inc_mw_mult != 0, color(blue) start(-2.01) width(.2)), name(ln_inc_mw_mult, replace)
