*** Study the effect on responses by tier
clear all

cd "/Users/jacob/SU/PhD/Projects/police_reduction"

import excel  "/Users/jacob/SU/PhD/Projects/police_reduction/Data/Utfallsdata/1548-25 Händelserapporter per prio.xlsx", firstrow clear

* Merge to LPO and regions
merge m:1 Kommun using "Data/kommun_match_with_pop.dta"
replace Lokalpolisområde = LPO if Lokalpolisområde =="Värde saknas"
drop LPO _merge
rename Lokalpolisområde LPO
merge m:1 LPO using "Data/reg_match.dta"
drop if _merge == 1

* Collapsing data on PO level, prio level
collapse (sum) AntalHR, by(Datum reg_id PrioSlutlig)
merge m:1 reg_id using "Data/reg_match_with_pop.dta"
drop _merge
* Dropping data before 2023 and after 2024 due to lacking data on transfers.
gen month = month(Datum)
gen year = year(Datum)
gen day = day(Datum)
merge m:1 year month day reg_id using "Analysis/outcomes_from.dta"
drop if year < 2023 
drop if year == 2023 & month <= 12
drop if year > 2024

replace event_count = 0 if event_count == .

gen date = mdy(month, day, year)   // daily date
format date %td
encode reg_id, gen(reg_num)
destring PrioSlutlig, replace

drop if reg_id == "Operativa enheten"

foreach p in 1 2 3 5 6 7 8 9 {
	preserve
	keep if PrioSlutlig == `p'
	xtset reg_num date
    di "Running regression for priolevel = `p'"
    xtreg AntalHR event_count i.month i.year , fe cluster(reg_num) 
    estimates store prio`p'
	twowayfeweights AntalHR reg_num date event_count, type(feTR) summary_measures controls(month year)
	restore
}
preserve
	gen prio_group = .
	replace prio_group = 1
	replace prio_group = 2 if PrioSlutlig >=3
	keep if prio_group == 2
	collapse (mean) AntalHR event_count pop, by(month year day reg_num)
	gen date = mdy(month, day, year)   // daily date
	format date %td
	xtset reg_num date
    di "Running regression for priolevel = `p'"
    xtreg AntalHR event_count i.month i.year , fe cluster(reg_num)
    estimates store prio_above_two
	twowayfeweights AntalHR reg_num date event_count, type(feTR) summary_measures controls(month year)
restore

estimates table prio_above_two prio1 prio2 prio3 prio5 prio6 prio7 prio8 prio9, ///
    b(%9.3f) se stats(N r2)
	
esttab  prio1 prio2 prio_above_two ///
    using "hr_outcomes.tex",  star( * 0.10 ** 0.05 *** 0.010) ///
    se b(%9.3f) stats(N r2, fmt(%9.3f) labels("Observations" "R-squared")) ///
    label replace
