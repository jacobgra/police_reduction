*** Study the effect on trafic controls
clear all

cd "/Users/jacob/SU/PhD/Projects/police_reduction"

import excel  "/Users/jacob/SU/PhD/Projects/police_reduction/Data/Utfallsdata/1548-25 trafikkontroll.xlsx", firstrow clear

* Merge to LPO and regions
merge m:1 Kommun using "Data/kommun_match.dta"
replace Lokalpolisområde = LPO if Lokalpolisområde =="Värde saknas"
drop LPO _merge
rename Lokalpolisområde LPO
merge m:1 LPO using "Data/reg_match.dta"
drop if _merge == 1

* Collapsing data on PO level, prio level
collapse (sum) AntalHR, by(Datum reg_id)
merge m:1 reg_id using "Data/reg_match_with_pop.dta"
drop _merge

* Dropping data before 2023 and after 2024 due to lacking data on transfers.
gen month = month(Datum)
gen year = year(Datum)
gen day = day(Datum)

* Merging with event data set
*Sending
preserve
merge m:1 year month day reg_id using "Analysis/outcomes_from.dta"
drop if year < 2023
drop if year > 2024
replace event_count = 0 if event_count == .
gen date = mdy(month, day, year)
format date %td
encode reg_id, gen(reg_num)

xtset reg_num date  
tsfill
replace Datum = date if AntalHR == .
replace AntalHR =0 if AntalHR == 0
drop if reg_id == ""
drop if reg_id == "Operativa enheten"


* Regressing the amount of övertid 
xtreg AntalHR event_count i.month i.year [fweight = pop], fe cluster(reg_num)
estimates store sending
esttab using "trafikkontroll_outcomes.tex",  star( * 0.10 ** 0.05 *** 0.010) ///
    se b(%9.3f) stats(N r2, fmt(%9.3f) labels("Observations" "R-squared")) ///
    label replace
restore
