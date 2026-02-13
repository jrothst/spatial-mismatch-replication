use ${output}/gridmulttable, clear



line wh_fr_n bl_fr_n wh_fr_psi3 bl_fr_psi3 radius if origdist<=50 & czgroupB<3, ///
     lstyle(p1 p2 p3 p1 p2 p3) lpattern(solid solid solid dash dash dash) ///
     xscale(log) yscale(log) ///
     xlabel(0.5 1 2 5 10 30) ylabel(0.01 0.1 0.5) ///
     by(czgroupB, title("Fraction of jobs and top-tercile firm jobs within radius r" /// 
                        "of average black and white resident", span) ) ///
     legend(label(1 "White" "residents:" "all jobs") label(2 "Black" "residents:" "all jobs") ///
            label(3 "Hispanic" "residents:" "all jobs") label(4 "White" "residents:" "good jobs") ///
            label(5 "Black" "residents:" "good jobs") label(6 "Hispanic" "residents:" "good jobs")) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Fraction of jobs in CZ") ///
     saving(${output}/fig_accessgraphs.gph, replace)     
graph export ${output}/fig_accessgraphs.png, replace

foreach v of varlist wh_fr_n bl_fr_n wh_fr_psi3 bl_fr_psi3 {
  gen pct_`v'=`v'/wh_fr_n
}
line pct_wh_fr_n pct_bl_fr_n pct_wh_fr_psi3 pct_bl_fr_psi3 radius if origdist<=50 & czgroupB<3, ///
     lstyle(p1 p2 p3 p1 p2 p3) lpattern(solid solid solid dash dash dash) ///
     xscale(log) yscale(log) ///
     xlabel(0.5 1 2 5 10 30) ///
     by(czgroupB, title("Fraction of jobs and top-tercile firm jobs within radius r" /// 
                        "of average Black, white, and Hispanic resident", span) ///
                  subtitle("Relative to fraction of jobs within radius r of avg. white resident", span) ) ///
     legend(label(1 "White" "residents:" "all jobs") label(2 "Black" "residents:" "all jobs") ///
            label(3 "Hispanic" "residents:" "all jobs") label(4 "White" "residents:" "good jobs") ///
            label(5 "Black" "residents:" "good jobs") label(6 "Hispanic" "residents:" "good jobs")) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Relative fraction of jobs in CZ") ///
     saving(${output}/fig_accessgraphs_relative.gph, replace)
graph export ${output}/fig_accessgraphs_relative.png, replace


line whe1_fr_e1 ble1_fr_e1  whe1_fr_e1_psi3 ble1_fr_e1_psi3 origdist if  czgroupC==1, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash ) ///
     xscale(log extend) yscale(log extend) ///
     xlabel(0.5 1 2 5 10 30) ylabel(0.001 0.01 0.1 0.5) ///
     subtitle("Older industrial CZs, non-college") ///
     legend(label(1 "White: all jobs") label(2 "Black: all jobs") label(3 "White: good jobs") label(4 "Black: good jobs") ///
            order(1 2 3 4) ring(0) pos(4) cols(1)) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Fraction of jobs in CZ") ///
     name(gp1e1, replace)
line whe2_fr_e2 ble2_fr_e2  whe2_fr_e2_psi3 ble2_fr_e2_psi3 origdist if  czgroupC==1, ///
     lstyle(p1 p2 p1 p2) lpattern(solid solid dash dash) ///
     xscale(log extend) yscale(log extend) ///
     xlabel(0.5 1 2 5 10 30) ylabel(0.001 0.01 0.1 0.5) ///
     subtitle("Older industrial CZs, college") ///
     legend(off) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Fraction of jobs in CZ") ///
     name(gp1e2, replace)
line whe1_fr_e1 ble1_fr_e1  whe1_fr_e1_psi3 ble1_fr_e1_psi3 origdist if  czgroupC==2, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash) ///
     xscale(log extend) yscale(log extend) ///
     xlabel(0.5 1 2 5 10 30) ylabel(0.001 0.01 0.1 0.5) ///
     subtitle("Sunbelt CZs, non-college") ///
     legend(off) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Fraction of jobs in CZ") ///
     name(gp2e1, replace)
line whe2_fr_e2 ble2_fr_e2  whe2_fr_e2_psi3 ble2_fr_e2_psi3 origdist if  czgroupC==2, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash) ///
     xscale(log extend) yscale(log extend) ///
     xlabel(0.5 1 2 5 10 30) ylabel(0.001 0.01 0.1 0.5) ///
     subtitle("Sunbelt CZs, college") ///
     legend(off) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Fraction of jobs in CZ") ///
     name(gp2e2, replace)

 
foreach v of varlist     whe1_fr_e1      ble1_fr_e1 whe1_fr_e1_psi3 ble1_fr_e1_psi3 {
  gen rel_`v'=`v'/whe1_fr_e1
}     
foreach v of varlist      whe2_fr_e2      ble2_fr_e2   whe2_fr_e2_psi3 ble2_fr_e2_psi3 {
  gen rel_`v'=`v'/whe2_fr_e2
}     
line rel_whe1_fr_e1 rel_ble1_fr_e1  rel_whe1_fr_e1_psi3 rel_ble1_fr_e1_psi3 origdist if  czgroupC==1, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash ) ///
     xscale(log extend) yscale( range(0.5 1.7)) ///
     xlabel(0.5 1 2 5 10 30) ylabel(0.5 (0.1) 1.7) ///
     subtitle("Relative to non-college white-all jobs") ///
     legend(off) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Relative fraction of jobs in CZ") ///
     name(rgp1e1, replace)
line rel_whe2_fr_e2 rel_ble2_fr_e2  rel_whe2_fr_e2_psi3 rel_ble2_fr_e2_psi3 origdist if  czgroupC==1, ///
     lstyle(p1 p2 p1 p2) lpattern(solid solid dash dash) ///
     xscale(log extend) yscale( range(0.5 1.7)) ///
     xlabel(0.5 1 2 5 10 30) ylabel(0.5 (0.1) 1.7) ///
     subtitle("Relative to college white-all jobs") ///
     legend(off) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Relative fraction of jobs in CZ") ///
     name(rgp1e2, replace)
line rel_whe1_fr_e1 rel_ble1_fr_e1  rel_whe1_fr_e1_psi3 rel_ble1_fr_e1_psi3 origdist if  czgroupC==2, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash) ///
     xscale(log extend) yscale( range(0.5 1.7)) ///
     xlabel(0.5 1 2 5 10 30) ylabel(0.5 (0.1) 1.7) ///
     subtitle("Relative to non-college white-all jobs") ///
     legend(off) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Relative fraction of jobs in CZ") ///
     name(rgp2e1, replace)
line rel_whe2_fr_e2 rel_ble2_fr_e2  rel_whe2_fr_e2_psi3 rel_ble2_fr_e2_psi3 origdist if  czgroupC==2, ///
     lstyle(p1 p2 p1 p2 ) lpattern(solid solid dash dash) ///
     xscale(log extend) yscale( range(0.5 1.7)) ///
     xlabel(0.5 1 2 5 10 30) ylabel(0.5 (0.1) 1.7) ///
     subtitle("Relative to college white-all jobs") ///
     legend(off) ///
     xtitle("Distance from home (miles, rescaled)") ytitle("Relative fraction of jobs in CZ") ///
     name(rgp2e2, replace)
     
     
graph combine gp1e1 gp2e1 gp1e2 gp2e2, ///
      title("") col(4) name(g1, replace) ycommon xcommon
graph combine rgp1e1 rgp2e1 rgp1e2 rgp2e2, ///
      title("") col(4) name(g2, replace) ycommon xcommon     

graph combine g1 g2, row(2)  name(${output}/fig_accessgraphs_byeduc, replace)    
graph export ${output}/fig_accessgraphs_byeduc.png, replace


