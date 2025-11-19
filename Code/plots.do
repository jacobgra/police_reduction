* Plot events over time
clear all
cd "/Users/jacob/SU/PhD/Projects/police_reduction"

*****************************************************
*********TRANSFER PLOTS********************
*****************************************************
use "Analysis/outcomes_from.dta", clear
rename event_count from
rename Antal num_sent

merge 1:1 reg_id year month day using "Analysis/outcomes_to.dta"
rename event_count to
rename Antal num_rec
drop _merge

*keep if foresight < 2
gen date = mdy(month, day, year) 
format date %td 

gen net_transfers = from - to
gen net_transfer = num_sent - num_rec

twoway (scatter net_transfer date if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (scatter net_transfer date if reg_id=="E", lcolor(red) lpattern(dash) lwidth(medium)) ///
	   (scatter net_transfer date if reg_id=="F", lcolor(green) lpattern(dash) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date") ytitle("Net transfer from region") ///
       title("Transferred police (all types) over time for the regions")
graph export "Analysis/Plots/net_no_transferred_police.png", replace
	   

twoway (scatter net_transfers date if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (scatter net_transfers date if reg_id=="E", lcolor(red) lpattern(dash) lwidth(medium)) ///
	   (scatter net_transfers date if reg_id=="F", lcolor(green) lpattern(dash) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date") ytitle("Net no. transfer from region") ///
       title("Transfers over time for the regions")
graph export "Analysis/Plots/net_no_transfers.png", replace

*****************************************************
*********CRIME PLOTS********************
*****************************************************
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

*** Total crime over time
preserve
rename Brottsdatum date
gen year = year(date)
gen month = month(date)
collapse (sum) Anmäldabrott, by(month year reg_id)

gen date = ym(year,month) 

format date %tm
sort reg_id date
twoway (line Anmäldabrott date if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line Anmäldabrott date if reg_id=="E", lcolor(red) lpattern(solid) lwidth(medium)) ///
	   (line Anmäldabrott date if reg_id=="F", lcolor(green) lpattern(solid) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date (month)") ytitle("Number of reported crimes") ///
       title("Crimes by region")
graph export "Analysis/Plots/antal_brott_2023-2025.png", replace

restore
* Våldsbrott

preserve
rename Brottsdatum date
gen year = year(date)
gen month = month(date)
keep if Brottskategorier == "Våldsbrott"
collapse (sum) Anmäldabrott, by(month year reg_id)

gen date = ym(year,month) 

format date %tm
sort reg_id date
twoway (line Anmäldabrott date if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line Anmäldabrott date if reg_id=="E", lcolor(red) lpattern(solid) lwidth(medium)) ///
	   (line Anmäldabrott date if reg_id=="F", lcolor(green) lpattern(solid) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date (month)") ytitle("Number of reported crimes") ///
       title("Crimes by region, violent crime")
graph export "Analysis/Plots/antal_våldsbrott_2023-2025.png", replace

restore

* Trafikbrott

preserve
rename Brottsdatum date
gen year = year(date)
gen month = month(date)
keep if Brottskategorier == "Trafikbrott"
collapse (sum) Anmäldabrott, by(month year reg_id)

gen date = ym(year,month) 

format date %tm
sort reg_id date
twoway (line Anmäldabrott date if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line Anmäldabrott date if reg_id=="E", lcolor(red) lpattern(solid) lwidth(medium)) ///
	   (line Anmäldabrott date if reg_id=="F", lcolor(green) lpattern(solid) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date (month)") ytitle("Number of reported crimes") ///
       title("Crimes by region, traffic crime")
graph export "Analysis/Plots/antal_trafikbrott_2023-2025.png", replace

restore

*****************************************************
*********CASES TO PROSECUTOR PLOTS*******************
*****************************************************

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
rename end date
sort reg_id date
replace date = mofd(date)
format date %tm
* All crimes
preserve
collapse (sum) RedovtillÅkl, by(date reg_id)
sort reg_id date
twoway (line RedovtillÅkl date if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line RedovtillÅkl date if reg_id=="E", lcolor(red) lpattern(solid) lwidth(medium)) ///
	   (line RedovtillÅkl date if reg_id=="F", lcolor(green) lpattern(solid) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date (month)") ytitle("Number of cases") ///
       title("Number of cases brought to a prosecutor")
graph export "Analysis/Plots/ärende_till_åkl_2023-2025.png", replace
restore

* Våldsbrott
preserve
keep if Huvudbrottskategori == "Våldsbrott"
collapse (sum) RedovtillÅkl, by(date reg_id)
sort reg_id date
twoway (line RedovtillÅkl date if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line RedovtillÅkl date if reg_id=="E", lcolor(red) lpattern(solid) lwidth(medium)) ///
	   (line RedovtillÅkl date if reg_id=="F", lcolor(green) lpattern(solid) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date (month)") ytitle("Number of cases") ///
       title("Number of cases brought to a prosecutor")
graph export "Analysis/Plots/Våldsbrott_till_åkl_2023-2025.png", replace
restore

* Trafikbrott
preserve
keep if Huvudbrottskategori == "Trafikbrott"
collapse (sum) RedovtillÅkl, by(date reg_id)
sort reg_id date
twoway (line RedovtillÅkl date if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line RedovtillÅkl date if reg_id=="E", lcolor(red) lpattern(solid) lwidth(medium)) ///
	   (line RedovtillÅkl date if reg_id=="F", lcolor(green) lpattern(solid) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date (month)") ytitle("Number of cases") ///
       title("Number of cases brought to a prosecutor")
graph export "Analysis/Plots/Trafikbrott_till_åkl_2023-2025.png", replace
restore

*****************************************************
*********TRAFFIC CRIME PLOTS********************
*****************************************************
import excel  "/Users/jacob/SU/PhD/Projects/police_reduction/Data/Utfallsdata/1548-25 trafikkontroll.xlsx", firstrow clear

* Merge to LPO and regions
merge m:1 Kommun using "Data/kommun_match.dta"
replace Lokalpolisområde = LPO if Lokalpolisområde =="Värde saknas"
drop LPO _merge
rename Lokalpolisområde LPO
merge m:1 LPO using "Data/reg_match.dta"
drop if _merge == 1

gen date = mofd(Datum)
format date %tm

preserve
collapse (sum) AntalHR, by(date reg_id)
sort reg_id date
twoway (line AntalHR date if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line AntalHR date if reg_id=="E", lcolor(red) lpattern(solid) lwidth(medium)) ///
	   (line AntalHR date if reg_id=="F", lcolor(green) lpattern(solid) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date (month)") ytitle("Number of cases") ///
       title("Number of traffic controls")
graph export "Analysis/Plots/trafikkontroller_2023-2025.png", replace
restore


*****************************************************
*********NUMBER OF RESPONSES BY PRIO****************
*****************************************************

import excel  "/Users/jacob/SU/PhD/Projects/police_reduction/Data/Utfallsdata/1548-25 Händelserapporter per prio.xlsx", firstrow clear

* Merge to LPO and regions
merge m:1 Kommun using "Data/kommun_match.dta"
replace Lokalpolisområde = LPO if Lokalpolisområde =="Värde saknas"
drop LPO _merge
rename Lokalpolisområde LPO
merge m:1 LPO using "Data/reg_match.dta"
drop if _merge == 1

gen date = mofd(Datum)
format date %tm
* Collapsing data on PO level, prio level
destring PrioSlutlig, replace
replace PrioSlutlig = 3 if PrioSlutlig>=3
collapse (sum) AntalHR, by(date reg_id PrioSlutlig)

* Cases by prio in Östergötland

preserve
keep if reg_id == "E"
sort date

twoway (line AntalHR date if PrioSlutlig==1, lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line AntalHR date if PrioSlutlig==2, lcolor(red) lpattern(solid) lwidth(medium)) ///
	   (line AntalHR date if PrioSlutlig==3, lcolor(green) lpattern(solid) lwidth(medium)) ///
          (line AntalHR date if PrioSlutlig==5, lcolor(blue) lpattern(dash) lwidth(medium)) ///
          (line AntalHR date if PrioSlutlig==6, lcolor(red) lpattern(dash) lwidth(medium)) ///
          (line AntalHR date if PrioSlutlig==7, lcolor(green) lpattern(dash) lwidth(medium)) ///
          (line AntalHR date if PrioSlutlig==8, lcolor(blue) lpattern(dot) lwidth(medium)) ///
          (line AntalHR date if PrioSlutlig==9, lcolor(red) lpattern(dot) lwidth(medium)), ///
       legend(order(1 "1" 2 "2" 3 "3" 4 "5" 5 "6" 6 "7" 7 "8" 8 "9") title("Prio level")) ///
       xtitle("Date (month)") ytitle("Resonses to prio") ///
       title("Number of responses to prio level")
graph export "Analysis/Plots/hr_prio_2023-2025.png", replace
restore

preserve
keep if reg_id == "E"
sort date

twoway (line AntalHR date if PrioSlutlig==1, lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line AntalHR date if PrioSlutlig==2, lcolor(red) lpattern(solid) lwidth(medium)) ///
	   (line AntalHR date if PrioSlutlig==3, lcolor(green) lpattern(solid) lwidth(medium)), ///
       legend(order(1 "1" 2 "2" 3 ">=3") title("Prio level")) ///
       xtitle("Date (month)") ytitle("Resonses to prio") ///
       title("Number of responses to prio level")
graph export "Analysis/Plots/hr_prio_2023-2025.png", replace
restore




*****************************************************
*********ÖVERTID  					 ****************
*****************************************************

import excel  "/Users/jacob/SU/PhD/Projects/police_reduction/Data/Utfallsdata/1548-25 timmar övertid.xlsx", firstrow clear

* Merge to LPO and regions
gen LPO = substr(LPOSektion, 5, 20)

merge m:1 LPO using "Data/reg_match.dta"
drop if _merge == 1

* Övertid per region
preserve
gen month = mofd(Datum)
gen year = yofd(Datum)
collapse (sum) Timmarövertid, by(month year reg_id)
format month %tm


twoway (line Timmarövertid month if reg_id=="D", lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line Timmarövertid month if reg_id=="E", lcolor(red) lpattern(solid) lwidth(medium)) ///
       (line Timmarövertid month if reg_id=="F", lcolor(green) lpattern(solid) lwidth(medium)), ///
       legend(order(1 "Södermanland" 2 "Östergötland" 3 "Jönköping")) ///
       xtitle("Date (month)") ytitle("Hours") ///
       title("Hours overtime in the regions")
graph export "Analysis/Plots/övertid_2023-2025.png", replace
restore
