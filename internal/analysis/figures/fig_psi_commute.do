
use ${output}/psi_commute_groups, clear
keep if czgroupC<.

keep if czgroupC<3

line wh_psi bl_psi  commutedist, ///
     by(czgroupC, title("Average firm quality by commute distance") ///
                  note("Note: Commute distances are rescaled at the CZ level to set the 75th percentile to 16 miles," ///
                       "local linear models are fit for each CZ, then CZs are averaged by group."))      xscale(log) xlabel(1 5 10 25 50) ///
     xtitle("Commute distance (miles, rescaled)") ytitle("Average firm premium") ///
     legend(label(1 "White") label(2 "Black")) ///
     saving(${output}/fig_psi_commute, replace)
graph export ${output}/fig_psi_commute.png, replace


