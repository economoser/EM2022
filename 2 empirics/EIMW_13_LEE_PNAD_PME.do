********************************************************************************
* DESCRIPTION: Analyze earnings and employment in cross-sectional PNAD and
*              longitudinal PME household survey data.
********************************************************************************


*** macros
* years to loop over
// global years_pnad = "1976 1977 1978 1979      1981 1982 1983 1984 1985 1986 1987 1988 1989 1990      1992 1993      1995 1996 1997 1998 1999      2001 2002 2003 2004 2005 2006 2007 2008 2009      2011 2012 2013 2014 2015" // Note: 2000 and 2010 are missing due to those being Census years. E.g., "1996 1997 1998 1999      2001 2002 2003 2004 2005 2006 2007 2008 2009      2011 2012"
global years_pnad = "1996 1997 1998 1999      2001 2002 2003 2004 2005 2006 2007 2008 2009      2011 2012 2013 2014 2015" // Note: 2000 and 2010 are missing due to those being Census years. E.g., "1996 1997 1998 1999      2001 2002 2003 2004 2005 2006 2007 2008 2009      2011 2012"
// global years_pme_antiga = "1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001" // E.g., "1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001"
global years_pme_antiga = "1996 1997 1998 1999 2000 2001" // E.g., "1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001"
global years_pme_nova = "2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016" // E.g., "2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012"

* selection criteria
global use_conds_pnad = "gender == 1 & inrange(age,18,49) & in_school < ."
global use_conds_pme = "stratid < . & psu < . & gender == 1 & inrange(age,18,49) & in_school < ."
global select_fulltime = "" // "" = no restriction; "& inlist(hours,40)" = only 40 hours; "& inlist(hours,44)" = only 44 hours; "& inlist(hours,40,44)" = 40 or 44 hours
global adjust_hours = 0 // 0 = no adjustment; 1 = adjust earnings by factor (44 / hours)

* variable names
global earnings_pnad_1980 = "renda_mensal_ocup_prin" // renda_mensal_din = monthly monetary income from main job; renda_mensal_ocup_prin = monthly monetary + non-monetary income from main job
global earnings_pnad_1990 = "v9532" // v9532 = monthly monetary income from main job; v9535 = monthly non-monetary income from main job
global earnings_pme = "vI4182" // v4182 = usual gross income; vI4182 = imputed usual gross income
global weight_pme = "weight" // v4182 = usual gross income; vI4182 = imputed usual gross income
global kaitz_switch = "log_mw_p50_f" // "log_mw_p50_f" = formal sector Kaitz index on RHS of regression; "log_mw_p50_i" = informal sector; "log_mw_p50_fi" = both formal&informal sector

* percentiles to store in state-level data
global percentiles_list = "10 20 30 40 60 70 80 90"

* critical value for regressions
global crit_val = 2.576 // 1.645 = 90% level, 1.960 = 95% level, 2.576 = 99% level

* subgroup analysis by education groups
global sel = ""
global sel_edu1 = "& edu_degree == 1"
global sel_edu2 = "& edu_degree == 2"
global sel_edu3 = "& edu_degree == 3"
global sel_edu4 = "& edu_degree == 4"

* section switches
global pnad_extract   	= 0 // 0 = do not extract PNAD data; 1 = extract PNAD data
global pnad 			= 0 // 0 = do not run PNAD section; 1 = run PNAD section
	global pnad_clean 	= 0 // 0 = do not run Data Zoom to produce cleaned PNAD, 1 = run Data Zoom to produce cleaned PNAD
	global distribution = 1 // 0 = do not run; 1 = compute share at, below, and around MW in PNAD
	global employment 	= 1 // 0 = do not run; 1 = compute employment rate and labor force participation rate in PNAD
	global formal 		= 2 // 0 = run for informal workers only; 1 = run for formal workers only; 2 = run for all informal and formal workers in PNAD
	global others 		= 0 // 0 = do not run; 1 = run other LHS variables in PNAD
	global comp1990 	= 1 // 0 = do not run; 1 = run more LHS variables from individual 1990s compatible data in PNAD
	global hh 			= 1 // 0 = do not run; 1 = run more LHS variables from household 1990s compatible data in PNAD
	global percentiles 	= 1 // 0 = do not run; 1 = run additional Lee (1999) / AMS (2016) earnings percentiles exercise in PNAD
global pme_extract   	= 0 // 0 = do not extract PME data; 1 = extract PME data
global pme 				= 1 // 0 = do not run PME section; 1 = run PME section
	global pme_clean 	= 1 // 0 = do not run Data Zoom to produce cleaned PME, 1 = run Data Zoom to produce cleaned PME
	global transitions 	= 1 // 0 = do not run; 1 = compute transition dynamics in PME
global regressions 		= 0 // 0 = do not run regressions section; 1 = run regressions section
global plots 			= 0 // 0 = do not run plots section; 1 = run plots section


*** input data
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

* input data: MW levels in survey month (September) of each year
global minwage1976 = 2.79272727e-10
global minwage1977 = 4.02327273e-10
global minwage1978 = 5.67272727e-10
global minwage1979 = 8.24727273e-10
global minwage1980 = 1.50894545e-09
global minwage1981 = 3.078e-09
global minwage1982 = 6.039e-09
global minwage1983 = 1.26458182e-08
global minwage1984 = 3.53367273e-08
global minwage1985 = 1.21134545e-07
global minwage1986 = 2.924e-07
global minwage1987 = 8.727e-07
global minwage1988 = 6.895e-06
global minwage1989 = .00009072
global minwage1990 = .00220229
global minwage1991 = .01527273
global minwage1992 = .18988616
global minwage1993 = 3.4930909
global minwage1994 = 70
global minwage1995 = 100
global minwage1996 = 112
global minwage1997 = 120
global minwage1998 = 130
global minwage1999 = 136
global minwage2000 = 151
global minwage2001 = 180
global minwage2002 = 200
global minwage2003 = 240
global minwage2004 = 260
global minwage2005 = 300
global minwage2006 = 350
global minwage2007 = 380
global minwage2008 = 415
global minwage2009 = 465
global minwage2010 = 510
global minwage2011 = 545
global minwage2012 = 622
global minwage2013 = 678
global minwage2014 = 724
global minwage2015 = 788
global minwage2016 = 880
global minwage2017 = 937
global minwage2018 = 954


*** extract and clean PNAD and PME household survey files
* extract PNAD
if $pnad_extract {
	foreach y of global years_pnad {
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
}

* extract PME
if $pme_extract {
	foreach y in $years_pme_antiga $years_pme_nova {
		cap confirm file "${DIR_TEMP}/PME/`y'"
		if _rc {
			!mkdir "${DIR_TEMP}/PME/`y'"
		}
		local y_substr = substr("`y'", -2, 2)
		if inlist(`y', 1980, 1981, 1983, 1984, 1986, 1987, 1988, 1989) {
			foreach state in BA MG PE RJ RS SP {
	// 			!${APP_ZIPPER} e "${DIR_PME_DATA}/data/`y'/PME`y_substr'`state'.DAT" -o"${DIR_TEMP}/PME/`y'" -y
				!cp "${DIR_PME_DATA}/data/`y'/PME`y_substr'`state'.DAT" "${DIR_TEMP}/PME/`y'/PME`y_substr'`state'.DAT" // Note: This does not seem to be compressed file, but rather a data (text) file.
			}
		}
		else if inlist(`y', 1982) {
			foreach v in 1 2 {
				foreach state in BA MG PE RJ RS SP {
	// 				!${APP_ZIPPER} e "${DIR_PME_DATA}/data/`y'/PME`y_substr'`state'`v'.DAT" -o"${DIR_TEMP}/PME/`y'" -y
					!cp "${DIR_PME_DATA}/data/`y'/PME`y_substr'`state'`v'.DAT" "${DIR_TEMP}/PME/`y'/PME`y_substr'`state'`v'.DAT" // Note: This does not seem to be compressed file, but rather a data (text) file.
				}
			}
		}
		else if inlist(`y', 1985) {
			foreach state in BA BR MG PE RJ RS SP {
	// 			!${APP_ZIPPER} e "${DIR_PME_DATA}/data/`y'/PME`y_substr'`state'.DAT" -o"${DIR_TEMP}/PME/`y'" -y
				!cp "${DIR_PME_DATA}/data/`y'/PME`y_substr'`state'.DAT" "${DIR_TEMP}/PME/`y'/PME`y_substr'`state'.DAT" // Note: This does not seem to be compressed file, but rather a data (text) file.
			}
		}	
		else if inlist(`y', 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000) {
			!${APP_ZIPPER} e "${DIR_PME_DATA}/data/`y'/pme`y'.zip" -o"${DIR_TEMP}/PME/`y'" -y
		}
		else if `y' == 2001 {
			foreach state in BA MG PE PR RJ RS SP {
				!${APP_ZIPPER} e "${DIR_PME_DATA}/data/2001_CD/PME2001`state'.zip" -o"${DIR_TEMP}/PME/2001" -y
			}
		}
		else if `y' == 2002 {
			forval m = 3/12 {
				if `m' < 10 local m_str = "0`m'"
				else local m_str = "`m'"
				!${APP_ZIPPER} e "${DIR_PME_DATA}/data/2002_FTP_two_missing_months/PMEnova.`m_str'2002.zip" -o"${DIR_TEMP}/PME/2002" -y
			}
		}
		else if inlist(`y', 2003, 2004, 2005, 2006, 2007) {
			forval m = 1/12 {
				if `m' < 10 local m_str = "0`m'"
				else local m_str = "`m'"
				!${APP_ZIPPER} e "${DIR_PME_DATA}/data/`y'/PMEnova.`m_str'`y'.zip" -o"${DIR_TEMP}/PME/`y'" -y
			}
		}
		else if `y' == 2008 {
			foreach m_str in jan fev mar abr mai jun jul ago set out nov dez {
				!${APP_ZIPPER} e "${DIR_PME_DATA}/data/2008/`m_str'_2008.zip" -o"${DIR_TEMP}/PME/2008" -y
			}
		}
		else if inlist(`y', 2009, 2010, 2011, 2012, 2013, 2014, 2015) {
			forval m = 1/12 {
				if `m' < 10 local m_str = "0`m'"
				else local m_str = "`m'"
				!${APP_ZIPPER} e "${DIR_PME_DATA}/data/`y'/PMEnova_`m_str'`y'.zip" -o"${DIR_TEMP}/PME/`y'" -y
			}
		}
		else if `y' == 2016 {
			forval m = 1/2 {
				local m_str = "0`m'"
				!${APP_ZIPPER} e "${DIR_PME_DATA}/data/`y'/PMEnova_`m_str'`y'.zip" -o"${DIR_TEMP}/PME/`y'" -y
			}
		}
		else if `y' < 1980 | `y' > 2016 {
			disp as error "USER ERROR: Cannot read PME data for year `y' because those data do not exist!"
			error 1
		}
	}

	* move PME
	forval y = 1991/2001 {
		disp "--> moving PME-Antiga files for year `y'"
		cap confirm file "${DIR_TEMP}/PME/pme_antiga"
		if _rc {
			!mkdir "${DIR_TEMP}/PME/pme_antiga"
		}
		local list_files: dir "${DIR_TEMP}/PME/`y'" files "*.*"
		foreach file of local list_files {
			!mv "${DIR_TEMP}/PME/`y'/`file'" "${DIR_TEMP}/PME/pme_antiga/`file'"
		}
	}
	forval y = 2002/2016 {
		disp "--> moving PME-Nova files for year `y'"
		cap confirm file "${DIR_TEMP}/PME/pme_nova"
		if _rc {
			!mkdir "${DIR_TEMP}/PME/pme_nova"
		}
		local list_files: dir "${DIR_TEMP}/PME/`y'" files "*.*"
		foreach file of local list_files {
			!mv "${DIR_TEMP}/PME/`y'/`file'" "${DIR_TEMP}/PME/pme_nova/`file'"
		}
	}
}


********************************************************************************
* PNAD
********************************************************************************
if $pnad {


	*** main code
	disp "--> make PNAD data compatible across years"
	if $pnad_clean {
		foreach y of global years_pnad {
			disp _newline(1)
			disp "   ...year `y'"
			foreach unit in "pes" "dom" {
				foreach comp in 81 92 {
// 				foreach comp in 92 {
					disp "      --> unit = `unit', comp = `comp'"
					local file_list = `""'
					foreach file of global file_pnad_`unit'_`y' {
						local file_list = `" `file_list' "${DIR_TEMP}/PNAD/`y'/`file'" "'
					}
					if !("`unit'" == "dom" & `comp' == 81) qui datazoom_pnad, years(`y') original(`file_list') saving("${DIR_TEMP}/PNAD/`y'") `unit' comp`comp'
				}
			}
		}
	}
	
	/*
	NOTES:
	- may want to exclude "military&public servants" (v414==1)
	- code self-employed as informal (discard their earnings)
	- re-define labor force status, unemployed etc. NOT using earnings!
	*/

	disp "--> process compatible PNAD data by year"
	* generate counter
	local counter_max = 0
	foreach y_inner of global years_pnad {
		if `counter_max' == 0 local y_min = `y_inner'
		local ++counter_max
	}
	local counter = 1
	foreach y of global years_pnad {
		* load data
		// individual 1990s compatible data:
		if ${comp1990} == 1 {
			local use_vars_1990 = "v0301 v0302 v0602 cond_ocup_s v4706 v4729 v9062 v5062 v8005 v9034 v9042 v9035 v9065 v9083 v9080 v9081 v9113 v9120 v9122 id_dom v0403 v1181c v1182c v1110c v9087"
			qui use `use_vars_1990' using "${DIR_TEMP}/PNAD/`y'/PNAD`y'pes_comp92.dta", clear
			//cond_ocup_s = v4705
			//v4706 = 1, 2, ..., 14
			rename v0301 hh_mem_n
			rename id_dom hh_n
			qui ${gtools}egen long person_id = group(hh_n hh_mem_n)
			rename v0403 fam_hh_n
			qui ${gtools}egen long fam_n = group(hh_n fam_hh_n)
			drop hh_mem_n fam_hh_n
			rename v0302 gender
			qui recode gender (2 = 1) (4 = 0)
			label define gender_l 0 "female" 1 "male", replace
			label val gender gender_l
			rename v8005 age
			rename v0602 in_school
			qui recode in_school (2 = 1) (4 = 0) (nonmissing = .)
			rename cond_ocup_s job
			rename v4706 job_type
			qui recode job_type (6 7 8 = 1) (1 2 3 4 5 = 2) (9 = 3) (10 = 4) (11 12 13 = 5) (14 = .)
			label define job_type_l 1 "domestic worker" 2 "employee" 3 "self-employed" 4 "employer" 5 "unpaid", replace
			label val job_type job_type_l
			qui gen byte military_public = .
			rename v9034 military
			rename v9035 public
			qui replace military_public = 1 if military == 2 | public == 1
			qui replace military_public = 0 if military == 4 & public == 3
			drop military public
			rename v9042 formal_emp
			qui recode formal_emp (2 = 1) (4 = 0) (nonmissing = .)
			qui replace formal_emp = 1 if military_public == 1 /* this has the same tab values as the one auto-constructed for 1980s-compatible data! */
			drop military_public
			qui gen byte military_public_f = .
			rename v9080 military_f
			rename v9081 public_f
			rename v9113 military_public_f2
			qui replace military_public_f = 1 if ((military_f == 2 | public_f == 1) | military_public_f2 == 1)
			qui replace military_public_f = 0 if ((military_f == 4 & public_f == 3) & military_public_f2 == 3)
			drop military_f public_f military_public_f2
			rename v9065 formal_emp_f1
			rename v9083 formal_emp_f2
			qui gen byte formal_emp_f = .
			qui replace formal_emp_f = formal_emp_f1 if formal_emp_f1 < .
			qui replace formal_emp_f = formal_emp_f2 if formal_emp_f2 < .
			qui recode formal_emp_f (1 = 1) (3 = 0) (nonmissing = .)
			qui replace formal_emp_f = 1 if military_public_f == 1 /* this has different tab values than the one auto-constructed for 1980s-compatible data! */
			drop military_public_f formal_emp_f1 formal_emp_f2
			rename v9062 ee_eue_trans
			qui recode ee_eue_trans (2 = 1) (4 = 0) (nonmissing = .)
			rename v9122 retired
			qui recode retired (2 = 1) (4 = 0) (nonmissing = .)
			rename v5062 migrated_state
			qui recode migrated_state (0 = 1) (1/9 = 0) (nonmissing = .)
			rename v9120 ret_contr
			qui recode ret_contr (2 = 1) (4 = 0) (nonmissing = .)
			rename v1181c child_born_month
			qui recode child_born_month (. = -999)
			qui bys fam_n (child_born_month): replace child_born_month = child_born_month[_N]
			rename v1182c child_born_year
			qui recode child_born_year (. = -999)
			qui bys fam_n (child_born_year): replace child_born_year = child_born_year[_N]
			qui gen long child_born_date = mdy(child_born_month, 30, child_born_year)
			qui gen byte child_born = ((date("30/09/`y'", "DMY") - child_born_date) <= 366)
			drop child_born_month child_born_year child_born_date
			rename v1110c child_dead
			qui recode child_dead (2 = 1) (4 = 0) (. = -999) (nonmissing = -999)
			qui bys fam_n (child_dead): replace child_dead = child_dead[_N]
			qui recode child_dead (-999 = .)
			rename v9087 union_member
			qui recode union_member (1 = 1) (3 = 0) (nonmissing = .)
			rename v4729 weight
			qui keep if ${use_conds_pnad}
			drop fam_n gender age
			order person_id weight *
			sort person_id
			qui compress
			qui save "${DIR_TEMP}/PNAD/temp.dta", replace
		}
		// individual 1980s compatible data:
	// 	local use_vars_1980 = "ordem id_dom num_fam sexo idade freq_escola ${earnings_pnad_1980} renda_ocup_prin_def renda_aposentadoria pos_ocup_sem tomou_prov_semana tem_carteira_assinada uf grau_nao_freq tinha_outro_trab horas_trab_sem renda_abono renda_mensal_prod tinha_cart_assin_ant_ano urbana ler_escrever educa peso"
		local use_vars_1980 = "ordem id_dom num_fam sexo idade freq_escola ${earnings_pnad_1980} renda_ocup_prin_def                                  tomou_prov_semana                       uf grau_nao_freq tinha_outro_trab horas_trab_sem renda_abono renda_mensal_prod                          urbana ler_escrever educa peso"
		qui use `use_vars_1980' using "${DIR_TEMP}/PNAD/`y'/PNAD`y'pes_comp81.dta", clear
		rename ordem hh_mem_n
		rename id_dom hh_n
		qui ${gtools}egen long person_id = group(hh_n hh_mem_n)
		rename num_fam fam_hh_n
		qui ${gtools}egen long fam_n = group(hh_n fam_hh_n)
		drop hh_mem_n fam_hh_n
		rename freq_escola in_school
		rename ${earnings_pnad_1980} earnings
		rename renda_ocup_prin_def earnings_def
		qui gen float log_earn_mw = ln(earnings) - ln(${minwage`y'})
		qui gen float log_earn_d = ln(earnings_def)
	// 	rename renda_aposentadoria income_retirement
		rename tomou_prov_semana searching
	// 	rename tem_carteira_assinada formal_emp
	// 	qui replace formal_emp = 0 if pos_ocup_sem == 2
		rename uf region
		qui destring region, replace
		rename grau_nao_freq edu_degree
		rename tinha_outro_trab second_job
		rename horas_trab_sem hours
// 		qui gen float log_hours = ln(hours)
		rename renda_abono income_bonus
		rename renda_mensal_prod income_goods
	// 	rename tinha_cart_assin_ant_ano formal_emp_f
		rename urbana urban
		rename ler_escrever literate
		rename educa edu_years
		rename peso weight
		rename sexo gender
		label define gender_l 0 "female" 1 "male", replace
		label val gender gender_l
		rename idade age
		qui keep if ${use_conds_pnad}
		drop gender
// 		drop age
		order person_id region in_school earnings weight *
		sort person_id
		// merge individual 1980s compatible data with 1990s compatible data:
		if ${comp1990} == 1 {
			qui merge 1:1 person_id using "${DIR_TEMP}/PNAD/temp.dta"
			assert _merge == 3
			drop _merge
			qui erase "${DIR_TEMP}/PNAD/temp.dta"
		}
		drop person_id
		// household 1990s compatible data:
		if ${hh} == 1 {
			qui compress
			qui save "${DIR_TEMP}/PNAD/temp.dta", replace
			local use_vars_hh = "id_dom v4614 v0203 v0204 v0207 v0208 v0209 v0211 v0215 telefone v0222 v0221 v0225 v0227 v0226 v0228 v0229 v0230 v0219"
			qui use `use_vars_hh' using "${DIR_TEMP}/PNAD/`y'/PNAD`y'dom_comp92.dta", clear
			rename id_dom hh_n
			rename v4614 income_hh
			rename v0203 walls_solid
			qui recode walls_solid (1 = 1) (nonmissing = 0)
			rename v0204 roof_solid
			qui recode roof_solid (1 2 = 1) (nonmissing = 0)
			rename v0207 house_owner
			qui recode house_owner (1 2 = 1) (nonmissing = 0)
			rename v0208 rent
			rename v0209 mortgage
			rename v0211 water_piped
			qui recode water_piped (1 = 1) (3 = 0) (nonmissing = .)
			rename v0215 bathroom
			qui recode bathroom (1 = 1) (3 = 0) (nonmissing = .)
			rename telefone phone
			qui gen byte stove = (v0222 == 2 | v0221 == 1) if (v0222 < 9 | v0221 < 9)
			drop v0222 v0221
			rename v0225 radio
			qui recode radio (1 = 1) (3 = 0) (nonmissing = .)
			qui gen byte tv = (v0227 == 1 | v0226 == 2) if (v0227 < 9 | v0226 < 9)
			drop v0227 v0226
			qui gen byte fridge_freezer = (inlist(v0228,2,4) | v0229 == 1) if (v0228 < 9 | v0229 < 9)
			drop v0228 v0229
			rename v0230 washing_mac
			qui recode washing_mac (2 = 1) (4 = 0) (nonmissing = .)
			rename v0219 light_elec
			qui recode light_elec (1 = 1) (3 5 = 0) (nonmissing = .)
			order hh_n income_hh rent mortgage *
			sort hh_n
			qui compress
			qui save "${DIR_TEMP}/PNAD/temp_hh.dta", replace
			qui use "${DIR_TEMP}/PNAD/temp.dta", clear
			qui merge m:1 hh_n using "${DIR_TEMP}/PNAD/temp_hh.dta"
			assert inlist(_merge, 2, 3)
			qui keep if _merge == 3
			drop _merge
			qui erase "${DIR_TEMP}/PNAD/temp.dta"
			qui erase "${DIR_TEMP}/PNAD/temp_hh.dta"
		}
		drop hh_n
		
		* generate modal earnings
		foreach m in "min" "max" {
			qui ${gtools}egen float earnings_`m'mode = mode(earnings), `m'mode
			qui replace earnings_`m'mode = . if earnings != earnings_`m'mode
			sum earnings_`m'mode [fw = weight], meanonly
			local `m'mode_nom_trunc: di %8.0f `r(mean)'
			
			qui ${gtools}egen float earnings_def_`m'mode = mode(earnings_def), `m'mode
			qui replace earnings_def_`m'mode = . if earnings_def != earnings_def_`m'mode
			sum earnings_def_`m'mode [fw = weight], meanonly
			local `m'mode_real_trunc: di %8.0f `r(mean)'
		}
		
		if ((`minmode_nom_trunc' != `maxmode_nom_trunc') | (`minmode_real_trunc' != `maxmode_real_trunc')) local caution = "(CAREFUL: two or more modes!)"
		else local caution = ""
		
		* define labor force status
		qui gen byte in_laborforce = .
		qui replace in_laborforce = 1 if (in_school == 0 & retired == 0 & !inlist(job_type,4,5) & ((job == 1 & inlist(job_type,1,2,3)) | searching == 1))
		qui replace in_laborforce = 0 if (in_school == 1 | retired == 1 | inlist(job_type,4,5) | ((job == 0 | inlist(job_type,4,5)) & searching == 0))
	// 	OLD:
	// 	qui replace in_laborforce = 1 if (in_school == 0 & inlist(income_retirement,0,.) & ((earnings > 0 & earnings < .) | searching == 1))
	// 	qui replace in_laborforce = 0 if (in_school == 1 | !inlist(income_retirement,0,.) & (earnings == 0 & searching == 0))
	//	qui gen byte out_of_laborforce = 1 if (in_school == 1 | (income_retirement > 0 & income_retirement < .) | (inlist(earnings,0,.) & inlist(searching,0,.)))
		
		* prepare analysis by skill groups
		qui gen byte complt_le = inlist(edu_degree,1,8,9) if edu_degree < .
		qui gen byte complt_pr = inlist(edu_degree,2,4) if edu_degree < .
		qui gen byte complt_hs = inlist(edu_degree,3,5) if edu_degree < .
		qui gen byte complt_co = inlist(edu_degree,6,7) if edu_degree < .
		qui recode edu_degree (1 8 9 = 1) (2 4 = 2) (3 5 = 3) (6 7 = 4) (nonmissing = .)
		
		* create counts and shares of workers: overall, at, or at/below MW
		if ${adjust_hours} == 1 qui replace earnings = earnings*44/hours
		qui gen byte one = 1
		// general & summary statistics:
		// XXX NOTE: should standard errors be computed using -svy- command?!?!
		foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
			qui sum one if 1 == 1 ${sel`subpop'}, meanonly
			local N_pop_unw`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if 1 == 1 ${sel`subpop'}, meanonly
			local N_pop`subpop'_trunc: di %8.0f `r(N)'
			foreach var of varlist age edu_years complt_le complt_pr complt_hs complt_co hours log_earn_mw log_earn_d {
				qui sum `var' if in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} ${sel`subpop'}
				local N_`var'_f_unw`subpop'_trunc: di %8.0f `r(N)'
				qui sum `var' [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} ${sel`subpop'}
				local N_`var'_f`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'_f`subpop'_trunc: di %5.3f `r(mean)'
				local sd_`var'_f`subpop'_trunc: di %5.3f `r(sd)'
				qui sum `var' if in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} ${sel`subpop'}
				local N_`var'_i_unw`subpop'_trunc: di %8.0f `r(N)'
				qui sum `var' [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} ${sel`subpop'}
				local N_`var'_i`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'_i`subpop'_trunc: di %5.3f `r(mean)'
				local sd_`var'_i`subpop'_trunc: di %5.3f `r(sd)'
				qui sum `var' if in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} ${sel`subpop'}
				local N_`var'_fi_unw`subpop'_trunc: di %8.0f `r(N)'
				qui sum `var' [fw = weight] if in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} ${sel`subpop'}
				local N_`var'_fi`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'_fi`subpop'_trunc: di %5.3f `r(mean)'
				local sd_`var'_fi`subpop'_trunc: di %5.3f `r(sd)'
				qui sum `var' if in_laborforce == 1 & job == 0 ${select_fulltime} ${sel`subpop'}
				local N_`var'_u_unw`subpop'_trunc: di %8.0f `r(N)'
				qui sum `var' [fw = weight] if in_laborforce == 1 & job == 0 ${select_fulltime} ${sel`subpop'}
				local N_`var'_u`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'_u`subpop'_trunc: di %5.3f `r(mean)'
				local sd_`var'_u`subpop'_trunc: di %5.3f `r(sd)'
			}
		}
		// distribution:
		foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} ${sel`subpop'}, meanonly
			local N_formal`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} ${sel`subpop'}, meanonly
			local N_informal`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} ${sel`subpop'}, meanonly
			local N_forminform`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} & earnings == ${minwage`y'} ${sel`subpop'}, meanonly
			local N_f_at_mw`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} & earnings <= ${minwage`y'} ${sel`subpop'}, meanonly
			local N_f_atbelow_mw`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} & inrange(earnings,0.95${minwage`y'},1.05*${minwage`y'}) ${sel`subpop'}, meanonly
			local N_f_around_mw`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} & earnings == ${minwage`y'} ${sel`subpop'}, meanonly
			local N_i_at_mw`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} & earnings <= ${minwage`y'} ${sel`subpop'}, meanonly
			local N_i_atbelow_mw`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} & inrange(earnings,0.95${minwage`y'},1.05*${minwage`y'}) ${sel`subpop'}, meanonly
			local N_i_around_mw`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} & earnings == ${minwage`y'} ${sel`subpop'}, meanonly
			local N_fi_at_mw`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} & earnings <= ${minwage`y'} ${sel`subpop'}, meanonly
			local N_fi_atbelow_mw`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} & inrange(earnings,0.95${minwage`y'},1.05*${minwage`y'}) ${sel`subpop'}, meanonly
			local N_fi_around_mw`subpop'_trunc: di %8.0f `r(N)'
			local share_at_mw_f`subpop'_trunc: di %5.3f `N_f_at_mw`subpop'_trunc'/`N_formal`subpop'_trunc'
			local share_atbelow_mw_f`subpop'_trunc: di %5.3f `N_f_atbelow_mw`subpop'_trunc'/`N_formal`subpop'_trunc'
			local share_around_mw_f`subpop'_trunc: di %5.3f `N_f_around_mw`subpop'_trunc'/`N_formal`subpop'_trunc'
			local share_at_mw_i`subpop'_trunc: di %5.3f `N_i_at_mw`subpop'_trunc'/`N_informal`subpop'_trunc'
			local share_atbelow_mw_i`subpop'_trunc: di %5.3f `N_i_atbelow_mw`subpop'_trunc'/`N_informal`subpop'_trunc'
			local share_around_mw_i`subpop'_trunc: di %5.3f `N_i_around_mw`subpop'_trunc'/`N_informal`subpop'_trunc'
			local share_at_mw_fi`subpop'_trunc: di %5.3f `N_fi_at_mw`subpop'_trunc'/`N_forminform`subpop'_trunc'
			local share_atbelow_mw_fi`subpop'_trunc: di %5.3f `N_fi_atbelow_mw`subpop'_trunc'/`N_forminform`subpop'_trunc'
			local share_around_mw_fi`subpop'_trunc: di %5.3f `N_fi_around_mw`subpop'_trunc'/`N_forminform`subpop'_trunc'
		}
		// employment:
		qui gen byte status = .
		qui replace status = 1 if in_laborforce == 0
		qui replace status = 2 if in_laborforce == 1 & job == 0
		qui gen byte unemployed = .
		qui replace unemployed = 1 if in_laborforce == 1 & job == 0
		qui replace unemployed = 0 if in_laborforce == 1 & job == 1
		qui replace status = 3 if in_laborforce == 1 & job == 1 & formal_emp == 0
		qui replace status = 4 if in_laborforce == 1 & job == 1 & formal_emp == 1
		label define status_l 1 "out of labor force" 2 "unemployed" 3 "informal" 4 "formal", replace
		label val status status_l
		label var status "work status"
		foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
			qui sum one [fw = weight] if in_laborforce == 1 ${sel`subpop'}, meanonly
			local N_in_laborforce`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if in_laborforce == 0 ${sel`subpop'}, meanonly
			local N_out_of_laborforce`subpop'_trunc: di %8.0f `r(N)'
			qui sum one [fw = weight] if inlist(in_laborforce,0,1) ${sel`subpop'}, meanonly
			local N_in_out_laborforce`subpop'_trunc: di %8.0f `r(N)'
			local share_in_laborforce`subpop'_trunc: di %5.3f `N_in_laborforce`subpop'_trunc'/`N_in_out_laborforce`subpop'_trunc'
			qui sum one [fw = weight] if unemployed == 1 ${sel`subpop'}, meanonly
			local N_unemployed`subpop'_trunc: di %8.0f `r(N)'
			local share_unemployed`subpop'_trunc: di %5.3f `N_unemployed`subpop'_trunc'/`N_in_laborforce`subpop'_trunc'
			qui sum one [fw = weight] if unemployed == 0 ${sel`subpop'}, meanonly
			local N_employed`subpop'_trunc: di %8.0f `r(N)'
			local share_employed`subpop'_trunc: di %5.3f `N_employed`subpop'_trunc'/`N_in_laborforce`subpop'_trunc'
// 			foreach l in N_pop`subpop' N_in_laborforce`subpop' N_out_of_laborforce`subpop' N_in_out_laborforce`subpop' N_employed`subpop' {
// 				local `l'_trunc: di %8.0f ``l''
// 			}
// 			foreach l in share_in_laborforce`subpop' share_employed`subpop' {
// 				local `l'_trunc: di %5.3f ``l''
// 			}
		}
		// formal:
		foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" { // < 1 = primary school, 2 = primary school, 3 = high school, 4 = college
			local share_formal`subpop'_trunc: di %5.3f `N_formal`subpop'_trunc'/`N_forminform`subpop'_trunc'
			local N_formal`subpop'_trunc: di %8.0f `N_formal`subpop'_trunc'
		}
		// others:
		foreach var of varlist second_job formal_emp_f searching urban literate in_school complt_le complt_pr complt_hs complt_co {
			foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
				qui sum one if inlist(`var',0,1) ${sel`subpop'} [fw = weight], meanonly
				local N_all_`var'`subpop'_trunc: di %8.0f `r(N)'
				qui sum one if `var' == 1 ${sel`subpop'} [fw = weight], meanonly
				local N_`var'`subpop'_trunc: di %8.0f `r(N)'
				local share_`var'`subpop'_trunc: di %5.3f `N_`var'`subpop'_trunc'/`N_all_`var'`subpop'_trunc'
			}
		}
		foreach var of varlist hours income_bonus income_goods edu_years {
			qui replace `var' = ln(`var')
			foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
				qui sum `var' if 1 == 1 ${sel`subpop'} [fw = weight], meanonly
				local N_all_`var'`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'`subpop'_trunc: di %5.3f `r(mean)'
			}
		}
		// comp1990:
		foreach var of varlist migrated_state ee_eue_trans union_member ret_contr child_born child_dead {
			foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
				qui sum one if inlist(`var',0,1) ${sel`subpop'} [fw = weight], meanonly
				local N_all_`var'`subpop'_trunc: di %8.0f `r(N)'
				qui sum one if `var' == 1 ${sel`subpop'} [fw = weight], meanonly
				local N_`var'`subpop'_trunc: di %8.0f `r(N)'
				local share_`var'`subpop'_trunc: di %5.3f `N_`var'`subpop'_trunc'/`N_all_`var'`subpop'_trunc'
			}
		}
		// hh:
		foreach var of varlist income_hh rent mortgage {
			qui replace `var' = ln(`var')
		}
		foreach var of varlist walls_solid roof_solid house_owner water_piped bathroom light_elec radio washing_mac phone stove tv fridge_freezer {
			foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
				qui sum one if inlist(`var',0,1) ${sel`subpop'} [fw = weight], meanonly
				local N_all_`var'`subpop'_trunc: di %8.0f `r(N)'
				qui sum one if `var' == 1 ${sel`subpop'} [fw = weight], meanonly
				local N_`var'`subpop'_trunc: di %8.0f `r(N)'
				local share_`var'`subpop'_trunc: di %5.3f `N_`var'`subpop'_trunc'/`N_all_`var'`subpop'_trunc'
			}
		}
		foreach var of varlist income_hh rent mortgage {
			foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
				qui sum `var' if 1 == 1 ${sel`subpop'} [fw = weight], meanonly
				local N_all_`var'`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'`subpop'_trunc: di %5.3f `r(mean)'
			}
		}
		
		* compute statistics at state-level
		qui sort region
		foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
			// general:
			if "${gtools}" == "" {
				qui by region: egen long N_pop`subpop' = total((1 == 1 ${sel`subpop'})*weight)
				qui by region: egen long N_formal`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} ${sel`subpop'})*weight)
				qui by region: egen long N_informal`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} ${sel`subpop'})*weight)
				qui by region: egen long N_forminform`subpop' = total((in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} ${sel`subpop'})*weight)
			}
			else {
				qui gegen long N_pop`subpop' = total((1 == 1 ${sel`subpop'})*weight), by(region)
				qui gegen long N_formal`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} ${sel`subpop'})*weight), by(region)
				qui gegen long N_informal`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} ${sel`subpop'})*weight), by(region)
				qui gegen long N_forminform`subpop' = total((in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} ${sel`subpop'})*weight), by(region)
			}
			// distribution:
			if "${gtools}" == "" {
				qui by region: egen long N_f_at_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} & earnings == ${minwage`y'} ${sel`subpop'})*weight)
				qui by region: egen long N_f_atbelow_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} & earnings <= ${minwage`y'} ${sel`subpop'})*weight)
				qui by region: egen long N_f_around_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} & inrange(earnings,0.95*${minwage`y'},1.05*${minwage`y'}) ${sel`subpop'})*weight)
				
				qui by region: egen long N_i_at_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} & earnings == ${minwage`y'} ${sel`subpop'})*weight)
				qui by region: egen long N_i_atbelow_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} & earnings <= ${minwage`y'} ${sel`subpop'})*weight)
				qui by region: egen long N_i_around_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} & inrange(earnings,0.95*${minwage`y'},1.05*${minwage`y'}) ${sel`subpop'})*weight)
				
				qui by region: egen long N_fi_at_mw`subpop' = total((in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} & earnings == ${minwage`y'} ${sel`subpop'})*weight)
				qui by region: egen long N_fi_atbelow_mw`subpop' = total((in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} & earnings <= ${minwage`y'} ${sel`subpop'})*weight)
				qui by region: egen long N_fi_around_mw`subpop' = total((in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} & inrange(earnings,0.95*${minwage`y'},1.05*${minwage`y'}) ${sel`subpop'})*weight)
			}
			else {
				qui gegen long N_f_at_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} & earnings == ${minwage`y'} ${sel`subpop'})*weight), by(region)
				qui gegen long N_f_atbelow_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} & earnings <= ${minwage`y'} ${sel`subpop'})*weight), by(region)
				qui gegen long N_f_around_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} & inrange(earnings,0.95*${minwage`y'},1.05*${minwage`y'}) ${sel`subpop'})*weight), by(region)
				
				qui gegen long N_i_at_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} & earnings == ${minwage`y'} ${sel`subpop'})*weight), by(region)
				qui gegen long N_i_atbelow_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} & earnings <= ${minwage`y'} ${sel`subpop'})*weight), by(region)
				qui gegen long N_i_around_mw`subpop' = total((in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} & inrange(earnings,0.95*${minwage`y'},1.05*${minwage`y'}) ${sel`subpop'})*weight), by(region)
				
				qui gegen long N_fi_at_mw`subpop' = total((in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} & earnings == ${minwage`y'} ${sel`subpop'})*weight), by(region)
				qui gegen long N_fi_atbelow_mw`subpop' = total((in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} & earnings <= ${minwage`y'} ${sel`subpop'})*weight), by(region)
				qui gegen long N_fi_around_mw`subpop' = total((in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} & inrange(earnings,0.95*${minwage`y'},1.05*${minwage`y'}) ${sel`subpop'})*weight), by(region)
			}
			qui gen float share_at_mw_f`subpop' = N_f_at_mw`subpop'/N_formal`subpop'
			qui gen float share_atbelow_mw_f`subpop' = N_f_atbelow_mw`subpop'/N_formal`subpop'
			qui gen float share_around_mw_f`subpop' = N_f_around_mw`subpop'/N_formal`subpop'
			
			qui gen float share_at_mw_i`subpop' = N_i_at_mw`subpop'/N_informal`subpop'
			qui gen float share_atbelow_mw_i`subpop' = N_i_atbelow_mw`subpop'/N_informal`subpop'
			qui gen float share_around_mw_i`subpop' = N_i_around_mw`subpop'/N_informal`subpop'
			
			qui gen float share_at_mw_fi`subpop' = N_fi_at_mw`subpop'/N_forminform`subpop'
			qui gen float share_atbelow_mw_fi`subpop' = N_fi_atbelow_mw`subpop'/N_forminform`subpop'
			qui gen float share_around_mw_fi`subpop' = N_fi_around_mw`subpop'/N_forminform`subpop'
			
			// employment:
			if "${gtools}" == "" {
				qui by region: egen long N_in_laborforce`subpop' = total((in_laborforce == 1 ${sel`subpop'})*weight)
				qui by region: egen long N_out_of_laborforce`subpop' = total((in_laborforce == 0 ${sel`subpop'})*weight)
				qui by region: egen long N_in_out_laborforce`subpop' = total((inlist(in_laborforce,0,1) ${sel`subpop'})*weight)
				qui by region: egen long N_employed`subpop' = total((in_laborforce == 1 & unemployed == 0 ${sel`subpop'})*weight)
			}
			else {
				qui gegen long N_in_laborforce`subpop' = total((in_laborforce == 1 ${sel`subpop'})*weight), by(region)
				qui gegen long N_out_of_laborforce`subpop' = total((in_laborforce == 0 ${sel`subpop'})*weight), by(region)
				qui gegen long N_in_out_laborforce`subpop' = total((inlist(in_laborforce,0,1) ${sel`subpop'})*weight), by(region)
				qui gegen long N_employed`subpop' = total((in_laborforce == 1 & unemployed == 0 ${sel`subpop'})*weight), by(region)
			}
			
			qui gen float share_in_laborforce`subpop' = N_in_laborforce`subpop'/N_in_out_laborforce
			qui gen float share_employed`subpop' = N_employed`subpop'/N_in_laborforce`subpop'
			
			// formal:
			qui gen float share_formal`subpop' = N_formal`subpop'/N_forminform`subpop'
			
			// others:
			foreach var of varlist second_job formal_emp_f searching urban literate in_school complt_le complt_pr complt_hs complt_co {
				if "${gtools}" == "" {
					qui by region: egen long N_all_`var'`subpop' = total((inrange(`var',0,1) ${sel`subpop'})*weight)
					qui by region: egen long N_`var'`subpop' = total((`var' == 1 ${sel`subpop'})*weight)
				}
				else {
					qui gegen long N_all_`var'`subpop' = total((inrange(`var',0,1) ${sel`subpop'})*weight), by(region)
					qui gegen long N_`var'`subpop' = total((`var' == 1 ${sel`subpop'})*weight), by(region)
				}
				qui gen float share_`var'`subpop' = N_`var'`subpop'/N_all_`var'`subpop'
				drop N_`var'`subpop' N_all_`var'`subpop'
			}
			foreach var of varlist hours income_bonus income_goods edu_years {
				if "${gtools}" == "" {
					qui by region: egen long N_all`subpop' = total((`var' != . ${sel`subpop'})*weight)
					qui by region: egen long sum_`var'`subpop' = total((1 == 1 ${sel`subpop'})*`var'*weight)
				}
				else {
					qui gegen long N_all`subpop' = total((`var' != . ${sel`subpop'})*weight), by(region)
					qui gegen long sum_`var'`subpop' = total((1 == 1 ${sel`subpop'})*`var'*weight), by(region)
				}
				qui gen float mean_`var'`subpop' = sum_`var'`subpop'/N_all`subpop'
				drop sum_`var'`subpop' N_all`subpop'
			}
			
			// comp1990:
			foreach var of varlist migrated_state ee_eue_trans union_member ret_contr child_born child_dead {
				if "${gtools}" == "" {
					qui by region: egen long N_all_`var'`subpop' = total((inrange(`var',0,1) ${sel`subpop'})*weight)
					qui by region: egen long N_`var'`subpop' = total((`var' == 1 ${sel`subpop'})*weight)
				}
				else {
					qui gegen long N_all_`var'`subpop' = total((inrange(`var',0,1) ${sel`subpop'})*weight), by(region)
					qui gegen long N_`var'`subpop' = total((`var' == 1 ${sel`subpop'})*weight), by(region)
				}
				qui gen float share_`var'`subpop' = N_`var'`subpop'/N_all_`var'`subpop'
				drop N_`var'`subpop' N_all_`var'`subpop'
			}
			
			// hh:
			foreach var of varlist walls_solid roof_solid house_owner water_piped bathroom light_elec radio washing_mac phone stove tv fridge_freezer {
				if "${gtools}" == "" {
					qui by region: egen long N_all_`var'`subpop' = total((inrange(`var',0,1) ${sel`subpop'})*weight)
					qui by region: egen long N_`var'`subpop' = total((`var' == 1 ${sel`subpop'})*weight)
				}
				else {
					qui gegen long N_all_`var'`subpop' = total((inrange(`var',0,1) ${sel`subpop'})*weight), by(region)
					qui gegen long N_`var'`subpop' = total((`var' == 1 ${sel`subpop'})*weight), by(region)
				}
				qui gen float share_`var'`subpop' = N_`var'`subpop'/N_all_`var'`subpop'
				drop N_`var'`subpop' N_all_`var'`subpop'
			}
			foreach var of varlist income_hh rent mortgage {
				if "${gtools}" == "" {
					qui by region: egen long N_all`subpop' = total((`var' != . ${sel`subpop'})*weight)
					qui by region: egen long sum_`var'`subpop' = total((1 == 1 ${sel`subpop'})*`var'*weight)
				}
				else {
					qui gegen long N_all`subpop' = total((`var' != . ${sel`subpop'})*weight), by(region)
					qui gegen long sum_`var'`subpop' = total((1 == 1 ${sel`subpop'})*`var'*weight), by(region)
				}
				qui gen float mean_`var'`subpop' = sum_`var'`subpop'/N_all`subpop'
				drop sum_`var'`subpop' N_all`subpop'
			}
		}
		
		* sort and fill gaps
		qui gen byte share_one = 1
		qui gen byte mean_one = 1
		foreach var of varlist share* mean* {
			if !inlist("`var'", "share_one", "mean_one") qui bys region (`var'): replace `var' = `var'[1]
		}
		drop share_one mean_one
		
		* display results
		if `counter' == 1 {
			cap log close log_sumstats_pnad
			log using "${DIR_LOG}/log_sumstats_pnad.log", replace name(log_sumstats_pnad)
		}
		else qui log on log_sumstats_pnad
		disp _newline(1)
		disp "...year `y'"
		disp "   Nom. modal wage (MW)  = `minmode_nom_trunc' `caution'"
		disp "   Real modal wage (MW)  = `minmode_real_trunc' `caution'"
		disp "                 N          | OVERALL    | < PRIMARY  | PRIMARY    | HIGH SCHL  | COLLEGE"
		// general:
		foreach var of varlist age edu_years complt_le complt_pr complt_hs complt_co hours log_earn_mw log_earn_d {
			disp "   `var':"
			foreach s in "f" "i" "fi" "u" {
				if !(inlist("`var'", "hours", "log_earn_mw", "log_earn_d") & "`s'" == "u") {
					disp "        N unw. (`s'):                   | `N_`var'_`s'_unw_trunc'  | `N_`var'_`s'_unw_edu1_trunc'  | `N_`var'_`s'_unw_edu2_trunc'  | `N_`var'_`s'_unw_edu3_trunc'  | `N_`var'_`s'_unw_edu4_trunc'"
					disp "        N (`s'):                        | `N_`var'_`s'_trunc'  | `N_`var'_`s'_edu1_trunc'  | `N_`var'_`s'_edu2_trunc'  | `N_`var'_`s'_edu3_trunc'  | `N_`var'_`s'_edu4_trunc'"
					disp "        mean (`s'):                     | `mean_`var'_`s'_trunc'     | `mean_`var'_`s'_edu1_trunc'     | `mean_`var'_`s'_edu2_trunc'     | `mean_`var'_`s'_edu3_trunc'     | `mean_`var'_`s'_edu4_trunc'"
					disp "        sd (`s'):                       | `sd_`var'_`s'_trunc'     | `sd_`var'_`s'_edu1_trunc'     | `sd_`var'_`s'_edu2_trunc'     | `sd_`var'_`s'_edu3_trunc'     | `sd_`var'_`s'_edu4_trunc'"
				}
			}
		}            
		// distribution:
		disp "   population size (unw.)=            | `N_pop_unw_trunc'   | `N_pop_unw_edu1_trunc'   | `N_pop_unw_edu2_trunc'   | `N_pop_unw_edu3_trunc'   | `N_pop_unw_edu4_trunc'"
		disp "   population size       =            | `N_pop_trunc'   | `N_pop_edu1_trunc'   | `N_pop_edu2_trunc'   | `N_pop_edu3_trunc'   | `N_pop_edu4_trunc'"
		
		disp "   number employed, f    =            | `N_formal_trunc'   | `N_formal_edu1_trunc'   | `N_formal_edu2_trunc'   | `N_formal_edu3_trunc'   | `N_formal_edu4_trunc'"
		disp "   share at MW, f        = `N_formal_trunc'   | `share_at_mw_f_trunc'      | `share_at_mw_f_edu1_trunc'      | `share_at_mw_f_edu2_trunc'      | `share_at_mw_f_edu3_trunc'      | `share_at_mw_f_edu4_trunc'"
		disp "   share <= MW, f        = `N_formal_trunc'   | `share_atbelow_mw_f_trunc'      | `share_atbelow_mw_f_edu1_trunc'      | `share_atbelow_mw_f_edu2_trunc'      | `share_atbelow_mw_f_edu3_trunc'      | `share_atbelow_mw_f_edu4_trunc'"
		disp "   share w/i 5%ofMW, f   = `N_formal_trunc'   | `share_around_mw_f_trunc'      | `share_around_mw_f_edu1_trunc'      | `share_around_mw_f_edu2_trunc'      | `share_around_mw_f_edu3_trunc'      | `share_around_mw_f_edu4_trunc'"
		
		disp "   number employed, i    =            | `N_informal_trunc'   | `N_informal_edu1_trunc'   | `N_informal_edu2_trunc'   | `N_informal_edu3_trunc'   | `N_informal_edu4_trunc'"
		disp "   share at MW, i        = `N_informal_trunc'   | `share_at_mw_i_trunc'      | `share_at_mw_i_edu1_trunc'      | `share_at_mw_i_edu2_trunc'      | `share_at_mw_i_edu3_trunc'      | `share_at_mw_i_edu4_trunc'"
		disp "   share <= MW, i        = `N_informal_trunc'   | `share_atbelow_mw_i_trunc'      | `share_atbelow_mw_i_edu1_trunc'      | `share_atbelow_mw_i_edu2_trunc'      | `share_atbelow_mw_i_edu3_trunc'      | `share_atbelow_mw_i_edu4_trunc'"
		disp "   share w/i 5%ofMW, i   = `N_informal_trunc'   | `share_around_mw_i_trunc'      | `share_around_mw_i_edu1_trunc'      | `share_around_mw_i_edu2_trunc'      | `share_around_mw_i_edu3_trunc'      | `share_around_mw_i_edu4_trunc'"
		
		disp "   number employed, fi   =            | `N_forminform_trunc'   | `N_forminform_edu1_trunc'   | `N_forminform_edu2_trunc'   | `N_forminform_edu3_trunc'   | `N_forminform_edu4_trunc'"
		disp "   share at MW, fi       = `N_forminform_trunc'   | `share_at_mw_fi_trunc'      | `share_at_mw_fi_edu1_trunc'      | `share_at_mw_fi_edu2_trunc'      | `share_at_mw_fi_edu3_trunc'      | `share_at_mw_fi_edu4_trunc'"
		disp "   share <= MW, fi       = `N_forminform_trunc'   | `share_atbelow_mw_fi_trunc'      | `share_atbelow_mw_fi_edu1_trunc'      | `share_atbelow_mw_fi_edu2_trunc'      | `share_atbelow_mw_fi_edu3_trunc'      | `share_atbelow_mw_fi_edu4_trunc'"
		disp "   share w/i 5%of MW, fi = `N_forminform_trunc'   | `share_around_mw_fi_trunc'      | `share_around_mw_fi_edu1_trunc'      | `share_around_mw_fi_edu2_trunc'      | `share_around_mw_fi_edu3_trunc'      | `share_around_mw_fi_edu4_trunc'"
		// employment:
		disp "   LFP rate ((E+U)/pop)  = `N_in_out_laborforce_trunc'   | `share_in_laborforce_trunc'      | `share_in_laborforce_edu1_trunc'      | `share_in_laborforce_edu2_trunc'      | `share_in_laborforce_edu3_trunc'      | `share_in_laborforce_edu4_trunc'"
		disp "   employment rate (1-u) = `N_in_laborforce_trunc'   | `share_employed_trunc'      | `share_employed_edu1_trunc'      | `share_employed_edu2_trunc'      | `share_employed_edu3_trunc'      | `share_employed_edu4_trunc'"
		// formal:
		disp "   share formal          = `N_forminform_trunc'   | `share_formal_trunc'      | `share_formal_edu1_trunc'      | `share_formal_edu2_trunc'      | `share_formal_edu3_trunc'      | `share_formal_edu4_trunc'"
		// others:
		disp "   share w/ second job   = `N_all_second_job_trunc'   | `share_second_job_trunc'      | `share_second_job_edu1_trunc'      | `share_second_job_edu2_trunc'      | `share_second_job_edu3_trunc'      | `share_second_job_edu4_trunc'"
		disp "   share U prev. formal  = `N_all_formal_emp_f_trunc'   | `share_formal_emp_f_trunc'      | `share_formal_emp_f_edu1_trunc'      | `share_formal_emp_f_edu2_trunc'      | `share_formal_emp_f_edu3_trunc'      | `share_formal_emp_f_edu4_trunc'"
		disp "   share searching job   = `N_all_searching_trunc'   | `share_searching_trunc'      | `share_searching_edu1_trunc'      | `share_searching_edu2_trunc'      | `share_searching_edu3_trunc'      | `share_searching_edu4_trunc'"
		disp "   share in urban area   = `N_all_urban_trunc'   | `share_urban_trunc'      | `share_urban_edu1_trunc'      | `share_urban_edu2_trunc'      | `share_urban_edu3_trunc'      | `share_urban_edu4_trunc'"
		disp "   share literate        = `N_all_literate_trunc'   | `share_literate_trunc'      | `share_literate_edu1_trunc'      | `share_literate_edu2_trunc'      | `share_literate_edu3_trunc'      | `share_literate_edu4_trunc'"
		disp "   share in school       = `N_all_in_school_trunc'   | `share_in_school_trunc'      | `share_in_school_edu1_trunc'      | `share_in_school_edu2_trunc'      | `share_in_school_edu3_trunc'      | `share_in_school_edu4_trunc'"
		disp "   share compltd < prim. = `N_all_complt_le_trunc'   | `share_complt_le_trunc'      | `share_complt_le_edu1_trunc'      | `share_complt_le_edu2_trunc'      | `share_complt_le_edu3_trunc'      | `share_complt_le_edu4_trunc'"
		disp "   share completed prim. = `N_all_complt_pr_trunc'   | `share_complt_pr_trunc'      | `share_complt_pr_edu1_trunc'      | `share_complt_pr_edu2_trunc'      | `share_complt_pr_edu3_trunc'      | `share_complt_pr_edu4_trunc'"
		disp "   share completed HS    = `N_all_complt_hs_trunc'   | `share_complt_hs_trunc'      | `share_complt_hs_edu1_trunc'      | `share_complt_hs_edu2_trunc'      | `share_complt_hs_edu3_trunc'      | `share_complt_hs_edu4_trunc'"
		disp "   share completed coll. = `N_all_complt_co_trunc'   | `share_complt_co_trunc'      | `share_complt_co_edu1_trunc'      | `share_complt_co_edu2_trunc'      | `share_complt_co_edu3_trunc'      | `share_complt_co_edu4_trunc'"
		disp "   mean hours worked     = `N_all_hours_trunc'   | `mean_hours_trunc'      | `mean_hours_edu1_trunc'      | `mean_hours_edu2_trunc'      | `mean_hours_edu3_trunc'      | `mean_hours_edu4_trunc'"
		disp "   mean bonus income     = `N_all_income_bonus_trunc'   | `mean_income_bonus_trunc'      | `mean_income_bonus_edu1_trunc'      | `mean_income_bonus_edu2_trunc'      | `mean_income_bonus_edu3_trunc'      | `mean_income_bonus_edu4_trunc'"
		disp "   mean non-mon. income  = `N_all_income_goods_trunc'   | `mean_income_goods_trunc'      | `mean_income_goods_edu1_trunc'      | `mean_income_goods_edu2_trunc'      | `mean_income_goods_edu3_trunc'      | `mean_income_goods_edu4_trunc'"
		disp "   mean education (y.s)  = `N_all_edu_years_trunc'   | `mean_edu_years_trunc'      | `mean_edu_years_edu1_trunc'      | `mean_edu_years_edu2_trunc'      | `mean_edu_years_edu3_trunc'      | `mean_edu_years_edu4_trunc'"
		// comp1990:
		disp "   share recent migrant  = `N_all_migrated_state_trunc'   | `share_migrated_state_trunc'      | `share_migrated_state_edu1_trunc'      | `share_migrated_state_edu2_trunc'      | `share_migrated_state_edu3_trunc'      | `share_migrated_state_edu4_trunc'"
		disp "   share recent EE/EUE   = `N_all_ee_eue_trans_trunc'   | `share_ee_eue_trans_trunc'      | `share_ee_eue_trans_edu1_trunc'      | `share_ee_eue_trans_edu2_trunc'      | `share_ee_eue_trans_edu3_trunc'      | `share_ee_eue_trans_edu4_trunc'"
		disp "   share union member    = `N_all_union_member_trunc'   | `share_union_member_trunc'      | `share_union_member_edu1_trunc'      | `share_union_member_edu2_trunc'      | `share_union_member_edu3_trunc'      | `share_union_member_edu4_trunc'"
		disp "   share vol.ret.contr.  = `N_all_ret_contr_trunc'   | `share_ret_contr_trunc'      | `share_ret_contr_edu1_trunc'      | `share_ret_contr_edu2_trunc'      | `share_ret_contr_edu3_trunc'      | `share_ret_contr_edu4_trunc'"
		disp "   share recent child    = `N_all_child_born_trunc'   | `share_child_born_trunc'      | `share_child_born_edu1_trunc'      | `share_child_born_edu2_trunc'      | `share_child_born_edu3_trunc'      | `share_child_born_edu4_trunc'"
		disp "   share recent dead ch. = `N_all_child_dead_trunc'   | `share_child_dead_trunc'      | `share_child_dead_edu1_trunc'      | `share_child_dead_edu2_trunc'      | `share_child_dead_edu3_trunc'      | `share_child_dead_edu4_trunc'"
		// hh:
		disp "   share solid walls     = `N_all_walls_solid_trunc'   | `share_walls_solid_trunc'      | `share_walls_solid_edu1_trunc'      | `share_walls_solid_edu2_trunc'      | `share_walls_solid_edu3_trunc'      | `share_walls_solid_edu4_trunc'"
		disp "   share solid roof      = `N_all_roof_solid_trunc'   | `share_roof_solid_trunc'      | `share_roof_solid_edu1_trunc'      | `share_roof_solid_edu2_trunc'      | `share_roof_solid_edu3_trunc'      | `share_roof_solid_edu4_trunc'"
		disp "   share house owners    = `N_all_house_owner_trunc'   | `share_house_owner_trunc'      | `share_house_owner_edu1_trunc'      | `share_house_owner_edu2_trunc'      | `share_house_owner_edu3_trunc'      | `share_house_owner_edu4_trunc'"
		disp "   share piped water     = `N_all_water_piped_trunc'   | `share_water_piped_trunc'      | `share_water_piped_edu1_trunc'      | `share_water_piped_edu2_trunc'      | `share_water_piped_edu3_trunc'      | `share_water_piped_edu4_trunc'"
		disp "   share bathroom        = `N_all_bathroom_trunc'   | `share_bathroom_trunc'      | `share_bathroom_edu1_trunc'      | `share_bathroom_edu2_trunc'      | `share_bathroom_edu3_trunc'      | `share_bathroom_edu4_trunc'"
		disp "   share electric light  = `N_all_roof_solid_trunc'   | `share_roof_solid_trunc'      | `share_roof_solid_edu1_trunc'      | `share_roof_solid_edu2_trunc'      | `share_roof_solid_edu3_trunc'      | `share_roof_solid_edu4_trunc'"
		disp "   share radio           = `N_all_radio_trunc'   | `share_radio_trunc'      | `share_radio_edu1_trunc'      | `share_radio_edu2_trunc'      | `share_radio_edu3_trunc'      | `share_radio_edu4_trunc'"
		disp "   share washing mach.   = `N_all_washing_mac_trunc'   | `share_washing_mac_trunc'      | `share_washing_mac_edu1_trunc'      | `share_washing_mac_edu2_trunc'      | `share_washing_mac_edu3_trunc'      | `share_washing_mac_edu4_trunc'"
		disp "   share phone           = `N_all_phone_trunc'   | `share_phone_trunc'      | `share_phone_edu1_trunc'      | `share_phone_edu2_trunc'      | `share_phone_edu3_trunc'      | `share_phone_edu4_trunc'"
		disp "   share stove           = `N_all_stove_trunc'   | `share_stove_trunc'      | `share_stove_edu1_trunc'      | `share_stove_edu2_trunc'      | `share_stove_edu3_trunc'      | `share_stove_edu4_trunc'"
		disp "   share TV              = `N_all_tv_trunc'   | `share_tv_trunc'      | `share_tv_edu1_trunc'      | `share_tv_edu2_trunc'      | `share_tv_edu3_trunc'      | `share_tv_edu4_trunc'"
		disp "   share fridge/freezer  = `N_all_fridge_freezer_trunc'   | `share_fridge_freezer_trunc'      | `share_fridge_freezer_edu1_trunc'      | `share_fridge_freezer_edu2_trunc'      | `share_fridge_freezer_edu3_trunc'      | `share_fridge_freezer_edu4_trunc'"
		disp "   mean household income = `N_all_income_hh_trunc'   | `mean_income_hh_trunc'      | `mean_income_hh_edu1_trunc'      | `mean_income_hh_edu2_trunc'      | `mean_income_hh_edu3_trunc'      | `mean_income_hh_edu4_trunc'"
		disp "   mean rent payment     = `N_all_rent_trunc'   | `mean_rent_trunc'      | `mean_rent_edu1_trunc'      | `mean_rent_edu2_trunc'      | `mean_rent_edu3_trunc'      | `mean_rent_edu4_trunc'"
		disp "   mean mortgage payment = `N_all_mortgage_trunc'   | `mean_mortgage_trunc'      | `mean_mortgage_edu1_trunc'      | `mean_mortgage_edu2_trunc'      | `mean_mortgage_edu3_trunc'      | `mean_mortgage_edu4_trunc'"
		qui log off log_sumstats_pnad
		
		* post results
		if `counter' == 1 {
			postutil clear
			qui postfile postfile_shares ///
				year N_pop N_formal N_informal N_forminform ///
				share_at_mw_f share_atbelow_mw_f share_around_mw_f share_at_mw_i share_atbelow_mw_i share_around_mw_i share_at_mw_fi share_atbelow_mw_fi share_around_mw_fi ///
				share_in_laborforce share_employed share_formal ///
				share_second_job share_formal_emp_f share_searching share_urban share_literate share_in_school share_complt_le share_complt_pr share_complt_hs share_complt_co mean_hours mean_income_bonus mean_income_goods mean_edu_years ///
				share_migrated_state share_ee_eue_trans share_union_member share_ret_contr share_child_born share_child_dead ///
				share_walls_solid share_roof_solid share_house_owner share_water_piped share_bathroom share_light_elec share_radio share_washing_mac share_phone share_stove share_tv share_fridge_freezer mean_income_hh mean_rent mean_mortgage ///
				using "${DIR_TEMP}/PNAD/pnad_pooled.dta", replace
		}
		foreach post_item in ///
			"y" "N_pop_trunc" "N_formal_trunc" "N_informal_trunc" "N_forminform_trunc" ///
			"share_at_mw_f_trunc" "share_atbelow_mw_f_trunc" "share_around_mw_f_trunc" "share_at_mw_i_trunc" "share_atbelow_mw_i_trunc" "share_around_mw_i_trunc" "share_at_mw_fi_trunc" "share_atbelow_mw_fi_trunc" "share_around_mw_fi_trunc" ///
			"share_in_laborforce_trunc" "share_employed_trunc" "share_formal_trunc" ///
			"share_second_job_trunc" "share_formal_emp_f_trunc" "share_searching_trunc" "share_urban_trunc" "share_literate_trunc" "share_in_school_trunc" "share_complt_le_trunc" "share_complt_pr_trunc" "share_complt_hs_trunc" "share_complt_co_trunc" "mean_hours_trunc" "mean_income_bonus_trunc" "mean_income_goods_trunc" "mean_edu_years_trunc" ///
			"share_migrated_state_trunc" "share_ee_eue_trans_trunc" "share_union_member_trunc" "share_ret_contr_trunc" "share_child_born_trunc" "share_child_dead_trunc" ///
			"share_walls_solid_trunc" "share_roof_solid_trunc" "share_house_owner_trunc" "share_water_piped_trunc" "share_bathroom_trunc" "share_light_elec_trunc" "share_radio_trunc" "share_washing_mac_trunc" "share_phone_trunc" "share_stove_trunc" "share_tv_trunc" "share_fridge_freezer_trunc" "mean_income_hh_trunc" "mean_rent_trunc" "mean_mortgage_trunc" {
			if "``post_item''" == "" {
				local `post_item' = .
			}
		}
		qui post postfile_shares ///
			(`y') (`N_pop_trunc') (`N_formal_trunc') (`N_informal_trunc') (`N_forminform_trunc') ///
			(`share_at_mw_f_trunc') (`share_atbelow_mw_f_trunc') (`share_around_mw_f_trunc') (`share_at_mw_i_trunc') (`share_atbelow_mw_i_trunc') (`share_around_mw_i_trunc') (`share_at_mw_fi_trunc') (`share_atbelow_mw_fi_trunc') (`share_around_mw_fi_trunc') ///
			(`share_in_laborforce_trunc') (`share_employed_trunc') (`share_formal_trunc') ///
			(`share_second_job_trunc') (`share_formal_emp_f_trunc') (`share_searching_trunc') (`share_urban_trunc') (`share_literate_trunc') (`share_in_school_trunc') (`share_complt_le_trunc') (`share_complt_pr_trunc') (`share_complt_hs_trunc') (`share_complt_co_trunc') (`mean_hours_trunc') (`mean_income_bonus_trunc') (`mean_income_goods_trunc') (`mean_edu_years_trunc') ///
			(`share_migrated_state_trunc') (`share_ee_eue_trans_trunc') (`share_union_member_trunc') (`share_ret_contr_trunc') (`share_child_born_trunc') (`share_child_dead_trunc') ///
			(`share_walls_solid_trunc') (`share_roof_solid_trunc') (`share_house_owner_trunc') (`share_water_piped_trunc') (`share_bathroom_trunc') (`share_light_elec_trunc') (`share_radio_trunc') (`share_washing_mac_trunc') (`share_phone_trunc') (`share_stove_trunc') (`share_tv_trunc') (`share_fridge_freezer_trunc') (`mean_income_hh_trunc') (`mean_rent_trunc') (`mean_mortgage_trunc')
		if `counter' == `counter_max' qui postclose postfile_shares
		
		* generate state-year panel
		qui gen float log_earnings = ln(earnings)
		qui gen float log_earnings_f_sel = log_earnings if in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime}
		qui gen float log_earnings_i_sel = log_earnings if in_laborforce == 0 & job == 1 & formal_emp == 0 ${select_fulltime}
		qui gen float log_earnings_fi_sel = log_earnings if inlist(in_laborforce,0,1) & job == 1 & inrange(formal_emp,0,1) ${select_fulltime}
		local p_f_collapse = ""
		local p_i_collapse = ""
		local p_fi_collapse = ""
		foreach p of global percentiles_list {
			local p_f_collapse = "`p_f_collapse' (p`p') log_p`p'_f = log_earnings_f_sel"
			local p_i_collapse = "`p_i_collapse' (p`p') log_p`p'_i = log_earnings_i_sel"
			local p_fi_collapse = "`p_fi_collapse' (p`p') log_p`p'_fi = log_earnings_fi_sel"
		}
		qui gen byte share_one = 1
		qui gen byte mean_one = 1
		${gtools}collapse ///
			`p_f_collapse' `p_i_collapse' `p_fi_collapse' ///
			(p50) log_p50_f=log_earnings_f_sel log_p50_i=log_earnings_i_sel log_p50_fi=log_earnings_fi_sel ///
			(firstnm) N_pop* N_formal* N_informal* N_forminform* share_* mean_* ///
			[pw = weight], by(region) fast
		drop share_one mean_one
		foreach p of global percentiles_list {
			qui gen float log_p`p'_p50_f = log_p`p'_f - log_p50_f
			qui gen float log_p`p'_p50_i = log_p`p'_i - log_p50_i
			qui gen float log_p`p'_p50_fi = log_p`p'_fi - log_p50_fi
		}
		qui gen int year = `y'
		qui compress
		qui save "${DIR_TEMP}/PNAD/pnad_panel_`y'.dta", replace
		if `counter' == `counter_max' {
			foreach y_inner of global years_pnad {
				if `y_inner' == `y_min' qui use "${DIR_TEMP}/PNAD/pnad_panel_`y_inner'.dta", clear
				else qui append using "${DIR_TEMP}/PNAD/pnad_panel_`y_inner'.dta"
				qui erase "${DIR_TEMP}/PNAD/pnad_panel_`y_inner'.dta"
			}
			qui compress
			qui save "${DIR_TEMP}/PNAD/pnad_panel.dta", replace
		}
		
		* clean up and increase counter
	// 	qui erase "${DIR_TEMP}/PNAD/temp.dta"
		local ++counter
	}

	* formatting
	qui use "${DIR_TEMP}/PNAD/pnad_pooled.dta", clear
	label var year "year"
	label var N_pop "population size"
	label var share_at_mw_f "share at MW (formal)"
	label var share_atbelow_mw_f "share at or below MW (formal)"
	label var share_around_mw_f "share within 5% around MW (formal)"
	label var share_at_mw_i "share at MW (informal)"
	label var share_atbelow_mw_i "share at or below MW (informal)"
	label var share_around_mw_i "share within 5% around MW (informal)"
	label var share_at_mw_fi "share at MW (formal&informal)"
	label var share_atbelow_mw_fi "share at or below MW (formal&informal)"
	label var share_around_mw_fi "share within 5% around MW (formal&informal)"
	label var share_formal "share formal"
	label var share_in_laborforce "share in labor force"
	label var share_employed "share employed"
	label var share_second_job "share with second job"
	label var share_formal_emp_f "share formerly formal"
	label var share_searching "share searching for job"
	label var share_urban "share living in urban area"
	label var share_literate "share literate"
	label var share_in_school "share in school"
	label var share_complt_le "share completed < primary"
	label var share_complt_pr "share completed primary"
	label var share_complt_hs "share completed high school"
	label var share_complt_co "share completed college"
	label var mean_hours "mean hours worked"
	label var mean_income_bonus "mean bonus income"
	label var mean_income_goods "mean non-monetary income"
	label var mean_edu_years "mean education (years)"
	label var share_migrated_state "share recent migrant"
	label var share_ee_eue_trans "share recent EE/EUE transition"
	label var share_union_member "share union members"
	label var share_ret_contr "share voluntary retirement contribution"
	label var share_child_born "share recent child born"
	label var share_child_dead "share recent dead child born"
	label var share_walls_solid "share solid walls"
	label var share_roof_solid "share solid roof"
	label var share_house_owner "share house owners"
	label var share_water_piped "share piped water"
	label var share_bathroom "share bathroom"
	label var share_light_elec "share electric light"
	label var share_radio "share radio"
	label var share_washing_mac "share washing machine"
	label var share_phone "share phone"
	label var share_stove "share stove"
	label var share_tv "share tv"
	label var share_fridge_freezer "share fridge/freezer"
	label var mean_income_hh "mean household income"
	label var mean_rent "mean rent payment"
	label var mean_mortgage "mean mortgage payment"
	order year N_pop *
	qui compress
	qui save "${DIR_TEMP}/PNAD/pnad_pooled.dta", replace
	
	qui use "${DIR_TEMP}/PNAD/pnad_panel.dta", clear
	label var region "state"
	label var year "year"
	global label_subpop = ""
	global label_subpop_edu1 = " (< primary school)"
	global label_subpop_edu2 = " (primary school)"
	global label_subpop_edu3 = " (high school)"
	global label_subpop_geq4 = " (college)"
	
	foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
		if ${distribution} == 1 {
			label var N_pop`subpop' "population size${label_subpop`subpop'}"
			
			label var share_at_mw_f`subpop' "share at MW${label_subpop`subpop'}, formal)"
			label var share_atbelow_mw_f`subpop' "share at or below MW${label_subpop`subpop'}, formal)"
			label var share_around_mw_f`subpop' "share within 5% around MW${label_subpop`subpop'}, formal)"
			
			label var share_at_mw_i`subpop' "share at MW${label_subpop`subpop'}, informal)"
			label var share_atbelow_mw_i`subpop' "share at or below MW${label_subpop`subpop'}, informal)"
			label var share_around_mw_i`subpop' "share within 5% around MW${label_subpop`subpop'}, informal)"
			
			label var share_at_mw_fi`subpop' "share at MW${label_subpop`subpop'}, formal&informal)"
			label var share_atbelow_mw_fi`subpop' "share at or below MW${label_subpop`subpop'}, formal&informal)"
			label var share_around_mw_fi`subpop' "share within 5% around MW${label_subpop`subpop'}, formal&informal)"
		}
		if ${employment} == 1 {
			label var share_in_laborforce`subpop' "share in labor force${label_subpop`subpop'}"
			label var share_employed`subpop' "share employed`label_subpop${label_subpop`subpop'}"
		}
		if ${formal} == 2 label var share_formal`subpop' "share formal${label_subpop`subpop'}"
		if ${others} == 1 {
			label var share_second_job`subpop' "share with second job${label_subpop`subpop'}"
			label var share_formal_emp_f`subpop' "share formerly formal${label_subpop`subpop'}"
			label var share_searching`subpop' "share searching for job${label_subpop`subpop'}"
			label var share_urban`subpop' "share living in urban area${label_subpop`subpop'}"
			label var share_literate`subpop' "share literate${label_subpop`subpop'}"
			label var share_in_school`subpop' "share in school${label_subpop`subpop'}"
			label var share_complt_le`subpop' "share completed < primary${label_subpop`subpop'}"
			label var share_complt_pr`subpop' "share completed primary${label_subpop`subpop'}"
			label var share_complt_hs`subpop' "share completed high school${label_subpop`subpop'}"
			label var share_complt_co`subpop' "share completed college${label_subpop`subpop'}"
			label var mean_hours`subpop' "mean hours worked${label_subpop`subpop'}"
			label var mean_income_bonus`subpop' "mean bonus income${label_subpop`subpop'}"
			label var mean_income_goods`subpop' "mean non-monetary income${label_subpop`subpop'}"
			label var mean_edu_years`subpop' "mean education (years)${label_subpop`subpop'}"
		}
		if ${comp1990} == 1 {
			label var share_migrated_state`subpop' "share recent migrant${label_subpop`subpop'}"
			label var share_ee_eue_trans`subpop' "share recent EE/EUE transition${label_subpop`subpop'}"
			label var share_union_member`subpop' "share union member${label_subpop`subpop'}"
			label var share_ret_contr`subpop' "share voluntary retirement contribution${label_subpop`subpop'}"
			label var share_child_born`subpop' "share recent child born${label_subpop`subpop'}"
			label var share_child_dead`subpop' "share recent dead child born${label_subpop`subpop'}"
		}
		if ${hh} == 1 {
			label var share_walls_solid`subpop' "share solid walls${label_subpop`subpop'}"
			label var share_roof_solid`subpop' "share solid roof${label_subpop`subpop'}"
			label var share_house_owner`subpop' "share house owners${label_subpop`subpop'}"
			label var share_water_piped`subpop' "share piped water${label_subpop`subpop'}"
			label var share_bathroom`subpop' "share bathroom${label_subpop`subpop'}"
			label var share_light_elec`subpop' "share electric light${label_subpop`subpop'}"
			label var share_radio`subpop' "share radio${label_subpop`subpop'}"
			label var share_washing_mac`subpop' "share washing machine${label_subpop`subpop'}"
			label var share_phone`subpop' "share phone${label_subpop`subpop'}"
			label var share_stove`subpop' "share stove${label_subpop`subpop'}"
			label var share_tv`subpop' "share tv${label_subpop`subpop'}"
			label var share_fridge_freezer`subpop' "share fridge/freezer${label_subpop`subpop'}"
			label var mean_income_hh`subpop' "mean household income${label_subpop`subpop'}"
			label var mean_rent`subpop' "mean rent payment${label_subpop`subpop'}"
			label var mean_mortgage`subpop' "mean mortgage payment${label_subpop`subpop'}"
		}
	}
	foreach p of global percentiles_list {
		label var log_p`p'_f "log(P`p') formal"
		label var log_p`p'_i "log(P`p') informal"
		label var log_p`p'_fi "log(P`p') formal&informal"
	}
	label var log_p50_f "log(P50) formal"
	label var log_p50_i "log(P50) informal"
	label var log_p50_fi "log(P50) formal&informal"
	qui gen float log_mw = .
	foreach y of global years_pnad {
		qui replace log_mw = ln(${minwage`y'}) if year == `y'
	}
	qui gen float log_mw_p50_f = log_mw - log_p50_f
	qui gen float log_mw_p50_i = log_mw - log_p50_i
	qui gen float log_mw_p50_fi = log_mw - log_p50_fi
	label var log_mw "log(MW)"
	label var log_mw_p50_f "log(MW/P50) formal"
	label var log_mw_p50_i "log(MW/P50) informal"
	label var log_mw_p50_fi "log(MW/P50) formal&informal"
	order region year *
	qui compress
	qui save "${DIR_TEMP}/PNAD/shares_state.dta", replace
	
	* close log file
	log close log_sumstats_pnad
}




********************************************************************************
* PME
********************************************************************************
if $pme {


	*** main code
	if $pme_clean {
		disp "--> make PME data compatible across years and construct panel"
		datazoom_pmeantiga, years(${years_pme_antiga}) original("${DIR_TEMP}/PME/pme_antiga") saving("${DIR_TEMP}/PME") idrs
		datazoom_pmenova, years(${years_pme_nova}) original("${DIR_TEMP}/PME/pme_nova") saving("${DIR_TEMP}/PME") idrs
	}
	
	/*
	NOTES:
	- may want to exclude "military&public servants" (v414==1)
	- differences with Meghir et al. (2015): inclusion of mil.&pub. workers, definition of labor concepts (?), truncating panel after first transition, years, age, interview spells
	*/
	
	XXXXXX

	disp "--> process compatible PME data panel"
	global l_first = "A"
	global l_last = "S"
	global l_list = ""
	forval l_n = 0/9 {
		foreach l in `c(ALPHA)' {
			if `l_n' == 0 & "`l'" == "${l_first}" disp "* reading panels:"
			if `l_n' == 0 local l_n_str = ""
			else local l_n_str = "`l_n'"
			disp "   ...`l'`l_n_str'"
			
			* read
			local use_vars = "idind v035 v070 v075 v072 v112 v113 v114 v115 v203 v211 v215 v234 v302 v306 v307 v310 v311 v409 ${earnings_pme} ${earnings_pme}df v401 v403 v414 v415 v4271 v4272 v4275 v4274 v428 v447 v449 v455 v456 v457 v458 v459 v465 v466 v407A v408A"
// 			qui use `use_vars' using "${DIR_TEMP}/PME/pmenova_painel_`l'`l_n_str'_rs.dta", clear
			qui use `use_vars' using "/Users/cm3594/Data/PME/processed/pmenova_painel_`l'`l_n_str'_rs.dta", clear
			rename idind id
			rename v035 region
			label define region_l 26 "Recife" 29 "Salvador" 31 "Belo Horizonte" 33 "Rio de Janeiro" 35 "Sao Paulo" 41 "Curitiba" 43 "Porto Alegre", replace
			label val region region_l
			rename v070 month
			rename v075 year
			rename v072 spell
			rename v112 stratid 
			rename v113 psu
			rename v114 pop
			qui drop if inlist(.,stratid,psu,pop)
			rename v211 weight
			rename v215 weight_proj
			rename v115 mw
			rename v203 gender
			qui recode gender (2 = 0)
			label define gender_l 0 "female" 1 "male", replace
			label val gender gender_l
			rename v234 age
			rename v302 in_school
			qui recode in_school (2 = 0) /* all non-missing for age >= 10: tab in_school if age >= 10, m */
			qui gen byte edu_degree = .
			rename v306 school_prior /* all non-missing for those out of school: tab school_prior if in_school == 0, m */
			rename v307 school_prior_grade /* all non-missing for those previously in school: tab school_prior_grade if school_prior == 1, m */
			rename v311 school_prior_concluded
			qui replace school_prior_concluded = 0 if in_school == 0 & school_prior == 1 & school_prior_concluded == . /* assume that respondent did not complete degree if previously attended but did not report graduation status */
			
			qui gen byte edu_years = .
			rename v310 school_years
			qui replace edu_years = 0 if school_prior == 2 | school_prior_grade == 8
			qui replace edu_years = 2 if school_prior_grade == 7
			forval school_y = 1/8 {
				qui replace edu_years = min(`school_y',4) if (school_prior_grade == 1 & school_years == `school_y')
				qui replace edu_years = 4 + min(`school_y',4) if (school_prior_grade == 2 & school_years == `school_y')
				qui replace edu_years = `school_y' if (school_prior_grade == 4 & school_years == `school_y')
				qui replace edu_years = 8 + `school_y' if (inlist(school_prior_grade,3,5) & school_years == `school_y')
				qui replace edu_years = 12 + min(`school_y',4) if (school_prior_grade == 6 & school_years == `school_y')
			}
			qui replace edu_years = 16 if school_prior_grade == 9
			qui replace edu_years = 2 if school_prior_grade == 1 & school_years == .
			qui replace edu_years = 6 if school_prior_grade == 2 & school_years == .
			qui replace edu_years = 4 if school_prior_grade == 4 & school_years == .
			qui replace edu_years = 10 if inlist(school_prior_grade,3,5) & school_years == .
			qui replace edu_years = 14 if school_prior_grade == 6 & school_years == .
			qui replace edu_years = 4 if school_prior_grade == 1 & school_prior_concluded == 1
			qui replace edu_years = 8 if school_prior_grade == 2 & school_prior_concluded == 1
			qui replace edu_years = 8 if school_prior_grade == 4 & school_prior_concluded == 1
			qui replace edu_years = 12 if inlist(school_prior_grade,3,5) & school_prior_concluded == 1
			qui replace edu_years = 16 if school_prior_grade == 6 & school_prior_concluded == 1
			qui replace edu_degree = 1 if (school_prior == 2 | inlist(school_prior_grade,7,8) | (inlist(school_prior_grade,1,4) & school_prior_concluded == 2))
			qui replace edu_degree = 2 if ((inlist(school_prior_grade,1,4) & school_prior_concluded == 1) | school_prior_grade == 2 | (inlist(school_prior_grade,3,5) & school_prior_concluded == 2))
			qui replace edu_degree = 3 if ((inlist(school_prior_grade,3,5) & school_prior_concluded == 1) | (school_prior_grade == 6 & school_prior_concluded == 2))
			qui replace edu_degree = 4 if ((school_prior_grade == 6 & school_prior_concluded == 1) | school_prior_grade == 9)
			label define edu_degree_l 1 "< primary school" 2 "primary school" 3 "high school" 4 "college", replace
			label val edu_degree edu_degree_l
			qui gen byte complt_le = edu_degree == 1 if edu_degree < .
			qui gen byte complt_pr = edu_degree == 2 if edu_degree < .
			qui gen byte complt_hs = edu_degree == 3 if edu_degree < .
			qui gen byte complt_co = edu_degree == 4 if edu_degree < .
			drop school_prior school_prior_grade school_prior_concluded
			rename v409 job_type
			qui recode job_type (6 = 5)
			label define job_type_l 1 "domestic worker" 2 "employee" 3 "self-employed" 4 "employer" 5 "unpaid", replace
			label val job_type job_type_l
			rename ${earnings_pme} earnings /* note: earnings = 0 if inlist(job_type,3,4,5,.) */
			rename ${earnings_pme}df earnings_def
			qui gen float log_earn_d = ln(earnings_def)
			qui gen byte job = .
			rename v401 job_worked
			rename v403 job_absent
			qui replace job_worked = 2 if job_type == . & (job_worked == 1 | job_absent == 1) /* asume respondent did not work if job type is not reported */
			qui replace job_absent = 2 if job_type == . & (job_worked == 1 | job_absent == 1) /* asume respondent was not absent from work if job type is not reported */
			qui replace job_absent = 2 if job_worked != 1 & job_absent == . & in_school == 0 /* asume respondent was not absent from work if did not work, did not attend school, and job absence is not reported */
			qui replace job = 1 if ((job_worked == 1 | job_absent == 1) & job_type != 5)
			qui replace job = 0 if ((job_worked == 2 & job_absent == 2) | inlist(job_type,4,5)) /* all non-missing for those out of school: tab job if in_school == 0, m */
			drop job_worked job_absent
			rename v414 military_public
			rename v415 formal_emp
			qui recode formal_emp (2 = 0)
			qui replace formal_emp = 0 if job_type == 3 /* note: originally, formal_emp = . if inlist(job_type,3,4,5,.) */
			qui replace formal_emp = 1 if military_public == 1
			drop military_public
			rename v4271 tenure_days
			rename v4272 tenure_y0_months
			rename v4275 tenure_y1_months
			rename v4274 tenure_years
			qui gen long tenure = .
			qui replace tenure = tenure_days if tenure_days < .
			qui replace tenure = round(tenure_y0_months*30.5) if tenure_y0_months < .
			qui replace tenure = 365 + round(tenure_y1_months*30.5) if tenure_y1_months < .
			qui replace tenure = tenure_years*365 if tenure_years < .
			drop tenure_days tenure_y0_months tenure_y1_months tenure_years
			rename v428 hours
			rename v447 job_type_prev /* XXX check tabulations from here on! */
			qui recode job_type_prev (6 = 5)
			label val job_type_prev job_type_l
			rename v449 formal_emp_prev
			qui recode formal_emp_prev (2 = 0)
			qui gen byte searching = .
			rename v455 searching_recent_U
			rename v456 searching_longtime_U
			rename v457 searching_really
			rename v458 took_measure_refweek
			rename v459 took_measure_pastmonth
			qui replace searching = 1 if ((searching_recent_U == 1 | searching_longtime_U == 1) & searching_really != 10 & (took_measure_refweek == 1 | took_measure_pastmonth == 1))
			qui replace searching = 0 if ((searching_recent_U == 2 | searching_longtime_U == 2) | searching_really == 10 | (took_measure_refweek == 2 & took_measure_pastmonth == 2))
			drop searching_really searching_recent_U searching_longtime_U took_measure_refweek took_measure_pastmonth
			rename v465 willing_able_refweek
			rename v466 willing_able_pastmonth
			qui gen byte willing_able = .
			qui replace willing_able = 1 if (willing_able_refweek == 1 | willing_able_pastmonth == 1)
			qui replace willing_able = 0 if (willing_able_refweek == 2 & willing_able_pastmonth == 2)
			drop willing_able_refweek willing_able_pastmonth
			qui gen byte in_laborforce = .
			qui replace in_laborforce = 1 if (in_school == 0 & !inlist(job_type,4,5) & ((job == 1 & inlist(job_type,1,2,3)) | (searching == 1 & willing_able == 1)))
			qui replace in_laborforce = 0 if (in_school == 1 | inlist(job_type,4,5) | ((job == 0 | inlist(job_type,4,5)) & (searching == 0 | willing_able == 0))) /* note: all respondents with in_laborforce = 0 & job = 1 are in school */
			drop searching willing_able
			rename v407A occ
			qui recode occ (1/5 11/13 = 1) (20/26 = 2) (30/39 = 3) (41/42 = 4) (51/52 = 5) (61/64 = 6) (71/78 81/87 = 7) (91/99 = 8) (nonmissing = 0), generate(occ_agg)
			label define occ_l 1 "public/military officers" 2 "scientists, artists" 3 "mid-level technical" 4 "administrators" 5 "service/sales workers" 6 "agricultural workers" 7 "production workers" 8 "repair/maintenance workers" 0 "other", replace
			label val occ occ_l
			rename v408A ind
			qui recode ind (10/41 = 1) (45 = 2) (50/53 = 3) (65/74 = 4) (75 80/85 = 5) (95 = 6) (55/64 90/93 = 7) (1/5 99 0 = 8) (nonmissing = 0), generate(ind_agg)
			label define ind_l 1 "manufacturing" 2 "construction" 3 "commerce" 4 "finance/real estate" 5 "public services" 6 "domestic services" 7 "transport/telecom/urban" 8 "agriculture/intl/other" 0 "other", replace
			label val ind ind_l
			
			* define work status
			/* LEVEL 1: in_laborforce = 0,1 */
			/* LEVEL 2: if in_laborforce = 1, then job = 0,1 --> if job = 0 then unemployed */
			/* LEVEL 3: if job = 1, then formal_emp = 0,1 --> if formal_emp = 1 then formal, else if formal_emp = 0 then informal */
			qui gen byte status = .
			qui replace status = 1 if in_laborforce == 0
			qui replace status = 2 if in_laborforce == 1 & job == 0
			qui gen byte unemployed = .
			qui replace unemployed = 1 if in_laborforce == 1 & job == 0
			qui replace unemployed = 0 if in_laborforce == 1 & job == 1
			qui replace status = 3 if in_laborforce == 1 & job == 1 & formal_emp == 0
			qui replace status = 4 if in_laborforce == 1 & job == 1 & formal_emp == 1
			label define status_l 1 "out of labor force" 2 "unemployed" 3 "informal" 4 "formal", replace
			label val status status_l
			
			* label
			label var id "unique individual ID"
			label var year "survey year"
			label var month "survey month"
			label var spell "interview spell (1-8)"
			label var region "metropolitan region"
			label var stratid "stratum ID"
			label var psu "primary sampling unit (PSU)"
			label var mw "minimum wage (nominal BRL)"
			label var gender "gender"
			label var age "age"
			label var edu_degree "education degree"
			label var status "work status"
			label var in_laborforce "labor force status"
			label var unemployed "unemployed status"
			label var job "job status"
			label var job_type "job type"
			label var formal_emp "formal employment"
			label var tenure "tenure (days)"
			label var hours "usual hours worked"
			label var earnings "earnings (nominal BRL)"
			label var ind "industry (CNAE-Domiciliar)"
			label var ind_agg "industry (aggregated)"
			label var occ "occupation (CBO-Domiciliar)"
			label var occ_agg "occupation (aggregated)"
			label var job_type_prev "job type at previous job"
			label var formal_emp_prev "formal employment at previous job"
			label var weight "inverse probability weight (raw)"
			label var weight_proj "inverse probability weight (pop. projection)"
			
			* clean up
			qui keep if ${use_conds_pme}
			drop in_school
			sort id year month
			order id year month spell region stratid psu gender age edu_degree status in_laborforce job ind ind_agg occ occ_agg job_type formal_emp tenure hours earnings job_type_prev formal_emp_prev mw weight weight_proj
			
			* save
			qui compress
			qui save "${DIR_TEMP}/PME/pme_panel_`l'`l_n_str'.dta", replace
			global l_list = "${l_list} `l'`l_n_str'"
			
			* loop control
			if "`l'`l_n_str'" == "${l_last}" local breaker = 1
			else local breaker = 0
			if `breaker' continue, break
		}
		if `breaker' continue, break
	}

	* append panels
	local counter_append = 1
	foreach l_str of global l_list {
		if `counter_append' == 1 qui use "${DIR_TEMP}/PME/pme_panel_`l_str'.dta", clear
		else qui append using "${DIR_TEMP}/PME/pme_panel_`l_str'.dta"
		local ++counter_append
	}
	
	// general & summary statistics:
	// XXX NOTE: should standard errors be computed using -svy- command?!?!
	cap log close log_sumstats_pme
	log using "${DIR_LOG}/log_sumstats_pme.log", replace name(log_sumstats_pme)
	foreach y in $years_pme_antiga $years_pme_nova {
		disp _newline(1)
		disp "...year `y'"
		disp "                  | OVERALL    | < PRIMARY  | PRIMARY    | HIGH SCHL  | COLLEGE"
		qui preserve
// 		qui keep if year == `y' & month == 9 // pick september of a given year to mimic PNAD survey month
		qui keep if year == `y'
		foreach var of varlist age edu_years complt_le complt_pr complt_hs complt_co hours log_earn_d {
			disp "`var':"
			foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
				qui sum `var' if in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} ${sel`subpop'}
				local N_`var'_f_unw`subpop'_trunc: di %8.0f `r(N)'
				qui sum `var' [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime} ${sel`subpop'}
				local N_`var'_f`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'_f`subpop'_trunc: di %6.3f `r(mean)'
				local sd_`var'_f`subpop'_trunc: di %6.3f `r(sd)'
				qui sum `var' if in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} ${sel`subpop'}
				local N_`var'_i_unw`subpop'_trunc: di %8.0f `r(N)'
				qui sum `var' [fw = weight] if in_laborforce == 1 & job == 1 & formal_emp == 0 ${select_fulltime} ${sel`subpop'}
				local N_`var'_i`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'_i`subpop'_trunc: di %6.3f `r(mean)'
				local sd_`var'_i`subpop'_trunc: di %6.3f `r(sd)'
				qui sum `var' if in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} ${sel`subpop'}
				local N_`var'_fi_unw`subpop'_trunc: di %8.0f `r(N)'
				qui sum `var' [fw = weight] if in_laborforce == 1 & job == 1 & inrange(formal_emp,0,1) ${select_fulltime} ${sel`subpop'}
				local N_`var'_fi`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'_fi`subpop'_trunc: di %6.3f `r(mean)'
				local sd_`var'_fi`subpop'_trunc: di %6.3f `r(sd)'
				qui sum `var' if in_laborforce == 1 & job == 0 ${select_fulltime} ${sel`subpop'}
				local N_`var'_u_unw`subpop'_trunc: di %8.0f `r(N)'
				qui sum `var' [fw = weight] if in_laborforce == 1 & job == 0 ${select_fulltime} ${sel`subpop'}
				local N_`var'_u`subpop'_trunc: di %8.0f `r(N)'
				local mean_`var'_u`subpop'_trunc: di %6.3f `r(mean)'
				local sd_`var'_u`subpop'_trunc: di %6.3f `r(sd)'
			}
			foreach s in "f" "i" "fi" "u" {
				if !(inlist("`var'", "hours", "log_earn_d") & "`s'" == "u") {
					disp "     N unw. (`s'):  | `N_`var'_`s'_unw_trunc'   | `N_`var'_`s'_unw_edu1_trunc'   | `N_`var'_`s'_unw_edu2_trunc'   | `N_`var'_`s'_unw_edu3_trunc'   | `N_`var'_`s'_unw_edu4_trunc'"
					disp "     N (`s'):       | `N_`var'_`s'_trunc'   | `N_`var'_`s'_edu1_trunc'   | `N_`var'_`s'_edu2_trunc'   | `N_`var'_`s'_edu3_trunc'   | `N_`var'_`s'_edu4_trunc'"
					disp "     mean (`s'):    | `mean_`var'_`s'_trunc'     | `mean_`var'_`s'_edu1_trunc'     | `mean_`var'_`s'_edu2_trunc'     | `mean_`var'_`s'_edu3_trunc'     | `mean_`var'_`s'_edu4_trunc'"
					disp "     sd (`s'):      | `sd_`var'_`s'_trunc'     | `sd_`var'_`s'_edu1_trunc'     | `sd_`var'_`s'_edu2_trunc'     | `sd_`var'_`s'_edu3_trunc'     | `sd_`var'_`s'_edu4_trunc'"
				}
			}
		}
		qui restore
	}
	qui log off log_sumstats_pme
	
	* re-group interview spells
	qui recode spell (1/4 = 1) (5/8 = 2), generate(spell_g) // NOTE: spell is defined as up to 4 consecutive months of interviews.
	qui ${gtools}egen long id_spell = group(id spell_g)

	* selection
	qui bys id_spell (in_laborforce): gen byte status_trunc = status if _N == 4 & in_laborforce[1] == 1
	label val status_trunc status_l

	* set panel
	qui gen long date = ym(year,month)
	label var date "date (year, month)"
	qui xtset id_spell date

	* transitions (codes for status_trunc: 2 = unemployed, 3 = informal, 4 = formal)
	qui gen byte trans_ui = (status_trunc == 2 & F.status_trunc == 3) if status_trunc == 2 & inlist(F.status_trunc,2,3,4)
	qui gen byte trans_uf = (status_trunc == 2 & F.status_trunc == 4) if status_trunc == 2 & inlist(F.status_trunc,2,3,4)
	qui gen byte trans_iu = (status_trunc == 3 & F.status_trunc == 2) if status_trunc == 3 & inlist(F.status_trunc,2,3,4)
	qui gen byte trans_ii = (status_trunc == 3 & F.status_trunc == 3 & F.tenure <= 30) if status_trunc == 3 & inlist(F.status_trunc,2,3,4) & F.tenure < .
	qui gen byte trans_if = (status_trunc == 3 & F.status_trunc == 4) if status_trunc == 3 & inlist(F.status_trunc,2,3,4)
	qui gen byte trans_fu = (status_trunc == 4 & F.status_trunc == 2) if status_trunc == 4 & inlist(F.status_trunc,2,3,4)
	qui gen byte trans_fi = (status_trunc == 4 & F.status_trunc == 3) if status_trunc == 4 & inlist(F.status_trunc,2,3,4)
	qui gen byte trans_ff = (status_trunc == 4 & F.status_trunc == 4 & F.tenure <= 30) if status_trunc == 4 & inlist(F.status_trunc,2,3,4) & F.tenure < .
	qui gen byte trans_nf_f = .
	qui replace trans_nf_f = 0 if trans_uf == 0 | trans_if == 0
	qui replace trans_nf_f = 1 if trans_uf == 1 | trans_if == 1
	qui gen byte trans_f_nf = .
	qui replace trans_f_nf = 0 if trans_fu == 0 | trans_fi == 0
	qui replace trans_f_nf = 1 if trans_fu == 1 | trans_fi == 1
	label var trans_ui "transition from unemployed to informal"
	label var trans_uf "transition from unemployed to formal"
	label var trans_iu "transition from informal to unemployed"
	label var trans_ii "transition from informal to informal"
	label var trans_if "transition from informal to formal"
	label var trans_fu "transition from formal to unemployed"
	label var trans_fi "transition from formal to informal"
	label var trans_ff "transition from formal to formal"
	label var trans_nf_f "transition from nonformal to formal"
	label var trans_f_nf "transition from formal to nonformal"

	* summarize and save summary statistics on transitions
	qui log on log_sumstats_pme
// 	foreach var of varlist trans_* {
// 		qui replace `var' = . if L.`var' < . | L2.`var' < . | L3.`var' < . // keep only first transition in a sub-panel
// 	}
	foreach y in $years_pme_antiga $years_pme_nova {
		disp _newline(1)
		qui count if status_trunc < . & year == `y'
		disp "Year `y': N = `r(N)'"
		sum trans_ui trans_uf trans_iu trans_ii trans_if trans_fu trans_fi trans_ff trans_nf_f trans_f_nf [fw = ${weight_pme}] if year == `y', sep(0)
	}
	disp "All years ($years_pme_antiga $years_pme_nova):"
	sum trans_ui trans_uf trans_iu trans_ii trans_if trans_fu trans_fi trans_ff trans_nf_f trans_f_nf [fw = ${weight_pme}], sep(0)
	// NOTE: F-to-F transition rates appears very low!
	
	* close log file
	log close log_sumstats_pme
	
	* save
	order id id_spell date year month spell spell_g region stratid psu gender age edu_degree status in_laborforce job ind ind_agg occ occ_agg job_type formal_emp hours earnings job_type_prev formal_emp_prev mw trans* weight weight_proj
	qui compress
	qui save "${DIR_TEMP}/PME/pme_panel.dta", replace

	* create metro panel -- !potentially add one more cross-variable, e.g. industry or occupation! -- NOTE: complex survey design matters only for standard errors!
	use "${DIR_TEMP}/PME/pme_panel.dta", clear
// 	svyset psu [pw = weight], strata(stratid) poststrata(region) postweight(pop)
	foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
		sort region year month
		if "${gtools}" == "" {
			qui by region year month: egen long N_pop`subpop' = total((1 == 1 ${sel`subpop'})*${weight_pme})
			qui by region year month: egen long N_forminform`subpop' = total((inlist(formal_emp,1,0) & in_laborforce == 1 & job == 1 ${select_fulltime} ${sel`subpop'})*weight)
// 			qui svy: month in_laborforce if month == 3
			qui by region year month: egen long N_in_laborforce`subpop' = total((in_laborforce == 1 ${sel`subpop'})*${weight_pme})
			qui by region year month: egen long N_out_of_laborforce`subpop' = total((in_laborforce == 0 ${sel`subpop'})*${weight_pme})
			qui by region year month: egen long N_employed`subpop' = total((in_laborforce == 1 & unemployed == 0 ${sel`subpop'})*${weight_pme})
			qui gen float share_in_laborforce`subpop' = N_in_laborforce`subpop'/(N_in_laborforce`subpop' + N_out_of_laborforce`subpop')
			qui gen float share_employed`subpop' = N_employed`subpop'/N_in_laborforce`subpop'
			qui by region year month: egen long N_formal`subpop' = total((formal_emp == 1 & in_laborforce == 1 & job == 1 ${select_fulltime} ${sel`subpop'})*${weight_pme})
			qui gen float share_formal`subpop' = N_formal`subpop'/N_forminform`subpop'
			qui by region year month: egen long N_informal`subpop' = total((formal_emp == 0 & in_laborforce == 1 & job == 1 ${select_fulltime} ${sel`subpop'})*${weight_pme})
			foreach trans in ui uf iu ii if fu fi ff nf_f f_nf {
				qui by region year month: egen long N_all_`trans'`subpop' = total((inlist(trans_`trans',1,0) ${sel`subpop'})*${weight_pme})
				qui by region year month: egen long N_trans_`trans'`subpop' = total((trans_`trans' == 1 ${sel`subpop'})*${weight_pme})
				qui gen float share_trans_`trans'`subpop' = N_trans_`trans'`subpop'/N_all_`trans'`subpop'
				drop N_trans_`trans'`subpop'
			}
		}
		else {
			qui gegen long N_pop`subpop' = total((1 == 1 ${sel`subpop'})*${weight_pme}), by(region year month)
			qui gegen long N_forminform`subpop' = total((inlist(formal_emp,1,0) & in_laborforce == 1 & job == 1 ${select_fulltime} ${sel`subpop'})*weight), by(region year month)
// 			qui svy: month in_laborforce if month == 3
			qui gegen long N_in_laborforce`subpop' = total((in_laborforce == 1 ${sel`subpop'})*${weight_pme}), by(region year month)
			qui gegen long N_out_of_laborforce`subpop' = total((in_laborforce == 0 ${sel`subpop'})*${weight_pme}), by(region year month)
			qui gegen long N_employed`subpop' = total((in_laborforce == 1 & unemployed == 0 ${sel`subpop'})*${weight_pme}), by(region year month)
			qui gen float share_in_laborforce`subpop' = N_in_laborforce`subpop'/(N_in_laborforce`subpop' + N_out_of_laborforce`subpop')
			qui gen float share_employed`subpop' = N_employed`subpop'/N_in_laborforce`subpop'
			qui gegen long N_formal`subpop' = total((formal_emp == 1 & in_laborforce == 1 & job == 1 ${select_fulltime} ${sel`subpop'})*${weight_pme}), by(region year month)
			qui gen float share_formal`subpop' = N_formal`subpop'/N_forminform`subpop'
			qui gegen long N_informal`subpop' = total((formal_emp == 0 & in_laborforce == 1 & job == 1 ${select_fulltime} ${sel`subpop'})*${weight_pme}), by(region year month)
			foreach trans in ui uf iu ii if fu fi ff nf_f f_nf {
				qui gegen long N_all_`trans'`subpop' = total((inlist(trans_`trans',1,0) ${sel`subpop'})*${weight_pme}), by(region year month)
				qui gegen long N_trans_`trans'`subpop' = total((trans_`trans' == 1 ${sel`subpop'})*${weight_pme}), by(region year month)
				qui gen float share_trans_`trans'`subpop' = N_trans_`trans'`subpop'/N_all_`trans'`subpop'
				drop N_trans_`trans'`subpop'
			}
		}
	}

	* fill gaps
	foreach var of varlist N_* share_* {
		qui bys region year month (`var'): replace `var' = `var'[1]
	}	

	* generate metro-year-month panel
	qui gen float log_earnings = ln(earnings)
	qui gen float log_earnings_sel = log_earnings if (in_laborforce == 1 & job == 1 & formal_emp == 1 ${select_fulltime})
	local p_collapse = ""
	foreach p of global percentiles_list {
		local p_collapse = "`p_collapse' (p`p') log_p`p' = log_earnings_sel"
	}
	qui gen float log_mw = ln(mw)
	${gtools}collapse ///
		`p_collapse' ///
		(p50) log_p50=log_earnings_sel ///
		(firstnm) N_* share_* log_mw date ///
		[pw = ${weight_pme}], by(region year month) fast
	foreach p of global percentiles_list {
		qui gen float log_p`p'_p50 = log_p`p' - log_p50
	}
	qui gen float log_mw_p50 = log_mw - log_p50
	label var log_mw "log(MW)"
	label var log_mw_p50 "log(MW/P50)"
	qui compress
	order region date year month
	qui save "${DIR_TEMP}/PNAD/trans_metro.dta", replace
}




********************************************************************************
* regressions
********************************************************************************
if $regressions {
	
	
	*** regression analysis
	cap log close regressions
	log using "${DIR_LOG}/log_regressions_pnad_pme.log", replace name(log_regressions_pnad_pme)
	local counter_graphs = 1
	foreach controls in ///
		"i.year" "i.date" ///
		"i.region" ///
		"i.region i.year" "i.region i.date" ///
		"i.region##(c.year)" "i.region##(c.date)" ///
		"i.region##(c.year c.year_2)" "i.region##(c.date c.date_2)" ///
		"i.region##(c.year c.year_2 c.year_3)" "i.region##(c.date c.date_2 c.date_3)" ///
		{
		local counter_disp = 1
		foreach part in "distribution" "employment" "formal" "others" "comp1990" "hh" "percentiles" "transitions" {
			if (${`part'} == 1 | "`part'" == "formal") & ((inlist("`part'", "distribution", "employment", "formal", "others", "comp1990", "hh", "percentiles") & !strpos("`controls'", "date")) | ("`part'" == "transitions" & !strpos("`controls'", "year"))) {
				if inlist("`part'", "distribution", "employment", "formal", "others", "comp1990", "hh", "percentiles") local reg_pnad = 1
				else local reg_pnad = 0
				else if "`part'" == "transitions" local reg_pme = 1
				else local reg_pme = 0
				if `counter_disp' == 1 {
					disp _newline(1)
					disp as result "* controls = `controls'"
					if `reg_pnad' disp as result "   MARGINAL EFFECTS (PNAD) | OVERALL          | < PRIMARY        | PRIMARY          | HIGH SCHOOL      | COLLEGE"
					else if `reg_pme' disp as result "   MARGINAL EFFECTS (PME)  | OVERALL          | < PRIMARY        | PRIMARY          | HIGH SCHOOL      | COLLEGE"
				}
				if `reg_pnad' qui use "${DIR_TEMP}/PNAD/shares_state.dta", clear
				else if `reg_pme' qui use "${DIR_TEMP}/PNAD/trans_metro.dta", clear
				
				* normalize `year_date' and create higher-order polynomial terms in `year_date'
				foreach year_date in year date {
					cap confirm var `year_date'
					if !_rc {
						* normalize `year_date'
						qui sum `year_date', meanonly
						qui replace `year_date' = `year_date' - r(min)
						
						* generate square of `year_date'
						gen long `year_date'_2 = `year_date'^2
						label var `year_date'_2 "`year_date' squared"
						
						* generate cube of `year_date'
						gen long `year_date'_3 = `year_date'^3
						label var `year_date'_3 "`year_date' cubed"
					}
				}
				
				* generate other variables
				foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
					qui gen float log_N_pop`subpop' = ln(N_pop`subpop')
					qui gen float log_N_formal`subpop' = ln(N_formal`subpop')
					qui gen float log_N_informal`subpop' = ln(N_informal`subpop')
					qui gen float log_N_forminform`subpop' = ln(N_forminform`subpop')
				}
				if inlist("`part'", "distribution", "employment", "formal", "others", "comp1990", "hh", "percentiles") qui gen float log_mw_p50 = ${kaitz_switch}
				qui gen float log_mw_p50_2 = log_mw_p50^2
				qui gen float kaitz = .
				qui gen float pred_m = .
				qui gen float pred_se = .
				qui gen float pred_upper = .
				qui gen float pred_lower = .
				local depvars = ""
				if "`part'" == "distribution" local depvars = "share_at_mw_f share_atbelow_mw_f share_around_mw_f share_at_mw_i share_atbelow_mw_i share_around_mw_i share_at_mw_fi share_atbelow_mw_fi share_around_mw_fi"
				else if "`part'" == "employment" local depvars = "log_N_pop log_N_formal log_N_informal log_N_forminform share_in_laborforce share_employed"
				else if "`part'" == "formal" local depvars = "share_formal"
				else if "`part'" == "others" local depvars = "share_second_job share_formal_emp_f share_searching share_urban share_literate share_in_school share_complt_le share_complt_pr share_complt_hs share_complt_co mean_hours mean_income_bonus mean_income_goods mean_edu_years"
				else if "`part'" == "comp1990" local depvars = "share_migrated_state share_ee_eue_trans share_union_member share_ret_contr share_child_born share_child_dead"
				else if "`part'" == "hh" local depvars = "share_walls_solid share_roof_solid share_house_owner share_water_piped share_bathroom share_light_elec share_radio share_washing_mac share_phone share_stove share_tv share_fridge_freezer mean_income_hh mean_rent mean_mortgage"
				else if "`part'" == "percentiles" {
					foreach formality in "_f" "_i" "_fi" {
						foreach p of global percentiles_list {
							local depvars = "`depvars' log_p`p'_p50`formality'"
						}
					}
				}
				else if "`part'" == "transitions" local depvars = "share_in_laborforce share_employed share_formal share_trans_ui share_trans_uf share_trans_iu share_trans_ii share_trans_if share_trans_fu share_trans_fi share_trans_ff share_trans_nf_f share_trans_f_nf"
				if ${formal} == 0 local formality_weight = "N_informal"
				else if ${formal} == 1 local formality_weight = "N_formal"
				else if ${formal} == 2 local formality_weight = "N_forminform"
				local counter_outer = 1
				foreach var in `depvars' {
					////// NO SUBGROUPS FOR PERCENTILE RATIOS????
					local counter_inner = 1
					foreach subpop in "" "_edu1" "_edu2" "_edu3" "_edu4" {
						if substr("`var'",1,5) != "log_p" | "`subpop'" == "" {
// 							qui reg `var'`subpop' log_mw_p50 log_mw_p50_2 `controls' [pw = `formality_weight']
							qui reghdfe `var'`subpop' log_mw_p50 log_mw_p50_2 `controls' [pw = `formality_weight'], noabsorb
							// manually compute marginal effect point estimate and standard error:
							matrix b = e(b)
							local b1 = b[1,1]
							local b2 = b[1,2]
							matrix s = e(V)
							local s1 = s[1,1]^.5
							local s2 = s[2,2]^.5
							local n = e(N)
							local r2 = e(r2)
							qui sum log_mw_p50 [fw = `formality_weight'], meanonly
							local mean_log_mw_p50 = r(mean)
							local pred_m_1 = `b1' + 2*`b2'*(`mean_log_mw_p50')
							local pred_se_1 = (`s1'^2 + (2*`mean_log_mw_p50')^2*`s2'^2)^.5
							// automatically compute marginal effect point estimate and standard error:
							qui lincom log_mw_p50 + 2*`mean_log_mw_p50'*log_mw_p50_2
							local pred_m_2 = r(estimate)
							local pred_se_2 = r(se)
							//graph predicted marginal effects over relevant range:
							local counter_graph = 1
							foreach kaitz of numlist -1(.1)0 {
								qui lincom log_mw_p50 + 2*`kaitz'*log_mw_p50_2
								local pred_m_2_graph_`counter_graph' = r(estimate)
								local pred_se_2_graph_`counter_graph' = r(se)
								qui replace kaitz = `kaitz' in `counter_graph'
								qui replace pred_m = `pred_m_2_graph_`counter_graph'' in `counter_graph' 
								qui replace pred_se = `pred_se_2_graph_`counter_graph'' in `counter_graph' 
								local ++counter_graph
							}
							qui replace pred_upper = pred_m + ${crit_val}*pred_se
							qui replace pred_lower = pred_m - ${crit_val}*pred_se
		// 					tw (line pred_m pred_upper pred_lower kaitz, lcolor(blue blue blue) lpattern(l - -) lwidth(thick thin thin)), title("marginal effect of MW on `var'") xtitle("Kaitz index: log(MW) - log(P50)") legend(order(1 "point estimate" 2 "95% CI") cols(2)) name(`var'_c`counter_graphs', replace)
							// display results:
							foreach l in pred_m_1 pred_m_2 {
								local `l'_trunc: di %6.3f ``l''
							}
							foreach l in pred_se_1 pred_se_2 {
								local `l'_trunc: di %5.3f ``l''
							}
							foreach l in 1 2 {
								if abs(`pred_m_`l''/`pred_se_`l'') >= 2.576 local significance_`l' = "***"
								else if abs(`pred_m_`l''/`pred_se_`l'') >= 1.960 local significance_`l' = "** "
								else if abs(`pred_m_`l''/`pred_se_`l'') >= 1.645 local significance_`l' = "*  "
								else local significance_`l' = "   "
							}
							/*disp "      ...marginal effect, manual = `pred_m_1_trunc'`significance_1' (`pred_se_1_trunc')"*/
							if "`part'" == "distribution" {
								local counter_outer_n = 1
								foreach formality in ", f" ", i" ", f&i" {
									foreach subvar in "share_at_mw" "share_atbelow_mw" "share_around_mw" {
										if `counter_outer' == `counter_outer_n' & "`subvar'" == "share_at_mw" local var_name = "share at MW`formality'"
										else if `counter_outer' == `counter_outer_n' & "`subvar'" == "share_atbelow_mw" local var_name = "share <= MW`formality'"
										else if `counter_outer' == `counter_outer_n' & "`subvar'" == "share_around_mw" local var_name = "share w/i 5% ofMW`formality'"
										local ++ counter_outer_n
									}
								}
							}
							else if "`part'" == "employment" & `counter_outer' == 1 local var_name = "log population size"
							else if "`part'" == "employment" & `counter_outer' == 2 local var_name = "log formal employed"
							else if "`part'" == "employment" & `counter_outer' == 3 local var_name = "log informal employed"
							else if "`part'" == "employment" & `counter_outer' == 4 local var_name = "log employed (f/i)"
							else if "`part'" == "employment" & `counter_outer' == 5 local var_name = "share in labor force"
							else if "`part'" == "employment" & `counter_outer' == 6 local var_name = "share employed (1-u)"
							else if "`part'" == "formal" & ${`part'} == 2 & `counter_outer' == 1 local var_name = "share formal"
							else if "`part'" == "others" & `counter_outer' == 1 local var_name = "share w/ second job"
							else if "`part'" == "others" & `counter_outer' == 2 local var_name = "share U prev. formal"
							else if "`part'" == "others" & `counter_outer' == 3 local var_name = "share searching job"
							else if "`part'" == "others" & `counter_outer' == 4 local var_name = "share in urban area"
							else if "`part'" == "others" & `counter_outer' == 5 local var_name = "share literate"
							else if "`part'" == "others" & `counter_outer' == 6 local var_name = "share in school"
							else if "`part'" == "others" & `counter_outer' == 7 local var_name = "share completed <prim."
							else if "`part'" == "others" & `counter_outer' == 8 local var_name = "share completed prim."
							else if "`part'" == "others" & `counter_outer' == 9 local var_name = "share completed HS"
							else if "`part'" == "others" & `counter_outer' == 10 local var_name = "share completed coll."
							else if "`part'" == "others" & `counter_outer' == 11 local var_name = "mean hours worked"
							else if "`part'" == "others" & `counter_outer' == 12 local var_name = "mean bonus income"
							else if "`part'" == "others" & `counter_outer' == 13 local var_name = "mean non-mon. income"
							else if "`part'" == "others" & `counter_outer' == 14 local var_name = "mean education (y.s)"
							else if "`part'" == "comp1990" & `counter_outer' == 1 local var_name = "share recent migrant"
							else if "`part'" == "comp1990" & `counter_outer' == 2 local var_name = "share recent EE/EUE"
							else if "`part'" == "comp1990" & `counter_outer' == 3 local var_name = "share union members"
							else if "`part'" == "comp1990" & `counter_outer' == 4 local var_name = "share vol.ret.contr."
							else if "`part'" == "comp1990" & `counter_outer' == 5 local var_name = "share recent child"
							else if "`part'" == "comp1990" & `counter_outer' == 6 local var_name = "share recent dead ch"
							else if "`part'" == "hh" & `counter_outer' == 1 local var_name = "share solid walls"
							else if "`part'" == "hh" & `counter_outer' == 2 local var_name = "share solid roof"
							else if "`part'" == "hh" & `counter_outer' == 3 local var_name = "share house owners"
							else if "`part'" == "hh" & `counter_outer' == 4 local var_name = "share piped water"
							else if "`part'" == "hh" & `counter_outer' == 5 local var_name = "share bathroom"
							else if "`part'" == "hh" & `counter_outer' == 6 local var_name = "share elec. light"
							else if "`part'" == "hh" & `counter_outer' == 7 local var_name = "share radio"
							else if "`part'" == "hh" & `counter_outer' == 8 local var_name = "share wash. mach."
							else if "`part'" == "hh" & `counter_outer' == 9 local var_name = "share phone"
							else if "`part'" == "hh" & `counter_outer' == 10 local var_name = "share stove"
							else if "`part'" == "hh" & `counter_outer' == 11 local var_name = "share tv"
							else if "`part'" == "hh" & `counter_outer' == 12 local var_name = "share fridge/freezer"
							else if "`part'" == "hh" & `counter_outer' == 13 local var_name = "mean hh income"
							else if "`part'" == "hh" & `counter_outer' == 14 local var_name = "mean rent"
							else if "`part'" == "hh" & `counter_outer' == 15 local var_name = "mean mortgage"
							else if "`part'" == "percentiles" {
								local counter_outer_n = 1
								foreach formality in ", f" ", i" ", f&i" {
									foreach p of global percentiles_list {
										if `counter_outer' == `counter_outer_n' local var_name = "log(P`p')-log(P50)`formality'"
										local ++ counter_outer_n
									}
								}
							}
							else if "`part'" == "transitions" & `counter_outer' == 1 local var_name = "share in labor force"
							else if "`part'" == "transitions" & `counter_outer' == 2 local var_name = "share employed (1-u)"
							else if "`part'" == "transitions" & `counter_outer' == 3 local var_name = "share formal"
							else if "`part'" == "transitions" & `counter_outer' == 4 local var_name = "share UI transition"
							else if "`part'" == "transitions" & `counter_outer' == 5 local var_name = "share UF transition"
							else if "`part'" == "transitions" & `counter_outer' == 6 local var_name = "share IU transition"
							else if "`part'" == "transitions" & `counter_outer' == 7 local var_name = "share II transition"
							else if "`part'" == "transitions" & `counter_outer' == 8 local var_name = "share IF transition"
							else if "`part'" == "transitions" & `counter_outer' == 9 local var_name = "share FU transition"
							else if "`part'" == "transitions" & `counter_outer' == 10 local var_name = "share FI transition"
							else if "`part'" == "transitions" & `counter_outer' == 11 local var_name = "share FF transition"
							else if "`part'" == "transitions" & `counter_outer' == 12 local var_name = "share NF-F transition"
							else if "`part'" == "transitions" & `counter_outer' == 13 local var_name = "share F-NF transition"
							local insert_space_n = max(22 - strlen("`var_name'"),0)
							local insert_space = ""
							forval n = 1/`insert_space_n' {
								local insert_space = " `insert_space'"
							}
							local reg_result_`counter_inner' = "`pred_m_2_trunc'`significance_2' (`pred_se_2_trunc')"
							if mod(`counter_inner',5) == 0 disp as text "   `var_name':`insert_space' |`reg_result_1' |`reg_result_2' |`reg_result_3' |`reg_result_4' |`reg_result_5'"
							else if "`part'" == "percentiles" disp as text "   `var_name':`insert_space' |`reg_result_1'"
							local ++counter_inner
						}
					}
					local ++counter_outer
				}
				local counter_disp = 0
			}
		}
	}
	log close log_regressions_pnad_pme
}



********************************************************************************
* plots
********************************************************************************
if ${plots} == 1 {
	
// 	* MW bindingness trends:
// 	qui use "${DIR_TEMP}/PNAD/pnad_pooled.dta", clear
// 	tw (connected share_at_mw share_atbelow_mw share_around_mw year, lcolor(blue red green) mcolor(blue red green)), xlabel(1996(2)2015) ylabel(0(.05).35, gmin gmax) legend(cols(3)) name(shares_mw, replace)
// 	qui use "${DIR_TEMP}/PNAD/shares_mw_state.dta", clear
// 	tw (connected share_at_mw share_atbelow_mw share_around_mw year, lcolor(blue red green) mcolor(blue red green)), by(state, note("")) xlabel(1996(4)2015) legend(cols(3)) name(shares_mw_state, replace)
	
// 	* formality trends:
// 	qui use "${DIR_TEMP}/PNAD/pnad_pooled.dta", clear
// 	tw (connected share_formal year, lcolor(blue) mcolor(blue)), xlabel(1996(2)2015) ylabel(0.5(.1)1, gmin gmax) legend(cols(1)) name(shares_formal, replace)
// 	qui use "${DIR_TEMP}/PNAD/shares_formal_state.dta", clear
// 	tw (connected share_formal year, lcolor(blue) mcolor(blue)), by(state, note("")) xlabel(1996(4)2015) legend(cols(1)) name(shares_formal_state, replace)
}


*** closing housekeeping
postutil clear
