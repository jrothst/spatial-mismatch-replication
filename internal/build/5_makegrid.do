
cap program drop makegrid
program define makegrid
  syntax , cz(integer) [saveinddata replace]
  di "Starting to make the grid for CZ `cz'"
  timer clear 1
  timer on 1


  use work_lat work_long live_lat live_long ///
      akm_estab akm_person racegp blacknh whitenh educacs ///
      sein seinunit ///
      using ${processed_data}/grids/inddata_cz`cz', clear

  foreach dir in lat long {
    su work_`dir', meanonly
    local min_`dir'=r(min)
    local max_`dir'=r(max)
    su live_`dir', meanonly
    local min_`dir'=min(`min_`dir'', r(min))
    local max_`dir'=max(`max_`dir'', r(max))
  }
  di "CZ `cz': Latitude range is `min_lat' to `max_lat'"
  di "CZ `cz': Longitude range is `min_long' to `max_long'"

  *Compute latitude distance (north-south)
  geodist `min_lat' `min_long' `max_lat' `min_long', miles sphere
  local lat_dist=r(distance)
  *Compute longtiude distance (east-west)
  geodist `min_lat' `min_long' `min_lat' `max_long', miles sphere
  local long_dist=r(distance)

  *Compute grid size
  local step=0.5 // approximate distance between points (in miles)
  local lat_step=((`max_lat')-(`min_lat'))/((`lat_dist')/`step')
  local long_step=((`max_long')-(`min_long'))/((`long_dist')/`step')
  local onestep=`min_long'+`long_step'
  geodist `min_lat' `min_long' `min_lat' `onestep', miles sphere
  local onestep=`min_lat'+`lat_step'
  geodist `min_lat' `min_long' `onestep' `min_long', miles sphere

  *Round to grid
  gen live_grid_y=round(((live_lat )-`min_lat' )/`lat_step') 
  gen live_grid_x=round(((live_long)-`min_long')/`long_step')
  gen work_grid_y=round(((work_lat )-`min_lat' )/`lat_step')
  gen work_grid_x=round(((work_long)-`min_long')/`long_step')
  gen live_grid_lat =live_grid_y*`lat_step'  + `min_lat'
  gen live_grid_long=live_grid_x*`long_step' + `min_long'
  gen work_grid_lat =work_grid_y*`lat_step'  + `min_lat'
  gen work_grid_long=work_grid_x*`long_step' + `min_long'

  geodist live_grid_lat live_grid_long ///
          work_grid_lat work_grid_long ///
         , gen(commutedist_grid) sphere
  corr commutedist commutedist_grid
  local corr=r(rho)
  notes: CZ `cz' correlation(actual commute distance, grid commute distance)=`corr'
  tempfile locs
  save `locs'




  // Make summary measures for grid calculations
  rename akm_estab psi
  rename akm_person alpha

  gen wh_psi=psi if racegp==0
  gen bl_psi=psi if racegp==1
  gen wh_alpha=alpha if racegp==0
  gen bl_alpha=alpha if racegp==1


  _pctile psi, percentiles(33 67)
  local cut1=r(r1)
  local cut2=r(r2)
  gen psi_tercile=(psi<`cut1')+2*(psi>=`cut1' & psi<=`cut2')+3*(psi>`cut2') if psi<.
  _pctile alpha, percentiles(33 67)
  local cut1=r(r1)
  local cut2=r(r2)
  gen alpha_tercile=(alpha<`cut1')+2*(alpha>=`cut1' & alpha<=`cut2')+3*(alpha>`cut2') if psi<.
  sort sein seinunit 
  bys sein seinunit: egen firmfrbl=mean(blacknh)
  forvalues t=1/3 {
    gen n_a`t'=1 if alpha_tercile==`t'
    gen a`t'_psi=psi if alpha_tercile==`t' 
    gen n_psi`t'=1 if psi_tercile==`t' 
    gen wh_n_a`t'=1 if alpha_tercile==`t' & racegp==0
    gen bl_n_a`t'=1 if alpha_tercile==`t' & racegp==1
    gen wh_a`t'_psi = wh_psi if alpha_tercile==`t'
    gen bl_a`t'_psi = bl_psi if alpha_tercile==`t'
    gen wh_n_psi`t'=1 if racegp==0 & psi_tercile==`t' 
    gen bl_n_psi`t'=1 if racegp==1 & psi_tercile==`t' 
  }
  gen wh_firmfrbl=firmfrbl if racegp==0
  gen bl_firmfrbl=firmfrbl if racegp==1 
  gen educ=1+inlist(educacs, 2, 3, 4) if educacs<.
  forvalues i=1/2 {
    gen wh_n_e`i'=1 if racegp==0 & educ==`i'
    gen bl_n_e`i'=1 if racegp==1 & educ==`i'
    gen n_e`i'=1 if educ==`i'
    forvalues t=1/3 {
      gen n_e`i'_psi`t'=1 if educ==`i' & psi_tercile==`t'
    }
  }
  tempfile griddat
  save `griddat'

  *Make a dataset of number of black and white workers, mean firm size, and top-quartile firm size
  * at each location
  collapse (sum) whitenh blacknh n_a? bl_n_a? wh_n_a? ///
                 n_e? bl_n_e? wh_n_e?  ///
           (mean) alpha bl_alpha wh_alpha , ///
           by(live_grid_lat live_grid_long live_grid_x live_grid_y)
  rename * live_*
  rename live_live_grid_* grid_*
  label var live_whitenh "Number of white residents"
  label var live_blacknh "Number of black residents"
  label var live_n_a1 "Number of bottom-third alpha residents"
  label var live_n_a2 "Number of middle-third alpha residents"
  label var live_n_a3 "Number of top-third alpha residents"
  label var live_wh_n_a1 "Number of bottom-third alpha white residents"
  label var live_wh_n_a2 "Number of middle-third alpha white residents"
  label var live_wh_n_a3 "Number of top-third alpha white residents"
  label var live_bl_n_a1 "Number of bottom-third alpha black residents"
  label var live_bl_n_a2 "Number of middle-third alpha black residents"
  label var live_bl_n_a3 "Number of top-third alpha black residents"
  label var live_n_e1 "# residents w no coll"
  label var live_n_e2 "# residents w coll"
  label var live_wh_n_e1 "# white residents w no coll"
  label var live_wh_n_e2 "# white residents w coll"
  label var live_bl_n_e1 "# black residents w no coll"
  label var live_bl_n_e2 "# black residents w coll"
  label var live_alpha "Mean alpha among residents"
  label var live_wh_alpha "Mean alpha among white residents"
  label var live_bl_alpha "Mean alpha among black residents"
  tempfile livegrid
  save `livegrid'
  use `griddat'
  keep if work_grid_lat<. & work_grid_long<.
  collapse (mean) psi bl_psi wh_psi firmfrbl bl_firmfrbl wh_firmfrbl  ///
                  a?_psi bl_a?_psi wh_a?_psi ///
           (sum) n_psi? bl_n_psi? wh_n_psi? blacknh whitenh n_e?_psi?, ///
	   by(work_grid_lat work_grid_long work_grid_x work_grid_y)
  rename * work_*
  rename work_work_grid_* grid_*
  label var work_psi "Mean firm effect of workers"
  label var work_wh_psi "Mean firm effect of white workers"
  label var work_bl_psi "Mean firm effect of black workers"
  label var work_firmfrbl "Mean firm fraction black of workers"
  label var work_wh_firmfrbl "Mean firm fraction black of white workers"
  label var work_bl_firmfrbl "Mean firm fraction black of black workers"
  label var work_a1_psi "Mean psi of firms with bottom-third alpha workers"
  label var work_a2_psi "Mean psi of firms with middle-third alpha workers"
  label var work_a3_psi "Mean psi of firms with top-third alpha workers"
  label var work_wh_a1_psi "Mean psi of firms with bottom-third alpha white workers"
  label var work_wh_a2_psi "Mean psi of firms with middle-third alpha white workers"
  label var work_wh_a3_psi "Mean psi of firms with top-third alpha white workers"
  label var work_bl_a1_psi "Mean psi of firms with bottom-third alpha black workers"
  label var work_bl_a2_psi "Mean psi of firms with middle-third alpha black workers"
  label var work_bl_a3_psi "Mean psi of firms with top-third alpha black workers"
  label var work_n_psi1 "Number of jobs at bottom-third psi firms"
  label var work_n_psi2 "Number of jobs at middle-third psi firms"
  label var work_n_psi3 "Number of jobs at top-third psi firms"
  label var work_n_e1_psi1 "# of non-coll jobs at bottom-third psi firms"
  label var work_n_e1_psi2 "# of non-coll jobs at middle-third psi firms"
  label var work_n_e1_psi3 "# of non-coll jobs at top-third psi firms"
  label var work_n_e2_psi1 "# of coll jobs at bottom-third psi firms"
  label var work_n_e2_psi2 "# of coll jobs at middle-third psi firms"
  label var work_n_e2_psi3 "# of coll jobs at top-third psi firms"
  label var work_wh_n_psi1 "Number of white jobs at bottom-third psi firms"
  label var work_wh_n_psi2 "Number of white jobs at middle-third psi firms"
  label var work_wh_n_psi3 "Number of white jobs at top-third psi firms"
  label var work_bl_n_psi1 "Number of black jobs at bottom-third psi firms"
  label var work_bl_n_psi2 "Number of black jobs at middle-third psi firms"
  label var work_bl_n_psi3 "Number of black jobs at top-third psi firms"
  label var work_whitenh "Number of white-held jobs"
  label var work_blacknh "Number of black-held jobs"

  tempfile workgrid
  save `workgrid'
  merge 1:1 grid_lat grid_long grid_x grid_y using `livegrid', nogen
  drop if grid_x==. | grid_y==.

  egen gridpt=group(grid_x grid_y)
  save ${processed_data}/grid_cz`cz', `replace'
  timer off 1
  di "Finished CZ `cz'."
  timer list 
  global time`cz'=r(t1)
  global finishedlist $finishedlist `cz'
end

timer clear
timer on 2


// Grab a list of 17 paper CZs
use ${processed_data}/1_czlist.dta
 keep if paper_cz==1
sort totbw
local nczs=_N
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
    makegrid, cz(`cznum`i'') replace saveinddata
  }
}


timer off 2
timer list 2
foreach cz of global finishedlist {
  di "CZ `cz' took ${time`cz'} seconds."
}










