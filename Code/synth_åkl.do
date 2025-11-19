* Synthetic control trial - focusing on one specific event
* 9 novemember 2023 move of 11 IGV from LPO Linköping
clear all

*** Import HR data

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


rename LPO send_LPO

* Merge with event data
collapse (sum) RedovtillÅkl, by(end send_LPO)
gen month = month(end)
gen year = year(end)
gen day = day(end)
merge m:1 year month day send_LPO using "Analysis/event_temp.dta"
replace RedovtillÅkl = 0 if RedovtillÅkl == .



encode send_LPO, gen(LPO_id)


preserve
collapse (sum) RedovtillÅkl (mean) event_count, by(year month send_LPO)
encode send_LPO, gen(LPO_id)
drop if month >= 3 & year >=2024
gen date = ym(year, month)
quietly summarize date if send_LPO == "Linköping" & event_count > 0, meanonly
local tdate = r(min)
format date %tm
tsset LPO_id date
rename send_LPO municipality
merge m:1 municipality using "swedish_municipalities.dta"
synth RedovtillÅkl pct_higher_ed unemp_rate pct_foreign population, trunit(4) trperiod(766) figure gen_vars
restore
