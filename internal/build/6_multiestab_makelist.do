
* Make a list of multi-establishment and single-establishment firms
use ${raw_data}/m5_ecf_seinunit
sort sein seinunit year quarter
by sein seinunit: keep if _n==1
by sein: gen nunits=_N
by sein: keep if _n==1
keep sein nunits
gen byte multiunit=(nunits>1)
su nunits, d
tab multiunit
save ${processed_data}/multiestab_makelist.dta, replace


