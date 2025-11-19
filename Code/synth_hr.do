* Synthetic control trial - focusing on one specific event
* 9 novemember 2023 move of 11 IGV from LPO Linköping
clear all

*** Import HR data

import excel  "/Users/jacob/SU/PhD/Projects/police_reduction/Data/Utfallsdata/1548-25 Händelserapporter per prio.xlsx", firstrow clear

* Date handling
gen month = month(Datum)
gen year = year(Datum)
gen day = day(Datum)
* Fix without LPO
preserve
drop if Lokalpolisområde =="Värde saknas"
keep Lokalpolisområde Kommun
duplicates drop Kommun, force
rename Lokalpolisområde LPO
save "Data/kommun_match.dta", replace
restore
merge m:1 Kommun using "Data/kommun_match.dta"
replace Lokalpolisområde = LPO if Lokalpolisområde =="Värde saknas"
drop _merge
rename LPO send_LPO

* Merge with event data
collapse (sum) AntalHR, by(year month day send_LPO PrioSlutlig)
merge m:1 year month day send_LPO using "Analysis/event_temp.dta"
replace event_count = 0 if event_count == .



gen date = mdy(month, day, year)   // daily date
gen week = week(date)


collapse (sum) AntalHR (mean) event_count, by(year month send_LPO PrioSlutlig)
encode send_LPO, gen(LPO_id)

save "Data/synthetic_data_HR.dta", replace
 
* Synthetic study of traffic crime
use "Data/synthetic_data_HR.dta", clear
destring PrioSlutlig, replace
keep if PrioSlutlig == 5
preserve
collapse (sum) AntalHR (mean) event_count, by(year month send_LPO)
encode send_LPO, gen(LPO_id)
drop if month >= 3 & year >=2024
gen date = ym(year, month)
format date %tm
quietly summarize date if send_LPO == "Linköping" & event_count > 0, meanonly
local tdate = r(min)
tsset LPO_id date
rename send_LPO municipality
merge m:1 municipality using "swedish_municipalities.dta"
synth AntalHR emp_rate avg_income pct_higher_ed unemp_rate pct_foreign population, trunit(4) trperiod(`tdate') figure gen_vars
restore
