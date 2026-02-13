

import excel using "../disclosed/Yi_tabs_T13T26_1.xlsx", sheet("3") cellrange(A3) firstrow clear

set scheme plotplainblind

drop if czgroupC=="Other top 200 CZs"

line wh_psi bl_psi commutedist if czgroupC=="Older industrial CZs", ///
  lpattern(solid dash) lcolor( sky reddish) ///
  xscale(log extend) xlabel(0.5 1 2 5 10 30) ylabel(0.1 (0.05) 0.3) ///
  xtitle("Commute distance (miles)") ytitle("Average AKM establishment effect") ///
  title("") subtitle("Older industrial CZs") ///
  legend(label(1 "White") label(2 "Black") cols(1) ring(0) pos(4)) ///
  name(rustbelt, replace) nodraw
line wh_psi bl_psi commutedist if czgroupC=="New sunbelt CZs", ///
  lpattern(solid dash) lcolor( sky reddish) ///
  xscale(log extend) xlabel(0.5 1 2 5 10 30) ylabel(0.1 (0.05) 0.3) ///
  xtitle("Commute distance (miles)") ytitle(" ") ///
  title("") subtitle("Newer sunbelt CZs") legend(off) ///
  name(sunbelt, replace) nodraw

graph combine rustbelt sunbelt, saving(../results/fig2.gph, replace)
graph export ../results/fig2.png, replace

