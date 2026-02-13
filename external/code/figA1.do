clear all
set more off

set scheme plotplainblind


import excel using "../disclosed/Yi_tabs_T13T26_2.xlsx", sheet("4") cellrange(A3) firstrow clear
drop if czgroupC=="Other top 200 CZs"
encode czgroupC, gen(czgroup)

assert czgroupC=="New sunbelt CZs" if czgroup==1

line whe1_fr_e1 ble1_fr_e1  whe1_fr_e1_psi3 ble1_fr_e1_psi3 origdist if  czgroup==2, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid shortdash shortdash ) lcolor( sky reddish sky reddish) ///
     xscale(log extend) yscale(log extend range(0.0002 0.5)) ///
     xlabel(0.5 1 2 4 8 16 32) ylabel(0.001 0.01 0.1 0.5) ///
     subtitle("Older industrial CZs, non-college") ///
     legend(label(1 "White: all jobs") label(2 "Black: all jobs") ///
            order(1 2) ring(0) pos(4) cols(1)) ///
     xtitle("Miles from home (rescaled)") ytitle("Fraction of jobs in CZ") ///
     name(gp1e1, replace)
line whe2_fr_e2 ble2_fr_e2  whe2_fr_e2_psi3 ble2_fr_e2_psi3 origdist if  czgroup==2, ///
     lstyle(p1 p2 p1 p2) lpattern(solid solid shortdash shortdash) lcolor( sky reddish sky reddish) ///
     xscale(log extend) yscale(log extend range(0.0002 0.5)) ///
     xlabel(0.5 1 2 4 8 16 32) ylabel(0.001 0.01 0.1 0.5) ///
     subtitle("Older industrial CZs, college") ///
     legend(label(3 "White: good jobs") label(4 "Black: good jobs") ///
            order(3 4) ring(0) pos(4) cols(1)) ///
     xtitle("Miles from home (rescaled)") ytitle("Fraction of jobs in CZ") ///
     name(gp1e2, replace)
line whe1_fr_e1 ble1_fr_e1  whe1_fr_e1_psi3 ble1_fr_e1_psi3 origdist if  czgroup==1, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash) lcolor( sky reddish sky reddish) ///
     xscale(log extend) yscale(log extend range(0.0002 0.5)) ///
     xlabel(0.5 1 2 4 8 16 32) ylabel(0.001 0.01 0.1 0.5) ///
     subtitle("Sunbelt CZs, non-college") ///
     legend(off) ///
     xtitle("Miles from home (rescaled)") ytitle("Fraction of jobs in CZ") ///
     name(gp2e1, replace)
line whe2_fr_e2 ble2_fr_e2  whe2_fr_e2_psi3 ble2_fr_e2_psi3 origdist if  czgroup==1, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash) lcolor( sky reddish sky reddish) ///
     xscale(log extend) yscale(log extend range(0.0002 0.5)) ///
     xlabel(0.5 1 2 4 8 16 32) ylabel(0.001 0.01 0.1 0.5) ///
     subtitle("Sunbelt CZs, college") ///
     legend(off) ///
     xtitle("Miles from home (rescaled)") ytitle("Fraction of jobs in CZ") ///
     name(gp2e2, replace)

	      
graph combine gp1e1 gp1e2 gp2e1 gp2e2, ///
      title("") col(4) name(g1, replace) 

 
foreach v of varlist     whe1_fr_e1      ble1_fr_e1 whe1_fr_e1_psi3 ble1_fr_e1_psi3 {
  gen rel_`v'=`v'/whe1_fr_e1
}     
foreach v of varlist      whe2_fr_e2      ble2_fr_e2   whe2_fr_e2_psi3 ble2_fr_e2_psi3 {
  gen rel_`v'=`v'/whe2_fr_e2
}     
line rel_whe1_fr_e1 rel_ble1_fr_e1  rel_whe1_fr_e1_psi3 rel_ble1_fr_e1_psi3 origdist if  czgroup==2, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash ) lcolor( sky reddish sky reddish) ///
     xscale(log extend) yscale( range(0.7 1.7)) ///
     xlabel(0.5 1 2 4 8 16 32) ylabel(0.7 (0.1) 1.7) ///
     subtitle("Older industrial CZs, non-college") ///
     legend(off) ///
     xtitle("Miles from home (rescaled)") ytitle("Relative fraction of jobs in CZ") ///
     name(rgp1e1, replace)
line rel_whe2_fr_e2 rel_ble2_fr_e2  rel_whe2_fr_e2_psi3 rel_ble2_fr_e2_psi3 origdist if  czgroup==2, ///
     lstyle(p1 p2 p1 p2) lpattern(solid solid dash dash) lcolor( sky reddish sky reddish) ///
     xscale(log extend) yscale( range(0.7 1.7)) ///
     xlabel(0.5 1 2 4 8 16 32) ylabel(0.7 (0.1) 1.7) ///
     subtitle("Older industrial CZs, college") ///
     legend(off) ///
     xtitle("Miles from home (rescaled)") ytitle("Relative fraction of jobs in CZ") ///
     name(rgp1e2, replace)
line rel_whe1_fr_e1 rel_ble1_fr_e1  rel_whe1_fr_e1_psi3 rel_ble1_fr_e1_psi3 origdist if  czgroup==1, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash) lcolor( sky reddish sky reddish) ///
     xscale(log extend) yscale( range(0.7 1.7)) ///
     xlabel(0.5 1 2 4 8 16 32) ylabel(0.7 (0.1) 1.7) ///
     subtitle("Sunbelt CZs, non-college") ///
     legend(off) ///
     xtitle("Miles from home (rescaled)") ytitle("Relative fraction of jobs in CZ") ///
     name(rgp2e1, replace)
line rel_whe2_fr_e2 rel_ble2_fr_e2  rel_whe2_fr_e2_psi3 rel_ble2_fr_e2_psi3 origdist if  czgroup==1, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash) lcolor( sky reddish sky reddish) ///
     xscale(log extend) yscale( range(0.7 1.7)) ///
     xlabel(0.5 1 2 4 8 16 32) ylabel(0.7 (0.1) 1.7) ///
     subtitle("Sunbelt CZs, college") ///
     legend(off) ///
     xtitle("Miles from home (rescaled)") ytitle("Relative fraction of jobs in CZ") ///
     name(rgp2e2, replace)
     
     
graph combine rgp1e1 rgp1e2 rgp2e1  rgp2e2, ///
      title("Relative to share of all jobs within distance radius for whites") col(4) name(g2, replace)       

graph combine g1 g2, row(2)  saving(../results/figA1.gph, replace)    
graph export ../results/figA1.png, replace


