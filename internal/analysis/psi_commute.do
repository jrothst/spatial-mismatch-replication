// Program to make mean of psi by commute distance (rescaled), by CZ

cap program drop onecz_meanpsi
program define onecz_meanpsi
  args cz
  use commutedist blacknh whitenh hispanic female akm_estab akmsamp if akmsamp==1 ///
      using ${processed_data}/grids/inddata_cz`cz', clear
  assert hispanic == 0
  local dlist "0.5 1:5 6 8 10 15 20 25 30 35 40 45 50"
  su commutedist, d
  local p75=r(p75)

  gen dist_rescale=commutedist*16/`p75'

  gen evalpts=.
  local i=1
  foreach j of numlist `dlist' {
    replace evalpts=`j' in `i'
    local i=`i'+1
  }
  
  gen lndist=ln(dist_rescale)
  gen lnevalpts=ln(evalpts)
  lpoly akm_estab lndist if blacknh==1, at(lnevalpts) gen(bl_psi) nograph degree(1)
  lpoly akm_estab lndist if whitenh==1, at(lnevalpts) gen(wh_psi) nograph degree(1)
  lpoly akm_estab lndist if blacknh==1 & female==1, at(lnevalpts) gen(bl_female_psi) nograph degree(1)
  lpoly akm_estab lndist if whitenh==1 & female==1, at(lnevalpts) gen(wh_female_psi) nograph degree(1)
  lpoly akm_estab lndist if blacknh==1 & female==0, at(lnevalpts) gen(bl_male_psi) nograph degree(1)
  lpoly akm_estab lndist if whitenh==1 & female==0, at(lnevalpts) gen(wh_male_psi) nograph degree(1)

  
  keep if evalpts<.
  keep evalpts ??_psi ??_male_psi ??_female_psi
  rename evalpts commutedist
  gen cz=`cz'
end


*local czlist          "19700 11600 16300 15200 12701 19400 20500 11304 20901 38300 32000"
*local czlist "`czlist' 9100 19600 18000 11302 37800 37400 37500 39400  7000 38000 35001"
*local czlist "`czlist' 33100 6700 24300 21501 24701 24100 28900 29502"
*local czlist "19700 11600"

// Grab a list of 17 paper CZs
use ${processed_data}/1_czlist.dta
 keep if paper_cz==1
gsort totbw
local nczs=_N
forvalues i=1/`nczs' {
 local cznum`i'=cz[`i']
}

tempfile allczs
forvalues i=1/`nczs' {
  local cz=`cznum`i''
  di "Starting CZ #`i'/`nczs', `cz'"
  onecz_meanpsi `cz'
  if `i'!=1 append using `allczs'
  save `allczs', replace
  local first=0
}

do sub_makeczgps
makeczgps
save ${processed_data}/psi_commute_czlevel, replace


tempfile groupB groupC
use if commutedist<=100 using psi_commute_czlevel, clear
collapse (mean) bl_psi wh_psi ??_male_psi ??_female_psi, by(czgroupC commutedist)
save `groupC'
use if commutedist<=100 using psi_commute_czlevel, clear
collapse (mean) bl_psi wh_psi ??_male_psi ??_female_psi, by(czgroupB commutedist)
save `groupB'
use if commutedist<=100 using psi_commute_czlevel, clear
collapse (mean) bl_psi wh_psi ??_male_psi ??_female_psi, by(czgroupA commutedist)
tempfile groupA
save `groupA'
append using `groupB'
append using `groupC'

save ${output}/psi_commute_groups, replace


