* Program to examine the distribution of commute distance by CZ group, race, and gender

use ${processed_data}/1_czlist.dta, clear
keep if paper_cz==1
gsort totbw
local nczs=_N
forvalues i=1/`nczs' {
 local cznum`i'=cz[`i']
}
do ../sub_makeczgps
makeczgps
tempfile czs
save `czs'

tempfile allczs
forvalues i=1/`nczs' {
  local cz=`cznum`i''
  di "Starting CZ #`i'/`nczs', `cz'"
  use pik qtime commutedist racegp female akmsamp if akmsamp==1 ///
      using ${processed_data}/grids/inddata_cz`cz', clear
  drop akmsamp
  _pctile commutedist, p(75)
  local p75=r(r1)
  gen dist_rescale=commutedist*16/`p75'
  drop commutedist 
  compress racegp female
  tempfile cz`cz'
  save `cz`cz''
}
cap program drop kds
program define kds
 tempfile fulldat
 save `fulldat'
 foreach b in 0 1 {
     use if racegp==`b' using `fulldat', clear
     gen lndist=ln(dist_rescale)
     gen dist0=(dist_rescale==0)
     gen distpt=0.1*_n if _n<=100
     replace distpt=_n-90 if _n>100 & _n<=190
     gen ldistpt=ln(distpt)
     if `b'==0 {
     	kdensity lndist , at(ldistpt) gen(dens_r`b') nograph
        return list
	local bw=r(bwidth)
     }
     else {
     	kdensity lndist , at(ldistpt) gen(dens_r`b') nograph bwidth(`bw')
     }
     su dist0 , meanonly
     gen frac0_r`b'=r(mean) if ldistpt<.
     keep if distpt<.
     keep distpt dens_r? frac0_r?
     tempfile densests_`b'
     save `densests_`b''
   }
 use `densests_0'
 merge 1:1 distpt using `densests_1', assert(3) nogen
end

//Loop over cz groups
forvalues c=1/2 {
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
    di "Running density models for group `c'"
    kds
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
 sort czgroup distpt
 label var dens_r0 "White"
 label var dens_r1 "Black"
 label def czgpsC 1 "Older industrial CZs" 2 "New sunbelt CZs" 3 "Other top 200 CZs" 
 rename czgroup czgroupC
 label values czgroupC czgpsC

 save ${output}/commutedensity_origsamp.dta, replace
 export excel using ${output}/commutedensity_origsamp.xls, replace firstrow(variables) keepcellfmt



