* Study outcomes on reported crime

cd "/Users/jacob/SU/PhD/Projects/police_reduction"

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
drop LPO _merge


*Match to regions
rename Lokalpolisområde LPO
merge m:1 LPO using "Data/reg_match.dta"

* Collapsing data on PO level
collapse (sum) Anmäldabrott, by(year month day reg_id Brottskategorier)
merge m:1 reg_id using "Data/reg_match_with_pop.dta"
drop _merge
* Dropping data before 2023 and after 2024 due to lacking data on transfers.
merge m:1 year month day reg_id using "Analysis/outcomes_from.dta"
drop if year < 2023
drop if year > 2024

replace event_count = 0 if event_count == .

gen date = mdy(month, day, year)   // daily date
format date %td
encode reg_id, gen(reg_num)

*Trafikbrott
preserve
keep if Brottskategorier == "Trafikbrott"
xtset reg_num date
tsfill
xtreg Anmäldabrott event_count i.month i.year [fweight = pop], fe cluster(reg_num)
estimates store trafik
twowayfeweights Anmäldabrott reg_num date event_count, type(feTR) summary_measures controls(month year)
restore
* Våldsbrott
preserve
keep if Brottskategorier == "Våldsbrott"
xtset reg_num date
xtreg Anmäldabrott event_count i.month i.year [fweight = pop], fe cluster(reg_num)
estimates store våld
twowayfeweights Anmäldabrott reg_num date event_count, type(feTR) summary_measures controls(month year)
restore
*Narkotikabrott
preserve
keep if Brottskategorier == "Narkotikabrott"
xtset reg_num date
xtreg Anmäldabrott event_count i.month i.year [fweight = pop], fe cluster(reg_num)
estimates store nark
twowayfeweights Anmäldabrott reg_num date event_count, type(feTR) summary_measures controls(month year)


restore
* Skadegörelsebrott
preserve
keep if Brottskategorier == "Skadegörelsebrott"
xtset reg_num date
xtreg Anmäldabrott event_count i.month i.year [fweight = pop], fe cluster(reg_num)
estimates store skad
twowayfeweights Anmäldabrott reg_num date event_count, type(feTR) summary_measures controls(month year)


restore
* Alla brott
preserve
collapse (sum) Anmäldabrott (mean) pop, by(month day year reg_id)
merge m:1 year month day reg_id using "Analysis/outcomes.dta"
drop if year < 2023
drop if year > 2024
replace event_count = 0 if event_count == .
gen date = mdy(month, day, year)  
format date %td
encode reg_id, gen(reg_num)
xtset reg_num date
xtreg Anmäldabrott event_count i.month i.year [fweight = pop], fe cluster(reg_num)
estimates store all
twowayfeweights Anmäldabrott reg_num date event_count, type(feTR) summary_measures controls(month year)
restore

estimates table trafik nark våld skad all, ///
    b(%9.3f) se stats(N r2)

esttab trafik nark våld skad all ///
    using "crime_outcomes.tex",  star( * 0.10 ** 0.05 *** 0.010) ///
    se b(%9.3f) stats(N r2, fmt(%9.3f) labels("Observations" "R-squared")) ///
    label replace