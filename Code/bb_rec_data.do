*** Summarising the biträdesbegäran over time
clear all

cd "/Users/jacob/SU/PhD/Projects/police_reduction"

import excel "Data/Inom Regionen/Sammanställning_inom.xlsx", sheet(2023) firstrow clear

preserve 
import excel "Data/Inom Regionen/Sammanställning_inom.xlsx", sheet(2024) firstrow clear
save "Temp/2024_bb_temp.dta"
restore

append using "Temp/2024_bb_temp.dta"
erase "Temp/2024_bb_temp.dta"

format Beviljadstart Beviljatslut Beslutsdatum %td


keep if strpos(Till, "PO")|strpos(Till, "OE")

gen receive_region = ""
replace receive_region = "F" if strpos(Till, "Värn")
replace receive_region = "E" if strpos(Till, "Norr")
replace receive_region = "E" if strpos(Till, "Lin")
replace receive_region = "D" if strpos(Till, "Esk")
replace receive_region = "D" if strpos(Till, "PO S")
replace receive_region = "D" if strpos(Till, "Sö")
replace receive_region = "E" if strpos(Till, "Öster")
replace receive_region = "E" if strpos(Till, "PO Ö")
replace receive_region = "F" if strpos(Till, "Jön")
replace receive_region = "D" if strpos(Till, "Hög")
replace receive_region = "D/E" if strpos(Till, "Sö")&strpos(Till, "Öster")
replace receive_region = "D/F" if strpos(Till, "Sö")&strpos(Till, "Jön")
replace receive_region = "E/F" if strpos(Till, "Öster")&strpos(Till, "Jön")
replace receive_region = "Operativa enheten" if strpos(Till, "OE")


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
gen multi_region = strpos(receive_region, "/") > 0
replace event_count = event_count*0.5 if multi_region == 1
gen n_expand = 1
replace n_expand = 2 if multi_region == 1
expand n_expand, generate(copy_index)

gen region_new = receive_region

* For multi-region rows, assign first or second region
replace region_new = substr(receive_region, 1, 1) if multi_region & copy_index == 0
replace region_new = substr(receive_region, 3, 1) if multi_region & copy_index == 1
drop receive_region copy_index n_expand multi_region
rename region_new reg_id

* Add restrictions on type of police or amount of foresight?


destring Antal, replace
collapse (count) event_count (sum) Antal (mean) foresight_to = foresight, by(year month day reg_id)
save "Analysis/outcomes_to.dta", replace
