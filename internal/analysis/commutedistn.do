// Compute the distribution of commute distance by alpha, race, and CZ group
// Grab a list of 17 paper CZs
use ${processed_data}/1_czlist.dta, clear
keep if paper_cz==1
gsort totbw
local nczs=_N
forvalues i=1/`nczs' {
 local cznum`i'=cz[`i']
}

cap program drop distbyalpha
program define distbyalpha
  syntax, cz(real) [outinddat(string)]
  use akm_person pik cty_fips racegp work_cz qtime commutedist using ${processed_data}/grids/inddata_cz`cz', clear
  rename akm_person alpha
  su alpha
  gen z_alpha=(alpha-r(mean))/r(sd)
  xtile gp_z_alpha=z_alpha, nquantiles(10)
   // Define CZ groupings
   rename work_cz cz
   
  // Make output data for computing summary statistics
   if "`outinddat'"~="" {
     keep pik cty_fips racegp gp_z_alpha cz qtime commutedist 
     save `outinddat', replace
     di "Got to here - file `outinddat' saved"
   }
  // New code to compute percentiles of 11 observations
   keep racegp gp_z_alpha commutedist
   sort racegp gp_z_alpha commutedist
   by racegp gp_z_alpha: gen rank=_n
   by racegp gp_z_alpha: gen nobs=_N
   gen ptile=.
   foreach p in 25 50 75 {
     replace ptile=`p' if abs(rank-round(nobs*`p'/100))<6
   }
   keep if ptile<.
   collapse (mean) commutedist (count) nobs=commutedist, by(racegp gp_z_alpha ptile)
   assert nobs>=11
   drop nobs
   reshape wide commutedist, i(racegp gp_z_alpha) j(ptile)
   rename commutedist?? p??
   gen cz=`cz'
end

do sub_makeczgps

tempfile allczs
forvalues i=1/`nczs' {
  local cz=`cznum`i''
  di "Starting CZ #`i'/`nczs', `cz'"
  tempfile inddat`i'
  distbyalpha, cz(`cz') outinddat(`inddat`i'')
  if `i'!=1 append using `allczs'
  save `allczs', replace
}
makeczgps
save ${processed_data}/commutedistn_czlevel.dta, replace

tempfile groupB groupC
use commutedistn_czlevel, clear
collapse (mean) p25 p50 p75, by(czgroupC gp_z_alpha racegp)
save `groupC'
use commutedistn_czlevel, clear
collapse (mean) p25 p50 p75, by(czgroupB gp_z_alpha racegp)
save `groupB'
use commutedistn_czlevel, clear
collapse (mean) p25 p50 p75, by(czgroupA gp_z_alpha racegp)
append using `groupB'
append using `groupC'
save ${output}/commutedistn_groups, replace

//Make disclosure table
  forvalues i=1/`nczs' {
    di "Loading cz `i', `cznum`i''
    use `inddat`i''
    keep cz pik qtime cty_fips racegp gp_z_alpha
    gen byte stfips=floor(cty_fips/1000)
    gen Nqs=1
    collapse (sum) Nqs, by(pik cz stfips racegp gp_z_alpha)
    save `inddat`i'', replace
  } 
  use `inddat1', clear
  forvalues i=2/`nczs' {
    append using `inddat`i''
  }
  makeczgps
  keep czgroupC cz pik stfips racegp gp_z_alpha Nqs
  sort czgroupC racegp gp_z_alpha pik stfips  
  egen oneperpikgp=tag(czgroupC racegp gp_z_alpha pik)
  egen oneperstgp=tag(czgroupC racegp gp_z_alpha stfips)
  egen oneperczgp=tag(czgroupC racegp gp_z_alpha cz)
  gen oneperobs=1
  collapse (sum) oneperobs (rawsum) oneperpikgp oneperstgp oneperczgp [fw=Nqs], by(czgroupC racegp gp_z_alpha)
  rename oneperobs N_pq
  rename oneperpikgp N_pik
  rename oneperstgp N_state
  rename oneperczgp N_cz
  format N_* %12.0f
  list czgroupC racegp gp_z_alpha N_pq N_pik N_state N_cz
  save ${output}/commutedistn_counts, replace


