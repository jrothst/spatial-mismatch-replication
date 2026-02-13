*Jesse note: Adapted from m12_runakm.do

/*----------------------------------------------------------------------------*\

Industry Project, black-white differential, Second Pass
M12: AKM, 
Loops over CZs, 17 CZs in paper

Note: input is all workers, but in pooled model we only have B+W, so
need to drop non-BNH and non-WNH workers

Source code: m11_runakm.do

Run AKM for all CZs, skip over those that failed in m11_runakm.do
loop broke for cz 29503 (354th cz of 461 total)

\*----------------------------------------------------------------------------*/

// Basic setup
cap log close
set more off
clear
clear matrix
clear mata
set linesize 95
set rmsg on

// Set directories
local origdata "${raw_data}/mig5_pikqtime_1022.dta"
local matlabdir "${processed_data}/scratch_matlab"
local output_local "${processed_data}/akmoutput"

// Log
cap log close
log using "3_runakm.log", text replace

local quitonfail 1 // Stop execution if AKM fails on any CZs.
local czdatadir "${processed_data}/CZfiles"
local czdatafile "bwobs_cz"
local logdir "${output}/matlablogs"
//------------------------------------------------------------------------------
// Loop over all 17 CZs in paper sample
//------------------------------------------------------------------------------

*Get list of CZs by number of black-nh pik-qtime observations in 2019
use "`datadir'/1_czlist.dta
 keep if paper_cz==1
 // Drop alaska
  drop if cz>34100 & cz<34200
 // Code to limit to a specified list of CZs
  if "`czlist'"~="" {
    gen keep=0
    foreach c of numlist `czlist' {
      replace keep=1 if cz==`c'
    }
    keep if keep==1
    drop keep
  }
  if "`finishlist'"~="" {
    sort cz
    tempfile origlist
    save `origlist'
    use "`output_local'/AKMstats.dta"
    keep if timestamp>`finishlist' & timestamp<.
    keep cz
    sort cz
    merge 1:1 cz using `origlist'
    keep if _merge==2
    drop _merge
  }
gsort -blacknh
sort totbw // temporarily in *increasing* size for speedy testing.
local N_cz = _N
local cz = cz[1]
local czlist `cz'
forvalues rank = 2(1)`N_cz' {
	local cz = cz[`rank']
	local czlist `czlist' `cz'
}
di "Selected CZs, in sequence, are `czlist'"
di "Data file is `origdata'"

local sequence=1
foreach cz in `czlist' {

	timer clear 12
	timer on 12
	di "Entering loop for CZ #`sequence', `cz'"
	// use if cz==`cz' & (whitenh==1 | blacknh==1 | hispanic==1) & year<2020 using "`origdata'", clear
        use `czdatadir'/`czdatafile'`cz'.dta, clear
	assert blacknh == 1 | whitenh == 1 //check taht we only have blacknh + whitenh
        rename work_cz cz
	qui count
	di "Original sample has observation count=`r(N)'"
          keep if samecz==1
        qui count
	di "After limiting to CZ residents, sample has observation count=`r(N)'"
        gen age=(dofq(yq(year, quarter)) - dob)/365
	isid pik qtime
	sort sein seinunit pik qtime
	egen double firmnum=group(sein seinunit)
        egen double piknum=group(pik)
        drop if e>9999998
        gen y=ln(e)
	order piknum state qtime cz firmnum sein seinunit y  age
	// We are going to normalize a single industry to have zero mean firm effect
	// Note: 7225 is restaurants
        // For now, we have only 2-digit industry, so use that instead
	     // gen byte normind=(naics4d==7225)
        gen byte normind=(naics2d==72)
	sort piknum qtime
	export delimited piknum qtime firmnum y age cz normind ///
               using "`matlabdir'/data2matlab.raw", replace
	tempfile data_`cz'
	save `data_`cz''
	*Clean up, so we will know if AKM worked
	cap rm "`matlabdir'/datafrommatlab_cz.raw"

	*Run matlab to run the AKM model
	di "Starting the matlab call for CZ #`sequence', `cz'"
	cap noisily ! matlab -nodisplay -nosplash -batch ///
	 "firmAKM_callable('`matlabdir'/data2matlab.raw', '`matlabdir'/datafrommatlab')"
	di "Matlab call finished for CZ `cz'" 

	*Confirm that it worked
	local czdisp dne // default setting- if AKM worked, this macro will be updated to the cz code
	cap import delimited using "`matlabdir'/datafrommatlab_cz.raw", clear
	cap local czdisp = v1[1]
	if regexm("`czdisp'","[0-9]")==1 { // AKM output exists; old condition was "`czdisp'" != ""
		di v1[1]
		*Now read in statistics from Matlab -- R2, sample sizes, etc.;
		import delimited using "`matlabdir'/datafrommatlab_stats.raw", clear
		gen cz = regexr("`cz'", "[czd]+","")
		destring cz, replace
		su reffirm, meanonly
		local ref=r(min)
		tempfile stats
		save `stats', replace

		*check if AKM actually worked or if we are missing person or firm effects
		if meanpe == . | meanfe == . {
			if "`quitonfail'"=="1" {
                          di "AKM failed on CZ `cz' - stopping"
                          use `data_`cz'', clear
                          save "`matlabdir'/data_`cz'", replace
                          err
                        }
                        else {
                          di "AKM failed- move on to next CZ"		
                          use `data_`cz'', clear
                          save "`matlabdir'/failedrun.dta", replace
                        }
		}
		else {
                        *Move the log file somewhere more permanent
                        ! mv `matlabdir'/datafrommatlab_diary`cz'.log `logdir'/matlablog_`cz'.log
			*Read in the results
			import delimited using "`matlabdir'/datafrommatlab_firm.raw", clear
			rename v1 firmnum
			rename v2 akm_firm
			tempfile firmfx
			save `firmfx'
			import delimited using "`matlabdir'/datafrommatlab_person.raw", clear
			rename v1 piknum
			rename v2 akm_person
			tempfile personfx
			save `personfx'
			import delimited using "`matlabdir'/datafrommatlab_xbr.raw", clear
			rename v1 piknum
			rename v2 qtime
			rename v3 xb
                        rename v4 r
			tempfile xbeta_resid
			save `xbeta_resid'
			*import delimited using "`datadir'/datafrommatlab_r.raw", clear
			*rename v1 pik
			*rename v2 qtime
			*rename v3 r
			*tempfile resid
			*save `resid'

			use "`data_`cz''", replace
			qui levelsof firmnum if firmnum==`ref', clean
			local reffirmtxt =r(levels)
			merge m:1 piknum using `personfx', assert(1 3) nogen
			merge m:1 piknum qtime using `xbeta_resid', assert(1 3) nogen
			*merge m:1 pik qtime using `resid', assert(1 3) nogen
			merge m:1 firmnum using `firmfx', assert(1 3) nogen
			assert akm_person==. if akm_firm==.
			assert akm_person<. if akm_firm<.
			keep if akm_person<.
			keep pik qtime sein seinunit akm_person akm_firm xb r
			save "`output_local'/AKMests_`cz'.dta", replace

			use `stats'
			gen reffirm_orig="`reffirmtxt'"
                        gen thisobs=1
                        gen timestamp=clock("`c(current_date)' `c(current_time)'", "DMYhms")
                        format timestamp %tc
			if `sequence'!=1 append using "`output_local'/AKMstats.dta"
                        *append using "`output_local'/AKMstats.dta"
                        drop if cz==`cz' & thisobs!=1
                        drop thisobs
			save "`output_local'/AKMstats.dta", replace

			di "Finished loop for CZ #`sequence', `cz'"
			timer off 12
			qui timer list 12
			di "This loop took `r(t12)' seconds to complete"
			di "It finished on `c(current_date)' at `c(current_time)'"
			di ""
			di ""
		}
	}
	else if regexm("`czdisp'","[0-9]")==0 { // old code was "`czdisp'" == ""
		if "`quitonfail'"=="1" {
                  di "AKM failed on CZ `cz' - stopping"
                  use `data_`cz'', clear
                  save "`matlabdir'/data_`cz'", replace
                  err
                }
                else {
                  di "AKM failed- move on to next CZ"		
                  use `data_`cz'', clear
                  save "`matlabdir'/failedrun.dta", replace
                 }
	}

	local sequence=`sequence'+1
}

log close

