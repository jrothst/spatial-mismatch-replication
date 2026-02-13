/*
Basic decomposition of Black-White wage gap for all CZs
*/
clear
set more off
set linesize 155

//Set directories and file names
local akmdir "${output}/akmoutput/"
local sampdir "${processed_data}/grids/"
local sampfile "inddata_cz"


// Do decomposition both with and without imposing dual connected set restriction


cap program drop decomp_onecz
program define decomp_onecz
  syntax, cz(integer) basefile(string) akmfile(string)

  use pik qtime e naics2d work_cz samecz blacknh hispanic using `basefile'`cz', clear
  assert hispanic == 0
  gen y=ln(e)
  gen byte racegp=(blacknh==1)
  drop blacknh hispanic
  merge 1:1 pik qtime using `akmfile'`cz', assert(1 3)
  assert r<. if _merge==3
  gen byte akmsamp=(r<.)
  drop _merge

  //Construct variables
  gen y_samecz=y if samecz==1
  gen y_akmsamp=y if akmsamp==1
  bys naics2d: egen psi=mean(akm_firm) if akmsamp==1
  gen h=akm_firm-psi
  sort pik sein seinunit
  by pik sein seinunit: egen match=mean(r) if akmsamp==1
  gen r_match=r-match
  gen persfirm=akm_firm+akm_person
  preserve
  tempfile fullsampmean fullsampsd fullsamp sepmean sepsd sepall
  // Construct overall means
    collapse (mean) y y_samecz y_akmsamp psi akm_firm h akm_person xb r match r_match  ///
             (sum) N_akmsamp=akmsamp N_samecz=samecz (count) N=y
    gen cz=`cz'
    save `fullsampmean'
    restore, preserve
    collapse (sd) y y_samecz y_akmsamp psi akm_firm h akm_person xb r match r_match persfirm
    rename (y y_samecz y_akmsamp psi akm_firm h akm_person xb r match r_match persfirm) sd_=
    gen cz=`cz'
    save `fullsampsd'
    use `fullsampmean'
    merge 1:1 cz using `fullsampsd', assert(3) nogen
    save `fullsamp'
  // Now do by race
    restore, preserve
    collapse (mean) y y_samecz y_akmsamp psi akm_firm h akm_person xb r match r_match ///
             (sum) N_akmsamp=akmsamp N_samecz=samecz (count) N=y, by(racegp)
    gen cz=`cz'
    reshape wide y y_samecz y_akmsamp psi akm_firm h akm_person xb r match r_match ///
            N_akmsamp N_samecz N, i(cz) j(racegp)
    rename (*0) (wh_*)
    rename (*1) (bl_*)
    rename (wh_N*) (N_wh*)
    rename (bl_N*) (N_bl*)
    save `sepmean'
    restore, preserve
    collapse (sd) y y_samecz y_akmsamp psi akm_firm h akm_person xb r match r_match, by(racegp)
    gen cz=`cz'
    reshape wide y y_samecz y_akmsamp psi akm_firm h akm_person xb r match r_match ///
            , i(cz) j(racegp)
    rename (*0) (sd_wh_*)
    rename (*1) (sd_bl_*)
    save `sepsd'
    use `sepmean'
    merge 1:1 cz using `sepsd', assert(3) nogen
    save `sepall'
    use `fullsamp'
    merge 1:1 cz using `sepall', assert(3) nogen
    restore, not

  // Overall variance decomposition
    foreach v in psi akm_firm h akm_person xb r match r_match {
      gen Vpt_`v'=(sd_`v'/sd_y_akmsamp)^2
    }
    gen Vpt_2covpersfirm=(sd_persfirm/sd_y_akmsamp)^2-Vpt_akm_firm-Vpt_akm_person
    drop sd_persfirm
  // Gap decomposition
    foreach v in y y_samecz y_akmsamp psi akm_firm h akm_person xb r match r_match {
      gen bwgap_`v'=wh_`v'-bl_`v'
    }
end

use "`akmdir'/AKMstats"
keep if timestamp<.
gsort -timestamp
keep cz
gen cznum=_n
tempfile fullczlist
save `fullczlist', replace
su cz
local nczs=r(N)

forvalues i=1/`nczs' {
  use if cznum==`i' using `fullczlist'
  su cz, meanonly
  local cz=r(mean)
  di "Starting CZ number `i'/`nczs', `cz'"
  
  qui decomp_onecz, cz(`cz') basefile("`sampdir'/`sampfile'") akmfile("`akmdir'/AKMests_")
  if `i'>1 {
    append using "${processed_data}/akmdecomp.dta"
  }
  save "${processed_data}/akmdecomp.dta", replace
}

