use ${output}/commutedensity, clear

keep if czgroupC<.

line dens_r0 dens_r1 distpt, ///
  lstyle(p1 p1 p2 p2 p3 p3) lpattern(solid dash solid dash solid dash) ///
  xscale(log) xlabel(1 5 10 25 50) ///
  by(czgroupC, title("Density of log commute distances by race, gender, region")) ///
  xtitle("Commute distance (miles, rescaled, log scale)") ///
  saving(${output}/fig_commutedensity, replace)
graph export ${output}/fig_commutedensity.png, replace
  
