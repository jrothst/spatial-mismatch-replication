

cap program drop pullonecz
program define pullonecz
  args cz
  use pik qtime e whitenh racegp female commutedist educacs akm_person akm_estab akmsamp if akmsamp==1 ///
      using ${processed_data}/grids/inddata_cz`cz', clear
  gen cz=`cz'
  egen byte oneperpers=tag(pik)
  gen byte educ_coll=inlist(educacs, 2, 3, 4) if educacs<.
  gen lne=ln(e)
  drop akmsamp educacs qtime pik
  keep e lne akm_person akm_estab commutedist educ_coll racegp female oneperpers
  compress racegp female
  rename akm_person alpha
  rename akm_estab psi
end

use ${processed_data}/1_czlist.dta, clear
keep if paper_cz==1
gsort totbw
local nczs=_N
forvalues i=1/`nczs' {
 local cznum`i'=cz[`i']
}
do sub_makeczgps
makeczgps
tempfile czs
save `czs'


tempfile allczs
forvalues i=1/`nczs' {
  local cz=`cznum`i''
  di "Starting CZ #`i'/`nczs', `cz'"
  pullonecz `cz'
  tempfile cz`cz'
  save `cz`cz''
}

//Loop over cz groups
forvalues c=1/3 {
  di "Starting CZ group `c'"
  use `czs', clear
  count if czgroupC==`c'
  if r(N)>0 {
    local havegp`c'=1
    keep if czgroupC==`c'
    levelsof cz, local(czlist)
    local first=1
    foreach cz of local czlist {
      di "Adding cz `cz' to group `c'"
      if `first'==1 use `cz`cz'', clear
      else append using `cz`cz''
      local first=0
    }
    collapse (mean) e lne alpha psi commutedist educ_coll  ///
             (sd) sd_e=e sd_lne=lne sd_alpha=alpha sd_psi=psi sd_commutedist=commutedist ///
             (sum) npers=oneperpers (count) npq=e ///
             , by(racegp female)
    gen czgroup=`c'
    tempfile group`c'
    save `group`c''
  }
  else di "No CZs to include from CZ group `c'
}

drop _all
if "`havegp1'"=="1" append using `group1'
if "`havegp2'"=="1" append using `group2'
if "`havegp3'"=="1" append using `group3'
 sort czgroup racegp
 save ${output}/summstats.dta, replace
 export excel using ${output}/summstats.xls, replace firstrow(variables) keepcellfmt

