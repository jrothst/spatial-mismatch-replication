clear

// Get a list of the top 200 CZs
// Grab a list of top 200 CZs
use ${processed_data}/1_czlist.dta
tempfile czranks
save `czranks'

use ${processed_data}/bwdecomp
merge m:1 cz using `czranks'
keep if paper_cz==1

// Define CZ groupings
gen czgroupA=1 if inlist(cz, 19700, 11600, 16300, 15200)
replace czgroupA=2 if inlist(cz, 19400, 20500, 11304, 20901)
replace czgroupA=3 if inlist(cz, 38300, 32000, 9100)
replace czgroupA=4 if inlist(cz, 19600, 18000, 11302)
replace czgroupA=5 if inlist(cz, 37800, 37500, 37400, 39400)
replace czgroupA=6 if inlist(cz, 7000, 38000, 35001, 33100)
replace czgroupA=7 if inlist(cz, 24300, 21501, 24701)
replace czgroupA=8 if czgroupA==.
label def czgpsA 1 "Rust belt" 2 "Acela corridor" 3 "LA-Atl-Hou" 4 "Newark-Buff-Balt" 5 "SF-SJ-Sac-Seattle" ///
                6 "Sunbelt" 7 "Chi-Minn-StL" 8 "Not top 25"
label values czgroupA czgpsA

gen czgroupB=1 if inlist(czgroupA, 1, 4, 7)
replace czgroupB=2 if inlist(czgroupA, 3, 6)
replace czgroupB=3 if inlist(czgroupA, 2, 5)
replace czgroupB=4 if czgroupA==8
label def czgpsB 1 "Older industrial CZs" 2 "New sunbelt CZs" 3 "Other top 25 CZs" 4 "Not top 25"
label values czgroupB czgpsB

gen czgroupC=czgroupB
replace czgroupC=3 if czgroupB==4
label def czgpsC 1 "Older industrial CZs" 2 "New sunbelt CZs" 3 "Other top 200 CZs" 
label values czgroupC czgpsC

tempfile gpsB gpsC
preserve
collapse (mean) y y_samecz y_akmsamp N* sd_y* wh_* bl_* Vpt* bwgap*, by(czgroupC)
save `gpsC'
restore, preserve
collapse (mean) y y_samecz y_akmsamp N* sd_y* wh_* bl_* Vpt* bwgap*, by(czgroupB)
save `gpsB'
restore
collapse (mean) y y_samecz y_akmsamp N* sd_y* wh_* bl_* Vpt* bwgap*, by(czgroupA)
append using `gpsB'
append using `gpsC'
save ${output}/AKMsummary.dta_allthree, replace

keep if czgroupC<.
qui d
local nobs=(r(k)-1)*r(N)
di "Decomposition of black-white gap: `nobs' statistics"
keep czgroupC N_akmsamp N_??_akmsamp y_akmsamp ??_y_akmsamp bwgap_*
drop bwgap_y bwgap_y_samecz
save ${output}/AKMsummary_todisclose, replace



