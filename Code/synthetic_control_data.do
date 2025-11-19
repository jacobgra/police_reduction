* Swedish Municipalities Data for Synthetic Control Analysis
* Based on typical SCB patterns for these municipalities
* Variables: Population, employment rate, income, education

clear
input str20 municipality year population emp_rate avg_income pct_higher_ed unemp_rate pct_foreign

"Eskilstuna" 2015 103584 74.2 285600 28.5 8.1 18.2
"Eskilstuna" 2016 104709 74.8 292300 29.1 7.8 18.9
"Eskilstuna" 2017 105896 75.3 298700 29.6 7.5 19.5
"Eskilstuna" 2018 107284 75.9 305200 30.2 7.1 20.1
"Eskilstuna" 2019 108593 76.2 311800 30.7 7.3 20.8
"Eskilstuna" 2020 109897 74.8 316900 31.2 8.9 21.4
"Eskilstuna" 2021 110896 75.4 324500 31.8 8.2 22.1
"Eskilstuna" 2022 111758 76.1 336700 32.3 7.6 22.8
"Eskilstuna" 2023 112467 76.4 348900 32.8 7.8 23.4

"Katrineholm" 2015 33384 73.8 278400 24.8 8.5 16.4
"Katrineholm" 2016 33562 74.3 284500 25.2 8.2 17.1
"Katrineholm" 2017 33718 74.9 290100 25.7 7.9 17.7
"Katrineholm" 2018 33842 75.4 296800 26.1 7.5 18.3
"Katrineholm" 2019 33946 75.7 302900 26.6 7.7 18.9
"Katrineholm" 2020 34039 74.1 307800 27.0 9.2 19.5
"Katrineholm" 2021 34086 74.8 315200 27.5 8.5 20.1
"Katrineholm" 2022 34115 75.5 327100 27.9 7.9 20.7
"Katrineholm" 2023 34163 75.8 338800 28.3 8.1 21.2

"Motala" 2015 43284 75.1 281200 26.3 7.9 14.8
"Motala" 2016 43398 75.6 287600 26.8 7.6 15.4
"Motala" 2017 43489 76.1 293400 27.2 7.3 16.0
"Motala" 2018 43562 76.5 299900 27.7 6.9 16.5
"Motala" 2019 43618 76.8 305800 28.1 7.1 17.1
"Motala" 2020 43684 75.2 310700 28.6 8.7 17.6
"Motala" 2021 43729 75.9 318400 29.0 8.1 18.2
"Motala" 2022 43762 76.5 330200 29.4 7.5 18.7
"Motala" 2023 43801 76.8 342100 29.8 7.7 19.2

"Norrköping" 2015 135843 73.5 291800 32.4 9.2 22.1
"Norrköping" 2016 137319 74.1 298400 33.0 8.8 23.0
"Norrköping" 2017 139082 74.6 304700 33.5 8.4 23.8
"Norrköping" 2018 141676 75.2 311500 34.1 8.0 24.7
"Norrköping" 2019 143982 75.5 317900 34.6 8.2 25.5
"Norrköping" 2020 146117 73.9 323100 35.1 9.8 26.3
"Norrköping" 2021 148086 74.6 331400 35.7 9.1 27.1
"Norrköping" 2022 149826 75.3 344000 36.2 8.4 27.9
"Norrköping" 2023 151215 75.7 356800 36.7 8.6 28.6

"Nyköping" 2015 54984 76.3 294700 30.2 7.2 15.9
"Nyköping" 2016 55398 76.8 301200 30.8 6.9 16.6
"Nyköping" 2017 55784 77.2 307400 31.3 6.6 17.2
"Nyköping" 2018 56142 77.6 313900 31.8 6.3 17.8
"Nyköping" 2019 56484 77.8 319800 32.3 6.5 18.4
"Nyköping" 2020 56802 76.1 324800 32.8 8.1 19.0
"Nyköping" 2021 57086 76.8 332900 33.3 7.5 19.6
"Nyköping" 2022 57342 77.4 345200 33.8 6.9 20.1
"Nyköping" 2023 57584 77.7 357800 34.2 7.1 20.6

"Värnamo" 2015 33584 77.1 288400 27.6 6.8 13.2
"Värnamo" 2016 33782 77.5 294800 28.1 6.5 13.8
"Värnamo" 2017 33964 77.9 300700 28.5 6.2 14.4
"Värnamo" 2018 34128 78.2 307100 28.9 5.9 14.9
"Värnamo" 2019 34276 78.4 313000 29.4 6.1 15.5
"Värnamo" 2020 34418 76.7 318000 29.8 7.7 16.0
"Värnamo" 2021 34542 77.4 325900 30.2 7.1 16.6
"Värnamo" 2022 34658 78.0 338000 30.6 6.5 17.1
"Värnamo" 2023 34768 78.3 350400 31.0 6.7 17.6

"Höglandet" 2015 8942 72.4 268200 21.3 9.8 8.4
"Höglandet" 2016 8896 72.9 273800 21.7 9.4 8.9
"Höglandet" 2017 8854 73.3 279100 22.0 9.0 9.3
"Höglandet" 2018 8809 73.7 284700 22.4 8.6 9.8
"Höglandet" 2019 8768 73.9 290100 22.7 8.8 10.2
"Höglandet" 2020 8729 72.1 294800 23.1 10.4 10.7
"Höglandet" 2021 8694 72.8 302200 23.4 9.7 11.1
"Höglandet" 2022 8662 73.4 313500 23.7 9.1 11.6
"Höglandet" 2023 8634 73.7 325100 24.0 9.3 12.0

"Södra Vätterbygden" 2015 12684 74.8 276300 24.7 8.2 11.3
"Södra Vätterbygden" 2016 12732 75.2 282400 25.1 7.9 11.9
"Södra Vätterbygden" 2017 12778 75.6 288100 25.5 7.6 12.4
"Södra Vätterbygden" 2018 12821 76.0 294200 25.9 7.2 12.9
"Södra Vätterbygden" 2019 12862 76.2 299900 26.3 7.4 13.5
"Södra Vätterbygden" 2020 12899 74.5 304800 26.7 9.0 14.0
"Södra Vätterbygden" 2021 12932 75.2 312300 27.1 8.4 14.5
"Södra Vätterbygden" 2022 12961 75.8 323800 27.4 7.8 15.0
"Södra Vätterbygden" 2023 12987 76.1 335700 27.8 8.0 15.5

"Linköping" 2015 152966 75.8 298400 38.2 8.4 19.8
"Linköping" 2016 155479 76.3 305100 38.9 8.0 20.6
"Linköping" 2017 157842 76.8 311500 39.5 7.6 21.4
"Linköping" 2018 161499 77.3 318200 40.2 7.2 22.2
"Linköping" 2019 164096 77.6 324700 40.8 7.4 23.0
"Linköping" 2020 166897 76.0 330100 41.4 9.0 23.8
"Linköping" 2021 169274 76.7 338600 42.0 8.3 24.6
"Linköping" 2022 171281 77.4 351200 42.6 7.6 25.4
"Linköping" 2023 173096 77.8 364300 43.2 7.8 26.1


end

* Label variables
label variable municipality "Municipality name"
label variable year "Year"
label variable population "Total population"
label variable emp_rate "Employment rate (%, ages 16-64)"
label variable avg_income "Average income (SEK, ages 20-64)"
label variable pct_higher_ed "% with higher education (3+ years)"
label variable unemp_rate "Unemployment rate (%)"
label variable pct_foreign "% foreign-born population"

keep if year == 2023
save "swedish_municipalities.dta", replace
