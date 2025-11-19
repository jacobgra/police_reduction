*** Study the effect on redovis to åklagare
* Thoughts: perhaps control for type of crime?
clear all

cd "/Users/jacob/SU/PhD/Projects/police_reduction"

import excel  "/Users/jacob/SU/PhD/Projects/police_reduction/Data/Utfallsdata/1548-25 redovisade till åkl.xlsx", firstrow clear

* Merge to LPO and regions
gen LPO = substr(LPOSektion, 5, 20)

merge m:1 LPO using "Data/reg_match.dta"
drop if _merge == 1

rename Inskrivningsdatum start
format start %td
gen end = date(Redovisningsdatum, "DMY")
format end %td
gen duration = end - start + 1

* Collapsing data on PO level, prio level
collapse (sum) RedovtillÅkl (mean) duration, by(end reg_id Huvudbrottskategori)
merge m:1 reg_id using "Data/reg_match_with_pop.dta"
drop _merge
* Dropping data before 2023 and after 2024 due to lacking data on transfers.
rename end Datum
gen month = month(Datum)
gen year = year(Datum)
gen day = day(Datum)

collapse (sum) Redov (mean) pop, by(month year day Huvud reg_id)

* Merging with event data set
merge m:1 year month day reg_id using "Analysis/outcomes_from.dta"
drop if year < 2023
drop if year > 2024
replace event_count = 0 if event_count == .
gen date = mdy(month, day, year)
format date %td
encode reg_id, gen(reg_num)

* Some dates have no crimes reported to prosecutor but still have events. Must be set to 0.
replace RedovtillÅkl = 0 if RedovtillÅkl == .
replace event_count = 0 if event_count == .
rename Huvudbrottskategori Brottskategorier

*Trafikbrott
preserve
keep if Brottskategorier == "Trafikbrott"
xtset reg_num date

* To make panel balanced, we fill the empty wholes with zeroes (no cases brought to prosecutor, no events happening)
tsfill


xtreg RedovtillÅkl event_count i.month i.year [fweight = pop], fe cluster(reg_num)
estimates store trafik
twowayfeweights RedovtillÅkl reg_num date event_count, type(feTR) summary_measures controls(month year)
restore
* Våldsbrott
preserve
keep if Brottskategorier == "Våldsbrott"
xtset reg_num date
xtreg RedovtillÅkl event_count i.month i.year [fweight = pop], fe cluster(reg_num) 
estimates store våld
twowayfeweights RedovtillÅkl reg_num date event_count, type(feTR) summary_measures controls(month year)
restore
*Narkotikabrott
preserve
keep if Brottskategorier == "Narkotikabrott"
xtset reg_num date
xtreg RedovtillÅkl event_count i.month i.year [fweight = pop], fe cluster(reg_num) 
estimates store nark
twowayfeweights RedovtillÅkl reg_num date event_count, type(feTR) summary_measures controls(month year)
restore
* Skadegörelsebrott
preserve
keep if Brottskategorier == "Skadegörelsebrott"
xtset reg_num date
xtreg RedovtillÅkl event_count i.month i.year [fweight = pop], fe cluster(reg_num) 
estimates store skad
twowayfeweights RedovtillÅkl reg_num date event_count, type(feTR) summary_measures controls(month year)
restore
* Alla brott
preserve
collapse (sum) RedovtillÅkl (mean) pop, by(month day year reg_id)
merge m:1 year month day reg_id using "Analysis/outcomes_from.dta"
drop if year < 2023
drop if year > 2024
replace event_count = 0 if event_count == .
gen date = mdy(month, day, year)   // daily date
format date %td
encode reg_id, gen(reg_num)
xtset reg_num date
xtreg RedovtillÅkl event_count i.month i.year [fweight = pop], fe cluster(reg_num) 
estimates store all
twowayfeweights RedovtillÅkl reg_num date event_count, type(feTR) summary_measures controls(month year)
restore

estimates table trafik nark våld skad all, ///
    b(%9.3f) se stats(N r2)

esttab trafik nark våld skad all ///
    using "åkl_outcomes.tex",  star( * 0.10 ** 0.05 *** 0.010) ///
    se b(%9.3f) stats(N r2, fmt(%9.3f) labels("Observations" "R-squared")) ///
    label replace
