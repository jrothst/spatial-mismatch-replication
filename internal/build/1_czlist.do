***********************************
* 1_czlist
*
* Purpose: Make a list of CZs, with total pop (B/W) by race. We'll use this for the AKM loop
*
* Content: 
* 1. Set up environment
* 2. Read in data and collapse to cz level
* 3. Create indicator top 200 CZs (by B/W population) 
* 4. Create indicator for the 17 CZs in the paper
*************************************

//Set up environment
cap log close
log using 1_czlist.log, text replace

local origdata "${raw_data}/mig5_pikqtime_1022.dta"

// Make a list of top 200 CZs 
use e whitenh blacknh cz year if year==2015 & e<. using "`origdata'"
collapse (sum) whitenh blacknh, by(cz)

gen totbw=whitenh+blacknh
 // Drop alaska
gen alaska=(cz>34100 & cz<34200)
gsort alaska -totbw
by alaska: gen byte top200_bw=(_n<=200)*(1-alaska)
list

assert top200_bw==0 if alaska==1

tab top200 top200_bw

//Make list of 17 paper CZs
//Older industrial CZs
local czlist "19700 11600 16300 15200 19600 18000 11302 24300 21501 24701" 
//New sunbelt CZs
local czlist "`czlist' 38300 32000 9100 7000 38000 35001 33100"

gen byte paper_cz = 0
foreach cz in `czlist'{
	di "`cz'"
	replace paper_cz = 1 if cz == `cz'
}

list

sum paper_cz
assert abs(`=r(mean)' - 17/`=_N') <= .0001 

save ${processed_data}/1_czlist.dta, replace

log close

