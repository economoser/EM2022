********************************************************************************
* DESCRIPTION: Function to define time stamp file name extension.
********************************************************************************


*** define extension
* create new dataset with one observation
clear
set obs 1

* create unique time stamp
local ext_exists = 1
while `ext_exists' {
	global ext = clock("${S_DATE} ${S_TIME}", "DMYhms")/10^3 // create string of digits representing the date and time (year/month/day/hour/minute/second), to be used as file extension
	cap confirm file "${DIR_TEMP}/RAIS/temp_ext_${ext}.dta"
	local ext_exists = !_rc
	sleep 1000
}
disp "--> time stamp = ${ext}"

* use time stamp as file name extension
save "${DIR_TEMP}/RAIS/temp_ext_${ext}.dta", emptyok replace
clear


********************************************************************************
* END OF FUNCTION FUN_EXTENSION.do
********************************************************************************
