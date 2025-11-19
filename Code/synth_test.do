* Synthetic control trial - focusing on one specific event
* 9 novemember 2023 move of 11 IGV from LPO Linköping
clear all

cd "/Users/jacob/SU/PhD/Projects/police_reduction"

import excel "Data/Inom Regionen/Sammanställning_inom.xlsx", sheet(2023) firstrow clear

preserve 
import excel "Data/Inom Regionen/Sammanställning_inom.xlsx", sheet(2024) firstrow clear
save "Temp/2024_bb_temp.dta"
restore

append using "Temp/2024_bb_temp.dta"
erase "Temp/2024_bb_temp.dta"

format Beviljadstart Beviljatslut Beslutsdatum %td

keep if strpos(Från, "LPO Linköping")

**Date formating
rename Beviljadstart start
rename Beviljatslut end

gen foresight = start - Beslutsdatum

* Expand so that every event is located to its day.
gen start_d = dofd(start)
gen end_d   = dofd(end)
format start_d end_d %td
gen n_days = end_d - start_d + 1
expand n_days
bysort Anr (start_d): gen day_index = _n - 1
gen event_day = start_d + day_index
format event_day %td

* Some data handling
gen event_count = 1
gen year  = yofd(dofd(event_day))
gen month = month(dofd(event_day))
gen day = day(dofd(event_day))
drop start	end	start_d	end_d	n_days	day_index	event_day

gen send_region = "LPO Linköping"
gen send_LPO = substr(send_region, 5, 20)

keep day month year send_LPO event_count
save "Analysis/event_temp.dta", replace

*** Import crime data

import excel "Data/Utfallsdata/1548-25 anmälda brott 2023", firstrow clear
preserve
import excel "Data/Utfallsdata/1548-25 anmälda brott 2022", firstrow clear
save "Temp/2022_temp.dta", replace
import excel "Data/Utfallsdata/1548-25 anmälda brott - 2024", firstrow clear
save "Temp/2024_temp.dta", replace
restore
append using "Temp/2022_temp.dta"
append using "Temp/2024_temp.dta"
erase "Temp/2022_temp.dta" 
erase "Temp/2024_temp.dta"

* Date handling
gen month = month(Brottsdatum)
gen year = year(Brottsdatum)
gen day = day(Brottsdatum)
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
collapse (sum) Anmäldabrott, by(year month day send_LPO Brottskategorier)
merge m:1 year month day send_LPO using "Analysis/event_temp.dta"
replace event_count = 0 if event_count == .


gen date = mdy(month, day, year)   // daily date
gen week = week(date)


collapse (sum) Anmäldabrott (mean) event_count, by(year week send_LPO Brottskategorier)
encode send_LPO, gen(LPO_id)

save "Data/synthetic_data.dta", replace
 
* Synthetic study of traffic crime
use "Data/synthetic_data.dta", clear
preserve
collapse (sum) Anmäldabrott (mean) event_count, by(year week send_LPO)
encode send_LPO, gen(LPO_id)
drop if year < 2023
drop if year > 2023
drop if week < 34
gen date = yw(year, week)
tsset LPO_id date
rename send_LPO municipality
merge m:1 municipality using "swedish_municipalities.dta"
synth Anmäldabrott emp_rate avg_income pct_higher_ed unemp_rate pct_foreign population, trunit(4) trperiod(3321) figure gen_vars
restore
