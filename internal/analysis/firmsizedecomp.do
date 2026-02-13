* Program to examine the distribution of establishment effects across establishments within firms,
* by firm size category

local cz=100

cap program drop preponecz
program define preponecz
args cz
use akm_person akm_estab e sein seinunit qtime akmsamp racegp female if akmsamp==1 ///
    using ${processed_data}/grids/inddata_cz`cz', clear
gen wh_f=(racegp==0)*female
gen wh_m=(racegp==0)*(1-female)
gen bl_f=(racegp==1)*female
gen bl_m=(racegp==1)*(1-female)
rename akm_person alpha
rename akm_estab psi
collapse (mean) alpha psi e (sum) bl_? wh_? (count) estabsize_q=e, by(sein seinunit qtime)
sort sein seinunit qtime
by sein seinunit: egen estabsize_totpq=sum(estabsize_q)
bys sein seinunit: egen estabsize_avg=mean(estabsize_q)
bys sein seinunit: egen estabsize_max=max(estabsize_q)
by sein seinunit: egen estabtot_alpha=sum(alpha*estabsize_q)
by sein seinunit: egen estabtot_psi=sum(psi*estabsize_q)
gen estabavg_alpha=estabtot_alpha/estabsize_totpq
gen estabavg_psi=estabtot_psi/estabsize_totpq
drop estabtot_alpha estabtot_psi 

sort sein qtime seinunit
by sein: egen firmsize_totpq=sum(estabsize_q)
by sein qtime: egen firmsize_q=sum(estabsize_q)
// Compute average firm size across quarters
  egen oneperfirmq=tag(sein qtime) if firmsize_q<.
  gen tmp_firmsize_q=firmsize_q if oneperfirmq==1
  by sein: egen tmp_firmsize_avg=mean(tmp_firmsize_q)
  replace tmp_firmsize_avg=0 if tmp_firmsize_avg==.
  by sein: egen firmsize_avg=max(tmp_firmsize_avg)
  drop oneperfirm tmp_firmsize_q tmp_firmsize_avg
by sein: egen firmsize_max=max(firmsize_q)
by sein: egen firmtot_psi=sum(psi*estabsize_q)
by sein: egen firmtot_alpha=sum(alpha*estabsize_q)
gen firmavg_psi=firmtot_psi/firmsize_totpq
gen firmavg_alpha=firmtot_alpha/firmsize_totpq
drop firmtot*
gen estabdiff_psi=estabavg_psi-firmavg_psi
gen estabdiff_alpha=estabavg_alpha-firmavg_alpha


collapse (mean) firmavg_alpha estabavg_alpha estabdiff_alpha ///
                firmavg_psi   estabavg_psi   estabdiff_psi ///
                firmsize_max firmsize_totpq firmsize_avg estabsize_totpq estabsize_max estabsize_avg ///
         (sum) bl_? wh_?, ///
         by(sein seinunit)
sort sein seinunit
by sein: gen byte multiestab=(_N>1)
expand 6
sort sein seinunit
by sein seinunit: gen obsnum=_n
gen racegp=(inlist(obsnum, 3, 4)) + 2*(inlist(obsnum, 5, 6))
gen female=inlist(obsnum,2, 4, 6)
gen count=wh_f if racegp==0 & female==1
replace count=wh_m if racegp==0 & female==0
replace count=bl_f if racegp==1 & female==1
replace count=bl_m if racegp==1 & female==0
gen cz=`cz'
end



// Grab a list of 17 paper CZs
use ${processed_data}1_czlist.dta
keep if paper_cz==1
gsort totbw
local nczs=_N
forvalues i=1/`nczs' {
 local cznum`i'=cz[`i']
}

do sub_makeczgps
tempfile allczs
forvalues i=1/`nczs' {
  local cz=`cznum`i''
  di "Starting CZ #`i'/`nczs', `cz'"
  preponecz `cz'
  if `i'!=1 append using `allczs'
  save `allczs', replace
  local first=0
}

makeczgps

// Figure out median firm size
//_pctile firmsize_max if firmsize_max>10 [aw=estabsize_totpq], p(50)
*local cutoff=r(r1)
*Hardcode cutoff as 276 - this is what it is in the paper. 
local cutoff=276
return list

gen byte firmsizegp=1 if (firmsize_max==1)
replace firmsizegp=2 if(firmsize_max>1 & firmsize_max<=10)
replace firmsizegp=3 if firmsize_max>10 & firmsize_max<`cutoff'
replace firmsizegp=4 if firmsize_max>=`cutoff' & firmsize_max<.
label def sizegp 1 "1" 2 "2-10" 3 "11-`cutoff'" 4 ">`cutoff'"
label values firmsizegp sizegp

tempfile assembled collapse1 collapse2 collapse3 collapse4
save `assembled'
use `assembled'
collapse (mean) firmavg_alpha estabavg_alpha estabdiff_alpha ///
                firmavg_psi   estabavg_psi   estabdiff_psi ///
                firmsize_max firmsize_totpq firmsize_avg estabsize_max estabsize_totpq estabsize_avg ///
         (sd)   sd_firmavg_alpha=firmavg_alpha sd_estabavg_alpha=estabavg_alpha ///
                sd_estabdiff_alpha=estabdiff_alpha sd_firmavg_psi=firmavg_psi ///
                sd_estabavg_psi=estabavg_psi sd_estabdiff_psi=estabdiff_psi ///
	 (rawsum) npq=count ///
         [fw=count], by(czgroupC firmsizegp multiestab)
save `collapse1'
use `assembled'
collapse (mean) firmavg_alpha estabavg_alpha estabdiff_alpha ///
                firmavg_psi   estabavg_psi   estabdiff_psi ///
                firmsize_max firmsize_totpq firmsize_avg estabsize_max estabsize_totpq estabsize_avg ///
         (sd)   sd_firmavg_alpha=firmavg_alpha sd_estabavg_alpha=estabavg_alpha ///
                sd_estabdiff_alpha=estabdiff_alpha sd_firmavg_psi=firmavg_psi ///
                sd_estabavg_psi=estabavg_psi sd_estabdiff_psi=estabdiff_psi ///
	 (rawsum) npq=count ///
         [fw=count], by(czgroupC firmsizegp multiestab racegp)
save `collapse2'
use `assembled'
collapse (mean) firmavg_alpha estabavg_alpha estabdiff_alpha ///
                firmavg_psi   estabavg_psi   estabdiff_psi ///
                firmsize_max firmsize_totpq firmsize_avg estabsize_max estabsize_totpq estabsize_avg ///
         (sd)   sd_firmavg_alpha=firmavg_alpha sd_estabavg_alpha=estabavg_alpha ///
                sd_estabdiff_alpha=estabdiff_alpha sd_firmavg_psi=firmavg_psi ///
                sd_estabavg_psi=estabavg_psi sd_estabdiff_psi=estabdiff_psi ///
	 (rawsum) npq=count ///
         [fw=count], by(czgroupC firmsizegp multiestab female)
save `collapse3'
use `assembled'
collapse (mean) firmavg_alpha estabavg_alpha estabdiff_alpha ///
                firmavg_psi   estabavg_psi   estabdiff_psi ///
                firmsize_max firmsize_totpq firmsize_avg estabsize_max estabsize_totpq estabsize_avg ///
         (sd)   sd_firmavg_alpha=firmavg_alpha sd_estabavg_alpha=estabavg_alpha ///
                sd_estabdiff_alpha=estabdiff_alpha sd_firmavg_psi=firmavg_psi ///
                sd_estabavg_psi=estabavg_psi sd_estabdiff_psi=estabdiff_psi ///
	 (rawsum) npq=count ///
         [fw=count], by(czgroupC firmsizegp multiestab racegp female)
save `collapse4'
use `collapse1'
append using `collapse2'
append using `collapse3'
append using `collapse4'
gen pct_betweenfirm=sd_firmavg_psi^2/sd_estabavg_psi^2 if multiestab==1
gen pct_approxerr=(sd_estabavg_psi^2 - sd_firmavg_psi^2 - sd_estabdiff_psi^2)/(sd_estabavg_psi^2) if multiestab==1

save ${output}/firmsizedecomp.dta, replace



