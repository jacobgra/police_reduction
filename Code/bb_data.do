*** Summarising the biträdesbegäran over time
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

keep if strpos(Från, "PO")|strpos(Från, "OE")

gen send_region = ""
replace send_region = "F" if strpos(Från, "Värn")
replace send_region = "D" if strpos(Från, "PO S")
replace send_region = "D" if strpos(Från, "Sö")
replace send_region = "E" if strpos(Från, "Öster")
replace send_region = "F" if strpos(Från, "Jön")
replace send_region = "D/E" if strpos(Från, "Sö")&strpos(Från, "Öster")
replace send_region = "D/F" if strpos(Från, "Sö")&strpos(Från, "Jön")
replace send_region = "E/F" if strpos(Från, "Öster")&strpos(Från, "Jön")
replace send_region = "Operativa enheten" if strpos(Från, "OE")

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
gen year  = yofd(dofd(event_day))
gen month = month(dofd(event_day))
gen day = day(dofd(event_day))
drop start	end	start_d	end_d	n_days	day_index	event_day

* Summarize events per region
gen event_count = 1
* Divide equally if extracted from more than one region
gen multi_region = strpos(send_region, "/") > 0
replace event_count = event_count*0.5 if multi_region == 1
gen n_expand = 1
replace n_expand = 2 if multi_region == 1
expand n_expand, generate(copy_index)
gen region_new = send_region

* For multi-region rows, assign first or second region
replace region_new = substr(send_region, 1, 1) if multi_region & copy_index == 0
replace region_new = substr(send_region, 3, 1) if multi_region & copy_index == 1
drop send_region copy_index n_expand multi_region
rename region_new reg_id

* Add restrictions on type of police or amount of foresight?
destring Antal, replace
collapse (count) event_count (sum) Antal (mean) foresight, by(year month day reg_id)
*drop if foresight > 2
save "Analysis/outcomes_from.dta", replace
