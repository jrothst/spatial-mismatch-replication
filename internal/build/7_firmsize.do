*Program uses original LEHD data to create firm size that includes black, white, and hispanic workers
local origdata "${raw_data}/mig5_pikqtime_1022.dta"

*Create list of 17 CZs
use "`datadir'/v6/1_czlist.dta
keep if paper_cz==1
local N_cz = _N
local first_cz = cz[1]
local czlist `first_cz'
forvalues rank = 2(1)`N_cz' {
	local cz = cz[`rank']
	local czlist `czlist' `cz'
}


*Read in each CZ, collapse to sein level 
di "List of CZs: `czlist'"
local append_list
foreach cz in `czlist'{
	
	di "Starting CZ - `cz'"
	
	use e whitenh blacknh hispanic cz year sein qtime if cz == `cz' & year < 2020 & e<. using "`origdata'", clear
	*Keep only subset that we prviously would have kept
	keep if whitenh==1 | blacknh==1 | hispanic == 1
	keep if e<9999998
	
	collapse (count) firmsize_q=e, by(sein qtime cz)
	
	collapse (max) firmsize_max= firmsize_q, by(sein cz)
	keep cz sein firmsize_max
	
	*Append data
	if `cz' == `first_cz'{
	tempfile firm_data
	save `firm_data'
		
	}
	else{
	 append using `firm_data'
	 save `firm_data', replace
	}
	
}

isid sein cz
sum firmsize_max, d

save "${processed_data}/firmsize.dta", replace

