
cap program drop makesamp
program define makesamp
  syntax , cz(integer) [replace]
  di "Starting to make the grid for CZ `cz'"
  timer clear 1
  timer on 1

  // Prepare data / sample
  use pik qtime e dob naics2d whitenh blacknh hispanic female hispanic sein seinunit ///
      work_cz live_cz samecz live_lat live_long work_lat work_long cty_fips ///
      using ${processed_data}/CZfiles/bwobs_cz`cz', clear
  assert work_cz==`cz'
  gen byte racegp=(blacknh==1)+2*(hispanic==1)
  assert racegp <= 1

  *Merge to AKM 
  merge 1:1 pik qtime using ${output}/akmoutput/AKMests_`cz', ///
        assert(1 3) nogen
  rename akm_firm akm_estab
  gen byte akmsamp=(akm_estab<.)
  // From here, limit to AKM sample
  keep if akmsamp==1

  merge m:1 pik using ${raw_data}/m5_piklist_educacs, keep(1 3) keepusing(pik educacs)


  // Get lat/long, and assign them to grid points
  foreach v of varlist live_lat live_long work_lat work_long {
    replace `v'=`v'/1e6
  }
  geodist live_lat live_long work_lat work_long, gen(commutedist) miles sphere
  su commutedist, d

  // Save the individual data
  save ${processed_data}/grids/inddata_cz`cz', `replace'

  timer off 1
  di "Finished CZ `cz'."
  timer list 
  global time`cz'=r(t1)
  global finishedlist $finishedlist `cz'
end

timer clear
timer on 2


// Grab 17 paper CZs
use ${processed_data}/1_czlist.dta
keep if paper_cz==1
// Drop alaska
drop if cz>34100 & cz<34200
local nczs=_N
sort totbw
forvalues i=1/`nczs' {
 local cznum`i'=cz[`i']
}
drop _all

forvalues i=1/`nczs' {
  // Select based on timestamp
  use ${output}/akmoutput/AKMstats
  su timestamp if cz==`cznum`i''
  local ts=r(mean)
  //if r(N)==0 | `ts'<tc(12 nov 2023 00:00:01) {
  //  di "Skipping CZ #`i'/`nczs', `cznum`i'': AKM estimates not ready"
  //}
  //else if `ts'<tc(15 oct 2023 17:38:00) {
  //  di "Skipping CZ #`i'/`nczs', `cznum`i'': Already run"
  //}
  else {
    di "Starting CZ #`i'/`nczs', `cznum`i''."
    di "AKM estimate vintage: " %tc `ts'
    drop _all
    makesamp, cz(`cznum`i'') replace 
  }
}



timer off 2
timer list 2
foreach cz of global finishedlist {
  di "CZ `cz' took ${time`cz'} seconds."
}










