// Make a dataset of percentiles of commuting distance for specified CZs, for use in normalizing data

local k=0
forvalues i=1/100000 {
  cap confirm file ${processed_data}/grids/inddata_cz`i'.dta
  if !_rc {
    local k=`k'+1
    di "Starting commute distance calculations for CZ `i' (number `k')
    use commutedist using ${processed_data}/grids/inddata_cz`i', clear
    collapse (mean) avg=commutedist ///
             (p10)  p10=commutedist ///
             (p25)  p25=commutedist ///
             (p50)  p50=commutedist ///
             (p75)  p75=commutedist ///
             (p90)  p90=commutedist
    gen cz=`i'
    tempfile cz`k'
    save `cz`k''
  }
}

drop _all
use `cz1'
forvalues i=2/`k' {
  append using `cz`i''
}
save {processed_data}/commutedist.dta, replace

