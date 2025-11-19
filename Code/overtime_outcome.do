*** Study the effect on overtime
clear all

cd "/Users/jacob/SU/PhD/Projects/police_reduction"

import excel "Data/Utfallsdata/1548-25 timmar övertid.xlsx", firstrow clear

gen month = month(Datum)
gen year = year(Datum)
gen day = day(Datum)

*Labeling
gen reg_id = ""
replace reg_id = "Operativa enheten" if strpos(POEnhet, "Operativ enhet")
replace reg_id = "D" if strpos(POEnhet, "Södermanland")
replace reg_id = "E" if strpos(POEnhet, "Östergötland")
replace reg_id = "F" if strpos(POEnhet, "Jönköping")
drop if reg_id ==""

* Collapsing data on PO level
collapse (sum) Timmarövertid, by(year month day reg_id)
merge m:1 reg_id using "Data/reg_match_with_pop.dta"
drop _merge
preserve
* Sending
* Dropping data before 2023 and after 2024 due to lacking data on transfers.
merge 1:1 year month day reg_id using "Analysis/outcomes_from.dta"
drop if year < 2023
drop if year > 2024


replace event_count = 0 if event_count == .

gen date = mdy(month, day, year)   // daily date
format date %td
encode reg_id, gen(reg_num)
xtset reg_num date  

* Regressing the amount of övertid 
xtreg Timmarövertid event_count i.month i.year [fweight = pop], fe cluster(reg_num)
estimates store receiving
*Store and table results
esttab using "overtime_outcomes.tex",  star( * 0.10 ** 0.05 *** 0.010) ///
    se b(%9.3f) stats(N r2, fmt(%9.3f) labels("Observations" "R-squared")) ///
    label replace
restore

preserve
