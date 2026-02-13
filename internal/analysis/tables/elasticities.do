
cap program drop pullonecz
program define pullonecz
  args cz
  use pik qtime e racegp commutedist akmsamp akm_estab akm_person if akmsamp==1 ///
      using ${processed_data}/grids/inddata_cz`cz', clear
  rename akm_estab alpha
  rename akm_person psi
  gen cz=`cz'
  gen lne=ln(e)
  gen lncommutedist=ln(commutedist)
  su commutedist if commutedist>0, meanonly
  replace lncommutedist=ln(r(min)) if commutedist==0
  assert lncommutedist<.
  keep lne alpha psi lncommutedist racegp pik cz
  compress racegp 
end

use ${processed_data}/1_czlist.dta, clear
keep if paper_cz==1
gsort totbw
do ../sub_makeczgps
makeczgps
//keep if inlist(cz, 24300, 21501, 32000, 9100, 11304, 20901)
local nczs=_N
forvalues i=1/`nczs' {
 local cznum`i'=cz[`i']
}
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
    forvalues r=0/1 {
      foreach v of varlist lne alpha psi {
        areg `v' lncommutedist if racegp==`r', absorb(cz)
        eststo `v'_r`r'_gp`c', title(`v'_r`r'_gp`c')
        local b_`v'_`r'_`c'=_b[lncommutedist]
      }
    }
    matrix elast_gp`c'=(`b_lne_0_`c'', `b_lne_1_`c'', ///
                        `b_alpha_0_`c'', `b_alpha_1_`c'', ///
                        `b_psi_0_`c'', `b_psi_1_`c'')
  }
  else di "No CZs to include from CZ group `c'
}


esttab using ${output}/elasticities.txt, cells(b se) stats(N r2, fmt(%12.0f %9.5f)) ///
       drop(_cons) mlabels(, titles) replace
matrix elasticities=(elast_gp1', elast_gp2')
matrix colnames elasticities=rustbelt sunbelt 
matrix rownames elasticities=lne_wh lne_bl alpha_wh alpha_bl psi_wh psi_bl

putexcel set ${output}/elasticities, replace
putexcel C3=matrix(elasticities), names

                  
