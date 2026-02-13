/*
* CLEANING 2
PHF CLEANING (SUBSAMPLE)
*/
clear
set more off
cd $raw_data


********************************************************************************
********************************************************************************
*************************** MAIN CLEANING **************************************
*2010Q1-2022Q1 (101-149);
* transform into pik-qtime format
forval q=101(1)149 {
noi dis "********** QTIME `q' **********"

* r1. only keep quarters with earnings above $3800
use pik sein seinunit e`q' state if (e`q'>=3800 & e`q'~=.) using phftemp_akm.dta, replace
rename e`q' e
gen qtime=`q'

* flag multiple jobs
sort pik qtime
by pik: gen multjob=(_N~=1)
by pik: gen N=_N
* drop obs with more than 20 jobs 
drop if N>20

* r3. age restriction
* add date of birth from icf, drop if dob missing or if not in age range 22-62
merge n:1 pik using m5_icf_dob.dta, keep(master match) nogen sorted
drop if dob==.
drop if (((qtime+99)-qofd(dob))/4<22) | (((qtime+99)-qofd(dob))/4>=63)

save m5_temp_qtime`q', replace
}

* Append/merge all separate files clear
forval q=101(1)149 {
append using m5_temp_qtime`q'.dta
dis "qtime `q'"
count
}

rename seinunit1 seinunit
sort pik qtime
* r3. drop "transitional quarters"
gen est=sein+"_"+seinunit
gen trq=0
by pik: replace trq=1 if ((est~=est[_n-1]) | (est~=est[_n+1])) & _n~=1 & _n~=_N 
* addressing multiple jobs (if there is any match in to multiple job firms, then quarter is not transitional)
sum N
local maxmultjobs=r(max)
forval i=1/`maxmultjobs' {
dis "`i'"
by pik: replace trq=0 if  (qtime[_n+`i']==qtime+1) & (multjob==0 & multjob[_n+`i']==1) & (est==est[_n+`i'])
by pik: replace trq=0 if  (qtime[_n-`i']==qtime-1) & (multjob==0 & multjob[_n-`i']==1) & (est==est[_n-`i'])
} 
drop est N
tab trq, miss
keep if trq==0
drop trq
* r2. drop spells with multiple jobs
tab multjob, miss
drop if multjob==1
drop multjob
save mig5_pikqtime_1022.dta, replace

************ here, this needs to happen after all qtimes are included
* r6: LF attachment restriction - drop if not observed in at least 8 quarters (in 8 year case)
* for efficiency purposes, clean before appending
use pik e using mig5_pikqtime_1022.dta, replace
collapse (count) count=e, by(pik) fast
tab count
drop if count<8
drop count
sort pik
tempfile piklist
save `piklist', replace
use mig5_pikqtime_1022.dta, replace
merge n:1 pik using `piklist', keep(match) nogen sorted 
save mig5_pikqtime_1022.dta, replace


* add workplace location and industry, drop if cz or naics2d missing
use m5_ecf_seinunit.dta, clear
rename leg_county cty_fips 
rename leg_state state
destring cty_fips, replace
assert cty_fips~=.
merge n:1 cty_fips using cw_cty_czone.dta, nogen keep(master match)
rename czone cz
gen naics2d=substr(naics2012fnl,1,2)
sort sein seinunit year quarter
tempfile ecf
save `ecf', replace
use mig5_pikqtime_1022.dta, replace
gen year=floor((qtime-1)/4+1985)
gen quarter=qtime-4*(year-1985)
sort sein seinunit year quarter
merge n:1 sein seinunit year quarter using `ecf', sorted keep(master match) keepusing(cty_fips cz naics2d)
tab _merge 
drop _merge
destring naics2d, replace force
drop if cz==.
drop if naics2d==.
save mig5_pikqtime_1022.dta, replace


* r7: drop pq observations in cz-ind cells with less than 200 pik-q obs - this requires full sample
use  pik cz naics2d e using mig5_pikqtime_1022.dta, replace
collapse (count) count=e, by(cz naics2d) fast
save mig5_cells_1022.dta, replace
keep if count<200
keep cz naics2d 
sort cz naics2d
tempfile droplist
save `droplist', replace

use mig5_pikqtime_1022.dta, replace
sort cz naics2d
merge n:1 cz naics2d using `droplist', sorted keep(master match)
tab _merge
keep if _merge==1
drop _merge
sort pik qtime
save mig5_pikqtime_1022.dta, replace



**************** done with restrictions **************************

* get final list of piks
use pik using mig5_pikqtime_1022.dta, replace
by pik: keep if _n==1
set type double
destring pik, gen(pikn) force
save mig5_pikqtime_1022_finalpiklist.dta, replace
use if pikn==. using mig5_pikqtime_1022_finalpiklist.dta, replace
egen double pikn2=group(pik)
replace pikn=pikn2+1000000000 if pikn==. & pikn2~=.
drop pikn2
bys pikn: assert _n==1
tempfile t
save `t', replace
use if pikn~=. using mig5_pikqtime_1022_finalpiklist.dta, replace
append using `t'
format pikn %20.0f
bys pikn: assert _n==1
sort pik
save mig5_pikqtime_1022_finalpiklist.dta, replace

* demographic variables 
import sas using $icf_dir/icf_us.sas7bdat, clear case(lower)
keep pik race ethnicity sex dob pob
tempfile icffile
save `icffile', replace
use mig5_pikqtime_1022.dta, replace
merge n:1 pik using `icffile', keep(master match) keepusing(race ethnicity sex)
assert _merge==3
drop _merge
gen whitenh = (race == "1" & ethnicity == "N") // dummy for white non-hispanic
gen blacknh = (race == "2" & ethnicity == "N") // dummy for black non-hispanic
gen female = (sex == "F") // dummy for female
gen hispanic = (ethnicity == "H")
drop ethnicity
save mig5_pikqtime_1022.dta, replace

