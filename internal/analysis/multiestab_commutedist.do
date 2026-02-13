// Program to make two kinds of figures:
// 1) Distribution of commute distance, by CZ
// 2) Mean of psi by commute distance (rescaled), by CZ

cap program drop onecz_meanpsi
program define onecz_meanpsi
  args cz
  use akmsamp racegp live_cz work_cz commutedist sein akm_estab if akmsamp==1 ///
      using ${processed_data}/grids/inddata_cz`cz', clear
  drop if live_cz~=work_cz
  rename work_cz cz
  merge m:1 sein using ${processed_data}/multiestab_makelist.dta, assert(2 3) keep(3) nogen
  merge m:1 cz sein using ${processed_data}/firmsize.dta, assert(2 3) keep(3) nogen
  tab multiunit
  su nunits, d
  gen byte firmsizegp=1 if firmsize_max<=10
  replace firmsizegp=2 if firmsize_max>10 & firmsize_max<276
  replace firmsizegp=3 if firmsize_max>276
  gen firmtype=firmsizegp*10 + (nunits>1)
  replace firmtype=10 if firmtype==11
  label define ftype 10 "<10" 20 "11-276, 1 estab" 21 "11-276, 2+ estab" 30 ">276, 1 estab" 31 ">276, 2+ estab"
  label values firmtype ftype
  //local dlist "0.5 1:10 20(10)100"
  local dlist "0.5 1:5 6 8 10 15 20 25 30 35 40 45 50"
  su commutedist, d
  local p75=r(p75)

  gen dist_rescale=commutedist*16/`p75'

  keep akm_estab dist_rescale racegp firmtype 
  gen evalpts=.
  local i=1
  foreach j of numlist `dlist' {
    replace evalpts=`j' in `i'
    local i=`i'+1
  }
  
  gen lndist=ln(dist_rescale)
  gen lnevalpts=ln(evalpts)
  keep akm_estab lndist racegp firmtype lnevalpts evalpts
  forvalues r=0/1 {
    foreach f in 10 20 21 30 31 {
      lpoly akm_estab lndist if racegp==`r' & firmtype==`f', at(lnevalpts) gen(r`r'_f`f'_psi) nograph degree(1)
    }
  }
  keep if evalpts<.
  keep evalpts r?_f??_psi
  rename evalpts commutedist
  gen cz=`cz'
end


// Grab a list of 17 paper CZs
use ${processed_data}/1_czlist.dta
 keep if paper_cz==1
gsort totbw
*keep if _n<10
local nczs=_N
forvalues i=1/`nczs' {
 local cznum`i'=cz[`i']
}

do sub_makeczgps
tempfile allczs
forvalues i=1/`nczs' {
  local cz=`cznum`i''
  di "Starting CZ #`i'/`nczs', `cz'"
  onecz_meanpsi `cz'
  if `i'!=1 append using `allczs'
  save `allczs', replace
  local first=0
}
makeczgps

save ${processed_data}/multiestab_commutedist_czlevel.dta, replace


tempfile groupB groupC
use if commutedist<=100 using multiestab_commutedist_czlevel, clear
collapse (mean) r?_f??_psi, by(czgroupC commutedist)
save `groupC'
use if commutedist<=100 using multiestab_commutedist_czlevel, clear
collapse (mean) r?_f??_psi, by(czgroupB commutedist)
save `groupB'
use if commutedist<=100 using multiestab_commutedist_czlevel, clear
collapse (mean) r?_f??_psi, by(czgroupA commutedist)
tempfile groupA
save `groupA'
append using `groupB'
append using `groupC'

save ${output}/multiestab_commutedist_groups, replace




