
clear
use ${processed_data}/gridcorrs.dta

do sub_makeczgps
makeczgps


tempfile groupsB groupsC
preserve
collapse (mean) avg=rho n (sd) sd=rho, by(czgroupC var1 var2 radius)
save `groupsC'
restore, preserve
collapse (mean) avg=rho n (sd) sd=rho, by(czgroupB var1 var2 radius)
save `groupsB'
restore
collapse (mean) avg=rho n (sd) sd=rho, by(czgroupA var1 var2 radius)
append using `groupsB'
append using `groupsC'
save ${output}/gridcorrtable.dta, replace


