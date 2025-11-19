* Create matching file

import excel "Data/Utfallsdata/1548-25 timmar övertid.xlsx", firstrow clear

keep if strpos(POEnhet, "PO")
keep if strpos(LPOSektion, "LPO")

duplicates drop LPOSektion, force

gen LPO = substr(LPOSektion, 5,100)

replace LPO = "Södra Vätterbygden" if LPO == "S Vätterbygden"

keep LPO POEnhet

gen reg_id = ""
replace reg_id = "D" if strpos(POEnhet, "Södermanland")
replace reg_id = "E" if strpos(POEnhet, "Östergötland")
replace reg_id = "F" if strpos(POEnhet, "Jönköping")

set obs `=_N+1'
replace POEnhet = "Operativa enheten" in L
replace LPO = "" if POEnhet == "Operativa enheten"
replace reg_id = "OE" if POEnhet == "Operativa enheten"


save "Data/reg_match.dta", replace
