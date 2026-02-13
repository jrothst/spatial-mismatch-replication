use ${processed_data}/gridmult, clear

do sub_makeczgps
makeczgps

preserve

tempfile groupsB groupsC
collapse (mean) wh_fr_n-ble2_fr_e2_psi3 radius, by(czgroupC origdist)
save `groupsC'
restore, preserve
collapse (mean) wh_fr_n-ble2_fr_e2_psi3 radius, by(czgroupB origdist)
save `groupsB'
restore
collapse (mean) wh_fr_n-ble2_fr_e2_psi3 radius, by(czgroupA origdist)
append using `groupsB'
append using `groupsC'
save ${output}/gridmulttable.dta, replace

