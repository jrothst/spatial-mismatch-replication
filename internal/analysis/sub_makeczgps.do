
cap program drop makeczgps
program define makeczgps

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

end

